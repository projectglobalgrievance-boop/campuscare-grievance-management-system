"""AI service for the Student Grievance Management app.

Run (dev):
    .venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000

With the Firestore emulator (optional, enables duplicate detection + write-back):
    FIRESTORE_EMULATOR_HOST=localhost:8080 .venv/bin/uvicorn main:app --port 8000
"""
from __future__ import annotations

import asyncio
import contextlib
from datetime import datetime, timezone

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

from app import firestore_client
from app.escalation import run_escalation_sweep
from app.geofence import is_inside_campus, zone_name
from app.pipeline import analyze_complaint

ESCALATION_SWEEP_SECONDS = 3600


@contextlib.asynccontextmanager
async def _lifespan(app):
    async def sweeper():
        while True:
            db = firestore_client.get_db()
            if db is not None:
                try:
                    n = await asyncio.to_thread(run_escalation_sweep, db)
                    if n:
                        print(f"[escalation] escalated {n} stale complaint(s)")
                except Exception as e:  # sweep must never kill the service
                    print(f"[escalation] sweep failed: {e}")
            await asyncio.sleep(ESCALATION_SWEEP_SECONDS)

    task = asyncio.create_task(sweeper())
    yield
    task.cancel()


app = FastAPI(title="Grievance AI Service", version="1.0.0",
              lifespan=_lifespan)


class AnalyzeRequest(BaseModel):
    complaintId: str | None = None
    description: str = Field(default="", max_length=4000)
    lat: float
    lng: float
    capturedAt: datetime | None = None
    # Demo/test accounts only (seeded demoTester users): skip the geofence.
    bypassGeofence: bool = False
    # Department id the student picked on the form (None = let the AI route).
    department: str | None = None


class GeofenceRequest(BaseModel):
    lat: float
    lng: float


@app.get("/", include_in_schema=False)
def root():
    from fastapi.responses import RedirectResponse
    return RedirectResponse("/docs")


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "firestore": firestore_client.get_db() is not None}


@app.post("/escalation/run")
def escalation_run() -> dict:
    """Manual trigger for the SLA sweep (also runs hourly in-process)."""
    db = firestore_client.get_db()
    if db is None:
        raise HTTPException(status_code=503, detail="Firestore not available")
    return {"escalated": run_escalation_sweep(db)}


@app.post("/geofence/check")
def geofence_check(req: GeofenceRequest) -> dict:
    inside = is_inside_campus(req.lat, req.lng)
    return {"inside": inside, "zone": zone_name(req.lat, req.lng) if inside else None}


@app.post("/analyze")
def analyze(req: AnalyzeRequest) -> dict:
    captured = req.capturedAt or datetime.now(timezone.utc)
    if captured.tzinfo is None:
        captured = captured.replace(tzinfo=timezone.utc)

    recent = firestore_client.fetch_recent_complaints()
    try:
        result = analyze_complaint(req.description, req.lat, req.lng,
                                   captured, recent,
                                   enforce_geofence=not req.bypassGeofence,
                                   department=req.department)
    except ValueError as e:
        if str(e) == "outside_campus":
            raise HTTPException(
                status_code=422,
                detail={"code": "outside_campus",
                        "message": "You're outside the campus — complaints can "
                                   "only be submitted from inside campus."})
        raise

    written = False
    if req.complaintId:
        written = firestore_client.write_enrichment(
            req.complaintId, result["aliasName"], result["ai"],
            result["ai"]["duplicateOf"])

    return {**result, "writtenToFirestore": written}

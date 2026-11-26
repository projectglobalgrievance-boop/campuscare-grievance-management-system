"""Optional Firestore integration (emulator-aware).

The pipeline is fully functional without Firestore (standalone mode: the app
writes enrichment itself). When Firestore IS reachable the service also:
  - pulls recent complaints for duplicate detection
  - writes the enrichment back to the complaint document

Emulator: set FIRESTORE_EMULATOR_HOST=localhost:8080 (no credentials needed).
Production: set GOOGLE_APPLICATION_CREDENTIALS to a service-account JSON.
"""
from __future__ import annotations

import os
from datetime import datetime, timedelta, timezone

PROJECT_ID = os.environ.get("FIREBASE_PROJECT_ID", "demo-campuscare")

_db = None
_init_failed = False


def emulator_credential_if_needed():
    """firebase-admin insists on credentials even against emulators; hand it
    an anonymous one when emulator env vars are present. Returns None (=ADC)
    for real projects."""
    if not (os.environ.get("FIRESTORE_EMULATOR_HOST")
            or os.environ.get("FIREBASE_AUTH_EMULATOR_HOST")):
        return None
    import google.auth.credentials
    from firebase_admin import credentials

    class _Anon(credentials.Base):
        def get_credential(self):
            return google.auth.credentials.AnonymousCredentials()

    return _Anon()


def get_db():
    global _db, _init_failed
    if _db is not None or _init_failed:
        return _db
    try:
        import firebase_admin
        from firebase_admin import firestore
        if not firebase_admin._apps:
            firebase_admin.initialize_app(
                credential=emulator_credential_if_needed(),
                options={"projectId": PROJECT_ID})
        _db = firestore.client()
    except Exception:
        _init_failed = True
        _db = None
    return _db


def fetch_recent_complaints(hours: int = 24) -> list[dict]:
    db = get_db()
    if db is None:
        return []
    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)
    try:
        docs = (db.collection("complaints")
                  .where("submittedAt", ">=", cutoff)
                  .stream())
        out = []
        for doc in docs:
            d = doc.to_dict()
            out.append({
                "id": doc.id,
                "category": (d.get("ai") or {}).get("category"),
                "zone": (d.get("location") or {}).get("zoneName"),
                "submittedAt": d.get("submittedAt"),
                "status": d.get("status"),
            })
        return out
    except Exception:
        return []


def write_enrichment(complaint_id: str, alias: str, ai: dict,
                     duplicate_of: str | None) -> bool:
    db = get_db()
    if db is None:
        return False
    try:
        from firebase_admin import firestore
        # Top-level `department` is what department admins query and what the
        # rules scope them by; set it here too so complaints from app builds
        # that predate the department picker still reach the right admin.
        update = {"aliasName": alias, "ai": ai, "department": ai["department"],
                  "analyzedAt": firestore.SERVER_TIMESTAMP}
        db.collection("complaints").document(complaint_id).update(update)
        if duplicate_of:
            from app.priority import bump_priority
            orig_ref = db.collection("complaints").document(duplicate_of)
            orig = orig_ref.get()
            if orig.exists:
                orig_ai = orig.to_dict().get("ai") or {}
                level = orig_ai.get("priority")
                if level:
                    orig_ref.update({"ai.priority": bump_priority(level),
                                     "ai.duplicateCount":
                                         (orig_ai.get("duplicateCount") or 0) + 1})
        return True
    except Exception:
        return False

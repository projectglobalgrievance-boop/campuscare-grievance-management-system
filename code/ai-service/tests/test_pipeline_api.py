from datetime import datetime, timezone

import pytest
from fastapi.testclient import TestClient

from app.pipeline import analyze_complaint
from main import app

client = TestClient(app)

INSIDE = {"lat": 12.92665, "lng": 77.52640}  # Canteen zone (real GAT campus)
OUTSIDE = {"lat": 12.8990, "lng": 77.5121}   # old placeholder site, ~3 km away


def test_pipeline_end_to_end_inside():
    result = analyze_complaint(
        "dustbin full and smelling near the canteen, this is really bad!",
        INSIDE["lat"], INSIDE["lng"], datetime.now(timezone.utc), [])
    ai = result["ai"]
    assert result["zoneName"] == "Canteen"
    assert ai["category"] == "Cleanliness"
    assert ai["priority"] in ("Medium", "High", "Critical")
    assert ai["department"] == "housekeeping"
    assert "Canteen" in ai["tagline"]
    assert len(result["aliasName"].split()) == 2


def test_pipeline_rejects_outside():
    with pytest.raises(ValueError, match="outside_campus"):
        analyze_complaint("anything", OUTSIDE["lat"], OUTSIDE["lng"])


def test_api_health():
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["status"] == "ok"


def test_api_geofence_check():
    r = client.post("/geofence/check", json=INSIDE)
    assert r.json() == {"inside": True, "zone": "Canteen"}
    r = client.post("/geofence/check", json=OUTSIDE)
    assert r.json() == {"inside": False, "zone": None}


def test_api_analyze_inside():
    r = client.post("/analyze", json={
        "description": "fan not working in room 204", **INSIDE})
    assert r.status_code == 200
    body = r.json()
    assert body["ai"]["category"] == "Electrical"
    assert body["ai"]["department"] == "electrical_maintenance"


def test_api_analyze_outside_is_422():
    r = client.post("/analyze", json={"description": "x", **OUTSIDE})
    assert r.status_code == 422
    assert r.json()["detail"]["code"] == "outside_campus"


def test_api_analyze_outside_with_bypass_succeeds():
    # Demo/test accounts skip the geofence and fall back to the generic zone.
    r = client.post("/analyze", json={
        "description": "fan not working", "bypassGeofence": True, **OUTSIDE})
    assert r.status_code == 200
    assert r.json()["zoneName"] == "Campus"


def test_description_is_truncated():
    result = analyze_complaint("water leaking " * 500,
                               INSIDE["lat"], INSIDE["lng"])
    assert result["ai"]["category"] == "Plumbing"  # still classified sanely


def test_student_department_decides_routing():
    # The text reads as Cleanliness, but the student routed it to Electrical.
    ai = analyze_complaint(
        "dustbin full and smelling near the canteen",
        INSIDE["lat"], INSIDE["lng"], department="electrical_maintenance")["ai"]
    assert ai["department"] == "electrical_maintenance"
    assert ai["departmentName"] == "Maintenance"
    assert ai["category"] == "Electrical"
    assert ai["predictedCategory"] == "Cleanliness"
    assert ai["departmentSource"] == "student"


def test_unknown_department_falls_back_to_ai():
    ai = analyze_complaint("fan not working in classroom",
                           INSIDE["lat"], INSIDE["lng"],
                           department="nonsense")["ai"]
    assert ai["departmentSource"] == "ai"
    assert ai["department"] == "electrical_maintenance"


def test_api_analyze_accepts_department():
    r = client.post("/analyze", json={**INSIDE, "description": "tap leaking",
                                      "department": "hostel_office"})
    assert r.status_code == 200
    assert r.json()["ai"]["department"] == "hostel_office"

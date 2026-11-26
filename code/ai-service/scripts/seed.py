"""Seed the Firebase EMULATORS with demo users, departments, campus config and
~40 realistic complaints (enriched by the real AI pipeline).

Usage (emulators must be running):
    cd code/ai-service
    FIRESTORE_EMULATOR_HOST=localhost:8080 \
    FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 \
    ./.venv/bin/python scripts/seed.py

Demo accounts created:
    student@demo.com / password123   (student)
    admin@demo.com   / password123   (admin — custom claim admin=true)
"""
from __future__ import annotations

import json
import os
import random
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import firebase_admin
from firebase_admin import auth, firestore

from app.categories import DEPARTMENT_ADMINS, DEPARTMENT_NAMES, DEPARTMENT_ROUTING
from app.pipeline import analyze_complaint

if "FIRESTORE_EMULATOR_HOST" not in os.environ and os.environ.get("SEED_TARGET") != "prod":
    sys.exit(
        "Refusing to run: FIRESTORE_EMULATOR_HOST not set (emulator only).\n"
        "To seed a REAL project on purpose (it OVERWRITES seed-*** complaints "
        "and the demo logins):\n"
        "  SEED_TARGET=prod FIREBASE_PROJECT_ID=<project-id> \\\n"
        "  GOOGLE_APPLICATION_CREDENTIALS=serviceAccount.json \\\n"
        "  ./.venv/bin/python scripts/seed.py")

from app.firestore_client import emulator_credential_if_needed

PROJECT_ID = os.environ.get("FIREBASE_PROJECT_ID", "demo-campuscare")
firebase_admin.initialize_app(
    credential=emulator_credential_if_needed(),
    options={"projectId": PROJECT_ID})
db = firestore.client()
rng = random.Random(2026)

GEO = json.loads((Path(__file__).resolve().parent.parent / "data" /
                  "campus_geo.json").read_text())

# A representative in-zone point for each zone (centroid of its rectangle).
ZONE_POINTS = {}
for z in GEO["zones"]:
    lats = [p["lat"] for p in z["polygon"]]
    lngs = [p["lng"] for p in z["polygon"]]
    ZONE_POINTS[z["name"]] = (sum(lats) / len(lats), sum(lngs) / len(lngs))

SAMPLES = [
    ("dustbin overflowing and smelling badly", "Canteen"),
    ("garbage piled up near the entrance", "Grounds"),
    ("toilet very dirty, no cleaning since days", "Block A"),
    ("washroom tap leaking continuously", "Block B"),
    ("fan not working in room 204", "Block A"),
    ("tube light flickering in the reading hall", "Library"),
    ("exposed wire near switchboard, very dangerous!", "Block C"),
    ("projector not turning on in lecture hall 2", "Block B"),
    ("no water supply in washroom", "Hostel"),
    ("water cooler leaking, floor is wet", "Canteen"),
    ("bench broken in the CS lab", "Block C"),
    ("chair wobbling badly in room 305", "Block B"),
    ("window pane cracked near the stairs", "Library"),
    ("mess food quality very bad today", "Hostel"),
    ("hot water not available in B block bathrooms", "Hostel"),
    ("wifi not working, affecting online classes", "Library"),
    ("internal marks not updated on the portal", "Block A"),
    ("stray dogs roaming near the parking area", "Parking"),
    ("bicycle stand full, no space to park", "Parking"),
    ("drain blocked, water logging after rain", "Grounds"),
    ("AC not cooling in the seminar hall", "Block C"),
    ("notice board fallen in the corridor", "Block B"),
    ("drinking water filter needs service", "Canteen"),
    ("flush not working in second floor washroom", "Block A"),
    ("power socket sparking in physics lab", "Block C"),
    ("cupboard door hanging loose in staff room", "Block A"),
    ("bad smell from washroom near canteen", "Canteen"),
    ("lab stools missing in chemistry lab", "Block B"),
    ("hostel corridor lights not working", "Hostel"),
    ("washing machine broken in hostel", "Hostel"),
    ("printer out of service in library", "Library"),
    ("exam hall seating very congested", "Block B"),
    ("water leaking from ceiling in room 410", "Block C"),
    ("food waste spilled outside mess", "Hostel"),
    ("id card scanner at gate not working", "Parking"),
    ("cobwebs and dust all over the stairs", "Block A"),
    ("geyser not heating in hostel bathroom", "Hostel"),
    ("whiteboard markers never available", "Block B"),
    ("ground has broken glass near basketball court", "Grounds"),
    ("sports equipment room lock broken", "Grounds"),
]

STATUS_MIX = (["submitted"] * 10 + ["assigned"] * 10 +
              ["in_progress"] * 8 + ["resolved"] * 10 + ["rejected"] * 2)

FEEDBACK_COMMENTS = ["Fixed quickly, thanks!", "Took a while but resolved.",
                     "Great response.", "Okay.", "Very satisfied with the fix."]


def ensure_user(email: str, password: str, name: str, is_admin: bool,
                demo_tester: bool = False,
                admin_dept: str | None = None) -> str:
    try:
        user = auth.get_user_by_email(email)
    except auth.UserNotFoundError:
        user = auth.create_user(email=email, password=password, display_name=name)
    if is_admin:
        claims = {"admin": True}
        if admin_dept:
            claims["dept"] = admin_dept
        auth.set_custom_user_claims(user.uid, claims)
    role = "admin" if is_admin else "student"
    doc = {
        "name": name, "collegeEmail": email, "role": role,
        "dept": "ISE", "createdAt": firestore.SERVER_TIMESTAMP,
        # Geofence bypass for demos — only the seed can set this (rules block
        # clients from ever writing it).
        "demoTester": demo_tester,
    }
    if admin_dept:
        doc["adminDept"] = admin_dept
    db.collection("users").document(user.uid).set(doc)
    if not is_admin:
        # What the app writes at signup: the admin's "new registrations" feed.
        # Keyed by email, never by uid — a uid would let an admin join the
        # feed to complaints' studentUid and unmask the aliases.
        db.collection("registrations").document(email).set({
            "name": name, "email": email, "role": role, "dept": "ISE",
            "createdAt": firestore.SERVER_TIMESTAMP, "seen": False})
    return user.uid


def main() -> None:
    student_uid = ensure_user("student@demo.com", "password123",
                              "Arya Demo", False, demo_tester=True)
    ensure_user("admin@demo.com", "password123", "Campus Admin", True)
    # One department-scoped admin per department: each sees ONLY its own.
    for dept_id, email in DEPARTMENT_ADMINS.items():
        ensure_user(email, "password123", f"{DEPARTMENT_NAMES[dept_id]} Admin",
                    True, admin_dept=dept_id)
    extra_students = [
        ensure_user(f"student{i}@demo.com", "password123",
                    f"Demo Student {i}", False)
        for i in range(2, 6)
    ]
    all_students = [student_uid] + extra_students

    for dept_id, name in DEPARTMENT_NAMES.items():
        db.collection("departments").document(dept_id).set({
            "name": name,
            "categoryList": [c for c, d in DEPARTMENT_ROUTING.items() if d == dept_id],
        })

    db.collection("campus").document("config").set(GEO)

    now = datetime.now(timezone.utc)
    statuses = STATUS_MIX[:]
    rng.shuffle(statuses)

    for i, ((desc, zone), status) in enumerate(zip(SAMPLES, statuses)):
        lat, lng = ZONE_POINTS[zone]
        submitted = now - timedelta(hours=rng.randint(1, 24 * 21),
                                    minutes=rng.randint(0, 59))
        enriched = analyze_complaint(desc, lat, lng, submitted, recent=[])
        owner = rng.choice(all_students)

        history = [{"status": "submitted", "byRole": "student",
                    "at": submitted, "note": None}]
        cursor = submitted
        for step in ["assigned", "in_progress", "resolved", "rejected"]:
            if status == "rejected" and step == "assigned":
                cursor += timedelta(hours=rng.randint(1, 24))
                history.append({"status": "rejected", "byRole": "admin",
                                "at": cursor,
                                "note": "Could not verify the issue on site."})
                break
            if step == "rejected":
                break
            order = ["submitted", "assigned", "in_progress", "resolved"]
            if order.index(step) <= order.index(status):
                cursor += timedelta(hours=rng.randint(2, 48))
                history.append({"status": step, "byRole": "admin", "at": cursor,
                                "note": "Marked resolved after fix."
                                if step == "resolved" else None})

        doc = {
            "aliasName": enriched["aliasName"],
            "studentUid": owner,
            "description": desc,
            "photoUrl": None,  # demo seed has no real photos
            "location": {"lat": lat, "lng": lng, "accuracy": rng.uniform(5, 25),
                         "zoneName": zone},
            "capturedAt": submitted,
            "submittedAt": submitted,
            "ai": enriched["ai"],
            "department": enriched["ai"]["department"],
            "status": status,
            "statusHistory": history,
        }
        if status == "resolved" and rng.random() < 0.8:
            doc["feedback"] = {"rating": rng.randint(3, 5),
                               "comment": rng.choice(FEEDBACK_COMMENTS),
                               "at": history[-1]["at"] + timedelta(hours=2)}
        db.collection("complaints").document(f"seed-{i:03d}").set(doc)

    print(f"Seeded {len(SAMPLES)} complaints, {len(all_students) + 1} users, "
          f"{len(DEPARTMENT_NAMES)} departments, campus config.")
    print("Logins -> student@demo.com / admin@demo.com (password123)")


if __name__ == "__main__":
    main()

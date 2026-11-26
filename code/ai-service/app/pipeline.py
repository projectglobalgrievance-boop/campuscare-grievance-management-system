"""The full enrichment pipeline for one complaint."""
from __future__ import annotations

from datetime import datetime, timezone

from app.alias import generate_alias
from app.categories import (DEPARTMENT_CATEGORY, DEPARTMENT_NAMES,
                            DEPARTMENT_ROUTING)
from app.categorize import categorize
from app.indic import augment
from app.duplicates import find_duplicate
from app.geofence import is_inside_campus, zone_name
from app.priority import predict_priority
from app.sentiment import analyze_sentiment
from app.tagline import generate_tagline

MAX_DESCRIPTION_CHARS = 2000

# Light profanity screen (en + common Kannada/Hindi transliterations). A hit
# never blocks the complaint — it flags it for the admin. The app also warns
# client-side; this is the server-side backstop.
PROFANITY = {
    "fuck", "fucking", "shit", "bitch", "asshole", "bastard", "dumbass",
    "bloody hell", "bkl", "bsdk", "chutiya", "bewakoof", "nonsense fellow",
}


def is_profane(text: str) -> bool:
    lowered = f" {text.lower()} "
    return any(f" {w} " in lowered or lowered.strip() == w for w in PROFANITY)


def analyze_complaint(description: str, lat: float, lng: float,
                      captured_at: datetime | None = None,
                      recent: list[dict] | None = None,
                      enforce_geofence: bool = True,
                      department: str | None = None) -> dict:
    """Run the whole pipeline. Raises ValueError("outside_campus") when the
    server-side geofence check fails (skipped for demo/test accounts via
    enforce_geofence=False).

    `department` is the one the student picked on the form. When it is a
    known id it decides the routing and the category; the model's own guess
    is kept as `predictedCategory` so the admin can see a disagreement."""
    description = (description or "").strip()[:MAX_DESCRIPTION_CHARS]
    captured_at = captured_at or datetime.now(timezone.utc)

    # 1. Server-side geofence re-validation — never trust the client alone.
    if enforce_geofence and not is_inside_campus(lat, lng):
        raise ValueError("outside_campus")
    zone = zone_name(lat, lng) or "Campus"  # bypass outside campus -> generic

    # 2-5. NLP enrichment. The models are English-only, so Kannada/Hindi text
    # is first given its English keyword equivalents (no-op for English input);
    # the stored/returned description stays exactly what the student wrote.
    text = augment(description)
    cat = categorize(text)
    predicted = cat["category"]
    chosen = department in DEPARTMENT_CATEGORY
    category = DEPARTMENT_CATEGORY[department] if chosen else predicted
    senti = analyze_sentiment(text)
    prio = predict_priority(text, category, senti["label"], zone)

    # 6. Duplicate detection (best-effort; empty `recent` degrades gracefully).
    duplicate_of = find_duplicate(category, zone, captured_at, recent or [])

    # 7-8. Routing, alias, tagline.
    dept_id = department if chosen else DEPARTMENT_ROUTING.get(
        category, "general_administration")
    alias = generate_alias()
    tagline = generate_tagline(text, category, zone)

    return {
        "aliasName": alias,
        "zoneName": zone,
        "ai": {
            "category": category,
            "predictedCategory": predicted,
            "departmentSource": "student" if chosen else "ai",
            "categoryConfidence": cat["confidence"],
            "engine": cat["engine"],
            "sentiment": senti["label"],
            "sentimentPolarity": senti["polarity"],
            "priority": prio["level"],
            "priorityScore": prio["score"],
            "priorityKeywords": prio["matchedKeywords"],
            "department": dept_id,
            "departmentName": DEPARTMENT_NAMES.get(dept_id, dept_id),
            "tagline": tagline,
            "duplicateOf": duplicate_of,
            "flagged": is_profane(description),
        },
    }

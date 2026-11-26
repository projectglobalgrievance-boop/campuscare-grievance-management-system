"""Rule-assisted priority prediction: Low / Medium / High / Critical.

Explainable scoring model (viva-friendly): category base weight + urgent
keyword hits + sentiment + zone sensitivity, mapped to bands.
"""
from __future__ import annotations

CATEGORY_WEIGHT = {
    "Electrical": 3,   # shock/fire potential
    "Plumbing": 3,     # water damage, hygiene
    "Cleanliness": 2,
    "Hostel": 2,
    "Furniture": 1,
    "Academics": 1,
    "Other": 1,
}

# keyword -> score. Danger words dominate.
URGENT_KEYWORDS = {
    "danger": 5, "dangerous": 5, "shock": 5, "fire": 5, "sparking": 5,
    "spark": 4, "exposed wire": 5, "short circuit": 5, "burning": 5,
    "smoke": 4, "injury": 4, "injured": 4, "unsafe": 4, "hazard": 4,
    "flooding": 4, "flooded": 4, "burst": 4, "collapsed": 4, "broken glass": 4,
    "urgent": 3, "emergency": 3, "immediately": 3, "asap": 3,
    "overflowing": 3, "leaking": 3, "leakage": 3, "blocked": 2, "clogged": 2,
    "smelling": 2, "smelly": 2, "stinking": 3, "dirty": 1, "broken": 2,
    "not working": 2, "damaged": 2, "no water": 3, "no power": 3,
}

SENSITIVE_ZONES = {"Canteen": 2, "Hostel": 2, "Library": 1}

SENTIMENT_SCORE = {"calm": 0, "annoyed": 1, "angry": 2}


def predict_priority(description: str, category: str, sentiment_label: str,
                     zone: str | None) -> dict:
    text = description.lower()
    keyword_score = 0
    matched = []
    for kw, score in URGENT_KEYWORDS.items():
        if kw in text:
            keyword_score += score
            matched.append(kw)
    keyword_score = min(keyword_score, 8)

    score = (
        CATEGORY_WEIGHT.get(category, 1)
        + keyword_score
        + SENTIMENT_SCORE.get(sentiment_label, 0)
        + SENSITIVE_ZONES.get(zone or "", 0)
    )

    if score >= 10:
        level = "Critical"
    elif score >= 6:
        level = "High"
    elif score >= 3:
        level = "Medium"
    else:
        level = "Low"

    return {"level": level, "score": score, "matchedKeywords": matched[:5]}


def bump_priority(level: str) -> str:
    """One notch up — used when duplicates confirm a recurring issue."""
    order = ["Low", "Medium", "High", "Critical"]
    return order[min(order.index(level) + 1, len(order) - 1)]

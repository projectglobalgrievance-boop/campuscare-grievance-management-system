"""Template-based tagline generation for the admin view.

"In the {zone} area, {category phrase}. {call to action}!"
Keyword-refined so common cases read naturally.
"""
from __future__ import annotations

# (keyword in description) -> phrase override, checked in order
KEYWORD_PHRASES = [
    ("dustbin", "a dustbin is overflowing", "Please clean up this mess"),
    ("garbage", "garbage is piling up", "Please clean up this mess"),
    ("toilet", "a toilet needs urgent cleaning", "Please send housekeeping"),
    ("washroom", "a washroom needs attention", "Please send housekeeping"),
    ("fan", "a fan is not working", "Please send an electrician"),
    ("light", "a light is not working", "Please send an electrician"),
    ("wire", "there is an exposed wire", "Please fix this immediately"),
    ("ac ", "an AC unit is faulty", "Please send a technician"),
    ("projector", "a projector is not working", "Please send a technician"),
    ("tap", "a tap is leaking", "Please send a plumber"),
    ("leak", "there is a water leakage", "Please send a plumber"),
    ("water", "there is a water supply issue", "Please send a plumber"),
    ("bench", "a bench is broken", "Please send carpentry"),
    ("chair", "a chair is broken", "Please send carpentry"),
    ("desk", "a desk is damaged", "Please send carpentry"),
    ("door", "a door is damaged", "Please send maintenance"),
    ("window", "a window is damaged", "Please send maintenance"),
    ("wifi", "the Wi-Fi is down", "Please check the network"),
]

CATEGORY_PHRASES = {
    "Cleanliness": ("a cleanliness issue needs attention", "Please clean up this area"),
    "Electrical": ("an electrical issue was reported", "Please send an electrician"),
    "Plumbing": ("a plumbing issue was reported", "Please send a plumber"),
    "Furniture": ("furniture needs repair", "Please send carpentry"),
    "Academics": ("an academic facility issue was reported", "Please look into it"),
    "Hostel": ("a hostel issue was reported", "Please inform the hostel office"),
    "Other": ("an issue was reported", "Please look into it"),
}


def generate_tagline(description: str, category: str, zone: str | None) -> str:
    text = f" {description.lower()} "
    phrase, cta = CATEGORY_PHRASES.get(category, CATEGORY_PHRASES["Other"])
    for kw, kw_phrase, kw_cta in KEYWORD_PHRASES:
        if kw in text:
            phrase, cta = kw_phrase, kw_cta
            break
    area = zone or "Campus"
    return f"In the {area} area, {phrase}. {cta}!"

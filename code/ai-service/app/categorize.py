"""Complaint categorization: TF-IDF + LinearSVC, trained by training/train.py.

Falls back to a keyword heuristic if the model file is missing, so the service
never hard-fails.
"""
from __future__ import annotations

from functools import lru_cache
from pathlib import Path

import joblib

MODEL_PATH = Path(__file__).resolve().parent.parent / "models" / "categorizer.joblib"

_FALLBACK_KEYWORDS = {
    "Cleanliness": ["dustbin", "garbage", "dirty", "litter", "smell", "clean", "toilet", "washroom"],
    "Electrical": ["fan", "light", "wire", "power", "socket", "switch", "ac", "projector", "spark"],
    "Plumbing": ["tap", "water", "leak", "pipe", "flush", "drain", "geyser"],
    "Furniture": ["bench", "chair", "desk", "table", "door", "window", "cupboard", "podium"],
    "Academics": ["marks", "timetable", "syllabus", "exam", "attendance", "library book", "lab equipment"],
    "Hostel": ["hostel", "mess", "warden", "room "],
}


@lru_cache(maxsize=1)
def _load_model():
    if MODEL_PATH.exists():
        return joblib.load(MODEL_PATH)
    return None


def categorize(description: str) -> dict:
    """Returns {category, confidence, engine}."""
    model = _load_model()
    if model is not None:
        category = model.predict([description])[0]
        confidence = None
        if hasattr(model, "decision_function"):
            import numpy as np
            scores = model.decision_function([description])[0]
            exp = np.exp(scores - scores.max())
            confidence = float(exp.max() / exp.sum())
        return {"category": str(category),
                "confidence": round(confidence, 3) if confidence else None,
                "engine": "linearsvc"}

    text = description.lower()
    best, hits = "Other", 0
    for cat, kws in _FALLBACK_KEYWORDS.items():
        n = sum(1 for kw in kws if kw in text)
        if n > hits:
            best, hits = cat, n
    return {"category": best, "confidence": None, "engine": "keyword-fallback"}

"""Duplicate detection: same category + same zone + within window -> duplicate.

Operates on plain dicts so it is testable without Firestore.
"""
from __future__ import annotations

from datetime import datetime, timedelta

DUPLICATE_WINDOW_HOURS = 24
OPEN_STATUSES = {"submitted", "assigned", "in_progress"}


def find_duplicate(category: str, zone: str | None, submitted_at: datetime,
                   recent: list[dict]) -> str | None:
    """Return the id of the earliest matching open complaint, else None.

    `recent` items: {id, category, zone, submittedAt: datetime, status}.
    """
    if zone is None:
        return None
    window_start = submitted_at - timedelta(hours=DUPLICATE_WINDOW_HOURS)
    candidates = [
        c for c in recent
        if c.get("category") == category
        and c.get("zone") == zone
        and c.get("status") in OPEN_STATUSES
        and c.get("submittedAt") is not None
        and c["submittedAt"] >= window_start
    ]
    if not candidates:
        return None
    return min(candidates, key=lambda c: c["submittedAt"])["id"]

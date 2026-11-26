"""SLA escalation: open complaints untouched for N days get their priority
bumped one level and an `escalated` flag, so they float to the top of the
admin queue instead of rotting quietly.

Pure logic here; the Firestore sweep lives in `run_escalation_sweep`.
"""
from __future__ import annotations

from datetime import datetime, timedelta, timezone

ESCALATE_AFTER_DAYS = 3
OPEN_STATUSES = {"submitted", "assigned", "in_progress"}
_BUMP = {"Low": "Medium", "Medium": "High", "High": "Critical",
         "Critical": "Critical"}


def should_escalate(status: str, last_activity: datetime,
                    already_escalated: bool,
                    now: datetime | None = None,
                    after_days: int = ESCALATE_AFTER_DAYS) -> bool:
    """True when an open, not-yet-escalated complaint has seen no status
    activity for `after_days` days."""
    if already_escalated or status not in OPEN_STATUSES:
        return False
    now = now or datetime.now(timezone.utc)
    if last_activity.tzinfo is None:
        last_activity = last_activity.replace(tzinfo=timezone.utc)
    return now - last_activity >= timedelta(days=after_days)


def bumped_priority(priority: str) -> str:
    return _BUMP.get(priority, "High")


def run_escalation_sweep(db) -> int:
    """Scan open complaints and escalate the stale ones. Returns the number
    escalated. `db` is a firestore client (admin SDK)."""
    escalated = 0
    docs = (db.collection("complaints")
              .where("status", "in", sorted(OPEN_STATUSES)).stream())
    for doc in docs:
        d = doc.to_dict()
        history = d.get("statusHistory") or []
        last = history[-1].get("at") if history else d.get("submittedAt")
        if last is None:
            continue
        if should_escalate(d.get("status", ""), last,
                           bool(d.get("escalated"))):
            ai = d.get("ai") or {}
            update = {"escalated": True}
            if ai:
                ai["priority"] = bumped_priority(ai.get("priority", "Low"))
                update["ai"] = ai
            doc.reference.update(update)
            escalated += 1
    return escalated

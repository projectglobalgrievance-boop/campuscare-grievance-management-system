from datetime import datetime, timedelta, timezone

from app.escalation import bumped_priority, should_escalate

NOW = datetime(2026, 8, 16, 12, 0, tzinfo=timezone.utc)


def test_stale_open_complaint_escalates():
    assert should_escalate("submitted", NOW - timedelta(days=4), False, NOW)


def test_fresh_complaint_does_not():
    assert not should_escalate("submitted", NOW - timedelta(days=1), False, NOW)


def test_resolved_and_already_escalated_are_skipped():
    assert not should_escalate("resolved", NOW - timedelta(days=30), False, NOW)
    assert not should_escalate("submitted", NOW - timedelta(days=30), True, NOW)


def test_priority_bump_ladder():
    assert bumped_priority("Low") == "Medium"
    assert bumped_priority("Medium") == "High"
    assert bumped_priority("High") == "Critical"
    assert bumped_priority("Critical") == "Critical"

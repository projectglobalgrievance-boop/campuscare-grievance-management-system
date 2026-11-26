from datetime import datetime, timedelta, timezone

from app.duplicates import find_duplicate

NOW = datetime(2026, 8, 4, 12, 0, tzinfo=timezone.utc)


def recent_item(id_, category="Cleanliness", zone="Canteen", hours_ago=2,
                status="submitted"):
    return {"id": id_, "category": category, "zone": zone,
            "submittedAt": NOW - timedelta(hours=hours_ago), "status": status}


def test_finds_earliest_open_match():
    recent = [recent_item("a", hours_ago=2), recent_item("b", hours_ago=5)]
    assert find_duplicate("Cleanliness", "Canteen", NOW, recent) == "b"


def test_ignores_other_zone_and_category():
    recent = [recent_item("a", zone="Hostel"), recent_item("b", category="Electrical")]
    assert find_duplicate("Cleanliness", "Canteen", NOW, recent) is None


def test_ignores_resolved_and_stale():
    recent = [recent_item("a", status="resolved"), recent_item("b", hours_ago=30)]
    assert find_duplicate("Cleanliness", "Canteen", NOW, recent) is None


def test_no_zone_means_no_duplicate():
    assert find_duplicate("Cleanliness", None, NOW, [recent_item("a")]) is None

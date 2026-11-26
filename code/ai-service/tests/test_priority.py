from app.priority import bump_priority, predict_priority


def test_danger_words_are_critical():
    p = predict_priority("exposed wire sparking near switchboard, dangerous!",
                         "Electrical", "angry", "Block C")
    assert p["level"] == "Critical"


def test_mild_issue_is_low_or_medium():
    p = predict_priority("notice board has outdated notices",
                         "Other", "calm", "Grounds")
    assert p["level"] in ("Low", "Medium")


def test_sensitive_zone_raises_score():
    base = predict_priority("dustbin overflowing", "Cleanliness", "calm", "Grounds")
    canteen = predict_priority("dustbin overflowing", "Cleanliness", "calm", "Canteen")
    assert canteen["score"] > base["score"]


def test_bump_priority():
    assert bump_priority("Low") == "Medium"
    assert bump_priority("High") == "Critical"
    assert bump_priority("Critical") == "Critical"

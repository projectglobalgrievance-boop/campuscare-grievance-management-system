from app.tagline import generate_tagline


def test_dustbin_tagline():
    t = generate_tagline("dustbin full and smelling", "Cleanliness", "Block C")
    assert t == "In the Block C area, a dustbin is overflowing. Please clean up this mess!"


def test_fan_tagline():
    t = generate_tagline("the fan is not working in room 204", "Electrical", "Block A")
    assert "a fan is not working" in t
    assert t.startswith("In the Block A area")


def test_category_fallback_when_no_keyword():
    t = generate_tagline("something odd happened", "Plumbing", "Hostel")
    assert t == "In the Hostel area, a plumbing issue was reported. Please send a plumber!"


def test_no_zone_uses_campus():
    t = generate_tagline("garbage everywhere", "Cleanliness", None)
    assert t.startswith("In the Campus area")

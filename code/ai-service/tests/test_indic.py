from app.indic import augment, english_hints

def test_english_is_untouched():
    s = "Fan is not working in the classroom"
    assert augment(s) == s
    assert english_hints(s) == []

def test_empty_input():
    assert augment("") == ""
    assert english_hints("") == []

def test_kannada_gets_english_hints():
    assert "fan" in english_hints("ತರಗತಿಯಲ್ಲಿ ಫ್ಯಾನ್ ಕೆಲಸ ಮಾಡುತ್ತಿಲ್ಲ")
    assert "not" in english_hints("ಫ್ಯಾನ್ ಕೆಲಸ ಮಾಡುತ್ತಿಲ್ಲ")

def test_hindi_gets_english_hints():
    assert "fan" in english_hints("कक्षा में पंखा काम नहीं कर रहा है")
    assert "water" in english_hints("बाथरूम में पानी लीक हो रहा है")

def test_original_text_is_preserved():
    s = "ಬೆಂಚ್ ಮುರಿದಿದೆ"
    assert augment(s).startswith(s)

def test_ambiguous_kannada_locative_is_not_a_tap():
    # ನಲ್ಲಿ means both "tap" and the locative "in" — must not drag to Plumbing.
    assert "tap" not in english_hints("Block C ನಲ್ಲಿ ಫ್ಯಾನ್")

def test_multilingual_routing_is_correct():
    from app.pipeline import analyze_complaint
    LAT, LNG = 12.92665, 77.52640
    for text in ("Fan is not working in the classroom",
                 "ತರಗತಿಯಲ್ಲಿ ಫ್ಯಾನ್ ಕೆಲಸ ಮಾಡುತ್ತಿಲ್ಲ",
                 "कक्षा में पंखा काम नहीं कर रहा है"):
        ai = analyze_complaint(text, LAT, LNG)["ai"]
        assert ai["category"] == "Electrical", (text, ai["category"])
        assert ai["department"] == "electrical_maintenance"

def test_description_is_not_mutated_by_pipeline():
    from app.pipeline import analyze_complaint
    s = "ಬೆಂಚ್ ಮುರಿದಿದೆ"
    out = analyze_complaint(s, 12.92665, 77.52640)
    assert "fan" not in out["ai"]["tagline"].lower()

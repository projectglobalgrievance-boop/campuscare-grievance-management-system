"""Kannada / Hindi -> English keyword hints for the classifier.

The categorizer is TF-IDF over English text, so a complaint written in Kannada
or Devanagari produces an all-zero feature vector and lands on whatever class
wins by default — a broken fan in Kannada was being routed to the Academic
Office. Rather than retrain (the labelled corpus is English), we append the
English equivalents of any domain words we recognise, then classify that.

Pure-English text matches nothing here and is returned byte-for-byte unchanged,
so existing behaviour is untouched.

Matching is substring-based on purpose: Kannada agglutinates
(ಫ್ಯಾನ್ + ನಲ್ಲಿ -> ಫ್ಯಾನ್‌ನಲ್ಲಿ) and Hindi inflects, so whole-word matching
would miss most real input.
"""
from __future__ import annotations

# Deliberately excludes ambiguous words — Kannada ನಲ್ಲಿ is both "tap" and the
# locative "in" ("Block C ನಲ್ಲಿ"), so mapping it to `tap` would drag every
# complaint towards Plumbing.
_LEXICON: dict[str, str] = {
    # ---- Kannada ----
    "ಫ್ಯಾನ್": "fan", "ಗಾಳಿಯಂತ್ರ": "fan",
    "ಲೈಟ್": "light", "ದೀಪ": "light", "ಬಲ್ಬ್": "light bulb",
    "ವಿದ್ಯುತ್": "power electricity", "ಕರೆಂಟ್": "power",
    "ಸ್ವಿಚ್": "switch", "ವೈರ್": "wire", "ಪ್ಲಗ್": "socket",
    "ನೀರು": "water", "ಪೈಪ್": "pipe", "ಸೋರಿಕೆ": "leak", "ಸೋರುತ್ತಿದೆ": "leak",
    "ಟ್ಯಾಪ್": "tap", "ಗೀಸರ್": "geyser", "ಚರಂಡಿ": "drain",
    "ಶೌಚಾಲಯ": "toilet", "ಟಾಯ್ಲೆಟ್": "toilet", "ಬಾತ್ರೂಮ್": "washroom",
    "ಕಸ": "garbage", "ಕಸದ": "garbage", "ಡಸ್ಟ್‌ಬಿನ್": "dustbin",
    "ಕೊಳಕು": "dirty", "ಗಲೀಜು": "dirty", "ವಾಸನೆ": "smell", "ದುರ್ವಾಸನೆ": "smell",
    "ಸ್ವಚ್ಛ": "clean", "ಶುಚಿ": "clean",
    "ಬೆಂಚ್": "bench", "ಕುರ್ಚಿ": "chair", "ಮೇಜು": "table", "ಡೆಸ್ಕ್": "desk",
    "ಬಾಗಿಲು": "door", "ಕಿಟಕಿ": "window", "ಕಪಾಟು": "cupboard",
    "ಗ್ರಂಥಾಲಯ": "library", "ಲೈಬ್ರರಿ": "library", "ಪುಸ್ತಕ": "book",
    "ಪರೀಕ್ಷೆ": "exam", "ಹಾಜರಾತಿ": "attendance", "ಅಂಕ": "marks",
    "ವೇಳಾಪಟ್ಟಿ": "timetable", "ಪಠ್ಯಕ್ರಮ": "syllabus", "ಲ್ಯಾಬ್": "lab",
    "ತರಗತಿ": "classroom", "ಪ್ರೊಜೆಕ್ಟರ್": "projector",
    "ಹಾಸ್ಟೆಲ್": "hostel", "ವಸತಿ": "hostel", "ಮೆಸ್": "mess",
    "ಊಟ": "food mess", "ವಾರ್ಡನ್": "warden", "ರೂಮ್": "room",
    "ಮುರಿದಿದೆ": "broken", "ಒಡೆದಿದೆ": "broken", "ಹಾಳಾಗಿದೆ": "broken damaged",
    "ಕೆಲಸ ಮಾಡುತ್ತಿಲ್ಲ": "not working", "ಕೆಲಸ ಮಾಡ್ತಿಲ್ಲ": "not working",
    "ಕೆಟ್ಟಿದೆ": "not working broken",
    # ---- Hindi ----
    "पंखा": "fan", "पंखे": "fan",
    "लाइट": "light", "बत्ती": "light", "बल्ब": "light bulb",
    "बिजली": "power electricity", "स्विच": "switch", "तार": "wire",
    "पानी": "water", "पाइप": "pipe", "रिसाव": "leak", "लीक": "leak",
    "नल": "tap", "गीजर": "geyser", "नाली": "drain",
    "शौचालय": "toilet", "टॉयलेट": "toilet", "बाथरूम": "washroom",
    "कचरा": "garbage", "कूड़ा": "garbage", "डस्टबिन": "dustbin",
    "गंदा": "dirty", "गंदी": "dirty", "बदबू": "smell", "साफ": "clean",
    "बेंच": "bench", "कुर्सी": "chair", "मेज": "table", "डेस्क": "desk",
    "दरवाजा": "door", "दरवाज़ा": "door", "खिड़की": "window", "अलमारी": "cupboard",
    "पुस्तकालय": "library", "लाइब्रेरी": "library", "किताब": "book",
    "परीक्षा": "exam", "उपस्थिति": "attendance", "अंक": "marks",
    "समय सारणी": "timetable", "पाठ्यक्रम": "syllabus", "प्रयोगशाला": "lab",
    "कक्षा": "classroom", "प्रोजेक्टर": "projector",
    "छात्रावास": "hostel", "हॉस्टल": "hostel", "मेस": "mess",
    "खाना": "food mess", "वार्डन": "warden", "कमरा": "room",
    "टूटा": "broken", "टूटी": "broken", "खराब": "broken not working",
    "काम नहीं": "not working", "बंद": "not working",
}


def english_hints(text: str) -> list[str]:
    """English keywords implied by the Kannada/Hindi terms present in `text`."""
    if not text:
        return []
    hits: list[str] = []
    for term, english in _LEXICON.items():
        if term in text:
            for word in english.split():
                if word not in hits:
                    hits.append(word)
    return hits


def augment(text: str) -> str:
    """`text` plus any English equivalents, for the English-only models.

    Returns `text` unchanged when nothing matches (all-English input).
    """
    hints = english_hints(text)
    return f"{text} {' '.join(hints)}" if hints else text

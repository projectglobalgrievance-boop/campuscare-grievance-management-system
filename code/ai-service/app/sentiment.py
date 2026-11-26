"""Sentiment analysis -> calm / annoyed / angry.

Self-contained lexicon analyzer (no nltk/textblob): nltk >= 3.10 ships an
import guard that breaks under pytest/uvicorn working-directory layouts (see
the import guard in nltk >= 3.10). A domain lexicon is explainable in a viva and plenty for
complaint tone detection.
"""
from __future__ import annotations

import re

_NEGATIVE = {
    "bad": 1, "dirty": 1, "smelly": 1, "smelling": 1, "stinking": 2,
    "broken": 1, "damaged": 1, "leaking": 1, "overflowing": 1, "blocked": 1,
    "poor": 1, "slow": 1, "late": 1, "delayed": 1, "ignored": 2,
    "terrible": 2, "horrible": 2, "awful": 2, "disgusting": 2, "pathetic": 2,
    "useless": 2, "worst": 2, "unbearable": 2, "shameful": 2, "ridiculous": 2,
    "dangerous": 2, "unsafe": 2, "hazardous": 2, "angry": 2, "frustrated": 2,
    "fed": 1,  # "fed up"
    "annoying": 1, "annoyed": 1, "irritating": 1, "nobody": 1, "never": 1,
}

_POSITIVE = {
    "good": 1, "great": 1, "nice": 1, "clean": 1, "fixed": 1, "thanks": 1,
    "thank": 1, "appreciated": 1, "happy": 1, "satisfied": 1, "resolved": 1,
    "excellent": 2, "wonderful": 2, "perfect": 2,
}

_INTENSIFIERS = {"very", "really", "extremely", "so", "too", "totally",
                 "completely", "absolutely"}

_TOKEN = re.compile(r"[a-z']+")


def analyze_sentiment(text: str) -> dict:
    tokens = _TOKEN.findall(text.lower())
    score = 0.0
    boost = 1.0
    for tok in tokens:
        if tok in _INTENSIFIERS:
            boost = 1.5
            continue
        if tok in _NEGATIVE:
            score -= _NEGATIVE[tok] * boost
        elif tok in _POSITIVE:
            score += _POSITIVE[tok] * boost
        boost = 1.0
    # exclamation marks amplify negativity in complaints
    score -= 0.5 * text.count("!") if score < 0 else 0

    # normalize roughly to [-1, 1]
    polarity = max(-1.0, min(1.0, score / 4.0))
    if polarity <= -0.75:
        label = "angry"
    elif polarity <= -0.25:
        label = "annoyed"
    else:
        label = "calm"
    return {"polarity": round(polarity, 3), "label": label}

"""Generate a synthetic labeled dataset of campus complaints (~800 rows).

Deterministic (seeded) so the dataset and model metrics are reproducible.
Run:  python data/generate_dataset.py   -> writes data/complaints.csv
"""
from __future__ import annotations

import csv
import random
from pathlib import Path

OUT = Path(__file__).resolve().parent / "complaints.csv"
rng = random.Random(42)

SUBJECTS = {
    "Cleanliness": [
        "dustbin near {place} is overflowing", "garbage piled up behind {place}",
        "toilet on {floor} floor of {place} is very dirty",
        "washroom in {place} has no cleaning since days",
        "{place} corridor is full of litter", "food waste spilled outside {place}",
        "bad smell coming from washroom in {place}",
        "cobwebs and dust all over {place} stairs",
        "spilled paint not cleaned in {place}", "washbasin in {place} is stained and dirty",
    ],
    "Electrical": [
        "fan in {room} of {place} is not working", "tube light flickering in {room}",
        "exposed wire near the switchboard in {place}", "power socket sparking in {room}",
        "no power supply in {place} since morning", "AC not cooling in {room}",
        "projector not turning on in {room}", "switch board broken in {place}",
        "short circuit smell in {place}", "emergency light not working on {floor} floor",
    ],
    "Plumbing": [
        "tap leaking continuously in {place} washroom", "no water supply in {place}",
        "water cooler in {place} not dispensing water", "pipe burst near {place}",
        "washroom flush not working in {place}", "drain blocked outside {place}",
        "water leaking from ceiling in {room}", "drinking water filter in {place} needs service",
        "water logging near {place} entrance", "geyser not heating in hostel bathroom",
    ],
    "Furniture": [
        "bench broken in {room} of {place}", "chair wobbling badly in {room}",
        "desk surface cracked in {room}", "door hinge broken in {place} washroom",
        "window pane cracked in {room}", "podium drawer stuck in {room}",
        "lab stool missing legs in {place}", "notice board fallen in {place} corridor",
        "cupboard door hanging loose in {room}", "table drawer lock broken in {place}",
    ],
    "Academics": [
        "projector remote missing in {room} affecting classes",
        "whiteboard markers never available in {room}",
        "class timetable clash for {dept} section {sec}",
        "lab equipment insufficient for {dept} practicals",
        "internal marks not updated on portal for {dept}",
        "library book {book} unavailable for reference",
        "wifi not working in {place} affecting online classes",
        "attendance not recorded properly for {dept} section {sec}",
        "syllabus copies not distributed for {dept}",
        "exam hall {room} had no proper seating arrangement",
    ],
    "Hostel": [
        "hostel room {hroom} fan making loud noise", "mess food quality very bad today",
        "hot water not available in hostel {hblock} block",
        "hostel wifi down in {hblock} block since yesterday",
        "room {hroom} window mesh torn, mosquitoes coming in",
        "washing machine in hostel {hblock} block not working",
        "hostel corridor lights off in {hblock} block",
        "water cooler on hostel {floor} floor leaking",
        "mess plates not cleaned properly", "hostel bathroom door latch broken in {hblock} block",
    ],
    "Other": [
        "stray dogs roaming near {place}", "parking area near {place} very congested",
        "id card machine at gate not scanning", "lost my calculator near {place}",
        "notice board outside {place} has outdated notices",
        "canteen tokens system very slow", "campus map board faded near {place}",
        "bicycle stand full, no space near {place}", "printer in {place} out of service",
        "atm near campus gate not working",
    ],
}

MOODS = [
    ("", 0.5), ("please fix this soon.", 0.2), ("this is really frustrating!", 0.1),
    ("it has been like this for a week, very bad situation.", 0.1),
    ("kindly look into it.", 0.05), ("this is urgent and dangerous!", 0.05),
]

PLACES = ["Block A", "Block B", "Block C", "the library", "the canteen",
          "the main building", "the seminar hall", "the sports complex"]
ROOMS = ["room 101", "room 204", "room 305", "the CS lab", "the physics lab",
         "lecture hall 2", "room 410", "the drawing hall"]
FLOORS = ["first", "second", "third", "ground"]
DEPTS = ["ISE", "CSE", "ECE", "ME", "CIVIL"]
SECS = ["A", "B", "C"]
BOOKS = ["'Operating System Concepts'", "'Clean Code'", "'DBMS by Navathe'"]
HBLOCKS = ["A", "B", "C"]


def fill(template: str) -> str:
    return (template
            .replace("{place}", rng.choice(PLACES))
            .replace("{room}", rng.choice(ROOMS))
            .replace("{floor}", rng.choice(FLOORS))
            .replace("{dept}", rng.choice(DEPTS))
            .replace("{sec}", rng.choice(SECS))
            .replace("{book}", rng.choice(BOOKS))
            .replace("{hroom}", str(rng.randint(101, 420)))
            .replace("{hblock}", rng.choice(HBLOCKS)))


def mood() -> str:
    r = rng.random()
    acc = 0.0
    for text, p in MOODS:
        acc += p
        if r <= acc:
            return text
    return ""


def _typos(text: str) -> str:
    """Realistic student typing: dropped letters, doubled letters, no caps."""
    chars = list(text)
    for _ in range(rng.randint(1, 2)):
        i = rng.randrange(len(chars))
        if chars[i].isalpha():
            if rng.random() < 0.5:
                chars[i] = ""          # dropped letter
            else:
                chars[i] = chars[i] * 2  # doubled letter
    return "".join(chars)


# Deliberately ambiguous complaints that straddle two categories — keeps the
# classifier honest (and the reported accuracy believable).
AMBIGUOUS = [
    ("washroom door not closing properly in {place}", ["Furniture", "Plumbing"]),
    ("water cooler area very dirty in {place}", ["Cleanliness", "Plumbing"]),
    ("hostel room light not working", ["Hostel", "Electrical"]),
    ("lab chairs dusty and broken in {room}", ["Furniture", "Cleanliness"]),
    ("mess washbasin tap loose", ["Hostel", "Plumbing"]),
    ("classroom switchboard cover fallen off in {room}", ["Electrical", "Furniture"]),
    ("library fan dusty and noisy", ["Electrical", "Cleanliness"]),
    ("hostel study table lamp flickering", ["Hostel", "Electrical"]),
]


def main() -> None:
    rows = []
    per_category = 800 // len(SUBJECTS)
    for category, templates in SUBJECTS.items():
        for _ in range(per_category):
            desc = fill(rng.choice(templates))
            extra = mood()
            if extra:
                desc = f"{desc}, {extra}"
            if rng.random() < 0.18:
                desc = _typos(desc)
            rows.append({"description": desc, "category": category})
    # ~8% ambiguous rows with a randomly-chosen plausible label
    for _ in range(64):
        template, cats = rng.choice(AMBIGUOUS)
        desc = fill(template)
        if rng.random() < 0.3:
            desc = _typos(desc)
        rows.append({"description": desc, "category": rng.choice(cats)})
    rng.shuffle(rows)
    with open(OUT, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["description", "category"])
        writer.writeheader()
        writer.writerows(rows)
    print(f"wrote {len(rows)} rows -> {OUT}")


if __name__ == "__main__":
    main()

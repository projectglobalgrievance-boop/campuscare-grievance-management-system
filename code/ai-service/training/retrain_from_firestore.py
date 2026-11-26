"""Retrain the categorizer on REAL complaints pulled from Firestore, merged
with the synthetic dataset so small real samples don't wreck coverage.

The label for each real complaint is its (admin-visible, AI-assigned and
implicitly admin-confirmed) `ai.category`. Complaints without a category or
with an empty description are skipped.

Usage (against the emulator):
    FIRESTORE_EMULATOR_HOST=localhost:8080 \
      ./.venv/bin/python training/retrain_from_firestore.py [--min-real 25]

Against production: set GOOGLE_APPLICATION_CREDENTIALS instead (service
account) and drop the emulator env var.
"""
from __future__ import annotations

import argparse
import csv
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import firebase_admin
from firebase_admin import firestore

from app.categories import DEPARTMENT_ROUTING
from app.firestore_client import emulator_credential_if_needed

ROOT = Path(__file__).resolve().parent.parent
SYNTHETIC = ROOT / "data" / "complaints.csv"
MERGED = ROOT / "data" / "complaints_merged.csv"
VALID = set(DEPARTMENT_ROUTING)


def fetch_real() -> list[tuple[str, str]]:
    project = os.environ.get("FIREBASE_PROJECT_ID", "demo-campuscare")
    firebase_admin.initialize_app(
        credential=emulator_credential_if_needed(),
        options={"projectId": project})
    db = firestore.client()
    rows = []
    for doc in db.collection("complaints").stream():
        d = doc.to_dict()
        text = (d.get("description") or "").strip()
        cat = ((d.get("ai") or {}).get("category") or "").strip()
        if text and cat in VALID:
            rows.append((text, cat))
    return rows


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--min-real", type=int, default=10,
                    help="refuse to retrain with fewer real samples")
    args = ap.parse_args()

    real = fetch_real()
    print(f"real complaints usable for training: {len(real)}")
    if len(real) < args.min_real:
        sys.exit(f"Only {len(real)} real samples (< {args.min_real}) — "
                 "collect more before retraining.")

    with open(SYNTHETIC, newline="") as f:
        synthetic = list(csv.reader(f))
    header, synthetic_rows = synthetic[0], synthetic[1:]

    with open(MERGED, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(synthetic_rows)
        w.writerows(real)
    print(f"merged dataset: {len(synthetic_rows)} synthetic + {len(real)} real "
          f"-> {MERGED.name}")

    sys.path.insert(0, str(Path(__file__).resolve().parent))
    import train
    train.main(csv_path=MERGED)


if __name__ == "__main__":
    main()

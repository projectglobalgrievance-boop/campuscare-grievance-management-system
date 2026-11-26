"""Grant (or revoke) admin to an existing account — the ONLY way to create
admins; the app and security rules deliberately have no client path.

Usage (emulator):
    FIRESTORE_EMULATOR_HOST=localhost:8080 FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 \
      ./.venv/bin/python scripts/make_admin.py someone@college.edu
    ... someone@college.edu --dept housekeeping   # department-scoped admin
    ... someone@college.edu --revoke

Production: run with GOOGLE_APPLICATION_CREDENTIALS (service account) instead.
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import firebase_admin
from firebase_admin import auth, firestore

from app.categories import DEPARTMENT_NAMES
from app.firestore_client import emulator_credential_if_needed


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("email")
    ap.add_argument("--dept", choices=sorted(DEPARTMENT_NAMES),
                    help="scope this admin to one department's complaints")
    ap.add_argument("--revoke", action="store_true",
                    help="remove admin instead of granting it")
    args = ap.parse_args()

    project = os.environ.get("FIREBASE_PROJECT_ID", "demo-campuscare")
    firebase_admin.initialize_app(
        credential=emulator_credential_if_needed(),
        options={"projectId": project})
    db = firestore.client()

    try:
        user = auth.get_user_by_email(args.email)
    except auth.UserNotFoundError:
        sys.exit(f"No account with email {args.email} — sign up in the app first.")

    if args.revoke:
        auth.set_custom_user_claims(user.uid, None)
        db.collection("users").document(user.uid).update(
            {"role": "student", "adminDept": firestore.DELETE_FIELD})
        print(f"{args.email}: admin revoked (back to student).")
        return

    claims = {"admin": True}
    if args.dept:
        claims["dept"] = args.dept
    auth.set_custom_user_claims(user.uid, claims)
    update = {"role": "admin"}
    update["adminDept"] = args.dept if args.dept else firestore.DELETE_FIELD
    db.collection("users").document(user.uid).update(update)
    scope = DEPARTMENT_NAMES.get(args.dept, "ALL departments") if args.dept \
        else "ALL departments"
    print(f"{args.email}: admin granted, scope = {scope}. "
          "They must sign out and back in for the new role to load.")


if __name__ == "__main__":
    main()

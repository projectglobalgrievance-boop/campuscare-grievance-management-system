"""Canonical category, department, priority and status vocabulary."""

CATEGORIES = [
    "Cleanliness",
    "Electrical",
    "Plumbing",
    "Furniture",
    "Academics",
    "Hostel",
    "Other",
]

# category -> department id (must match departments seeded in Firestore)
DEPARTMENT_ROUTING = {
    "Cleanliness": "housekeeping",
    "Electrical": "electrical_maintenance",
    "Plumbing": "plumbing_maintenance",
    "Furniture": "carpentry",
    "Academics": "academic_office",
    "Hostel": "hostel_office",
    "Other": "general_administration",
}

DEPARTMENT_NAMES = {
    "housekeeping": "Facilities",
    "electrical_maintenance": "Maintenance",
    "plumbing_maintenance": "Utilities",
    "carpentry": "Infrastructure",
    "academic_office": "Academic Office",
    "hostel_office": "Hostel Office",
    "general_administration": "General Administration",
}

# One scoped admin login per department (password is set by the seed).
DEPARTMENT_ADMINS = {
    "housekeeping": "facilities.admin@demo.com",
    "electrical_maintenance": "maintenance.admin@demo.com",
    "plumbing_maintenance": "utilities.admin@demo.com",
    "carpentry": "infrastructure.admin@demo.com",
    # Retired logins, kept for reference only. housekeeping.admin@demo.com is
    # disabled in live Firebase (not deleted); the other three never existed.
    #   housekeeping.admin@demo.com, electrical.admin@demo.com,
    #   plumbing.admin@demo.com, carpentry.admin@demo.com
    "academic_office": "academic.admin@demo.com",
    "hostel_office": "hostel.admin@demo.com",
    "general_administration": "general.admin@demo.com",
}

# department id -> category (the inverse of DEPARTMENT_ROUTING; one each)
DEPARTMENT_CATEGORY = {d: c for c, d in DEPARTMENT_ROUTING.items()}

PRIORITIES = ["Low", "Medium", "High", "Critical"]

STATUSES = ["submitted", "assigned", "in_progress", "resolved", "rejected"]

"""Regenerate code/mobile/lib/config/campus_geo.dart from campus_geo.json.

The JSON is the single source of truth for the campus boundary + zones.
On-site zone tuning workflow: walk the campus watching the app's live zone
chip, nudge the rectangles in data/campus_geo.json, run this script, rebuild
the app, and reseed.

    ./.venv/bin/python scripts/gen_campus_geo.py
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
JSON_PATH = ROOT / "data" / "campus_geo.json"
DART_PATH = (ROOT.parent / "mobile" / "lib" / "config" / "campus_geo.dart")

HEADER = '''/// Campus boundary + zones.
///
/// GENERATED from code/ai-service/data/campus_geo.json by
/// scripts/gen_campus_geo.py — edit the JSON and regenerate; do not edit
/// this file by hand.
library;

class GeoPoint2 {
  final double lat;
  final double lng;
  const GeoPoint2(this.lat, this.lng);
}

class CampusZone {
  final String name;
  final List<GeoPoint2> polygon;
  const CampusZone(this.name, this.polygon);
}

class CampusGeo {
  CampusGeo._();
'''


def dart_points(pts, indent):
    return "\n".join(f"{indent}GeoPoint2({p['lat']}, {p['lng']})," for p in pts)


def main() -> None:
    geo = json.loads(JSON_PATH.read_text())
    zones = "\n".join(
        f"    CampusZone('{z['name']}', [\n"
        f"{dart_points(z['polygon'], '      ')}\n    ]),"
        for z in geo["zones"])
    out = (
        f"{HEADER}\n"
        f"  static const double boundaryBufferMeters = "
        f"{geo['boundaryBufferMeters']};\n\n"
        f"  static const List<GeoPoint2> boundary = [\n"
        f"{dart_points(geo['boundary'], '    ')}\n  ];\n\n"
        f"  static const List<CampusZone> zones = [\n{zones}\n  ];\n}}\n")
    DART_PATH.write_text(out)
    print(f"wrote {DART_PATH} "
          f"({len(geo['boundary'])} boundary pts, {len(geo['zones'])} zones)")


if __name__ == "__main__":
    main()

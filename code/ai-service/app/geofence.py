"""Campus geofence: point-in-polygon with boundary buffer and zone resolution.

Mirrors code/mobile/lib/config/campus_geo.dart — keep both in sync with
data/campus_geo.json (the single source of truth).
"""
from __future__ import annotations

import json
import math
from functools import lru_cache
from pathlib import Path

GEO_PATH = Path(__file__).resolve().parent.parent / "data" / "campus_geo.json"

_METERS_PER_DEG_LAT = 111_320.0


@lru_cache(maxsize=1)
def load_geo() -> dict:
    with open(GEO_PATH, encoding="utf-8") as f:
        return json.load(f)


def _ray_cast(lat: float, lng: float, polygon: list[dict]) -> bool:
    """Standard ray-casting point-in-polygon test."""
    inside = False
    n = len(polygon)
    j = n - 1
    for i in range(n):
        yi, xi = polygon[i]["lat"], polygon[i]["lng"]
        yj, xj = polygon[j]["lat"], polygon[j]["lng"]
        if (xi > lng) != (xj > lng):
            intersect_lat = (yj - yi) * (lng - xi) / (xj - xi) + yi
            if lat < intersect_lat:
                inside = not inside
        j = i
    return inside


def _distance_to_segment_m(lat, lng, a, b) -> float:
    """Approximate metric distance from a point to a polygon edge."""
    cos_lat = math.cos(math.radians(lat))
    px = lng * _METERS_PER_DEG_LAT * cos_lat
    py = lat * _METERS_PER_DEG_LAT
    ax = a["lng"] * _METERS_PER_DEG_LAT * cos_lat
    ay = a["lat"] * _METERS_PER_DEG_LAT
    bx = b["lng"] * _METERS_PER_DEG_LAT * cos_lat
    by = b["lat"] * _METERS_PER_DEG_LAT
    dx, dy = bx - ax, by - ay
    if dx == dy == 0:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    return math.hypot(px - (ax + t * dx), py - (ay + t * dy))


def distance_to_boundary_m(lat: float, lng: float) -> float:
    boundary = load_geo()["boundary"]
    n = len(boundary)
    return min(
        _distance_to_segment_m(lat, lng, boundary[i], boundary[(i + 1) % n])
        for i in range(n)
    )


def is_inside_campus(lat: float, lng: float) -> bool:
    """True if inside the boundary polygon, or within the buffer just outside it
    (gate / compound-wall GPS tolerance)."""
    geo = load_geo()
    if _ray_cast(lat, lng, geo["boundary"]):
        return True
    return distance_to_boundary_m(lat, lng) <= geo.get("boundaryBufferMeters", 0)


def zone_name(lat: float, lng: float) -> str | None:
    """Named zone containing the point; 'Campus' if inside boundary but in no
    zone; None if outside campus entirely."""
    if not is_inside_campus(lat, lng):
        return None
    for zone in load_geo()["zones"]:
        if _ray_cast(lat, lng, zone["polygon"]):
            return zone["name"]
    return "Campus"

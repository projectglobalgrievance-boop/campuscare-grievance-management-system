from app.geofence import distance_to_boundary_m, is_inside_campus, zone_name

# Real GAT boundary (OSM way 766650745). Well inside the campus (central quad)
INSIDE = (12.92720, 77.52630)
# The old placeholder site ~3.3 km south-west — far outside the real campus
OUTSIDE_FAR = (12.8990, 77.5121)
# Just outside the east edge but within the 15 m buffer (~5 m out)
NEAR_EDGE = (12.92720, 77.52770)


def test_inside_campus():
    assert is_inside_campus(*INSIDE)


def test_far_outside_rejected():
    assert not is_inside_campus(*OUTSIDE_FAR)


def test_boundary_buffer_accepts_gate_tolerance():
    assert not _raw_inside(*NEAR_EDGE)
    assert distance_to_boundary_m(*NEAR_EDGE) <= 15
    assert is_inside_campus(*NEAR_EDGE)


def _raw_inside(lat, lng):
    from app.geofence import _ray_cast, load_geo
    return _ray_cast(lat, lng, load_geo()["boundary"])


def test_zone_resolution():
    # Main academic building (OSM building=college), east side
    assert zone_name(12.92760, 77.52710) == "Block A"
    # Canteen / gardens, centre
    assert zone_name(12.92665, 77.52640) == "Canteen"
    # Sports grounds (basketball + pitch), south-west leg
    assert zone_name(12.92580, 77.52620) == "Grounds"


def test_zone_none_when_outside():
    assert zone_name(*OUTSIDE_FAR) is None


def test_inside_but_unzoned_returns_campus():
    # Inside the boundary, east of the Canteen rectangle, below Block A
    assert zone_name(12.92660, 77.52710) == "Campus"

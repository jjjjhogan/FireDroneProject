import json
import urllib.parse
import urllib.request


NOMINATIM_USAGE_POLICY = {
    "status": "limited-free-public-service",
    "message": (
        "OpenStreetMap Nominatim is a limited free public service. Keep searches "
        "user-triggered, cache repeated queries, and stay below 1 request per second "
        "per application."
    ),
    "url": "https://operations.osmfoundation.org/policies/nominatim/",
}


class MapSearchError(Exception):
    pass


def search_nominatim_places(query, search_url, user_agent, limit=5, timeout=5):
    normalized_query = str(query or "").strip()
    if not normalized_query:
        raise ValueError("q query parameter is required")

    url = _search_url(search_url, normalized_query, limit)
    request = urllib.request.Request(
        url,
        headers={
            "Accept": "application/json",
            "User-Agent": _user_agent(user_agent),
        },
    )

    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except Exception as error:
        raise MapSearchError("Map search provider unavailable") from error

    if not isinstance(payload, list):
        raise MapSearchError("Map search provider returned an unexpected response")

    return {
        "provider": "nominatim",
        "query": normalized_query,
        "usagePolicy": NOMINATIM_USAGE_POLICY,
        "results": [_result_from_nominatim(item) for item in payload if isinstance(item, dict)],
    }


def _search_url(search_url, query, limit):
    base_url = str(search_url or "").strip() or "https://nominatim.openstreetmap.org/search"
    params = urllib.parse.urlencode(
        {
            "q": query,
            "format": "jsonv2",
            "limit": _bounded_limit(limit),
            "addressdetails": 1,
        }
    )
    return f"{base_url}?{params}"


def _bounded_limit(limit):
    try:
        parsed = int(limit)
    except (TypeError, ValueError):
        parsed = 5
    return max(1, min(parsed, 10))


def _user_agent(user_agent):
    configured = str(user_agent or "").strip()
    if configured:
        return configured
    return "FireDroneProject/0.1 public-safety-prototype"


def _result_from_nominatim(item):
    osm_type = str(item.get("osm_type") or "place").strip() or "place"
    osm_id = str(item.get("osm_id") or item.get("place_id") or "").strip()
    result_id = f"{osm_type}/{osm_id}" if osm_id else osm_type
    return {
        "id": result_id,
        "displayName": str(item.get("display_name") or "Unnamed place"),
        "lat": _float(item.get("lat")),
        "lng": _float(item.get("lon")),
        "category": str(item.get("category") or item.get("class") or "place"),
        "type": str(item.get("type") or "unknown"),
        "boundingBox": _bounding_box(item.get("boundingbox")),
    }


def _bounding_box(raw_box):
    if not isinstance(raw_box, list) or len(raw_box) < 4:
        return None
    return {
        "south": _float(raw_box[0]),
        "north": _float(raw_box[1]),
        "west": _float(raw_box[2]),
        "east": _float(raw_box[3]),
    }


def _float(value):
    try:
        return float(value)
    except (TypeError, ValueError):
        return 0.0

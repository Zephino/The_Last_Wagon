class_name Routes
extends RefCounted
## The cross-country routes. Each stop has a real city, a kind (store town,
## scavenging stop, start or finish), a map position (longitude/latitude) and
## road miles from the previous stop. Only Maine to Florida is playable so far.

enum Kind { START, SCAVENGE, TOWN, FINISH }


static func all() -> Array[Dictionary]:
	return [
		_maine_to_florida(),
		{"name": "Maine to California", "playable": false, "stops": []},
		{"name": "Maine to Oregon", "playable": false, "stops": []},
		{"name": "Oregon to Florida", "playable": false, "stops": []},
		{"name": "Florida to California", "playable": false, "stops": []},
	]


static func first_playable() -> Dictionary:
	for route: Dictionary in all():
		if route["playable"]:
			return route
	return {}


static func _stop(city: String, state: String, kind: Kind, lon: float, lat: float, miles: int) -> Dictionary:
	return {"city": city, "state": state, "kind": kind, "lon": lon, "lat": lat, "miles": miles}


static func _maine_to_florida() -> Dictionary:
	return {
		"name": "Maine to Florida",
		"playable": true,
		"stops": [
			_stop("Portland", "ME", Kind.START, -70.26, 43.66, 0),
			_stop("Boston", "MA", Kind.SCAVENGE, -71.06, 42.36, 110),
			_stop("New York", "NY", Kind.SCAVENGE, -74.0, 40.71, 215),
			_stop("Philadelphia", "PA", Kind.TOWN, -75.16, 39.95, 95),
			_stop("Washington", "DC", Kind.SCAVENGE, -77.04, 38.9, 140),
			_stop("Richmond", "VA", Kind.SCAVENGE, -77.44, 37.54, 110),
			_stop("Raleigh", "NC", Kind.TOWN, -78.64, 35.78, 170),
			_stop("Charleston", "SC", Kind.SCAVENGE, -79.93, 32.78, 280),
			_stop("Savannah", "GA", Kind.SCAVENGE, -81.1, 32.08, 110),
			_stop("Jacksonville", "FL", Kind.TOWN, -81.66, 30.33, 140),
			_stop("Miami", "FL", Kind.FINISH, -80.19, 25.76, 350),
		],
	}

class_name Routes
extends RefCounted
## The cross-country routes. Each stop has a real city, a kind (store town,
## scavenging stop, start or finish), a map position (longitude/latitude) and
## road miles from the previous stop. Maine to Florida is open from the start;
## the others are unlocked with awards (see Awards, "unlock": route id).

enum Kind { START, SCAVENGE, TOWN, FINISH }


static func all() -> Array[Dictionary]:
	return [
		_maine_to_florida(),
		_maine_to_california(),
		_maine_to_oregon(),
		_oregon_to_florida(),
		_florida_to_california(),
	]


static func first_playable() -> Dictionary:
	for route: Dictionary in all():
		if route["playable"]:
			return route
	return {}


static func by_id(route_id: String) -> Dictionary:
	for route: Dictionary in all():
		if route["id"] == route_id:
			return route
	return {}


static func _stop(city: String, state: String, kind: Kind, lon: float, lat: float, miles: int) -> Dictionary:
	return {"city": city, "state": state, "kind": kind, "lon": lon, "lat": lat, "miles": miles}


static func _maine_to_florida() -> Dictionary:
	return {
		"id": "maine_to_florida",
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


static func _maine_to_california() -> Dictionary:
	return {
		"id": "maine_to_california",
		"name": "Maine to California",
		"playable": true,
		"stops": [
			_stop("Portland", "ME", Kind.START, -70.26, 43.66, 0),
			_stop("Albany", "NY", Kind.SCAVENGE, -73.75, 42.65, 235),
			_stop("Cleveland", "OH", Kind.SCAVENGE, -81.69, 41.5, 475),
			_stop("Chicago", "IL", Kind.TOWN, -87.63, 41.88, 345),
			_stop("Des Moines", "IA", Kind.SCAVENGE, -93.6, 41.59, 330),
			_stop("Omaha", "NE", Kind.SCAVENGE, -95.94, 41.26, 135),
			_stop("Denver", "CO", Kind.TOWN, -104.99, 39.74, 540),
			_stop("Salt Lake City", "UT", Kind.SCAVENGE, -111.89, 40.76, 520),
			_stop("Las Vegas", "NV", Kind.SCAVENGE, -115.14, 36.17, 420),
			_stop("Los Angeles", "CA", Kind.FINISH, -118.24, 34.05, 270),
		],
	}


static func _maine_to_oregon() -> Dictionary:
	return {
		"id": "maine_to_oregon",
		"name": "Maine to Oregon",
		"playable": true,
		"stops": [
			_stop("Portland", "ME", Kind.START, -70.26, 43.66, 0),
			_stop("Syracuse", "NY", Kind.SCAVENGE, -76.15, 43.05, 300),
			_stop("Detroit", "MI", Kind.SCAVENGE, -83.05, 42.33, 380),
			_stop("Chicago", "IL", Kind.TOWN, -87.63, 41.88, 280),
			_stop("Minneapolis", "MN", Kind.SCAVENGE, -93.27, 44.98, 410),
			_stop("Fargo", "ND", Kind.SCAVENGE, -96.79, 46.88, 235),
			_stop("Billings", "MT", Kind.TOWN, -108.5, 45.78, 530),
			_stop("Missoula", "MT", Kind.SCAVENGE, -114.0, 46.87, 340),
			_stop("Spokane", "WA", Kind.SCAVENGE, -117.43, 47.66, 200),
			_stop("Portland", "OR", Kind.FINISH, -122.68, 45.52, 350),
		],
	}


static func _oregon_to_florida() -> Dictionary:
	return {
		"id": "oregon_to_florida",
		"name": "Oregon to Florida",
		"playable": true,
		"stops": [
			_stop("Portland", "OR", Kind.START, -122.68, 45.52, 0),
			_stop("Boise", "ID", Kind.SCAVENGE, -116.2, 43.62, 430),
			_stop("Salt Lake City", "UT", Kind.TOWN, -111.89, 40.76, 340),
			_stop("Denver", "CO", Kind.SCAVENGE, -104.99, 39.74, 520),
			_stop("Oklahoma City", "OK", Kind.SCAVENGE, -97.52, 35.47, 680),
			_stop("Dallas", "TX", Kind.TOWN, -96.8, 32.78, 205),
			_stop("Houston", "TX", Kind.SCAVENGE, -95.37, 29.76, 240),
			_stop("New Orleans", "LA", Kind.SCAVENGE, -90.07, 29.95, 350),
			_stop("Tallahassee", "FL", Kind.TOWN, -84.28, 30.44, 380),
			_stop("Orlando", "FL", Kind.FINISH, -81.38, 28.54, 260),
		],
	}


static func _florida_to_california() -> Dictionary:
	return {
		"id": "florida_to_california",
		"name": "Florida to California",
		"playable": true,
		"stops": [
			_stop("Miami", "FL", Kind.START, -80.19, 25.76, 0),
			_stop("Tampa", "FL", Kind.SCAVENGE, -82.46, 27.95, 280),
			_stop("Pensacola", "FL", Kind.TOWN, -87.22, 30.42, 440),
			_stop("New Orleans", "LA", Kind.SCAVENGE, -90.07, 29.95, 200),
			_stop("Houston", "TX", Kind.SCAVENGE, -95.37, 29.76, 350),
			_stop("San Antonio", "TX", Kind.TOWN, -98.49, 29.42, 200),
			_stop("El Paso", "TX", Kind.SCAVENGE, -106.49, 31.76, 550),
			_stop("Phoenix", "AZ", Kind.SCAVENGE, -112.07, 33.45, 430),
			_stop("San Diego", "CA", Kind.FINISH, -117.16, 32.72, 355),
		],
	}

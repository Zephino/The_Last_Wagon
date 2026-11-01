class_name Routes
extends RefCounted
## The cross-country routes, in short, medium and long lengths. Each stop has
## a real city, a kind (store town, scavenging stop, start or finish), a map
## position (longitude/latitude) and road miles from the previous stop. The
## region of each stop comes from its position (see Regions). Two routes are
## open from the start; the others are unlocked with awards (see Unlocks).

enum Kind { START, SCAVENGE, TOWN, FINISH }


static func all() -> Array[Dictionary]:
	return [
		_new_york_to_washington(),
		_maine_to_florida(),
		_chicago_to_new_orleans(),
		_texas_to_washington(),
		_maine_to_california(),
		_maine_to_oregon(),
		_oregon_to_florida(),
		_florida_to_california(),
		_seattle_to_boston(),
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


## "short", "medium" or "long", from the number of stops.
static func length_name(route: Dictionary) -> String:
	var count: int = route["stops"].size()
	if count <= 10:
		return "short"
	if count <= 15:
		return "medium"
	return "long"


static func _stop(city: String, state: String, kind: Kind, lon: float, lat: float, miles: int) -> Dictionary:
	return {"city": city, "state": state, "kind": kind, "lon": lon, "lat": lat, "miles": miles}



static func _new_york_to_washington() -> Dictionary:
	return {
		"id": "new_york_to_washington",
		"name": "New York to Washington",
		"playable": true,
		"stops": [
			_stop("New York", "NY", Kind.START, -74.0, 40.71, 0),
			_stop("Trenton", "NJ", Kind.SCAVENGE, -74.76, 40.22, 60),
			_stop("Philadelphia", "PA", Kind.TOWN, -75.16, 39.95, 35),
			_stop("Wilmington", "DE", Kind.SCAVENGE, -75.55, 39.74, 30),
			_stop("Baltimore", "MD", Kind.SCAVENGE, -76.61, 39.29, 70),
			_stop("Washington", "DC", Kind.FINISH, -77.04, 38.9, 40),
		],
	}


static func _maine_to_florida() -> Dictionary:
	return {
		"id": "maine_to_florida",
		"name": "Maine to Florida",
		"playable": true,
		"stops": [
			_stop("Portland", "ME", Kind.START, -70.26, 43.66, 0),
			_stop("Portsmouth", "NH", Kind.SCAVENGE, -70.76, 43.07, 50),
			_stop("Boston", "MA", Kind.TOWN, -71.06, 42.36, 60),
			_stop("Providence", "RI", Kind.SCAVENGE, -71.41, 41.82, 50),
			_stop("Hartford", "CT", Kind.SCAVENGE, -72.68, 41.76, 75),
			_stop("New York", "NY", Kind.TOWN, -74.0, 40.71, 115),
			_stop("Philadelphia", "PA", Kind.SCAVENGE, -75.16, 39.95, 95),
			_stop("Baltimore", "MD", Kind.SCAVENGE, -76.61, 39.29, 100),
			_stop("Washington", "DC", Kind.TOWN, -77.04, 38.9, 40),
			_stop("Richmond", "VA", Kind.SCAVENGE, -77.44, 37.54, 110),
			_stop("Raleigh", "NC", Kind.SCAVENGE, -78.64, 35.78, 170),
			_stop("Charleston", "SC", Kind.TOWN, -79.93, 32.78, 280),
			_stop("Savannah", "GA", Kind.SCAVENGE, -81.1, 32.08, 110),
			_stop("Jacksonville", "FL", Kind.SCAVENGE, -81.66, 30.33, 140),
			_stop("Miami", "FL", Kind.FINISH, -80.19, 25.76, 350),
		],
	}


static func _chicago_to_new_orleans() -> Dictionary:
	return {
		"id": "chicago_to_new_orleans",
		"name": "Chicago to New Orleans",
		"playable": true,
		"stops": [
			_stop("Chicago", "IL", Kind.START, -87.63, 41.88, 0),
			_stop("Springfield", "IL", Kind.SCAVENGE, -89.65, 39.78, 200),
			_stop("St. Louis", "MO", Kind.TOWN, -90.2, 38.63, 100),
			_stop("Cape Girardeau", "MO", Kind.SCAVENGE, -89.52, 37.31, 115),
			_stop("Memphis", "TN", Kind.SCAVENGE, -90.05, 35.15, 175),
			_stop("Clarksdale", "MS", Kind.TOWN, -90.57, 34.2, 80),
			_stop("Jackson", "MS", Kind.SCAVENGE, -90.18, 32.3, 150),
			_stop("Hattiesburg", "MS", Kind.SCAVENGE, -89.29, 31.33, 90),
			_stop("Baton Rouge", "LA", Kind.SCAVENGE, -91.15, 30.45, 125),
			_stop("New Orleans", "LA", Kind.FINISH, -90.07, 29.95, 80),
		],
	}


static func _texas_to_washington() -> Dictionary:
	return {
		"id": "texas_to_washington",
		"name": "Texas to Washington",
		"playable": true,
		"stops": [
			_stop("Houston", "TX", Kind.START, -95.37, 29.76, 0),
			_stop("Austin", "TX", Kind.SCAVENGE, -97.74, 30.27, 165),
			_stop("Waco", "TX", Kind.TOWN, -97.15, 31.55, 100),
			_stop("Dallas", "TX", Kind.SCAVENGE, -96.8, 32.78, 95),
			_stop("Wichita Falls", "TX", Kind.SCAVENGE, -98.49, 33.91, 140),
			_stop("Amarillo", "TX", Kind.TOWN, -101.83, 35.22, 225),
			_stop("Raton", "NM", Kind.SCAVENGE, -104.44, 36.9, 215),
			_stop("Pueblo", "CO", Kind.SCAVENGE, -104.61, 38.25, 110),
			_stop("Denver", "CO", Kind.TOWN, -104.99, 39.74, 115),
			_stop("Cheyenne", "WY", Kind.SCAVENGE, -104.82, 41.14, 100),
			_stop("Casper", "WY", Kind.SCAVENGE, -106.31, 42.87, 180),
			_stop("Billings", "MT", Kind.TOWN, -108.5, 45.78, 280),
			_stop("Missoula", "MT", Kind.SCAVENGE, -114.0, 46.87, 340),
			_stop("Spokane", "WA", Kind.SCAVENGE, -117.43, 47.66, 200),
			_stop("Seattle", "WA", Kind.FINISH, -122.33, 47.61, 280),
		],
	}


static func _maine_to_california() -> Dictionary:
	return {
		"id": "maine_to_california",
		"name": "Maine to California",
		"playable": true,
		"stops": [
			_stop("Portland", "ME", Kind.START, -70.26, 43.66, 0),
			_stop("Portsmouth", "NH", Kind.SCAVENGE, -70.76, 43.07, 50),
			_stop("Boston", "MA", Kind.TOWN, -71.06, 42.36, 60),
			_stop("Worcester", "MA", Kind.SCAVENGE, -71.8, 42.26, 50),
			_stop("Albany", "NY", Kind.SCAVENGE, -73.75, 42.65, 125),
			_stop("Syracuse", "NY", Kind.TOWN, -76.15, 43.05, 145),
			_stop("Buffalo", "NY", Kind.SCAVENGE, -78.88, 42.89, 150),
			_stop("Erie", "PA", Kind.SCAVENGE, -80.09, 42.13, 100),
			_stop("Cleveland", "OH", Kind.TOWN, -81.69, 41.5, 100),
			_stop("Toledo", "OH", Kind.SCAVENGE, -83.54, 41.65, 115),
			_stop("Chicago", "IL", Kind.SCAVENGE, -87.63, 41.88, 245),
			_stop("Davenport", "IA", Kind.TOWN, -90.58, 41.52, 165),
			_stop("Des Moines", "IA", Kind.SCAVENGE, -93.6, 41.59, 175),
			_stop("Omaha", "NE", Kind.SCAVENGE, -95.94, 41.26, 135),
			_stop("North Platte", "NE", Kind.TOWN, -100.77, 41.12, 280),
			_stop("Denver", "CO", Kind.SCAVENGE, -104.99, 39.74, 260),
			_stop("Grand Junction", "CO", Kind.SCAVENGE, -108.55, 39.06, 245),
			_stop("Salt Lake City", "UT", Kind.TOWN, -111.89, 40.76, 285),
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
			_stop("Concord", "NH", Kind.SCAVENGE, -71.54, 43.21, 95),
			_stop("Burlington", "VT", Kind.TOWN, -73.21, 44.48, 150),
			_stop("Albany", "NY", Kind.SCAVENGE, -73.75, 42.65, 155),
			_stop("Syracuse", "NY", Kind.SCAVENGE, -76.15, 43.05, 145),
			_stop("Rochester", "NY", Kind.TOWN, -77.61, 43.16, 90),
			_stop("Buffalo", "NY", Kind.SCAVENGE, -78.88, 42.89, 75),
			_stop("Cleveland", "OH", Kind.SCAVENGE, -81.69, 41.5, 190),
			_stop("Toledo", "OH", Kind.TOWN, -83.54, 41.65, 115),
			_stop("Detroit", "MI", Kind.SCAVENGE, -83.05, 42.33, 60),
			_stop("Chicago", "IL", Kind.TOWN, -87.63, 41.88, 280),
			_stop("Milwaukee", "WI", Kind.SCAVENGE, -87.91, 43.04, 95),
			_stop("Madison", "WI", Kind.SCAVENGE, -89.4, 43.07, 80),
			_stop("Minneapolis", "MN", Kind.TOWN, -93.27, 44.98, 270),
			_stop("Fargo", "ND", Kind.SCAVENGE, -96.79, 46.88, 235),
			_stop("Bismarck", "ND", Kind.SCAVENGE, -100.78, 46.81, 195),
			_stop("Billings", "MT", Kind.TOWN, -108.5, 45.78, 415),
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
			_stop("Pendleton", "OR", Kind.SCAVENGE, -118.79, 45.67, 210),
			_stop("Boise", "ID", Kind.TOWN, -116.2, 43.62, 215),
			_stop("Twin Falls", "ID", Kind.SCAVENGE, -114.46, 42.56, 130),
			_stop("Salt Lake City", "UT", Kind.SCAVENGE, -111.89, 40.76, 220),
			_stop("Grand Junction", "CO", Kind.TOWN, -108.55, 39.06, 285),
			_stop("Denver", "CO", Kind.SCAVENGE, -104.99, 39.74, 245),
			_stop("Colorado Springs", "CO", Kind.SCAVENGE, -104.82, 38.83, 70),
			_stop("Amarillo", "TX", Kind.TOWN, -101.83, 35.22, 340),
			_stop("Oklahoma City", "OK", Kind.SCAVENGE, -97.52, 35.47, 260),
			_stop("Dallas", "TX", Kind.TOWN, -96.8, 32.78, 205),
			_stop("Shreveport", "LA", Kind.SCAVENGE, -93.75, 32.53, 190),
			_stop("Jackson", "MS", Kind.SCAVENGE, -90.18, 32.3, 220),
			_stop("Mobile", "AL", Kind.TOWN, -88.04, 30.69, 185),
			_stop("Pensacola", "FL", Kind.SCAVENGE, -87.22, 30.42, 60),
			_stop("Tallahassee", "FL", Kind.SCAVENGE, -84.28, 30.44, 195),
			_stop("Gainesville", "FL", Kind.TOWN, -82.32, 29.65, 150),
			_stop("Orlando", "FL", Kind.FINISH, -81.38, 28.54, 110),
		],
	}


static func _florida_to_california() -> Dictionary:
	return {
		"id": "florida_to_california",
		"name": "Florida to California",
		"playable": true,
		"stops": [
			_stop("Miami", "FL", Kind.START, -80.19, 25.76, 0),
			_stop("Fort Myers", "FL", Kind.SCAVENGE, -81.87, 26.64, 155),
			_stop("Tampa", "FL", Kind.TOWN, -82.46, 27.95, 125),
			_stop("Tallahassee", "FL", Kind.SCAVENGE, -84.28, 30.44, 275),
			_stop("Pensacola", "FL", Kind.SCAVENGE, -87.22, 30.42, 195),
			_stop("Mobile", "AL", Kind.TOWN, -88.04, 30.69, 60),
			_stop("New Orleans", "LA", Kind.SCAVENGE, -90.07, 29.95, 145),
			_stop("Lafayette", "LA", Kind.SCAVENGE, -92.02, 30.22, 135),
			_stop("Houston", "TX", Kind.TOWN, -95.37, 29.76, 215),
			_stop("San Antonio", "TX", Kind.SCAVENGE, -98.49, 29.42, 200),
			_stop("Del Rio", "TX", Kind.SCAVENGE, -100.9, 29.36, 155),
			_stop("El Paso", "TX", Kind.TOWN, -106.49, 31.76, 420),
			_stop("Tucson", "AZ", Kind.SCAVENGE, -110.97, 32.22, 320),
			_stop("Phoenix", "AZ", Kind.SCAVENGE, -112.07, 33.45, 115),
			_stop("San Diego", "CA", Kind.FINISH, -117.16, 32.72, 355),
		],
	}


static func _seattle_to_boston() -> Dictionary:
	return {
		"id": "seattle_to_boston",
		"name": "Seattle to Boston",
		"playable": true,
		"stops": [
			_stop("Seattle", "WA", Kind.START, -122.33, 47.61, 0),
			_stop("Spokane", "WA", Kind.SCAVENGE, -117.43, 47.66, 280),
			_stop("Missoula", "MT", Kind.TOWN, -114.0, 46.87, 200),
			_stop("Helena", "MT", Kind.SCAVENGE, -112.04, 46.59, 115),
			_stop("Billings", "MT", Kind.SCAVENGE, -108.5, 45.78, 240),
			_stop("Bismarck", "ND", Kind.TOWN, -100.78, 46.81, 415),
			_stop("Fargo", "ND", Kind.SCAVENGE, -96.79, 46.88, 195),
			_stop("Duluth", "MN", Kind.SCAVENGE, -92.1, 46.79, 250),
			_stop("Marquette", "MI", Kind.TOWN, -87.4, 46.54, 270),
			_stop("Sault Ste. Marie", "MI", Kind.SCAVENGE, -84.35, 46.5, 165),
			_stop("Detroit", "MI", Kind.SCAVENGE, -83.05, 42.33, 345),
			_stop("Cleveland", "OH", Kind.TOWN, -81.69, 41.5, 170),
			_stop("Erie", "PA", Kind.SCAVENGE, -80.09, 42.13, 100),
			_stop("Buffalo", "NY", Kind.SCAVENGE, -78.88, 42.89, 100),
			_stop("Rochester", "NY", Kind.TOWN, -77.61, 43.16, 75),
			_stop("Syracuse", "NY", Kind.SCAVENGE, -76.15, 43.05, 90),
			_stop("Albany", "NY", Kind.SCAVENGE, -73.75, 42.65, 145),
			_stop("Springfield", "MA", Kind.TOWN, -72.59, 42.1, 90),
			_stop("Worcester", "MA", Kind.SCAVENGE, -71.8, 42.26, 50),
			_stop("Boston", "MA", Kind.FINISH, -71.06, 42.36, 45),
		],
	}

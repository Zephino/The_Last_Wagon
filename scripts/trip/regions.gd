class_name Regions
extends RefCounted
## The five regions of the country. A stop's region comes from its map
## position, so new cities are never mislabelled. Each region has its own
## land colors and scenery, and changes the road a little: how many wrecks
## and enemies there are, how fast fuel goes, and store prices. Region-only
## road events live in RoadEvents.REGION_EVENTS.

const NORTHEAST := "northeast"
const MIDWEST := "midwest"
const MOUNTAINS := "mountains"
const DESERT := "desert"
const SOUTH := "south"
const ALL: Array[String] = [NORTHEAST, MIDWEST, MOUNTAINS, DESERT, SOUTH]

const DATA: Dictionary = {
	"northeast": {"name": "Northeast cities", "scenery": "city",
		"ground": Color("4a4440"), "top": Color("6a6460"), "scenery_color": Color("2a2630"),
		"wreck_share": 0.45, "extra_walkers": 1, "fuel": 1.0, "prices": 1.1, "level_bonus": 2,
		"blurb": "Dense ruined cities. More enemies."},
	"midwest": {"name": "Midwest plains", "scenery": "farms",
		"ground": Color("5a4a2a"), "top": Color("7a8a3a"), "scenery_color": Color("3a3420"),
		"wreck_share": 0.3, "extra_walkers": 0, "fuel": 1.0, "prices": 0.9, "level_bonus": 0,
		"blurb": "Long, open roads. Cheap stores."},
	"mountains": {"name": "Mountains and Northwest", "scenery": "peaks",
		"ground": Color("4a4a3a"), "top": Color("6a7a5a"), "scenery_color": Color("2e3a34"),
		"wreck_share": 0.6, "extra_walkers": 0, "fuel": 1.1, "prices": 1.0, "level_bonus": 1,
		"blurb": "Twisty roads full of wrecks."},
	"desert": {"name": "Desert Southwest", "scenery": "mesas",
		"ground": Color("8a6a3a"), "top": Color("b08a50"), "scenery_color": Color("6a4030"),
		"wreck_share": 0.45, "extra_walkers": 0, "fuel": 1.3, "prices": 1.15, "level_bonus": 1,
		"blurb": "Hot and empty. Fuel runs out faster."},
	"south": {"name": "South: swamps and coast", "scenery": "swamp",
		"ground": Color("3a4a30"), "top": Color("5a7a3a"), "scenery_color": Color("263a2a"),
		"wreck_share": 0.4, "extra_walkers": 0, "fuel": 1.0, "prices": 1.0, "level_bonus": 1,
		"blurb": "Swamps, heat and sudden storms."},
}


## The region a map position belongs to (longitude, latitude).
static func at(lon: float, lat: float) -> String:
	if lon < -103.0:
		return DESERT if lat < 37.5 else MOUNTAINS
	if lat < 33.5 or (lat < 36.6 and lon > -95.0):
		return SOUTH
	if lon > -84.0 and lat > 37.0:
		return NORTHEAST
	return MIDWEST


static func of_stop(stop: Dictionary) -> String:
	return at(float(stop["lon"]), float(stop["lat"]))


static func info(region: String) -> Dictionary:
	return DATA.get(region, DATA[MIDWEST])


static func display_name(region: String) -> String:
	return str(info(region)["name"])


## Region land colors, tinted a little toward the apocalypse's mood.
static func ground(region: String, apocalypse: Apocalypse) -> Color:
	return Color(info(region)["ground"]).lerp(apocalypse.ground_color(), 0.3)


static func ground_top(region: String, apocalypse: Apocalypse) -> Color:
	return Color(info(region)["top"]).lerp(apocalypse.ground_color(), 0.3)


static func scenery_color(region: String, apocalypse: Apocalypse) -> Color:
	return Color(info(region)["scenery_color"]).lerp(apocalypse.sky_color().darkened(0.4), 0.35)

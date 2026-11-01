class_name Unlocks
extends RefCounted
## Everything that can be unlocked between trips: awards (what you did),
## and what each award unlocks (a route, a survivor role, a starting perk or
## a car color). Progress (the autoload) remembers which awards you've earned.

## Each award: id, name, how to earn it, whether it's a secret (shown as ???
## until found), and what it unlocks: {"kind": "route"|"role"|"perk"|"color", "id": ...}.
const AWARDS: Array[Dictionary] = [
	{"id": "first_steps", "name": "First Steps", "how": "Reach your first stop.", "secret": false,
		"unlock": {"kind": "perk", "id": "pocket_money"}},
	{"id": "finish_any", "name": "End of the Road", "how": "Finish any route.", "secret": false,
		"unlock": {"kind": "route", "id": "maine_to_california"}},
	{"id": "finish_maine_to_california", "name": "Go West", "how": "Finish Maine to California.", "secret": false,
		"unlock": {"kind": "route", "id": "maine_to_oregon"}},
	{"id": "finish_maine_to_oregon", "name": "Rain Country", "how": "Finish Maine to Oregon.", "secret": false,
		"unlock": {"kind": "route", "id": "oregon_to_florida"}},
	{"id": "finish_oregon_to_florida", "name": "Coast to Coast", "how": "Finish Oregon to Florida.", "secret": false,
		"unlock": {"kind": "route", "id": "florida_to_california"}},
	{"id": "full_house", "name": "Full House", "how": "Finish a route with all four survivors standing.", "secret": false,
		"unlock": {"kind": "role", "id": "cook"}},
	{"id": "on_foot", "name": "Who Needs Wheels", "how": "Finish a route on foot.", "secret": false,
		"unlock": {"kind": "perk", "id": "spare_tank"}},
	{"id": "speed_demon", "name": "Speed Demon", "how": "Finish a route in 12 days or less.", "secret": false,
		"unlock": {"kind": "color", "id": "racing_yellow"}},
	{"id": "mixed_finish", "name": "Double Trouble", "how": "Finish a route during a mixed apocalypse.", "secret": false,
		"unlock": {"kind": "color", "id": "toxic_green"}},
	{"id": "crates_25", "name": "Crate Expectations", "how": "Open 25 crates (over all trips).", "secret": false,
		"unlock": {"kind": "perk", "id": "ammo_belt"}},
	{"id": "kills_100", "name": "Pest Control", "how": "Defeat 100 enemies (over all trips).", "secret": false,
		"unlock": {"kind": "color", "id": "matte_black"}},
	{"id": "wiped_out", "name": "Character Building", "how": "Lose a whole party.", "secret": false,
		"unlock": {"kind": "color", "id": "primer_grey"}},
	{"id": "stash_1", "name": "Sticky Fingers", "how": "Find a hidden stash in a scavenging level.", "secret": true,
		"unlock": {"kind": "role", "id": "thief"}},
	{"id": "stash_5", "name": "Treasure Hunter", "how": "Find 5 hidden stashes (over all trips).", "secret": true,
		"unlock": {"kind": "color", "id": "stash_gold"}},
	{"id": "radio_signal", "name": "Are You Receiving", "how": "Follow a strange radio signal on the road.", "secret": true,
		"unlock": {"kind": "perk", "id": "first_aid"}},
	{"id": "bunker", "name": "Down the Hatch", "how": "Open a bunker hatch on the road.", "secret": true,
		"unlock": {"kind": "perk", "id": "beater"}},
	{"id": "ice_cream", "name": "Brain Freeze", "how": "Meet the ice cream truck.", "secret": true,
		"unlock": {"kind": "color", "id": "ice_cream_pink"}},
]

## Starting perks: pick one before a trip. "none" is always available.
const PERKS: Array[Dictionary] = [
	{"id": "none", "name": "No perk", "text": "Start with nothing extra."},
	{"id": "pocket_money", "name": "Pocket Money", "text": "Start with $150 more."},
	{"id": "spare_tank", "name": "Spare Tank", "text": "Start with 10 gallons of fuel."},
	{"id": "first_aid", "name": "First Aid Kit", "text": "Start with 2 medkits."},
	{"id": "ammo_belt", "name": "Ammo Belt", "text": "Start with 40 rounds of ammo."},
	{"id": "beater", "name": "Old Beater", "text": "Start with a beat-up car (45% condition)."},
]

## Car colors (looks only). "classic_red" is always available.
const COLORS: Array[Dictionary] = [
	{"id": "classic_red", "name": "Classic Red", "color": Color("8a3a2a")},
	{"id": "racing_yellow", "name": "Racing Yellow", "color": Color("c8a020")},
	{"id": "toxic_green", "name": "Toxic Green", "color": Color("5aa030")},
	{"id": "matte_black", "name": "Matte Black", "color": Color("2a2a2e")},
	{"id": "primer_grey", "name": "Primer Grey", "color": Color("6a6a6a")},
	{"id": "stash_gold", "name": "Stash Gold", "color": Color("d8a838")},
	{"id": "ice_cream_pink", "name": "Ice Cream Pink", "color": Color("e890b0")},
]

## Unlocked from the very first trip.
const FREE: Dictionary = {
	"route": ["maine_to_florida"],
	"role": ["scout", "gunner", "medic", "mechanic"],
	"perk": ["none"],
	"color": ["classic_red"],
}


static func award(award_id: String) -> Dictionary:
	for entry: Dictionary in AWARDS:
		if entry["id"] == award_id:
			return entry
	return {}


## The award that unlocks this thing, or {} if it's free.
static func award_for(kind: String, thing_id: String) -> Dictionary:
	for entry: Dictionary in AWARDS:
		var unlock: Dictionary = entry["unlock"]
		if unlock["kind"] == kind and unlock["id"] == thing_id:
			return entry
	return {}


static func perk(perk_id: String) -> Dictionary:
	for entry: Dictionary in PERKS:
		if entry["id"] == perk_id:
			return entry
	return PERKS[0]


static func car_color(color_id: String) -> Color:
	for entry: Dictionary in COLORS:
		if entry["id"] == color_id:
			return entry["color"]
	return COLORS[0]["color"]


## A short line for what an award unlocks, e.g. "Unlocks route: Maine to Oregon".
static func describe_unlock(unlock: Dictionary) -> String:
	var thing_id: String = unlock["id"]
	match str(unlock["kind"]):
		"route":
			return "Unlocks route: %s" % Routes.by_id(thing_id).get("name", thing_id)
		"role":
			return "Unlocks survivor: %s" % Survivor.name_of_role(Survivor.role_from_id(thing_id))
		"perk":
			return "Unlocks perk: %s" % perk(thing_id)["name"]
		"color":
			for entry: Dictionary in COLORS:
				if entry["id"] == thing_id:
					return "Unlocks car color: %s" % entry["name"]
	return ""

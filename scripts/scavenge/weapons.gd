class_name Weapons
extends RefCounted
## The weapons you can find in scavenging levels. The party shares them for
## the whole trip (they're lost when the trip ends: it's a roguelike).
## Each weapon uses a supply as ammo ("" = none): the pistol, shotgun and
## rifle use ammo, the flamethrower burns fuel, and the nail gun eats scrap.

const START: Array[String] = ["pistol", "crowbar"]

## damage: per hit (the Gunner doubles it). cooldown: seconds between shots.
## cost: supply used per shot (the nail gun uses 1 scrap per 4 nails).
## pellets/spread: shots per pull and their angle (degrees).
## speed/range: how fast and far shots fly. pierce: enemies one shot can hit.
## melee: reach in pixels for swings (no projectile).
const DATA: Dictionary = {
	"pistol": {"name": "Pistol", "supply": "ammo", "cost": 1.0, "damage": 1, "cooldown": 0.32,
		"pellets": 1, "spread": 0.0, "speed": 280.0, "range": 240.0, "pierce": 1, "color": Color("ffe070")},
	"crowbar": {"name": "Crowbar", "supply": "", "cost": 0.0, "damage": 2, "cooldown": 0.42, "melee": 22.0},
	"shotgun": {"name": "Shotgun", "supply": "ammo", "cost": 2.0, "damage": 1, "cooldown": 0.7,
		"pellets": 5, "spread": 14.0, "speed": 300.0, "range": 110.0, "pierce": 1, "color": Color("ffd060")},
	"rifle": {"name": "Rifle", "supply": "ammo", "cost": 1.0, "damage": 3, "cooldown": 0.6,
		"pellets": 1, "spread": 0.0, "speed": 440.0, "range": 380.0, "pierce": 3, "color": Color("fff0b0")},
	"flamethrower": {"name": "Flamethrower", "supply": "fuel", "cost": 0.12, "damage": 1, "cooldown": 0.09,
		"pellets": 1, "spread": 10.0, "speed": 150.0, "range": 60.0, "pierce": 2, "color": Color("ff8030")},
	"nailgun": {"name": "Nail Gun", "supply": "scrap", "cost": 0.25, "damage": 1, "cooldown": 0.1,
		"pellets": 1, "spread": 3.0, "speed": 330.0, "range": 210.0, "pierce": 1, "color": Color("c0c8d0")},
}
## Order for number keys and switching.
const ORDER: Array[String] = ["crowbar", "pistol", "shotgun", "rifle", "flamethrower", "nailgun"]


static func info(weapon_id: String) -> Dictionary:
	return DATA.get(weapon_id, DATA["pistol"])


static func display_name(weapon_id: String) -> String:
	return str(info(weapon_id)["name"])


static func is_melee(weapon_id: String) -> bool:
	return info(weapon_id).has("melee")


## A weapon you don't have yet, picked at random ("" if you have them all).
static func random_new(rng: RandomNumberGenerator, owned: Array[String]) -> String:
	var missing: Array[String] = []
	for weapon_id: String in ORDER:
		if not owned.has(weapon_id):
			missing.append(weapon_id)
	if missing.is_empty():
		return ""
	return missing[rng.randi_range(0, missing.size() - 1)]


## "Shotgun (ammo: 12)" style text for the HUD; `left` is how much of its
## supply the party has.
static func hud_text(weapon_id: String, left: float) -> String:
	var data := info(weapon_id)
	var supply: String = data["supply"]
	if supply.is_empty():
		return str(data["name"])
	return "%s (%s: %d)" % [data["name"], supply, floori(left)]

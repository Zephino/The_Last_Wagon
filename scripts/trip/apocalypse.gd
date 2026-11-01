class_name Apocalypse
extends RefCounted
## What ended the world this run. Rolled at random for each new trip: one
## threat, or sometimes two at once. Sets enemy types and the world's colors.

enum Threat { ZOMBIES, FALLOUT, ALIENS, PLAGUE }

const MIX_CHANCE := 0.3

var threats: Array[Threat] = []


static func roll(rng: RandomNumberGenerator) -> Apocalypse:
	var result := Apocalypse.new()
	var first := rng.randi_range(0, 3)
	result.threats.append(first as Threat)
	if rng.randf() < MIX_CHANCE:
		var second := (first + rng.randi_range(1, 3)) % 4
		result.threats.append(second as Threat)
	return result


func is_mixed() -> bool:
	return threats.size() > 1


## Short id for the leaderboard, e.g. "zombies" or "fallout+aliens".
func id() -> String:
	var parts: Array[String] = []
	for threat: Threat in threats:
		parts.append(_short_name(threat).to_lower())
	return "+".join(parts)


func main_threat() -> Threat:
	return threats[0]


func pick_threat(rng: RandomNumberGenerator) -> Threat:
	return threats[rng.randi_range(0, threats.size() - 1)]


func title() -> String:
	if is_mixed():
		return "%s AND %s" % [_short_name(threats[0]), _short_name(threats[1])]
	return ["THE DEAD WALK", "THE BOMBS FELL", "THEY CAME FROM ABOVE", "THE COUGH"][main_threat()]


func intro() -> String:
	var lines: Array[String] = []
	for threat: Threat in threats:
		lines.append(_intro_line(threat))
	if is_mixed():
		lines.append("Experts agree this is \"a lot.\" The experts have since been eaten.")
	return " ".join(lines)


func sky_color() -> Color:
	return [Color("3a2433"), Color("4a4a26"), Color("221a3d"), Color("3b3f42")][main_threat()]


func horizon_color() -> Color:
	return [Color("b0563a"), Color("a7a94a"), Color("6d3fa0"), Color("7d8a85")][main_threat()]


func ground_color() -> Color:
	return [Color("4a3b2a"), Color("4f4a2c"), Color("3a3446"), Color("444a44")][main_threat()]


func land_tint() -> Color:
	return [Color("6b5a3a"), Color("7a7a3a"), Color("5a4a7a"), Color("5f6b62")][main_threat()]


## Name, health, speed (pixels/second), contact damage and colors per threat.
static func enemy_stats(threat: Threat) -> Dictionary:
	match threat:
		Threat.ZOMBIES:
			return {"name": "Shambler", "health": 3, "speed": 34.0, "damage": 12,
				"skin": Color("7d9a5a"), "cloth": Color("5a4a3a"), "eye": Color("e8e070")}
		Threat.FALLOUT:
			return {"name": "Glower", "health": 5, "speed": 28.0, "damage": 15,
				"skin": Color("c8d050"), "cloth": Color("6a5a2a"), "eye": Color("80ff60")}
		Threat.ALIENS:
			return {"name": "Visitor", "health": 2, "speed": 58.0, "damage": 10,
				"skin": Color("9a8ac8"), "cloth": Color("3a3a5a"), "eye": Color("30e0e0")}
		_:
			return {"name": "Hacker", "health": 3, "speed": 46.0, "damage": 11,
				"skin": Color("d8c8c0"), "cloth": Color("6a3a3a"), "eye": Color("e03030")}


func _short_name(threat: Threat) -> String:
	return ["ZOMBIES", "FALLOUT", "ALIENS", "PLAGUE"][threat]


func _intro_line(threat: Threat) -> String:
	match threat:
		Threat.ZOMBIES:
			return "The dead got up on a Tuesday. Nobody likes Tuesdays, but this was a lot."
		Threat.FALLOUT:
			return "The bombs fell. The sky is the color of old mustard and the rain stings."
		Threat.ALIENS:
			return "They came from above, said nothing, and started taking people. Rude."
		_:
			return "It started as a cough. Then everyone was coughing. Then they stopped coughing and started running at you."

class_name Survivor
extends RefCounted
## One member of the party. Each survivor has a role that changes how they
## play in levels and what they help with on the road. The first four roles
## are always available; Cook and Thief are unlocked with awards.

enum Role { MECHANIC, MEDIC, GUNNER, SCOUT, COOK, THIEF }

const BASE_ROLES: Array[Role] = [Role.SCOUT, Role.GUNNER, Role.MEDIC, Role.MECHANIC]
const ALL_ROLES: Array[Role] = [Role.SCOUT, Role.GUNNER, Role.MEDIC, Role.MECHANIC, Role.COOK, Role.THIEF]
const ROLE_IDS: Array[String] = ["mechanic", "medic", "gunner", "scout", "cook", "thief"]

const MAX_HEALTH := 100

const NAMES: Array[String] = [
	"Dolores", "Hank", "Mei", "Rusty", "Priya", "Otis", "June", "Big Carl",
	"Tamsin", "Eddie", "Nia", "Walt", "Rosa", "Dmitri", "Bev", "Kofi",
]
const SKIN_TONES: Array[Color] = [
	Color("f1c8a0"), Color("d9a066"), Color("a86b3c"), Color("7a4a2a"), Color("5a3520"),
]
const HAIR_COLORS: Array[Color] = [
	Color("2b1d14"), Color("6b3e1f"), Color("c9a24b"), Color("8a8a8a"), Color("a33b20"),
]

var name: String
var role: Role
var health: int = MAX_HEALTH
var skin: Color
var hair: Color


func _init(survivor_name: String, survivor_role: Role, skin_tone: Color, hair_color: Color) -> void:
	name = survivor_name
	role = survivor_role
	skin = skin_tone
	hair = hair_color


## A party of four, one of each base role, with random names and looks.
static func roll_party(rng: RandomNumberGenerator) -> Array[Survivor]:
	return make_party(rng, BASE_ROLES)


## A party with the given roles (one survivor each), random names and looks.
static func make_party(rng: RandomNumberGenerator, roles: Array[Role]) -> Array[Survivor]:
	var names := NAMES.duplicate()
	var party: Array[Survivor] = []
	for role_value: Role in roles:
		var picked: String = names.pop_at(rng.randi_range(0, names.size() - 1))
		var tone: Color = SKIN_TONES[rng.randi_range(0, SKIN_TONES.size() - 1)]
		var hair_color: Color = HAIR_COLORS[rng.randi_range(0, HAIR_COLORS.size() - 1)]
		party.append(Survivor.new(picked, role_value, tone, hair_color))
	return party


static func role_from_id(role_id: String) -> Role:
	return maxi(0, ROLE_IDS.find(role_id)) as Role


static func name_of_role(role_value: Role) -> String:
	return ["Mechanic", "Medic", "Gunner", "Scout", "Cook", "Thief"][role_value]


static func perk_of_role(role_value: Role) -> String:
	match role_value:
		Role.MECHANIC:
			return "Uses less fuel. Better repairs. Hotwires cars fast."
		Role.MEDIC:
			return "Medkits heal and revive much more."
		Role.GUNNER:
			return "Double damage. Shoots faster."
		Role.COOK:
			return "Makes food last: the party eats 40% less."
		Role.THIEF:
			return "Finds extra money everywhere."
		_:
			return "Runs faster, jumps higher, finds extra loot."


func is_downed() -> bool:
	return health <= 0


func hurt(amount: int) -> void:
	health = maxi(0, health - amount)


## Healing does nothing for a downed survivor; they need reviving first.
func heal(amount: int) -> void:
	if is_downed():
		return
	health = mini(MAX_HEALTH, health + amount)


func revive(to_health: int) -> void:
	health = clampi(to_health, 1, MAX_HEALTH)


func role_name() -> String:
	return name_of_role(role)


func perk() -> String:
	return perk_of_role(role)


func shirt_color() -> Color:
	return [Color("d08a2e"), Color("e8e8e8"), Color("6f7d3c"), Color("3f6fb0"), Color("b8483a"), Color("4a4a5a")][role]


func move_speed() -> float:
	return 112.0 if role == Role.SCOUT else 92.0


func jump_speed() -> float:
	return 330.0 if role == Role.SCOUT else 300.0


func shot_damage() -> int:
	return 2 if role == Role.GUNNER else 1


func fire_cooldown() -> float:
	return 0.2 if role == Role.GUNNER else 0.32


func sprite() -> Texture2D:
	return PixelArt.person(skin, hair, shirt_color(), Color("3b3b55"))

extends Node
## Autoload "Trip". Holds everything about the current run: route, party,
## supplies, vehicle and time. Screens read and change it, then call go().

const SCENES: Dictionary = {
	"title": "res://scenes/title.tscn",
	"town": "res://scenes/town.tscn",
	"map": "res://scenes/map.tscn",
	"road": "res://scenes/road.tscn",
	"scavenge": "res://scenes/scavenge.tscn",
	"end": "res://scenes/end.tscn",
	"leaderboard": "res://scenes/leaderboard.tscn",
	"settings": "res://scenes/settings.tscn",
}
const STARTING_MONEY := 600
const FOOD_PER_PERSON_PER_DAY := 2
const STARVING_DAMAGE := 8
const MAX_MESSAGES := 6
const REPAIR_SCRAP_COST := 5

var rng := RandomNumberGenerator.new()
var route: Dictionary = {}
var apocalypse: Apocalypse
var party: Array[Survivor] = []
var messages: Array[String] = []
var active_index := 0
var stop_index := 0
var days := 0.0
var miles_traveled := 0
var money := STARTING_MONEY
var food := 0
var fuel := 0.0
var ammo := 0
var medkits := 0
var scrap := 0
var has_vehicle := false
var vehicle_health := 0
var stop_scavenged := false
var won := false
var _day_carry := 0.0


func _ready() -> void:
	new_trip(Routes.first_playable(), int(Time.get_unix_time_from_system()))


## Starts a fresh run. On foot, no supplies, random apocalypse and party.
func new_trip(chosen_route: Dictionary, seed_value: int) -> void:
	rng.seed = seed_value
	route = chosen_route
	apocalypse = Apocalypse.roll(rng)
	party = Survivor.roll_party(rng)
	messages.clear()
	active_index = 0
	stop_index = 0
	days = 0.0
	miles_traveled = 0
	money = STARTING_MONEY
	food = 0
	fuel = 0.0
	ammo = 0
	medkits = 0
	scrap = 0
	has_vehicle = false
	vehicle_health = 0
	stop_scavenged = false
	won = false
	_day_carry = 0.0
	log_message(apocalypse.intro())


func go(screen: String) -> void:
	get_tree().change_scene_to_file(SCENES[screen])


func stops() -> Array:
	return route.get("stops", [])


func current_stop() -> Dictionary:
	return stops()[stop_index]


func next_stop() -> Dictionary:
	if stop_index + 1 < stops().size():
		return stops()[stop_index + 1]
	return {}


func stop_label(stop: Dictionary) -> String:
	return "%s, %s" % [stop["city"], stop["state"]]


func active() -> Survivor:
	return party[active_index]


func standing_count() -> int:
	var count := 0
	for survivor: Survivor in party:
		if not survivor.is_downed():
			count += 1
	return count


func anyone_standing() -> bool:
	return standing_count() > 0


## Everyone is down and no medkit is left to get anyone back up.
func is_game_over() -> bool:
	return not anyone_standing() and medkits <= 0


func has_standing_role(role: Survivor.Role) -> bool:
	for survivor: Survivor in party:
		if survivor.role == role and not survivor.is_downed():
			return true
	return false


func fuel_per_mile() -> float:
	return 1.0 / 24.0 if has_standing_role(Survivor.Role.MECHANIC) else 1.0 / 20.0


func log_message(text: String) -> void:
	messages.append(text)
	while messages.size() > MAX_MESSAGES:
		messages.pop_front()


## Supplies by name: "food", "fuel", "ammo", "medkits", "scrap", "money".
func get_supply(supply: String) -> float:
	match supply:
		"food": return food
		"fuel": return fuel
		"ammo": return ammo
		"medkits": return medkits
		"scrap": return scrap
		"money": return money
	return 0.0


func add_supply(supply: String, amount: int) -> void:
	match supply:
		"food": food = maxi(0, food + amount)
		"fuel": fuel = maxf(0.0, fuel + amount)
		"ammo": ammo = maxi(0, ammo + amount)
		"medkits": medkits = maxi(0, medkits + amount)
		"scrap": scrap = maxi(0, scrap + amount)
		"money": money = maxi(0, money + amount)


## Moves time forward. Each full day the whole party eats.
func pass_time(amount_days: float) -> void:
	days += amount_days
	_day_carry += amount_days
	while _day_carry >= 1.0:
		_day_carry -= 1.0
		_eat_for_one_day()


func _eat_for_one_day() -> void:
	var needed := party.size() * FOOD_PER_PERSON_PER_DAY
	if food >= needed:
		food -= needed
		return
	food = 0
	for survivor: Survivor in party:
		survivor.hurt(STARVING_DAMAGE)
	log_message("Nobody ate today. Someone suggested eating the map. It was a short meeting.")


## Makes the next standing survivor the active one. False if nobody is standing.
func switch_to_next_standing() -> bool:
	for step: int in range(1, party.size() + 1):
		var index := (active_index + step) % party.size()
		if not party[index].is_downed():
			active_index = index
			return true
	return false


func ensure_active_standing() -> void:
	if active().is_downed():
		switch_to_next_standing()


## Uses a medkit: revives a downed survivor or heals a hurt one.
func treat(survivor: Survivor) -> bool:
	if medkits <= 0:
		return false
	var medic := has_standing_role(Survivor.Role.MEDIC)
	medkits -= 1
	if survivor.is_downed():
		survivor.revive(60 if medic else 35)
		log_message("%s is back on their feet. Mostly." % survivor.name)
	else:
		survivor.heal(80 if medic else 50)
		log_message("%s got patched up." % survivor.name)
	return true


func can_repair() -> bool:
	return has_vehicle and vehicle_health < 100 and scrap >= REPAIR_SCRAP_COST


func repair_vehicle() -> bool:
	if not can_repair():
		return false
	scrap -= REPAIR_SCRAP_COST
	var amount := 40 if has_standing_role(Survivor.Role.MECHANIC) else 25
	vehicle_health = mini(100, vehicle_health + amount)
	log_message("You bang on the car with a wrench until it sounds happier.")
	return true


func lose_vehicle(reason: String) -> void:
	has_vehicle = false
	vehicle_health = 0
	log_message(reason)


func find_vehicle(health: int, fuel_in_tank: int) -> void:
	has_vehicle = true
	vehicle_health = health
	fuel += fuel_in_tank
	log_message("You found a car! It has %d gallons in the tank and a smell you'll get used to." % fuel_in_tank)


func arrive_at_next_stop() -> void:
	var stop := next_stop()
	if stop.is_empty():
		return
	miles_traveled += int(stop["miles"])
	stop_index += 1
	stop_scavenged = false
	log_message("Arrived in %s." % stop_label(stop))


func is_at_finish() -> bool:
	return int(current_stop()["kind"]) == Routes.Kind.FINISH


## Stops on the route after the start (reaching all of them finishes the trip).
func total_stops() -> int:
	return stops().size() - 1


## This trip as a leaderboard entry (see leaderboard-api/src/board.js).
func score_entry(player_name: String) -> Dictionary:
	return {
		"name": player_name,
		"route": str(route.get("id", "")),
		"finished": won,
		"stops": stop_index,
		"total_stops": total_stops(),
		"days": int(days) + 1,
		"survivors": standing_count(),
		"miles": miles_traveled,
		"apocalypse": apocalypse.id(),
		"version": str(ProjectSettings.get_setting("application/config/version", "")),
	}

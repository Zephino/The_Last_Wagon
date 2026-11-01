extends SceneTree
## Headless smoke test. Plays every screen of the core loop for real frames
## and checks the rules hold. Run:
##   godot --headless --path . -s res://scripts/tests/smoke_test.gd
## Exit code 0 = pass, 1 = fail. Also check the output for "SCRIPT ERROR".

const MAX_WAIT_FRAMES := 600
const TEST_PROGRESS := "user://test_progress_scratch.json"

var _errors: Array[String] = []
var _trip: Node
var _progress: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_trip = root.get_node("Trip")
	_progress = root.get_node("Progress")
	_progress.use_test_file(TEST_PROGRESS)
	_check_version()
	_check_new_trip()
	_check_level_layouts()
	_check_map_painter()
	await _check_screens_load()
	await _check_drive_to_next_stop()
	await _check_walk_and_hotwire()
	await _check_scavenge_exit()
	await _check_game_over()
	_check_score_entry()
	await _check_online_screens()
	_check_routes()
	_check_regions()
	_check_unlocks_and_awards()
	_check_road_events()
	await _check_choice_event_on_road()
	await _check_event_waits_for_jump()
	_check_stashes()
	await _check_meta_screens()
	await _check_cloud_sync()
	_check_weapons()
	await _check_enemy_kinds()
	await _check_bosses()
	await _check_level_pieces()
	_progress.use_test_file("")
	DirAccess.remove_absolute(TEST_PROGRESS)
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _check_version() -> void:
	var file := FileAccess.open("res://VERSION", FileAccess.READ)
	var version := file.get_as_text().strip_edges() if file != null else ""
	var setting := str(ProjectSettings.get_setting("application/config/version", ""))
	_expect(version != "" and version == setting, "project.godot config/version (%s) must match VERSION (%s)" % [setting, version])


## Most checks use Maine to Florida (open from the start, 15 stops).
func _new_trip(seed_value: int) -> void:
	_trip.new_trip(Routes.by_id("maine_to_florida"), seed_value)


func _check_new_trip() -> void:
	_new_trip(1234)
	_expect(_trip.party.size() == 4, "party should have 4 survivors")
	_expect(_trip.apocalypse != null and _trip.apocalypse.threats.size() >= 1, "apocalypse should be rolled")
	_expect(not _trip.has_vehicle, "trip should start on foot")
	_expect(_trip.money == _trip.STARTING_MONEY, "starting money")
	_trip.food = 10
	_trip.pass_time(1.0)
	_expect(_trip.food == 2, "4 survivors eat 8 food per day, got %d left" % _trip.food)
	_trip.pass_time(1.0)
	_expect(_trip.party[0].health == Survivor.MAX_HEALTH - _trip.STARVING_DAMAGE, "starving hurts everyone")
	var seen_mix := false
	var rng := RandomNumberGenerator.new()
	for index: int in 200:
		rng.seed = index
		if Apocalypse.roll(rng).is_mixed():
			seen_mix = true
	_expect(seen_mix, "some apocalypses should be a mix")


## Every generated level must be crossable: pits are either jumpable (48 px
## or less) or bridged by platforms/movers with jumpable steps, and climbs
## over 32 px have a ladder. Checked for every region and for boss levels.
func _check_level_layouts() -> void:
	var rng := RandomNumberGenerator.new()
	var regions: Array[String] = ["", "northeast", "midwest", "mountains", "desert", "south"]
	for seed_value: int in 120:
		rng.seed = seed_value
		var region: String = regions[seed_value % regions.size()]
		var layout := LevelLayout.generate(rng, seed_value % 10, seed_value % 7 == 0, region)
		var grounds: Array[Rect2] = []
		var steps: Array[Rect2] = []
		for solid: Dictionary in layout.solids:
			if solid["kind"] == "ground":
				grounds.append(solid["rect"])
			elif solid["kind"] in ["platform", "hay"]:
				steps.append(solid["rect"])
		for mover: Dictionary in layout.movers:
			var rect: Rect2 = mover["rect"]
			steps.append(rect.merge(Rect2(rect.position + Vector2(mover["travel"]), rect.size)))
		grounds.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)
		for index: int in range(1, grounds.size()):
			var left := grounds[index - 1]
			var right := grounds[index]
			var gap := right.position.x - left.end.x
			if gap > 48.0:
				_expect(_bridged(left.end.x, right.position.x, steps), "level %d (%s) has an unbridged %.0f px pit" % [seed_value, region, gap])
			var rise := left.position.y - right.position.y
			if rise > 32.0:
				var climbable := false
				for ladder: Rect2 in layout.ladders:
					if absf(ladder.end.x - right.position.x) < 16.0:
						climbable = true
				_expect(climbable, "level %d (%s) has a %.0f px climb with no ladder" % [seed_value, region, rise])
		_expect(layout.exit_spot.x > 300.0, "level %d exit should be far from the start" % seed_value)
		if seed_value % 7 == 0:
			_expect(layout.has_boss and layout.arena.size.x > 300.0, "boss level %d has an arena" % seed_value)


## True when a pit from `from_x` to `to_x` can be crossed in jumps of 48 px or
## less using the given platforms (each step must be inside the pit's span).
func _bridged(from_x: float, to_x: float, steps: Array[Rect2]) -> bool:
	var reach := from_x
	var moved := true
	while moved:
		moved = false
		if to_x - reach <= 48.0:
			return true
		for step: Rect2 in steps:
			if step.position.x - reach <= 48.0 and step.end.x > reach and step.position.x < to_x:
				reach = step.end.x
				moved = true
	return to_x - reach <= 48.0


func _check_map_painter() -> void:
	var texture := MapPainter.paint(Routes.first_playable()["stops"], 2, Color("6b5a3a"))
	_expect(texture != null and texture.get_width() == MapPainter.WIDTH, "map texture should paint")


func _change_to(screen: String) -> void:
	_trip.go(screen)
	await process_frame
	await process_frame
	for index: int in 20:
		await process_frame


func _wait_for_scene(scene_name: String) -> bool:
	for index: int in MAX_WAIT_FRAMES:
		if current_scene != null and current_scene.name == scene_name:
			return true
		await process_frame
	return false


func _check_screens_load() -> void:
	_new_trip(42)
	for screen: String in ["title", "town", "map", "road", "scavenge", "end"]:
		_new_trip(42)
		await _change_to(screen)
		_expect(current_scene != null, "screen '%s' should load" % screen)


func _check_drive_to_next_stop() -> void:
	_new_trip(7)
	_trip.has_vehicle = true
	_trip.vehicle_health = 100
	_trip.fuel = 50.0
	_trip.food = 100
	await _change_to("road")
	var road := current_scene
	_expect(road.name == "Road", "road screen should be showing")
	# Skip this stretch's choice events (tested separately) and jump to the end.
	(road.get("_choice_xs") as Array).clear()
	road.set("_x", float(road.get("_length")) - 2.0)
	var arrived := await _wait_for_scene("Map")
	_expect(arrived, "driving to the end of the road should arrive at the map")
	_expect(_trip.stop_index == 1, "should now be at the second stop, got %d" % _trip.stop_index)


func _check_walk_and_hotwire() -> void:
	_new_trip(8)
	await _change_to("road")
	var road := current_scene
	var car: Sprite2D = road.get("_abandoned_car")
	_expect(car != null, "first leg on foot should always have an abandoned car")
	if car != null:
		road.call("_take_car")
		await process_frame
		_expect(_trip.has_vehicle, "hotwiring should give you a car")
		_expect(_trip.fuel >= 1.5, "a found car should have some fuel (has %.2f)" % _trip.fuel)


func _check_scavenge_exit() -> void:
	_new_trip(9)
	_trip.stop_index = 1
	await _change_to("scavenge")
	# Scripts that use the Trip autoload can't be named as types in a test
	# script, so the level is reached through get().
	var level := current_scene
	_expect(level != null and level.name == "Scavenge", "scavenge screen should load")
	if level == null or level.name != "Scavenge":
		return
	var enemies: Array = level.get("enemies")
	_expect(enemies.size() > 0, "a level should have enemies")
	_expect(_trip.stop_scavenged, "entering marks the stop as scavenged")
	var player: CharacterBody2D = level.get("player")
	var start_x := player.position.x
	Input.action_press("move_right")
	for index: int in 40:
		await physics_frame
	Input.action_release("move_right")
	_expect(player.position.x > start_x + 20.0, "holding right should walk the survivor forward")
	_expect(player.is_on_floor(), "the survivor should be standing on the ground")
	var exit_rect: Rect2 = level.get("_exit_rect")
	player.position = exit_rect.get_center() + Vector2(0, exit_rect.size.y / 2.0)
	var left := await _wait_for_scene("Map")
	_expect(left, "reaching the exit should return to the map")


func _check_game_over() -> void:
	_new_trip(10)
	for survivor: Survivor in _trip.party:
		survivor.hurt(Survivor.MAX_HEALTH)
	_expect(_trip.is_game_over(), "everyone down with no medkits is game over")
	_trip.go("map")
	var ended := await _wait_for_scene("End")
	_expect(ended, "the map should send a wiped party to the end screen")
	_new_trip(11)
	_trip.medkits = 1
	_trip.party[0].hurt(Survivor.MAX_HEALTH)
	_expect(_trip.treat(_trip.party[0]), "a medkit should revive a downed survivor")
	_expect(not _trip.party[0].is_downed(), "revived survivor should be standing")


## The leaderboard entry must follow the Worker's rules (leaderboard-api/src/board.js).
func _check_score_entry() -> void:
	_new_trip(12)
	var lost: Dictionary = _trip.score_entry("Tester")
	_expect(lost["route"] == "maine_to_florida", "score entry should carry the route id")
	_expect(lost["finished"] == false and lost["stops"] == 0, "a fresh trip has reached no stops")
	_expect(lost["total_stops"] == 14, "Maine to Florida has 14 stops after the start")
	_expect(str(lost["apocalypse"]).split("+").size() >= 1, "apocalypse id should be set")
	_expect(lost["days"] >= 1, "days start at 1")
	_trip.stop_index = _trip.total_stops()
	_trip.miles_traveled = 1720
	_trip.days = 12.0
	_trip.won = true
	var won: Dictionary = _trip.score_entry("Tester")
	_expect(won["finished"] == true and won["stops"] == won["total_stops"], "a finished trip reached every stop")
	_expect(won["miles"] <= won["days"] * 400, "miles per day must stay believable")
	var end_script: GDScript = load("res://scripts/screens/end_screen.gd")
	_expect(end_script.clean_name("  Big  Carl!!<x> ") == "Big Carlx", "names are cleaned like the Worker does")


func _check_online_screens() -> void:
	_new_trip(13)
	await _change_to("settings")
	_expect(current_scene != null and current_scene.name == "Settings", "settings screen should load")
	var labels: Array[String] = []
	for node: Node in current_scene.find_children("*", "Button", true, false):
		labels.append((node as Button).text)
	for wanted: String in ["Fullscreen: Off", "Install app", "Update app", "Back"]:
		_expect(labels.has(wanted), "settings should have a '%s' button (has %s)" % [wanted, labels])
	current_scene.call("_on_update")
	_expect(str(current_scene.get("_message")) == "Only needed in the web version.", "Update app on PC explains it's for the web version")
	await _change_to("leaderboard")
	_expect(current_scene != null and current_scene.name == "Leaderboard", "leaderboard screen should load")
	await _change_to("end")
	_expect(current_scene != null and current_scene.name == "End", "end screen with Submit should load")
	await _change_to("title")
	var quit_buttons := current_scene.find_children("*", "Button", true, false).filter(
		func(node: Node) -> bool: return (node as Button).text == "Quit")
	_expect(quit_buttons.size() == 1, "the title screen should have a Quit button")
	var form: Node = load("res://scripts/screens/suggestion_form.gd").new()
	current_scene.add_child(form)
	await process_frame
	_expect(form.call("build_payload").is_empty(), "an empty suggestion must not be sent")
	form.get("_title_edit").text = "Add a motorcycle"
	form.get("_description").text = "A fast motorcycle that uses less fuel would be fun."
	var payload: Dictionary = form.call("build_payload")
	_expect(payload.get("category") == "gameplay", "suggestion category defaults to gameplay")
	_expect(payload.get("website") == "", "the spam trap stays empty")
	_expect(payload.get("client") is Dictionary, "device info is attached")
	form.queue_free()


func _check_routes() -> void:
	var ids: Array[String] = []
	for route: Dictionary in Routes.all():
		var stops: Array = route["stops"]
		ids.append(str(route["id"]))
		_expect(stops.size() >= 6 and stops.size() <= 20, "%s should have 6-20 stops (has %d)" % [route["id"], stops.size()])
		for index: int in range(1, stops.size()):
			var miles: int = stops[index]["miles"]
			_expect(miles >= 20 and miles <= 450, "%s: %d miles to %s is believable" % [route["id"], miles, stops[index]["city"]])
		_expect(int(stops[0]["kind"]) == Routes.Kind.START, "%s starts with a start town" % route["id"])
		_expect(int(stops[-1]["kind"]) == Routes.Kind.FINISH, "%s ends with a finish" % route["id"])
		for stop: Dictionary in stops:
			var pixel := MapPainter.to_pixel(float(stop["lon"]), float(stop["lat"]))
			_expect(pixel.x >= 0 and pixel.y >= 0 and pixel.x < MapPainter.WIDTH and pixel.y < MapPainter.HEIGHT,
				"%s is on the map" % stop["city"])
	for route_id: String in ids:
		_expect(ids.count(route_id) == 1, "route ids are unique")
		_expect(_progress.is_unlocked("route", route_id) or not Unlocks.award_for("route", route_id).is_empty(),
			"%s is free or has an award that unlocks it" % route_id)


func _check_regions() -> void:
	var expected := {"Boston": "northeast", "Chicago": "midwest", "Denver": "mountains", "Seattle": "mountains",
		"Phoenix": "desert", "El Paso": "desert", "New Orleans": "south", "Miami": "south", "Raleigh": "south",
		"Washington": "northeast", "Amarillo": "midwest"}
	var seen: Dictionary = {}
	for route: Dictionary in Routes.all():
		for stop: Dictionary in route["stops"]:
			var region := Regions.of_stop(stop)
			seen[region] = true
			if expected.has(stop["city"]):
				_expect(region == expected[stop["city"]], "%s should be in %s, not %s" % [stop["city"], expected[stop["city"]], region])
	for region: String in Regions.ALL:
		_expect(seen.has(region), "some route goes through %s" % region)
	var lengths: Dictionary = {}
	for route: Dictionary in Routes.all():
		lengths[Routes.length_name(route)] = true
	_expect(lengths.size() == 3, "there are short, medium and long routes")


func _check_unlocks_and_awards() -> void:
	_expect(_progress.is_unlocked("route", "maine_to_florida"), "Maine to Florida is open from the start")
	_expect(_progress.is_unlocked("route", "new_york_to_washington"), "the starter route is open from the start")
	_expect(not _progress.is_unlocked("route", "seattle_to_boston"), "Seattle to Boston starts locked")
	_expect(not _progress.is_unlocked("route", "maine_to_california"), "other routes start locked")
	_expect(not _progress.is_unlocked("role", "cook"), "the Cook starts locked")
	for award: Dictionary in Unlocks.AWARDS:
		_expect(Unlocks.describe_unlock(award["unlock"]) != "", "%s unlocks something real" % award["id"])
	# A perfect finish earns the end-of-trip awards and unlocks things.
	_trip.new_trip(Routes.first_playable(), 21, Survivor.BASE_ROLES, "none", "classic_red")
	_trip.won = true
	_trip.stop_index = _trip.total_stops()
	_trip.days = 10.0
	_trip.record_end()
	_trip.record_end()
	_expect(_progress.stat("finished") == 1, "a trip end is counted once")
	for award_id: String in ["finish_any", "finish_maine_to_florida", "full_house", "on_foot", "speed_demon"]:
		if award_id == "finish_maine_to_florida":
			continue
		_expect(_progress.has_award(award_id), "a perfect finish earns %s" % award_id)
	_expect(_progress.is_unlocked("route", "maine_to_california"), "finishing unlocks Maine to California")
	_expect(_progress.is_unlocked("route", "chicago_to_new_orleans"), "finishing the starter route unlocks Chicago to New Orleans")
	_expect(_progress.is_unlocked("role", "cook"), "Full House unlocks the Cook")
	# Progress survives a reload from disk.
	_progress.load_progress()
	_expect(_progress.has_award("finish_any"), "awards are saved")
	for count: int in 5:
		_progress.add_stat("stashes")
	_expect(_progress.has_award("stash_1") and _progress.has_award("stash_5"), "stashes earn their awards")
	# Perks and the Cook change the trip.
	var cook_party: Array[Survivor.Role] = [Survivor.Role.SCOUT, Survivor.Role.GUNNER, Survivor.Role.MEDIC, Survivor.Role.COOK]
	_trip.new_trip(Routes.first_playable(), 22, cook_party, "pocket_money", "racing_yellow")
	_expect(_trip.money == _trip.STARTING_MONEY + 150, "Pocket Money adds $150")
	_expect(_trip.car_color == Unlocks.car_color("racing_yellow"), "the chosen car color is used")
	_expect(_trip.score_entry("T")["perk"] == "pocket_money", "the perk goes on the leaderboard entry")
	_trip.food = 100
	_trip.pass_time(1.0)
	_expect(_trip.food == 100 - ceili(8 * _trip.COOK_FOOD_SHARE), "the Cook makes food last (left %d)" % _trip.food)
	_trip.new_trip(Routes.first_playable(), 23, Survivor.BASE_ROLES, "beater")
	_expect(_trip.has_vehicle and _trip.vehicle_health == 45, "Old Beater starts with a car")


## Every road event is well formed, and every outcome can be applied.
func _check_road_events() -> void:
	# RoadEvents uses the Trip autoload, so it's loaded by path (see _check_scavenge_exit).
	var road_events: GDScript = load("res://scripts/trip/road_events.gd")
	var known := ["food", "fuel", "ammo", "medkits", "scrap", "money", "hurt", "hurt_all", "heal_all", "car", "days", "award"]
	var events: Array = road_events.get("EVENTS")
	var rare_events: Array = road_events.get("RARE_EVENTS")
	var region_events: Dictionary = road_events.get("REGION_EVENTS")
	var all_events: Array = events + rare_events
	for region: String in Regions.ALL:
		_expect(Array(region_events.get(region, [])).size() >= 3, "%s has its own road events" % region)
		all_events += region_events.get(region, [])
	_expect(events.size() >= 12, "there should be plenty of road events")
	for event: Dictionary in all_events:
		var choices: Array = event["choices"]
		_expect(choices.size() >= 2 and choices.size() <= 4, "%s has 2-4 choices" % event["id"])
		var has_free_choice := false
		for choice: Dictionary in choices:
			if not choice.has("role") and not choice.has("needs"):
				has_free_choice = true
			var total := 0.0
			for outcome: Dictionary in choice["outcomes"]:
				total += float(outcome["chance"])
				for key: String in outcome["effects"]:
					_expect(known.has(key), "%s uses a known effect (%s)" % [event["id"], key])
				_trip.new_trip(Routes.first_playable(), 30, Survivor.BASE_ROLES, "beater")
				road_events.call("apply_effects", outcome["effects"], _trip.rng)
			_expect(absf(total - 1.0) < 0.001, "%s choice chances add up to 1" % event["id"])
		_expect(has_free_choice, "%s always has a choice anyone can pick" % event["id"])
	for rare: Dictionary in rare_events:
		_expect(not Unlocks.award(rare["id"]).is_empty(), "rare event %s has an award" % rare["id"])
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var picked: Array = road_events.call("pick_for_stretch", rng, func(_id: String) -> bool: return false, "desert")
	_expect(picked.size() >= 2 and picked.size() <= 3, "a stretch has 2-3 choice events")


func _check_choice_event_on_road() -> void:
	_new_trip(31)
	_trip.food = 50
	await _change_to("road")
	var road := current_scene
	var first_event: Dictionary = (load("res://scripts/trip/road_events.gd") as GDScript).get("EVENTS")[0]
	road.call("open_event", first_event)
	await process_frame
	var dialog: Node = road.get("_dialog")
	_expect(dialog != null, "a choice event opens a dialog")
	if dialog == null:
		return
	var start_x: float = road.get("_x")
	for index: int in 10:
		await process_frame
	_expect(is_equal_approx(float(road.get("_x")), start_x), "the road waits while the event is open")
	var food_before: int = _trip.food
	dialog.call("choose", first_event["choices"][0])
	_expect(_trip.food == food_before - 10, "sharing food costs 10 food")
	dialog.call("close")
	await process_frame
	_expect(road.get("_dialog") == null, "Continue closes the event")


## Regression: a choice event must never open in the middle of a jump over a
## wreck (it used to, and the car then fell onto the wreck and crashed).
func _check_event_waits_for_jump() -> void:
	_new_trip(50)
	_trip.has_vehicle = true
	_trip.vehicle_health = 100
	_trip.fuel = 40.0
	await _change_to("road")
	var road := current_scene
	for walker: Node in road.get("_walkers"):
		walker.queue_free()
	(road.get("_walkers") as Array).clear()
	(road.get("_wrecks") as Array).clear()
	road.call("_add_wreck", 600.0)
	var first_event: Dictionary = (load("res://scripts/trip/road_events.gd") as GDScript).get("EVENTS")[6]
	(road.get("_choice_xs") as Array).clear()
	(road.get("_choice_xs") as Array).append(600.0)
	(road.get("_choice_events") as Array).clear()
	(road.get("_choice_events") as Array).append(first_event)
	road.set("_x", 470.0)
	road.set("_speed", 150.0)
	Input.action_press("move_right")
	var jumped := false
	var opened := false
	for index: int in 240:
		await process_frame
		if not jumped and float(road.get("_x")) >= 553.0:
			Input.action_press("jump")
			jumped = true
		if road.get("_dialog") != null:
			opened = true
			_expect(float(road.get("_y")) >= 0.0, "the event waits until the car has landed")
			_expect(float(road.get("_x")) - 600.0 >= 80.0, "the event waits until the wreck is behind you")
			_expect(float(road.get("_speed")) > 0.0, "an event doesn't stop the car dead")
			break
	Input.action_release("jump")
	Input.action_release("move_right")
	_expect(opened, "the event still happens after the jump")
	_expect(_trip.vehicle_health == 100, "a clean jump over a wreck does no damage")
	var dialog: Node = road.get("_dialog")
	if dialog != null:
		dialog.call("close")
	for index: int in 30:
		await process_frame
	_expect(_trip.vehicle_health == 100, "continuing after the event doesn't crash the car")


## Hidden stashes: some levels have them, and every ledge is within jump reach.
func _check_stashes() -> void:
	var rng := RandomNumberGenerator.new()
	var with_stash := 0
	for seed_value: int in 40:
		rng.seed = seed_value
		var layout := LevelLayout.generate(rng, 3)
		if layout.stash_spots.is_empty():
			continue
		with_stash += 1
		var ledges: Array[Rect2] = []
		for solid: Dictionary in layout.solids:
			if solid["kind"] == "secret":
				ledges.append(solid["rect"])
		_expect(ledges.size() == 3, "a stash has 3 ledges")
		for index: int in range(1, ledges.size()):
			var rise := ledges[index - 1].position.y - ledges[index].position.y
			_expect(rise > 0.0 and rise <= 45.0, "stash ledges rise at most 45 px each")
	_expect(with_stash > 5 and with_stash < 35, "about half the levels hide a stash (%d of 40)" % with_stash)


func _check_meta_screens() -> void:
	_trip.route = Routes.first_playable()
	await _change_to("prepare")
	_expect(current_scene != null and current_scene.name == "Prepare", "prepare screen should load")
	current_scene.call("start_trip")
	var to_town := await _wait_for_scene("Town")
	_expect(to_town, "Start trip goes to the store")
	_expect(_trip.party.size() == 4, "the prepared party has 4 survivors")
	await _change_to("awards")
	_expect(current_scene != null and current_scene.name == "Awards", "awards screen should load")


## Online progress: codes, merging (nothing lost), and the Settings section.
## No real network use: the code is cleared again before anything is sent.
func _check_cloud_sync() -> void:
	var cloud: Node = root.get_node("CloudSync")
	var old_code: Variant = PlayerPrefs.get_value("sync_code", "")
	var old_email: Variant = PlayerPrefs.get_value("google_email", "")
	_expect(cloud.call("normalize", "abcd efgh-jk23") == "ABCDEFGHJK23", "codes are tidied")
	_expect(cloud.call("normalize", "ABCD-EFGH-JK2O") == "", "O isn't a code letter")
	var made: String = cloud.call("new_code")
	_expect(cloud.call("normalize", made) == made, "new codes are valid")
	_expect(cloud.call("pretty", "ABCDEFGHJK23") == "ABCD-EFGH-JK23", "codes are shown in groups")
	_progress.use_test_file(TEST_PROGRESS)
	_progress.earn("first_steps")
	_progress.add_stat("crates", 3)
	var changed: bool = _progress.merge({"save_version": 1,
		"awards": {"bunker": "2026-10-01T00:00:00", "first_steps": "2026-01-01T00:00:00", "made_up": "x"},
		"stats": {"crates": 1, "enemies": 40}})
	_expect(changed, "merging new progress changes things")
	_expect(_progress.has_award("bunker") and _progress.has_award("first_steps"), "merging keeps awards from both")
	_expect(not _progress.has_award("made_up"), "unknown awards are ignored")
	_expect(_progress.stat("crates") == 3 and _progress.stat("enemies") == 40, "each total keeps the higher number")
	_expect(not _progress.merge(_progress.to_save()), "merging the same progress changes nothing")
	_expect(_progress.to_save().get("save_version") == 1, "the online copy has a save version")
	await _change_to("settings")
	var labels: Array[String] = []
	for node: Node in current_scene.find_children("*", "Button", true, false):
		labels.append((node as Button).text)
	for wanted: String in ["Create sync code", "Use code", "Sign in with Google"]:
		_expect(labels.has(wanted), "Online progress should offer '%s' (has %s)" % [wanted, labels])
	_expect(not cloud.call("use_code", "nope"), "a bad code is refused")
	PlayerPrefs.set_value("sync_code", old_code)
	PlayerPrefs.set_value("google_email", old_email)


## Weapons: each one pays with the right supply, and an empty one falls
## back to the crowbar.
func _check_weapons() -> void:
	_new_trip(60)
	_expect(_trip.weapons.size() == 2 and _trip.weapons.has("crowbar") and _trip.current_weapon() == "pistol", "trips start with a pistol (in hand) and a crowbar")
	_trip.ammo = 10
	_expect(_trip.spend("ammo", 2.0) and _trip.ammo == 8, "the shotgun's 2 ammo is paid")
	_trip.scrap = 1
	for shot: int in 4:
		_expect(_trip.spend("scrap", 0.25), "nails cost a quarter scrap each")
	_expect(_trip.scrap == 0, "4 nails used 1 scrap (left %d)" % _trip.scrap)
	_expect(not _trip.spend("scrap", 0.25), "no scrap, no nails")
	_trip.fuel = 0.1
	_expect(not _trip.spend("fuel", 0.12), "the flamethrower needs fuel")
	_expect(_trip.add_weapon("shotgun") and not _trip.add_weapon("shotgun"), "a weapon is only added once")
	_expect(_trip.current_weapon() == "pistol", "picking up a weapon doesn't change the one in hand")
	_trip.cycle_weapon(1)
	_expect(_trip.current_weapon() == "shotgun", "switching goes to the next weapon")
	_trip.new_trip(Routes.first_playable(), 61, Survivor.BASE_ROLES, "sawed_off")
	_expect(_trip.weapons.has("shotgun"), "the Sawed-Off perk starts with a shotgun")
	for weapon_id: String in Weapons.ORDER:
		_expect(Weapons.DATA.has(weapon_id), "%s has weapon data" % weapon_id)


## Every enemy kind runs in a real level without errors, and the special
## ones do their thing (shooters spit, jumpers leap).
func _check_enemy_kinds() -> void:
	_new_trip(62)
	_trip.stop_index = 1
	await _change_to("scavenge")
	var level := current_scene
	var player: Node2D = level.get("player")
	for enemy: Node in level.get("enemies"):
		enemy.queue_free()
	(level.get("enemies") as Array).clear()
	var layout: Object = level.get("_layout")
	var ground_y: float = layout.get("player_start").y
	var spawned: Dictionary = {}
	var x := 120.0
	for kind: String in ["walker", "runner", "tank", "shooter", "jumper"]:
		spawned[kind] = level.call("spawn_enemy_near", Vector2(x, ground_y - 1), kind)
		x += 30.0
	var shooter: Node2D = spawned["shooter"]
	player.position = shooter.position + Vector2(-100, 0)
	player.set("_hurt_timer", 1000.0)
	var shots: Node = level.get("shots")
	var fired := false
	for frame: int in 180:
		await physics_frame
		if int(shots.call("enemy_shot_count")) > 0:
			fired = true
	_expect(fired, "a shooter spits at a player in range")
	var tank: Node = spawned["tank"]
	var walker: Node = spawned["walker"]
	_expect(int(tank.get("max_health")) > int(walker.get("max_health")), "tanks are tougher than walkers")
	_expect(float(spawned["runner"].get("speed")) > float(walker.get("speed")), "runners are faster than walkers")
	# A jumper leaps when the player is above it.
	var jumper: Node2D = spawned["jumper"]
	if is_instance_valid(jumper):
		player.position = jumper.position + Vector2(30, -60)
		var start_y := jumper.position.y
		var lowest := start_y
		for frame: int in 40:
			await physics_frame
			if is_instance_valid(jumper):
				lowest = minf(lowest, jumper.position.y)
		_expect(lowest < start_y - 20.0, "a jumper leaps toward a player above it")
	var counted := int(_progress.stat("enemies"))
	walker.call("hit", 99, 1)
	_expect(int(_progress.stat("enemies")) == counted + 1, "defeating an enemy counts toward awards")


## Each boss: appears at the right stop, attacks, and when beaten opens the
## exit and earns its award.
func _check_bosses() -> void:
	var route := Routes.by_id("maine_to_florida")
	_trip.new_trip(route, 63)
	_trip.stop_index = 1
	_expect(not _trip.is_boss_stop(), "early stops have no boss")
	_trip.stop_index = _trip.last_scavenge_index()
	_expect(_trip.is_boss_stop(), "the last scavenging stop of a medium route has a boss")
	_trip.new_trip(Routes.by_id("new_york_to_washington"), 64)
	_trip.stop_index = _trip.last_scavenge_index()
	_expect(not _trip.is_boss_stop(), "short routes have no boss")
	for threat: int in 4:
		_trip.new_trip(route, 70 + threat)
		_trip.apocalypse.threats.clear()
		_trip.apocalypse.threats.append(threat as Apocalypse.Threat)
		_trip.stop_index = _trip.last_scavenge_index()
		_trip.ammo = 200
		await _change_to("scavenge")
		var level := current_scene
		var boss: Node = level.get("boss")
		_expect(boss != null, "a boss waits at the last stop (threat %d)" % threat)
		if boss == null:
			continue
		_expect(not bool(level.call("exit_open")), "the exit stays shut while the boss lives")
		var player: Node2D = level.get("player")
		player.position = (boss as Node2D).position + Vector2(-90, 0)
		player.set("_hurt_timer", 1000.0)
		var shots: Node = level.get("shots")
		var attacked := false
		var enemies_before: int = (level.get("enemies") as Array).size()
		for frame: int in 300:
			await physics_frame
			if int(shots.call("enemy_shot_count")) > 0 or (level.get("enemies") as Array).size() > enemies_before:
				attacked = true
				break
		_expect(attacked, "%s attacks" % boss.call("display_name"))
		# Every boss must be reachable: a jumping shot (about 9-59 px up) can hit it.
		var boss_box: Rect2 = boss.call("box")
		var floor_y: float = player.position.y
		_expect(boss_box.end.y > floor_y - 59.0, "%s can be hit by a jumping shot" % boss.call("display_name"))
		var award_id: String = boss.call("award_id")
		boss.call("hit", 999, 1)
		await process_frame
		_expect(bool(level.call("exit_open")), "beating the boss opens the exit")
		_expect(_progress.has_award(award_id), "beating the boss earns %s" % award_id)


## Builds one level with every new piece and checks each really works with
## the game's physics: ladder, elevator, slider, falling platform, indoor room
## and hazards.
func _check_level_pieces() -> void:
	var layout := LevelLayout.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	layout._ground(-64.0, 224.0, 0)
	var x := 160.0
	x = layout._ladder_chunk(rng, x, 0, 0.0)
	x = layout._elevator_chunk(rng, x, 0, 0.0)
	x = layout._slider_chunk(rng, x, 0)
	x = layout._falling_chunk(rng, x, 0)
	x = layout._room_chunk(rng, x, 0, 0.0, "brick")
	x = layout._hazard_chunk(rng, x, 0, "fire")
	x = layout._swamp_chunk(rng, x, 0)
	layout._ground(x, 224.0, 0)
	layout.exit_spot = Vector2(x + 200.0, 0)
	layout.width = x + 224.0
	layout.enemy_spots.clear()
	layout.crate_spots.clear()
	_new_trip(90)
	_trip.stop_index = 1
	_trip.test_layout = layout
	await _change_to("scavenge")
	var level := current_scene
	for enemy: Node in level.get("enemies"):
		enemy.queue_free()
	(level.get("enemies") as Array).clear()
	var player: CharacterBody2D = level.get("player")
	var movers: Array = level.get("movers")
	# Ladder: climb up the tall building and step onto its roof.
	var ladder: Rect2 = layout.ladders[0]
	var roof_y := ladder.position.y + 14.0
	await _place(player, Vector2(ladder.position.x + 4.0, 0.0))
	Input.action_press("move_up")
	var on_roof := false
	for frame: int in 200:
		await physics_frame
		if player.position.y < roof_y + 2.0:
			Input.action_press("move_right")
		if player.is_on_floor() and player.position.x > ladder.end.x + 10.0:
			on_roof = true
			break
	Input.action_release("move_up")
	Input.action_release("move_right")
	_expect(on_roof, "you can climb off the top of a ladder onto the roof")
	_expect(player.is_on_floor() and absf(player.position.y - roof_y) < 2.0, "the ladder leads up onto the roof (at y %.0f, roof %.0f)" % [player.position.y, roof_y])
	# Elevator: stand on it and ride it up.
	var elevator: Node2D = _mover_of(movers, "elevator")
	await _place(player, elevator.position + Vector2(16, -1))
	var lowest := player.position.y
	for frame: int in 160:
		await physics_frame
		lowest = minf(lowest, player.position.y)
	_expect(lowest < -60.0, "the elevator carries you up (reached %.0f)" % lowest)
	# Slider: ride it across the pit.
	var slider: Node2D = _mover_of(movers, "slider")
	await _place(player, slider.position + Vector2(16, -1))
	var start_x := player.position.x
	var furthest := 0.0
	for frame: int in 200:
		await physics_frame
		furthest = maxf(furthest, absf(player.position.x - start_x))
	_expect(furthest > 40.0 and player.position.y < 5.0, "the slider carries you across (moved %.0f)" % furthest)
	# Falling platform: drops soon after you land on it.
	var falling: Node2D = _mover_of(movers, "falling")
	await _place(player, falling.position + Vector2(16, -1))
	await _frames(60)
	_expect(bool(falling.call("is_falling")), "a falling platform drops after you land on it")
	# Indoor room: walk in one door and out the other.
	var room: Rect2 = layout.rooms[0]
	await _place(player, Vector2(room.position.x - 20.0, 0.0))
	Input.action_press("move_right")
	for frame: int in 200:
		await physics_frame
		if player.position.x > room.end.x + 8.0:
			break
	Input.action_release("move_right")
	_expect(player.position.x > room.end.x + 8.0, "you can walk through a room's doors")
	# Fire hurts; swamp water slows you down.
	var fire: Rect2 = layout.hazards[0]["rect"]
	var survivor: Survivor = _trip.active()
	var health_before := survivor.health
	await _place(player, Vector2(fire.get_center().x, 0.0))
	player.set("_hurt_timer", 0.0)
	await _frames(5)
	_expect(_trip.active() != survivor or survivor.health < health_before, "fire hurts")
	var water: Rect2 = layout.hazards[1]["rect"]
	await _place(player, Vector2(water.position.x + 4.0, 0.0))
	Input.action_press("move_right")
	await _frames(20)
	var slowed: float = player.velocity.x
	Input.action_release("move_right")
	_expect(slowed > 0.0 and slowed < _trip.active().move_speed() * 0.8, "water slows you down (%.0f)" % slowed)


func _place(player: CharacterBody2D, at: Vector2) -> void:
	player.position = at
	player.velocity = Vector2.ZERO
	player.set("_hurt_timer", 1000.0)
	await _frames(3)


func _frames(count: int) -> void:
	for frame: int in count:
		await physics_frame


func _mover_of(movers: Array, kind: String) -> Node2D:
	for mover: Node in movers:
		if str(mover.get("kind")) == kind:
			return mover as Node2D
	return null


func _finish() -> void:
	if _errors.is_empty():
		print("SMOKE TEST PASSED")
		quit(0)
		return
	for error: String in _errors:
		push_error("FAIL: " + error)
	print("SMOKE TEST FAILED (%d problems)" % _errors.size())
	quit(1)

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
	_check_stashes()
	await _check_meta_screens()
	await _check_cloud_sync()
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


## Every generated level must be jumpable: gaps and steps within jump reach.
func _check_level_layouts() -> void:
	var rng := RandomNumberGenerator.new()
	for seed_value: int in 60:
		rng.seed = seed_value
		var layout := LevelLayout.generate(rng, seed_value % 10)
		var grounds: Array[Rect2] = []
		for solid: Dictionary in layout.solids:
			if solid["kind"] == "ground":
				grounds.append(solid["rect"])
		grounds.sort_custom(func(a: Rect2, b: Rect2) -> bool: return a.position.x < b.position.x)
		for index: int in range(1, grounds.size()):
			var gap := grounds[index].position.x - grounds[index - 1].end.x
			var rise := grounds[index - 1].position.y - grounds[index].position.y
			_expect(gap <= 48.0, "level %d has a gap of %.0f px (too wide to jump)" % [seed_value, gap])
			_expect(rise <= 16.0, "level %d has a step of %.0f px (too tall)" % [seed_value, rise])
		_expect(layout.exit_spot.x > 300.0, "level %d exit should be far from the start" % seed_value)


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


func _finish() -> void:
	if _errors.is_empty():
		print("SMOKE TEST PASSED")
		quit(0)
		return
	for error: String in _errors:
		push_error("FAIL: " + error)
	print("SMOKE TEST FAILED (%d problems)" % _errors.size())
	quit(1)

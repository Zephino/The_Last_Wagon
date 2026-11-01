extends SceneTree
## Headless smoke test. Plays every screen of the core loop for real frames
## and checks the rules hold. Run:
##   godot --headless --path . -s res://scripts/tests/smoke_test.gd
## Exit code 0 = pass, 1 = fail. Also check the output for "SCRIPT ERROR".

const MAX_WAIT_FRAMES := 600

var _errors: Array[String] = []
var _trip: Node


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	_trip = root.get_node("Trip")
	_check_version()
	_check_new_trip()
	_check_level_layouts()
	_check_map_painter()
	await _check_screens_load()
	await _check_drive_to_next_stop()
	await _check_walk_and_hotwire()
	await _check_scavenge_exit()
	await _check_game_over()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_errors.append(message)


func _check_version() -> void:
	var file := FileAccess.open("res://VERSION", FileAccess.READ)
	var version := file.get_as_text().strip_edges() if file != null else ""
	var setting := str(ProjectSettings.get_setting("application/config/version", ""))
	_expect(version != "" and version == setting, "project.godot config/version (%s) must match VERSION (%s)" % [setting, version])


func _new_trip(seed_value: int) -> void:
	_trip.new_trip(Routes.first_playable(), seed_value)


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
		_expect(_trip.fuel >= 2.0, "a found car should have some fuel")


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


func _finish() -> void:
	if _errors.is_empty():
		print("SMOKE TEST PASSED")
		quit(0)
		return
	for error: String in _errors:
		push_error("FAIL: " + error)
	print("SMOKE TEST FAILED (%d problems)" % _errors.size())
	quit(1)

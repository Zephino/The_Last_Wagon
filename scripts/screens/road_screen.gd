extends Node2D
## Travel between two stops, seen from the side.
## Driving: the car drives itself until danger is close, then you take the
## wheel (speed up, brake, jump wrecks, run over enemies).
## Walking: you have no car (or it died). Walk on, shoot enemies, and
## hotwire any abandoned car you find. Time passes much faster on foot.
## Along the way, choice events (RoadEvents) stop the trip and ask what to do.

enum Mode { DRIVING, WALKING, HOTWIRE, DONE }

const CRUISE_SPEED := 110.0
const BOOST_SPEED := 150.0
const BRAKE_SPEED := 40.0
const ACCELERATION := 140.0
const WALK_SPEED := 40.0
const WALK_HURRY_SPEED := 60.0
const JUMP_SPEED := 230.0
const GRAVITY := 700.0
const DANGER_RANGE := 160.0
const PIXELS_PER_MILE := 6.0
const MIN_LENGTH := 700.0
const MAX_LENGTH := 1800.0
const DRIVE_MILES_PER_DAY := 180.0
const WALK_MILES_PER_DAY := 30.0
const WRECK_DAMAGE := 25
const WRECK_PARTY_DAMAGE := 5
const SPLAT_DAMAGE := 3
const CAR_HALF_WIDTH := 16.0
const SHOT_SPEED := 260.0
const SHOT_RANGE := 220.0
const MELEE_RANGE := 18.0
const MELEE_COOLDOWN := 0.45
const HURT_COOLDOWN := 0.8
const ABANDONED_CAR_CHANCE := 0.5
const BANNER_TIME := 3.5

var _mode := Mode.WALKING
var _length := 0.0
var _px_per_mile := 1.0
var _x := 0.0
var _y := 0.0
var _vy := 0.0
var _speed := 0.0
var _danger := false
var _miles_driven := 0.0
var _miles_walked := 0.0
var _next_event_x := 0.0
var _fire_timer := 0.0
var _hurt_timer := 0.0
var _hotwire_timer := 0.0
var _end_timer := -1.0
var _end_screen := "map"
var _banner_time := 0.0
var _camera: Camera2D
var _actor: Sprite2D
var _abandoned_car: Sprite2D
var _wrecks: Array[Dictionary] = []
var _walkers: Array[RoadWalker] = []
var _shots: Array[Dictionary] = []
var _hud_route: Label
var _hud_progress: ProgressBar
var _hud_status: Label
var _hud_party: Label
var _hud_banner: Label
var _hud_prompt: Label
var _choice_events: Array[Dictionary] = []
var _choice_xs: Array[float] = []
var _dialog: EventDialog


func _ready() -> void:
	var next := Trip.next_stop()
	if next.is_empty():
		set_process(false)
		Trip.go("map")
		return
	var miles := float(next["miles"])
	_length = clampf(miles * PIXELS_PER_MILE, MIN_LENGTH, MAX_LENGTH)
	_px_per_mile = _length / miles
	Trip.ensure_active_standing()
	_build_world()
	_place_hazards()
	_place_abandoned_car()
	_actor = Sprite2D.new()
	add_child(_actor)
	_build_hud()
	_set_mode(Mode.DRIVING if Trip.has_vehicle else Mode.WALKING)
	_next_event_x = Trip.rng.randf_range(150, 300)
	_plan_choice_events()


func _process(delta: float) -> void:
	delta = minf(delta, 0.05)
	if _dialog != null:
		_refresh_hud()
		return
	_fire_timer -= delta
	_hurt_timer -= delta
	_banner_time -= delta
	match _mode:
		Mode.DRIVING:
			_drive(delta)
		Mode.WALKING:
			_walk(delta)
		Mode.HOTWIRE:
			_hotwire(delta)
		Mode.DONE:
			_count_down_to_exit(delta)
	if _mode != Mode.DONE:
		_update_walkers(delta)
		_update_shots(delta)
		_maybe_road_event()
		_maybe_choice_event()
		if _x >= _length:
			_arrive()
	_actor.position = Vector2(_x, _y)
	_camera.position = Vector2(_x + 70.0, -50.0)
	_refresh_hud()


# --- Building the stretch -------------------------------------------------

func _build_world() -> void:
	var apocalypse := Trip.apocalypse
	Backdrop.add_sky(self, apocalypse)
	_camera = Backdrop.add_camera(self, Vector2(70, -50))
	var rng := RandomNumberGenerator.new()
	rng.seed = Trip.stop_index * 31 + 5
	Backdrop.add_skyline(self, -300, _length * 0.35 + 500, 0, apocalypse.sky_color().darkened(0.25), rng, 0.65)
	Backdrop.add_skyline(self, -300, _length * 0.7 + 500, 0, apocalypse.sky_color().darkened(0.5), rng, 0.3)
	var ground := apocalypse.ground_color()
	add_child(PixelArt.ground_block(Color("3a3a3a"), ground, Vector2(-300, 0), Vector2(_length + 800, 90)))
	var dash := PixelArt.solid(Color("c8b860"))
	var dash_x := -300.0
	while dash_x < _length + 500:
		add_child(PixelArt.tiled(dash, Vector2(dash_x, 7), Vector2(10, 1)))
		dash_x += 32.0
	add_child(PixelArt.standing(PixelArt.exit_sign(), Vector2(_length + 30, 0)))


func _place_hazards() -> void:
	var rng := Trip.rng
	var x := 260.0
	while x < _length - 160.0:
		if rng.randf() < 0.45:
			_add_wreck(x)
		else:
			var count := rng.randi_range(2, 4) + int(Trip.stop_index / 3.0)
			for index: int in count:
				_add_walker(x + index * 14.0)
		x += rng.randf_range(220, 380)


func _add_wreck(at_x: float) -> void:
	var sprite := PixelArt.standing(PixelArt.car(Color("6a4a32")), Vector2(at_x, 0))
	sprite.flip_v = true
	sprite.modulate = Color(0.8, 0.75, 0.7)
	add_child(sprite)
	_wrecks.append({"node": sprite, "x": at_x, "done": false})


func _add_walker(at_x: float) -> void:
	var walker := RoadWalker.new()
	walker.setup(Apocalypse.enemy_stats(Trip.apocalypse.pick_threat(Trip.rng)), at_x)
	add_child(walker)
	_walkers.append(walker)


## On foot there may be an abandoned car somewhere ahead. Always on the first leg.
func _place_abandoned_car() -> void:
	if Trip.has_vehicle:
		return
	var chance := 1.0 if Trip.stop_index == 0 else ABANDONED_CAR_CHANCE
	if Trip.rng.randf() > chance:
		return
	var at_x := _length * Trip.rng.randf_range(0.25, 0.55)
	var colors: Array[Color] = [Color("3a6a8a"), Color("8a7a3a"), Color("5a8a4a"), Color("7a3a5a")]
	_abandoned_car = PixelArt.standing(PixelArt.car(colors[Trip.rng.randi_range(0, colors.size() - 1)]), Vector2(at_x, 0))
	_abandoned_car.modulate = Color(0.85, 0.85, 0.85)
	add_child(_abandoned_car)


# --- Driving ----------------------------------------------------------------

func _drive(delta: float) -> void:
	_danger = _danger_ahead()
	var target := CRUISE_SPEED
	if _danger:
		var steer := Controls.horizontal()
		if steer > 0.0:
			target = BOOST_SPEED
		elif steer < 0.0:
			target = BRAKE_SPEED
		if Input.is_action_just_pressed("jump") and _y >= 0.0:
			_vy = -JUMP_SPEED
	_speed = move_toward(_speed, target, ACCELERATION * delta)
	var dx := _speed * delta
	_x += dx
	var miles := dx / _px_per_mile
	_miles_driven += miles
	Trip.fuel = maxf(0.0, Trip.fuel - miles * Trip.fuel_per_mile())
	_vy += GRAVITY * delta
	_y += _vy * delta
	if _y >= 0.0:
		_y = 0.0
		_vy = 0.0
	_check_wrecks()
	if Trip.fuel <= 0.0:
		_ditch_car("Out of gas. You leave the car with a strongly worded note.")
	elif Trip.vehicle_health <= 0:
		_ditch_car("The engine makes a noise like a dying goose, then nothing.")


func _check_wrecks() -> void:
	for wreck: Dictionary in _wrecks:
		if wreck["done"]:
			continue
		var wreck_x: float = wreck["x"]
		if absf(wreck_x - _x) < CAR_HALF_WIDTH + 14.0 and _y > -12.0:
			wreck["done"] = true
			_speed = 0.0
			Trip.vehicle_health = maxi(0, Trip.vehicle_health - WRECK_DAMAGE)
			for survivor: Survivor in Trip.party:
				if not survivor.is_downed():
					survivor.hurt(WRECK_PARTY_DAMAGE)
			(wreck["node"] as Sprite2D).modulate = Color(0.5, 0.45, 0.4)
			_banner("CRASH! Seatbelts are a myth now. Car -%d%%" % WRECK_DAMAGE)
		elif wreck_x < _x - 30.0:
			wreck["done"] = true


func _ditch_car(reason: String) -> void:
	Trip.lose_vehicle(reason)
	var dead_car := PixelArt.standing(PixelArt.car(Color("4a4a4a")), Vector2(_x, 0))
	add_child(dead_car)
	move_child(dead_car, _actor.get_index())
	_y = 0.0
	_vy = 0.0
	_speed = 0.0
	_set_mode(Mode.WALKING)
	_banner(reason)


# --- Walking ----------------------------------------------------------------

func _walk(delta: float) -> void:
	_danger = _danger_ahead()
	var steer := Controls.horizontal()
	var target := WALK_SPEED
	if steer > 0.0:
		target = WALK_HURRY_SPEED
	elif steer < 0.0:
		target = 0.0
	if _walker_blocking():
		target = 0.0
	var dx := target * delta
	_x += dx
	_miles_walked += dx / _px_per_mile
	_handle_on_foot_actions()
	if _abandoned_car != null and _x >= _abandoned_car.position.x - 20.0:
		_mode = Mode.HOTWIRE
		_banner("An abandoned car! Press E to hotwire it.")


func _hotwire(delta: float) -> void:
	_danger = _danger_ahead()
	_handle_on_foot_actions()
	if _hotwire_timer > 0.0:
		_hotwire_timer -= delta
		if _hotwire_timer <= 0.0:
			_take_car()
	elif Input.is_action_just_pressed("interact"):
		_hotwire_timer = 0.5 if Trip.has_standing_role(Survivor.Role.MECHANIC) else 1.5
		_banner("Hotwiring... (the Mechanic does this fastest)")


func _handle_on_foot_actions() -> void:
	if Input.is_action_just_pressed("switch_survivor") and Trip.switch_to_next_standing():
		_update_actor_texture()
	if Input.is_action_pressed("fire") and _fire_timer <= 0.0:
		_fire()


func _take_car() -> void:
	Trip.find_vehicle(Trip.rng.randi_range(45, 85), Trip.rng.randi_range(2, 6))
	_abandoned_car.queue_free()
	_abandoned_car = null
	_speed = 0.0
	_set_mode(Mode.DRIVING)
	_banner("It starts! Everybody in.")


func _fire() -> void:
	var shooter := Trip.active()
	if Trip.ammo > 0:
		Trip.ammo -= 1
		var shot := Sprite2D.new()
		shot.texture = PixelArt.bullet()
		shot.position = Vector2(_x + 6.0, -9.0)
		add_child(shot)
		_shots.append({"node": shot, "start": _x})
		_fire_timer = shooter.fire_cooldown()
		return
	_fire_timer = MELEE_COOLDOWN
	for walker: RoadWalker in _walkers:
		var gap := walker.position.x - _x
		if walker.is_alive() and gap >= -4.0 and gap < MELEE_RANGE:
			_damage_walker(walker, shooter.shot_damage())
			return


# --- Enemies and shots ------------------------------------------------------

func _update_walkers(delta: float) -> void:
	for walker: RoadWalker in _walkers.duplicate():
		if not is_instance_valid(walker) or not walker.is_alive():
			continue
		var gap := walker.position.x - _x
		if gap < 260.0 and gap > -40.0:
			walker.position.x -= walker.speed * delta * 0.6
		if gap < -200.0:
			_remove_walker(walker)
			continue
		if _mode == Mode.DRIVING:
			if absf(gap) < CAR_HALF_WIDTH + 3.0 and _y > -10.0:
				Trip.vehicle_health = maxi(0, Trip.vehicle_health - SPLAT_DAMAGE)
				Progress.add_stat("enemies")
				_remove_walker(walker)
				_banner("Splat. Car -%d%%" % SPLAT_DAMAGE)
		elif gap > -6.0 and gap < 10.0 and _hurt_timer <= 0.0:
			_hurt_active(walker.damage)


func _walker_blocking() -> bool:
	for walker: RoadWalker in _walkers:
		var gap := walker.position.x - _x
		if walker.is_alive() and gap >= -2.0 and gap < 12.0:
			return true
	return false


func _danger_ahead() -> bool:
	for wreck: Dictionary in _wrecks:
		var gap: float = float(wreck["x"]) - _x
		if not wreck["done"] and gap > 0.0 and gap < DANGER_RANGE and _mode == Mode.DRIVING:
			return true
	for walker: RoadWalker in _walkers:
		var gap := walker.position.x - _x
		if walker.is_alive() and gap > -10.0 and gap < DANGER_RANGE:
			return true
	return false


func _update_shots(delta: float) -> void:
	for shot: Dictionary in _shots.duplicate():
		var node: Sprite2D = shot["node"]
		node.position.x += SHOT_SPEED * delta
		var hit_walker: RoadWalker = null
		for walker: RoadWalker in _walkers:
			if walker.is_alive() and absf(walker.position.x - node.position.x) < 5.0:
				hit_walker = walker
				break
		if hit_walker != null:
			_damage_walker(hit_walker, Trip.active().shot_damage())
		if hit_walker != null or node.position.x - float(shot["start"]) > SHOT_RANGE:
			_shots.erase(shot)
			node.queue_free()


func _damage_walker(walker: RoadWalker, amount: int) -> void:
	if walker.hit(amount):
		Progress.add_stat("enemies")
		_remove_walker(walker)


func _remove_walker(walker: RoadWalker) -> void:
	_walkers.erase(walker)
	walker.queue_free()


func _hurt_active(amount: int) -> void:
	_hurt_timer = HURT_COOLDOWN
	var survivor := Trip.active()
	survivor.hurt(amount)
	_actor.modulate = Color(1, 0.4, 0.4)
	create_tween().tween_property(_actor, "modulate", Color.WHITE, 0.3)
	if not survivor.is_downed():
		return
	if Trip.switch_to_next_standing():
		_update_actor_texture()
		_banner("%s is down! %s takes over." % [survivor.name, Trip.active().name])
	else:
		Trip.log_message("Everyone went down on the road. Your party crawled back to %s." % Trip.current_stop()["city"])
		_banner("Everyone is down...")
		_finish_leg(false)


# --- Events, arrival and mode changes ----------------------------------------

func _maybe_road_event() -> void:
	if _danger or _x < _next_event_x:
		return
	_next_event_x = _x + Trip.rng.randf_range(250, 450)
	var event := Flavor.random_road_event(Trip.rng)
	var text: String = event["text"]
	var supply: String = event["supply"]
	if supply != "":
		var amount: int = event["amount"]
		Trip.add_supply(supply, amount)
		text += "  (%+d %s)" % [amount, supply]
	Trip.log_message(text)
	_banner(text)


## Spreads this stretch's choice events evenly along the road.
func _plan_choice_events() -> void:
	_choice_events = RoadEvents.pick_for_stretch(Trip.rng, Progress.has_award)
	var count := _choice_events.size()
	for index: int in count:
		var spot := _length * float(index + 1) / float(count + 1)
		_choice_xs.append(spot + Trip.rng.randf_range(-40.0, 40.0))


## Opens the next choice event once you reach it, when no danger is near.
func _maybe_choice_event() -> void:
	if _choice_xs.is_empty() or _danger or _x < _choice_xs[0] or _mode == Mode.DONE:
		return
	_choice_xs.pop_front()
	open_event(_choice_events.pop_front())


## Shows a choice event and waits (also used by tests).
func open_event(event: Dictionary) -> void:
	_speed = 0.0
	_dialog = EventDialog.new()
	_dialog.event = event
	_dialog.closed.connect(_on_event_closed)
	add_child(_dialog)


func _on_event_closed() -> void:
	_dialog = null
	if not Trip.anyone_standing():
		Trip.log_message("Everyone went down on the road. Your party crawled back to %s." % Trip.current_stop()["city"])
		_banner("Everyone is down...")
		_finish_leg(false)
		return
	Trip.ensure_active_standing()
	_update_actor_texture()


func _arrive() -> void:
	_finish_leg(true)
	Trip.arrive_at_next_stop()
	_banner("You made it to %s." % Trip.current_stop()["city"])


## Ends this stretch: time passes for the distance covered, then we leave.
func _finish_leg(arrived: bool) -> void:
	_mode = Mode.DONE
	Trip.pass_time(_miles_driven / DRIVE_MILES_PER_DAY + _miles_walked / WALK_MILES_PER_DAY)
	_end_screen = "end" if not arrived and Trip.is_game_over() else "map"
	_end_timer = 1.8 if arrived else 2.5


func _count_down_to_exit(delta: float) -> void:
	_end_timer -= delta
	if _end_timer <= 0.0 and _end_timer > -1.0:
		_end_timer = -2.0
		Trip.go(_end_screen)


func _set_mode(mode: Mode) -> void:
	_mode = mode
	_update_actor_texture()


func _update_actor_texture() -> void:
	var texture: Texture2D = PixelArt.car(Trip.car_color) if _mode == Mode.DRIVING else Trip.active().sprite()
	_actor.texture = texture
	_actor.offset = Vector2(0, -texture.get_height() / 2.0)


func _banner(text: String) -> void:
	_hud_banner.text = text
	_banner_time = BANNER_TIME


# --- HUD -----------------------------------------------------------------------

func _build_hud() -> void:
	var root := UiKit.make_layer(self)
	var top := UiKit.panel(Vector2(400, 0))
	UiKit.pin(top, root, Vector2(0, 0), Vector2(8, 8))
	var column := UiKit.vbox(2)
	top.add_child(column)
	_hud_route = UiKit.label("", 12, UiKit.ACCENT)
	column.add_child(_hud_route)
	_hud_progress = UiKit.bar(0, 1, UiKit.ACCENT, Vector2(380, 6))
	column.add_child(_hud_progress)
	_hud_status = UiKit.label("", 10)
	column.add_child(_hud_status)
	var party_panel := UiKit.panel()
	UiKit.pin(party_panel, root, Vector2(1, 0), Vector2(-170, 8))
	_hud_party = UiKit.label("", 9)
	party_panel.add_child(_hud_party)
	_hud_banner = UiKit.wrapped("", 12, UiKit.TEXT, 460)
	_hud_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.pin(_hud_banner, root, Vector2(0.5, 0), Vector2(-230, 92))
	_hud_prompt = UiKit.label("", 11, UiKit.DIM)
	_hud_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.pin(_hud_prompt, root, Vector2(0.5, 1), Vector2(-260, -24), Vector2(520, 0))


func _refresh_hud() -> void:
	var next := Trip.next_stop()
	var destination: String = Trip.stop_label(next) if not next.is_empty() else Trip.stop_label(Trip.current_stop())
	var miles_left := maxf(0.0, (_length - _x) / _px_per_mile)
	_hud_route.text = "%s  ->  %s    %d mi left" % [Trip.current_stop()["city"], destination, ceili(miles_left)]
	_hud_progress.value = clampf(_x / _length, 0.0, 1.0)
	_hud_status.text = "Day %d    %s    %s" % [int(Trip.days) + 1, UiKit.vehicle_text(), UiKit.supplies_text()]
	var lines: Array[String] = []
	for index: int in Trip.party.size():
		var survivor := Trip.party[index]
		var marker := ">" if index == Trip.active_index else " "
		var status := "DOWN" if survivor.is_downed() else str(survivor.health)
		lines.append("%s %s  %s" % [marker, survivor.name, status])
	_hud_party.text = "\n".join(lines)
	_hud_banner.visible = _banner_time > 0.0
	_hud_prompt.text = _prompt_text()
	_hud_prompt.add_theme_color_override("font_color", UiKit.DANGER if _danger else UiKit.DIM)


func _prompt_text() -> String:
	match _mode:
		Mode.DRIVING:
			if _danger:
				return "DANGER! You have the wheel:  RIGHT speed up   LEFT brake   SPACE jump"
			return "Cruising. The car drives itself until there's trouble."
		Mode.WALKING:
			return "On foot.  RIGHT hurry   LEFT stop   F shoot   TAB switch survivor"
		Mode.HOTWIRE:
			return "E hotwire the car   F shoot   TAB switch survivor"
	return ""

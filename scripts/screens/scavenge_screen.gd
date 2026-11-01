class_name ScavengeScreen
extends Node2D
## A side-scrolling scavenging level: run, jump and shoot through a ruined
## city, open crates for supplies and reach the EXIT sign. Downed survivors
## hand over to the next one; if everyone goes down, you retreat.

const KILL_Y := 260.0
const BULLET_SPEED := 280.0
const BULLET_RANGE := 240.0
const MELEE_RANGE := 18.0
const SCOUT_LOOT_BONUS := 1.3
const END_DELAY := 2.5
const TIME_SPENT_DAYS := 0.5
const BANNER_TIME := 3.0

var player: ScavPlayer
var enemies: Array[ScavEnemy] = []
var _layout: LevelLayout
var _rng := RandomNumberGenerator.new()
var _crates: Array[Dictionary] = []
var _bullets: Array[Dictionary] = []
var _exit_rect := Rect2()
var _loot: Dictionary = {}
var _finished := false
var _end_timer := 0.0
var _end_screen := "map"
var _banner_time := 0.0
var _hud_party: Label
var _hud_supplies: Label
var _hud_banner: Label


func _ready() -> void:
	Trip.stop_scavenged = true
	Trip.ensure_active_standing()
	if not Trip.anyone_standing():
		_finished = true
		Trip.go("map")
		return
	_rng.seed = Trip.rng.randi()
	_layout = LevelLayout.generate(_rng, Trip.stop_index)
	_build_world()
	_spawn_crates()
	_spawn_player()
	_spawn_enemies()
	_build_hud()
	_banner("Scavenging %s. Open crates, then reach the EXIT sign." % Trip.current_stop()["city"])


func _process(delta: float) -> void:
	_banner_time -= delta
	if _finished:
		_end_timer -= delta
		if _end_timer <= 0.0 and player != null:
			player = null
			Trip.go(_end_screen)
		return
	_update_bullets(delta)
	_check_crates()
	if player.box().intersects(_exit_rect):
		_end("You slip out of %s with your loot." % Trip.current_stop()["city"])
	elif Input.is_action_just_pressed("back"):
		_end("You leave early. Discretion, valor, something like that.")
	_refresh_hud()


func is_finished() -> bool:
	return _finished


# --- Building the level ---------------------------------------------------

func _build_world() -> void:
	var apocalypse := Trip.apocalypse
	Backdrop.add_sky(self, apocalypse)
	Backdrop.add_skyline(self, -300, _layout.width * 0.4 + 500, 40, apocalypse.sky_color().darkened(0.3), _rng, 0.6)
	var solid_body := StaticBody2D.new()
	solid_body.collision_layer = 1
	add_child(solid_body)
	var ground := apocalypse.ground_color()
	for solid: Dictionary in _layout.solids:
		var rect: Rect2 = solid["rect"]
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.get_center()
		solid_body.add_child(shape)
		add_child(_solid_visual(str(solid["kind"]), ground, rect))
	add_child(PixelArt.standing(PixelArt.exit_sign(), _layout.exit_spot))
	_exit_rect = Rect2(_layout.exit_spot - Vector2(8, 24), Vector2(16, 24))


func _solid_visual(kind: String, ground: Color, rect: Rect2) -> Node2D:
	match kind:
		"platform":
			return PixelArt.tiled(PixelArt.plank_tile(Color("7a5a3a")), rect.position, rect.size)
		"building":
			return PixelArt.tiled(PixelArt.brick_tile(Color("5a3a32")), rect.position, rect.size)
	return PixelArt.ground_block(ground.lightened(0.25), ground, rect.position, rect.size)


func _spawn_crates() -> void:
	for spot: Vector2 in _layout.crate_spots:
		var sprite := PixelArt.standing(PixelArt.crate(), spot)
		add_child(sprite)
		_crates.append({"rect": Rect2(spot - Vector2(5, 10), Vector2(10, 10)), "node": sprite})


func _spawn_player() -> void:
	player = ScavPlayer.new()
	player.setup(self, _layout.player_start)
	add_child(player)
	var camera := Backdrop.add_camera(player, Vector2(0, -45))
	camera.limit_left = -64
	camera.limit_right = int(_layout.width)
	camera.limit_bottom = 60
	camera.position_smoothing_enabled = true


func _spawn_enemies() -> void:
	for spot: Vector2 in _layout.enemy_spots:
		var enemy := ScavEnemy.new()
		enemy.setup(self, Apocalypse.enemy_stats(Trip.apocalypse.pick_threat(_rng)), spot - Vector2(0, 1))
		add_child(enemy)
		enemies.append(enemy)


# --- Combat ---------------------------------------------------------------

func spawn_bullet(from: Vector2, direction: int, damage: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = PixelArt.bullet()
	sprite.position = from
	add_child(sprite)
	_bullets.append({"node": sprite, "direction": direction, "damage": damage, "start": from.x})


func _update_bullets(delta: float) -> void:
	var space := get_world_2d().direct_space_state
	for bullet: Dictionary in _bullets.duplicate():
		var node: Sprite2D = bullet["node"]
		var direction: int = bullet["direction"]
		var to := node.position + Vector2(direction * BULLET_SPEED * delta, 0)
		var query := PhysicsRayQueryParameters2D.create(node.position, to, 1 | 4)
		var hit := space.intersect_ray(query)
		var spent := absf(to.x - float(bullet["start"])) > BULLET_RANGE
		if not hit.is_empty():
			var enemy := hit["collider"] as ScavEnemy
			if enemy != null:
				enemy.hit(int(bullet["damage"]), direction)
			spent = true
		if spent:
			_bullets.erase(bullet)
			node.queue_free()
		else:
			node.position = to


func melee(from: Vector2, facing: int, damage: int) -> void:
	for enemy: ScavEnemy in enemies:
		var offset := enemy.position - from
		if offset.x * facing >= -4.0 and absf(offset.x) < MELEE_RANGE and absf(offset.y) < 16.0:
			enemy.hit(damage, facing)
			return


func on_enemy_killed(enemy: ScavEnemy) -> void:
	if not enemies.has(enemy):
		return
	enemies.erase(enemy)
	enemy.queue_free()


func on_survivor_downed(survivor: Survivor) -> void:
	if Trip.switch_to_next_standing():
		player.refresh_look()
		_banner("%s is down! %s takes over." % [survivor.name, Trip.active().name])
	else:
		_end("Everyone is down. You drag yourselves back to the road, minus some dignity.")


# --- Loot and leaving ---------------------------------------------------

func _check_crates() -> void:
	var player_box := player.box()
	for crate: Dictionary in _crates.duplicate():
		if player_box.intersects(crate["rect"]):
			_crates.erase(crate)
			(crate["node"] as Sprite2D).queue_free()
			_open_crate()


func _open_crate() -> void:
	var roll := _rng.randf()
	var supply := "medkits"
	var amount := 1
	if roll < 0.30:
		supply = "food"
		amount = _rng.randi_range(10, 25)
	elif roll < 0.55:
		supply = "ammo"
		amount = _rng.randi_range(6, 15)
	elif roll < 0.70:
		supply = "fuel"
		amount = _rng.randi_range(1, 4)
	elif roll < 0.85:
		supply = "scrap"
		amount = _rng.randi_range(2, 6)
	elif roll < 0.95:
		supply = "money"
		amount = _rng.randi_range(15, 60)
	if Trip.has_standing_role(Survivor.Role.SCOUT):
		amount = ceili(amount * SCOUT_LOOT_BONUS)
	Trip.add_supply(supply, amount)
	_loot[supply] = int(_loot.get(supply, 0)) + amount
	_banner("Crate: +%d %s" % [amount, supply])


func _end(text: String) -> void:
	if _finished:
		return
	_finished = true
	Trip.pass_time(TIME_SPENT_DAYS)
	var summary := _loot_summary()
	Trip.log_message("%s %s" % [text, summary])
	_banner("%s\n%s" % [text, summary])
	_end_screen = "end" if Trip.is_game_over() else "map"
	_end_timer = END_DELAY


func _loot_summary() -> String:
	if _loot.is_empty():
		return "You found nothing."
	var parts: Array[String] = []
	for supply: String in _loot:
		parts.append("+%d %s" % [_loot[supply], supply])
	return "Found: " + ", ".join(parts)


# --- HUD -------------------------------------------------------------------

func _build_hud() -> void:
	var root := UiKit.make_layer(self)
	var party_panel := UiKit.panel()
	UiKit.pin(party_panel, root, Vector2(0, 0), Vector2(8, 8))
	_hud_party = UiKit.label("", 9)
	party_panel.add_child(_hud_party)
	_hud_supplies = UiKit.label("", 10)
	UiKit.pin(_hud_supplies, root, Vector2(1, 0), Vector2(-330, 10), Vector2(320, 0))
	_hud_supplies.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hud_banner = UiKit.wrapped("", 12, UiKit.TEXT, 460)
	_hud_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.pin(_hud_banner, root, Vector2(0.5, 0), Vector2(-230, 70))
	var hint := UiKit.label("A/D move   SPACE jump   F shoot   TAB switch survivor   ESC leave", 10, UiKit.DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.pin(hint, root, Vector2(0.5, 1), Vector2(-260, -22), Vector2(520, 0))


func _refresh_hud() -> void:
	var lines: Array[String] = []
	for index: int in Trip.party.size():
		var survivor := Trip.party[index]
		var marker := ">" if index == Trip.active_index else " "
		var status := "DOWN" if survivor.is_downed() else str(survivor.health)
		lines.append("%s %s (%s)  %s" % [marker, survivor.name, survivor.role_name(), status])
	_hud_party.text = "\n".join(lines)
	_hud_supplies.text = UiKit.supplies_text()
	_hud_banner.visible = _banner_time > 0.0


func _banner(text: String) -> void:
	_hud_banner.text = text
	_banner_time = BANNER_TIME

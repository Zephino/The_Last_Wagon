class_name ScavengeScreen
extends Node2D
## A side-scrolling scavenging level: run, jump and shoot through a ruined
## city, open crates for supplies and reach the EXIT sign. Downed survivors
## hand over to the next one; if everyone goes down, you retreat.

const KILL_Y := 260.0
## Chance that a normal crate holds a weapon you don't have yet.
const WEAPON_CRATE_CHANCE := 0.1
const SCOUT_LOOT_BONUS := 1.3
const END_DELAY := 2.5
const TIME_SPENT_DAYS := 0.5
const BANNER_TIME := 3.0

var player: ScavPlayer
var enemies: Array[ScavEnemy] = []
var shots: Shots
var boss: ScavBoss
var hazards: Hazards
var movers: Array[Mover] = []
var _layout: LevelLayout
var _region := Regions.MIDWEST
var _rng := RandomNumberGenerator.new()
var _crates: Array[Dictionary] = []
var _exit_sign: Sprite2D
var _difficulty := 0
var _exit_rect := Rect2()
var _loot: Dictionary = {}
var _finished := false
var _end_timer := 0.0
var _end_screen := "map"
var _banner_time := 0.0
var _hud_party: Label
var _hud_supplies: Label
var _hud_banner: Label
var _hud_weapon: Label
var _boss_bar: ProgressBar
var _boss_label: Label


func _ready() -> void:
	Trip.stop_scavenged = true
	Trip.ensure_active_standing()
	if not Trip.anyone_standing():
		_finished = true
		Trip.go("map")
		return
	_rng.seed = Trip.rng.randi()
	_region = Regions.of_stop(Trip.current_stop())
	_difficulty = Trip.stop_index + int(Regions.info(_region)["level_bonus"])
	_layout = LevelLayout.generate(_rng, _difficulty, Trip.is_boss_stop(), _region)
	if Trip.test_layout != null:
		_layout = Trip.test_layout
		Trip.test_layout = null
	shots = Shots.new()
	shots.level = self
	_build_world()
	_spawn_crates()
	_spawn_player()
	add_child(shots)
	_spawn_enemies()
	_build_hud()
	if _layout.has_boss:
		_spawn_boss()
		_banner("Something big is waiting in %s. Beat it to open the EXIT." % Trip.current_stop()["city"])
	else:
		_banner("Scavenging %s. Open crates, then reach the EXIT sign." % Trip.current_stop()["city"])


func _process(delta: float) -> void:
	_banner_time -= delta
	if _finished:
		_end_timer -= delta
		if _end_timer <= 0.0 and player != null:
			player = null
			Trip.go(_end_screen)
		return
	_check_crates()
	if exit_open() and player.box().intersects(_exit_rect):
		_end("You slip out of %s with your loot." % Trip.current_stop()["city"])
	elif Input.is_action_just_pressed("back"):
		open_pause()
	_refresh_hud()


func is_finished() -> bool:
	return _finished


## The exit only opens once the boss (if any) is beaten.
func exit_open() -> bool:
	return boss == null


# --- Building the level ---------------------------------------------------

func _build_world() -> void:
	var apocalypse := Trip.apocalypse
	Backdrop.add_sky(self, apocalypse)
	var scenery := Regions.scenery_color(_region, apocalypse)
	Backdrop.add_scenery(self, _region, -300, _layout.width * 0.4 + 500, 40, scenery, _rng, 0.6)
	for room: Rect2 in _layout.rooms:
		var inside := PixelArt.tiled(PixelArt.brick_tile(Color("2a1e1c")), room.position, room.size)
		inside.modulate = Color(0.55, 0.55, 0.6)
		add_child(inside)
	var solid_body := StaticBody2D.new()
	solid_body.collision_layer = 1
	add_child(solid_body)
	var ground := Regions.ground(_region, apocalypse)
	var top := Regions.ground_top(_region, apocalypse)
	for solid: Dictionary in _layout.solids:
		var rect: Rect2 = solid["rect"]
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.get_center()
		solid_body.add_child(shape)
		add_child(_solid_visual(str(solid["kind"]), ground, top, rect))
	_build_pieces()
	_exit_sign = PixelArt.standing(PixelArt.exit_sign(), _layout.exit_spot)
	_exit_sign.visible = not _layout.has_boss
	add_child(_exit_sign)
	_exit_rect = Rect2(_layout.exit_spot - Vector2(8, 24), Vector2(16, 24))


func _solid_visual(kind: String, ground: Color, top: Color, rect: Rect2) -> Node2D:
	match kind:
		"secret":
			var ledge := PixelArt.tiled(PixelArt.plank_tile(Color("7a5a3a")), rect.position, rect.size)
			ledge.modulate = Color(1, 1, 1, 0.3)
			return ledge
		"platform":
			return PixelArt.tiled(PixelArt.plank_tile(Color("7a5a3a")), rect.position, rect.size)
		"building":
			return PixelArt.tiled(PixelArt.brick_tile(Color("5a3a32")), rect.position, rect.size)
		"barn":
			return PixelArt.tiled(PixelArt.plank_tile(Color("8a2e24")), rect.position, rect.size)
		"hay":
			return PixelArt.tiled(PixelArt.plank_tile(Color("c8a850")), rect.position, rect.size)
	return PixelArt.ground_block(top, ground, rect.position, rect.size)


## Ladders, rails, hazards and moving platforms.
func _build_pieces() -> void:
	for ladder: Rect2 in _layout.ladders:
		var rails := Node2D.new()
		add_child(rails)
		var wood := PixelArt.solid(Color("8a6a3a"))
		rails.add_child(PixelArt.tiled(wood, ladder.position, Vector2(2, ladder.size.y)))
		rails.add_child(PixelArt.tiled(wood, ladder.position + Vector2(ladder.size.x - 2, 0), Vector2(2, ladder.size.y)))
		var y := ladder.position.y + 2.0
		while y < ladder.end.y:
			rails.add_child(PixelArt.tiled(wood, Vector2(ladder.position.x, y), Vector2(ladder.size.x, 1)))
			y += 5.0
	for piece: Dictionary in _layout.decor:
		var rect: Rect2 = piece["rect"]
		add_child(PixelArt.tiled(PixelArt.solid(Color("8a8a90")), rect.position, rect.size))
	hazards = Hazards.new()
	add_child(hazards)
	hazards.setup(self, _layout.hazards)
	for data: Dictionary in _layout.movers:
		var mover := Mover.new()
		mover.setup(self, data)
		add_child(mover)
		movers.append(mover)


## True when the box touches a ladder (the player can climb).
func ladder_at(box: Rect2) -> bool:
	for ladder: Rect2 in _layout.ladders:
		if ladder.intersects(box):
			return true
	return false


func _spawn_crates() -> void:
	for spot: Vector2 in _layout.crate_spots:
		var sprite := PixelArt.standing(PixelArt.crate(), spot)
		add_child(sprite)
		_crates.append({"rect": Rect2(spot - Vector2(5, 10), Vector2(10, 10)), "node": sprite, "stash": false})
	for spot: Vector2 in _layout.stash_spots:
		var golden := PixelArt.standing(PixelArt.golden_crate(), spot)
		add_child(golden)
		_crates.append({"rect": Rect2(spot - Vector2(5, 10), Vector2(10, 10)), "node": golden, "stash": true})


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
		var kind := pick_enemy_kind(_rng, _difficulty)
		spawn_enemy_near(spot - Vector2(0, 1), kind)
		if kind == "runner":
			spawn_enemy_near(spot + Vector2(14, -1), "runner")


## Which kind of enemy to place: tougher kinds show up as the trip goes on.
static func pick_enemy_kind(rng: RandomNumberGenerator, difficulty: int) -> String:
	var weights := {"walker": 5.0, "runner": 2.0 if difficulty >= 1 else 0.0, "shooter": 1.6 if difficulty >= 2 else 0.0,
		"jumper": 1.2 if difficulty >= 3 else 0.0, "tank": 1.0 if difficulty >= 4 else 0.0}
	var total := 0.0
	for kind: String in weights:
		total += float(weights[kind])
	var roll := rng.randf() * total
	for kind: String in weights:
		roll -= float(weights[kind])
		if roll <= 0.0:
			return kind
	return "walker"


func spawn_enemy_near(at: Vector2, kind: String) -> ScavEnemy:
	var enemy := ScavEnemy.new()
	enemy.setup(self, Apocalypse.enemy_stats(Trip.apocalypse.pick_threat(_rng)), at, kind)
	add_child(enemy)
	enemies.append(enemy)
	return enemy


func _spawn_boss() -> void:
	boss = ScavBoss.new()
	var threat := Trip.apocalypse.main_threat()
	var type_id: String = ["zombies", "fallout", "aliens", "plague"][threat]
	boss.setup_boss(self, Apocalypse.enemy_stats(threat), _layout.boss_spot, type_id, _layout.arena, _difficulty)
	add_child(boss)
	enemies.append(boss)


func on_boss_beaten(beaten: ScavBoss) -> void:
	if boss != beaten:
		return
	enemies.erase(beaten)
	beaten.queue_free()
	boss = null
	_exit_sign.visible = true
	Progress.add_stat("enemies")
	Progress.add_stat("bosses")
	Progress.earn(beaten.award_id())
	var parts: Array[String] = [_gain("food", 40), _gain("ammo", 40), _gain("medkits", 2), _gain("money", 150)]
	var weapon := Weapons.random_new(_rng, Trip.weapons)
	if weapon != "" and Trip.add_weapon(weapon):
		parts.append("a %s" % Weapons.display_name(weapon))
	_banner("%s is down! %s. The EXIT is open." % [beaten.display_name(), ", ".join(parts)])


# --- Combat ---------------------------------------------------------------

## Uses the held weapon. Returns how long until it can be used again, or
## -1 if there's nothing to shoot it with (the caller switches to the crowbar).
func fire_weapon(from: Vector2, facing: int, survivor: Survivor) -> float:
	var weapon_id := Trip.current_weapon()
	var weapon := Weapons.info(weapon_id)
	var damage := int(weapon["damage"]) * survivor.shot_damage()
	var gunner_speed := 0.7 if survivor.role == Survivor.Role.GUNNER else 1.0
	if Weapons.is_melee(weapon_id):
		melee(from, facing, damage, float(weapon["melee"]))
		return float(weapon["cooldown"])
	if not Trip.spend(str(weapon["supply"]), float(weapon["cost"])):
		return -1.0
	shots.fire_player(from + Vector2(facing * 6.0, -9.0), facing, weapon, damage)
	return float(weapon["cooldown"]) * gunner_speed


func melee(from: Vector2, facing: int, damage: int, reach := 18.0) -> void:
	for enemy: ScavEnemy in enemies:
		var offset := enemy.position - from
		if offset.x * facing >= -4.0 and absf(offset.x) < reach + enemy.box().size.x / 2.0 and absf(offset.y) < 16.0 + enemy.box().size.y / 2.0:
			enemy.hit(damage, facing)
			return


func on_enemy_killed(enemy: ScavEnemy) -> void:
	if not enemies.has(enemy):
		return
	enemies.erase(enemy)
	enemy.queue_free()
	if enemy.health <= 0:
		Progress.add_stat("enemies")


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
			if crate["stash"]:
				_open_stash()
			else:
				_open_crate()


func _open_crate() -> void:
	if _rng.randf() < WEAPON_CRATE_CHANCE:
		var found := Weapons.random_new(_rng, Trip.weapons)
		if found != "" and Trip.add_weapon(found):
			Progress.add_stat("crates")
			_banner("Crate: a %s! Press Q/E or %d to use it." % [Weapons.display_name(found), Weapons.ORDER.find(found) + 1])
			return
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
	var text := "Crate: " + _gain(supply, amount)
	if Trip.has_standing_role(Survivor.Role.THIEF):
		text += ", " + _gain("money", _rng.randi_range(5, 20))
	Progress.add_stat("crates")
	_banner(text)


## A hidden stash: a big haul of several supplies, and it counts toward awards.
func _open_stash() -> void:
	var parts: Array[String] = []
	parts.append(_gain("food", _rng.randi_range(20, 35)))
	parts.append(_gain("ammo", _rng.randi_range(20, 35)))
	parts.append(_gain("medkits", 1))
	parts.append(_gain("money", _rng.randi_range(40, 90)))
	var weapon := Weapons.random_new(_rng, Trip.weapons)
	if weapon != "" and Trip.add_weapon(weapon):
		parts.append("a %s" % Weapons.display_name(weapon))
	Progress.add_stat("stashes")
	_banner("HIDDEN STASH! " + ", ".join(parts))


## Adds a supply to the trip and to this level's haul; returns "+N supply".
func _gain(supply: String, amount: int) -> String:
	Trip.add_supply(supply, amount)
	_loot[supply] = int(_loot.get(supply, 0)) + amount
	return "+%d %s" % [amount, supply]


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

func open_pause() -> PauseMenu:
	return PauseMenu.open(self, "Leave level", _end.bind("You leave early. Discretion, valor, something like that."))


func _build_hud() -> void:
	var touch := TouchControls.new()
	add_child(touch)
	# Under the party list, top left.
	touch.place_pause(Vector2(0, 0), Vector2(30, 104))
	var ids: Array[String] = ["jump", "fire", "weapon", "survivor"]
	touch.set_buttons(ids)
	touch.pause_pressed.connect(open_pause)
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
	_hud_weapon = UiKit.label("", 11, UiKit.ACCENT)
	UiKit.pin(_hud_weapon, root, Vector2(1, 0), Vector2(-330, 26), Vector2(320, 0))
	_hud_weapon.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_boss_label = UiKit.label("", 11, UiKit.DANGER)
	_boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.pin(_boss_label, root, Vector2(0.5, 0), Vector2(-150, 40), Vector2(300, 0))
	_boss_bar = UiKit.bar(1, 1, UiKit.DANGER, Vector2(300, 8))
	UiKit.pin(_boss_bar, root, Vector2(0.5, 0), Vector2(-150, 56), Vector2(300, 8))
	var hint_text := "Stick: move, up/down climbs ladders   II: pause / leave" if Mobile.controls_shown() \
		else "A/D move  SPACE jump  F shoot  Q/E or 1-6 weapon  TAB survivor  ESC pause"
	var hint := UiKit.label(hint_text, 10, UiKit.DIM)
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
	var kit: Array[String] = []
	for weapon_id: String in Trip.weapons:
		kit.append(("[%s]" if weapon_id == Trip.current_weapon() else "%s") % Weapons.display_name(weapon_id))
	var held := Trip.current_weapon()
	var supply := str(Weapons.info(held)["supply"])
	_hud_weapon.text = "%s    %s" % [Weapons.hud_text(held, Trip.get_supply(supply) if supply != "" else 0.0), " ".join(kit)]
	_boss_label.visible = boss != null
	_boss_bar.visible = boss != null
	if boss != null:
		_boss_label.text = boss.display_name()
		_boss_bar.max_value = boss.max_health
		_boss_bar.value = maxi(0, boss.health)
	_hud_banner.visible = _banner_time > 0.0


func _banner(text: String) -> void:
	_hud_banner.text = text
	_banner_time = BANNER_TIME

class_name ScavBoss
extends ScavEnemy
## A boss guarding the last scavenging stop of medium and long routes. One
## per apocalypse type, each with its own attack pattern:
##   zombies - The Big Rotten: huge and slow; slams the ground (shockwaves
##             roll both ways along the floor) and calls in walkers.
##   fallout - the Glowmother: lobs arcs of three glowing globs.
##   aliens  - The Overseer: hovers above the arena and drops bombs, then
##             blinks to a new spot.
##   plague  - Patient Zero: charges across the arena, coughing a spray of spit.

const BOSSES: Dictionary = {
	"zombies": {"name": "The Big Rotten", "award": "boss_zombies", "health": 45, "speed": 22.0, "damage": 20, "scale": 2.6},
	"fallout": {"name": "The Glowmother", "award": "boss_fallout", "health": 40, "speed": 26.0, "damage": 18, "scale": 2.2},
	"aliens": {"name": "The Overseer", "award": "boss_aliens", "health": 32, "speed": 60.0, "damage": 16, "scale": 2.0},
	"plague": {"name": "Patient Zero", "award": "boss_plague", "health": 38, "speed": 34.0, "damage": 18, "scale": 2.0},
}
const ATTACK_EVERY := 2.4
## The Overseer hovers just above head height: jump (or stand on a ledge) to hit it.
const HOVER_HEIGHT := 36.0
const CHARGE_SPEED := 170.0
const CHARGE_TIME := 0.9

var boss_type := "zombies"
var _attack_timer := 1.5
var _charge_left := 0.0
var _hover_target := Vector2.ZERO
var _arena := Rect2()


func setup_boss(owner_level: ScavengeScreen, threat_stats: Dictionary, at: Vector2, type_id: String, arena: Rect2, difficulty: int) -> void:
	boss_type = type_id if BOSSES.has(type_id) else "zombies"
	var data: Dictionary = BOSSES[boss_type]
	setup(owner_level, threat_stats, at, "walker")
	kind = "boss"
	health = int(data["health"]) + difficulty * 2
	max_health = health
	speed = data["speed"]
	damage = data["damage"]
	_arena = arena
	_size = ScavEnemy.SIZE * float(data["scale"])
	var shape: CollisionShape2D = get_child(0)
	(shape.shape as RectangleShape2D).size = _size
	shape.position = Vector2(0, -_size.y / 2.0)
	_sprite.scale = Vector2.ONE * float(data["scale"])
	_tint = Color(1.1, 0.9, 0.9) if boss_type != "aliens" else Color(0.9, 1.0, 1.2)
	_sprite.modulate = _tint
	_hover_target = Vector2(at.x, arena.end.y - HOVER_HEIGHT)


func display_name() -> String:
	return str(BOSSES[boss_type]["name"])


func award_id() -> String:
	return str(BOSSES[boss_type]["award"])


func _physics_process(delta: float) -> void:
	if boss_type != "aliens":
		super(delta)
		return
	# The Overseer hovers: no gravity, glides toward its hover spot.
	if level.is_finished():
		return
	_think(delta)
	position = position.move_toward(_hover_target, speed * delta)
	_sprite.flip_h = level.player.position.x < position.x
	if box().intersects(level.player.box()):
		level.player.hurt(damage)
	_update_flash(delta)


func _think(delta: float) -> void:
	var to_player := level.player.position - position
	direction = 1 if to_player.x > 0.0 else -1
	_attack_timer -= delta
	match boss_type:
		"zombies":
			velocity.x = direction * speed
			if _attack_timer <= 0.0 and is_on_floor():
				_attack_timer = ATTACK_EVERY
				_ground_slam()
		"fallout":
			velocity.x = direction * speed * (0.4 if absf(to_player.x) < 80.0 else 1.0)
			if _attack_timer <= 0.0:
				_attack_timer = ATTACK_EVERY * 0.8
				_lob_globs(to_player)
		"aliens":
			if _attack_timer <= 0.0:
				_attack_timer = ATTACK_EVERY * 0.6
				_drop_bomb()
				if randf() < 0.35:
					_blink()
		"plague":
			if _charge_left > 0.0:
				_charge_left -= delta
				velocity.x = direction * CHARGE_SPEED
			else:
				velocity.x = direction * speed * 0.5
				if _attack_timer <= 0.0 and is_on_floor():
					_attack_timer = ATTACK_EVERY
					_charge_left = CHARGE_TIME
					_cough(to_player)


func _ground_slam() -> void:
	for side: int in [-1, 1]:
		level.shots.fire_enemy(position + Vector2(side * _size.x / 2.0, -4.0), Vector2(side * 120.0, 0),
			int(damage * 0.7), Color("a08060"), 0.0, Vector2(8, 6))
	if level.enemies.size() < 8:
		level.spawn_enemy_near(position + Vector2(-direction * 60.0, -2.0), "walker")


func _lob_globs(to_player: Vector2) -> void:
	for spread: float in [-40.0, 0.0, 40.0]:
		var push := clampf(to_player.x * 0.9, -160.0, 160.0) + spread
		level.shots.fire_enemy(position + Vector2(0, -_size.y), Vector2(push, -240.0), int(damage * 0.7),
			Color("b0ff50"), 600.0, Vector2(5, 5))


func _drop_bomb() -> void:
	level.shots.fire_enemy(position + Vector2(0, 4.0), Vector2(0, 60.0), damage, Color("30e0e0"), 300.0, Vector2(5, 5))
	_hover_target.x = clampf(level.player.position.x + randf_range(-30.0, 30.0), _arena.position.x + 20.0, _arena.end.x - 20.0)


func _blink() -> void:
	position.x = randf_range(_arena.position.x + 30.0, _arena.end.x - 30.0)
	_hover_target.x = position.x
	_flash = 0.3


func _cough(to_player: Vector2) -> void:
	var side := 1.0 if to_player.x > 0.0 else -1.0
	for angle: float in [-0.25, 0.0, 0.25]:
		level.shots.fire_enemy(position + Vector2(side * 10.0, -_size.y * 0.7),
			Vector2(side * 150.0, 0).rotated(angle * side), int(damage * 0.6), Color("d0b0b0"), 0.0, Vector2(4, 4))


func hit(amount: int, _push_direction: int) -> void:
	health -= amount
	_flash = FLASH_TIME
	if health <= 0:
		level.on_boss_beaten(self)

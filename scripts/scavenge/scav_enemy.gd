class_name ScavEnemy
extends CharacterBody2D
## An enemy in a scavenging level. The look and base numbers come from the
## apocalypse (Apocalypse.enemy_stats); the kind decides how it fights:
##   walker  - patrols its ledge, chases you when you're close and level with it
##   runner  - weak but sprints at you, usually in pairs
##   tank    - big, slow and very tough; hits hard and barely flinches
##   shooter - keeps its distance and spits projectiles you have to jump or dodge
##   jumper  - leaps up onto platforms and roofs to reach you

const GRAVITY := 900.0
const CHASE_RANGE := 110.0
const CHASE_HEIGHT := 40.0
const FLASH_TIME := 0.12
const KNOCKBACK := 3.0
const SIZE := Vector2(8, 14)
const KINDS: Array[String] = ["walker", "runner", "tank", "shooter", "jumper"]

## Changes to the apocalypse's base enemy for each kind.
const KIND_DATA: Dictionary = {
	"walker": {"name": "", "health": 1.0, "health_add": 0, "speed": 1.0, "damage": 1.0, "scale": 1.0, "tint": Color.WHITE},
	"runner": {"name": "Sprinter", "health": 0.5, "health_add": 0, "speed": 2.4, "damage": 0.8, "scale": 0.9, "tint": Color(1.15, 1.1, 1.0)},
	"tank": {"name": "Brute", "health": 3.0, "health_add": 3, "speed": 0.55, "damage": 1.7, "scale": 1.45, "tint": Color(0.8, 0.75, 0.75)},
	"shooter": {"name": "Spitter", "health": 1.0, "health_add": 0, "speed": 0.75, "damage": 0.8, "scale": 1.0, "tint": Color(0.85, 1.15, 0.85)},
	"jumper": {"name": "Leaper", "health": 1.0, "health_add": 0, "speed": 1.2, "damage": 1.0, "scale": 0.95, "tint": Color(1.1, 0.95, 1.15)},
}
const SHOOT_EVERY := 1.8
const SHOOT_MIN_DISTANCE := 60.0
const SHOOT_MAX_DISTANCE := 150.0
const SHOT_SPEED := 130.0
const LEAP_SPEED := Vector2(110, 340)
const LEAP_COOLDOWN := 1.6

var level: ScavengeScreen
var kind := "walker"
var health := 1
var max_health := 1
var speed := 30.0
var damage := 10
var direction := -1
var _sprite: Sprite2D
var _flash := 0.0
var _shoot_timer := 0.0
var _leap_timer := 0.0
var _size := SIZE
var _tint := Color.WHITE


func setup(owner_level: ScavengeScreen, stats: Dictionary, at: Vector2, enemy_kind := "walker") -> void:
	level = owner_level
	kind = enemy_kind if KIND_DATA.has(enemy_kind) else "walker"
	var data: Dictionary = KIND_DATA[kind]
	health = maxi(1, roundi(int(stats["health"]) * float(data["health"])) + int(data["health_add"]))
	max_health = health
	speed = float(stats["speed"]) * float(data["speed"])
	damage = roundi(int(stats["damage"]) * float(data["damage"]))
	_tint = data["tint"]
	_size = SIZE * float(data["scale"])
	position = at
	collision_layer = 4
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = _size
	shape.shape = rect
	shape.position = Vector2(0, -_size.y / 2.0)
	add_child(shape)
	_sprite = PixelArt.standing(PixelArt.enemy(stats), Vector2.ZERO)
	_sprite.scale = Vector2.ONE * float(data["scale"])
	_sprite.offset = Vector2(0, -_sprite.texture.get_height() / 2.0)
	_sprite.modulate = _tint
	add_child(_sprite)
	_shoot_timer = randf_range(0.5, SHOOT_EVERY)


## Like "Spitter", or "" for the plain walker (it uses the apocalypse's name).
static func kind_name(enemy_kind: String) -> String:
	return str(KIND_DATA.get(enemy_kind, KIND_DATA["walker"])["name"])


func _physics_process(delta: float) -> void:
	if level.is_finished():
		return
	_think(delta)
	velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
	move_and_slide()
	_sprite.flip_h = direction < 0
	if box().intersects(level.player.box()):
		level.player.hurt(damage)
	_update_flash(delta)
	if position.y > ScavengeScreen.KILL_Y:
		level.on_enemy_killed(self)


## Decides where to go this frame (sets direction and velocity.x).
func _think(delta: float) -> void:
	var to_player := level.player.position - position
	match kind:
		"shooter":
			_think_shooter(to_player, delta)
			return
		"jumper":
			if _try_leap(to_player, delta):
				return
	var chase_range := CHASE_RANGE * (1.6 if kind == "runner" else 1.0)
	var chasing := absf(to_player.x) < chase_range and absf(to_player.y) < CHASE_HEIGHT
	if chasing and absf(to_player.x) > 2.0:
		direction = 1 if to_player.x > 0.0 else -1
	elif not chasing and is_on_floor() and (is_on_wall() or not _ground_ahead()):
		direction = -direction
	var blocked := is_on_floor() and not _ground_ahead()
	if not is_on_floor() and kind == "jumper":
		return
	velocity.x = 0.0 if chasing and blocked else direction * speed


## Shooters keep a comfortable distance and spit at you when you're in range.
func _think_shooter(to_player: Vector2, delta: float) -> void:
	var distance := absf(to_player.x)
	direction = 1 if to_player.x > 0.0 else -1
	var level_with_player := absf(to_player.y) < 60.0
	var move := 0.0
	if level_with_player and distance < SHOOT_MIN_DISTANCE:
		move = -direction
	elif level_with_player and distance > SHOOT_MAX_DISTANCE * 0.8 and distance < SHOOT_MAX_DISTANCE * 2.0:
		move = direction
	if move != 0.0 and is_on_floor() and not _ground_ahead_in(int(move)):
		move = 0.0
	velocity.x = move * speed
	_shoot_timer -= delta
	if _shoot_timer <= 0.0 and level_with_player and distance < SHOOT_MAX_DISTANCE:
		_shoot_timer = SHOOT_EVERY
		var from := position + Vector2(direction * 6.0, -9.0)
		level.shots.fire_enemy(from, Vector2(direction * SHOT_SPEED, 0), damage, Color("90e040"))


## Jumpers leap toward you when you're above them (onto platforms and roofs).
func _try_leap(to_player: Vector2, delta: float) -> bool:
	_leap_timer -= delta
	if not is_on_floor():
		return true
	if _leap_timer <= 0.0 and to_player.y < -20.0 and absf(to_player.x) < 140.0:
		_leap_timer = LEAP_COOLDOWN
		direction = 1 if to_player.x > 0.0 else -1
		velocity = Vector2(direction * LEAP_SPEED.x, -LEAP_SPEED.y)
		return true
	return false


func box() -> Rect2:
	return Rect2(position - Vector2(_size.x / 2.0, _size.y), _size)


func hit(amount: int, push_direction: int) -> void:
	health -= amount
	_flash = FLASH_TIME
	if kind != "tank":
		position.x += push_direction * KNOCKBACK
	if health <= 0:
		level.on_enemy_killed(self)


func _update_flash(delta: float) -> void:
	if _flash <= 0.0:
		return
	_flash -= delta
	_sprite.modulate = Color(1, 0.4, 0.4) if _flash > 0.0 else _tint


func _ground_ahead() -> bool:
	return _ground_ahead_in(direction)


func _ground_ahead_in(side: int) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = position + Vector2(side * (_size.x / 2.0 + 3.0), 4.0)
	query.collision_mask = 1
	return not get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()

class_name ScavEnemy
extends CharacterBody2D
## An enemy in a scavenging level. It patrols its ledge, turns at walls and
## edges, and chases the player when they are close and on its level.

const GRAVITY := 900.0
const CHASE_RANGE := 110.0
const CHASE_HEIGHT := 40.0
const FLASH_TIME := 0.12
const KNOCKBACK := 3.0
const SIZE := Vector2(8, 14)

var level: ScavengeScreen
var health := 1
var speed := 30.0
var damage := 10
var direction := -1
var _sprite: Sprite2D
var _flash := 0.0


func setup(owner_level: ScavengeScreen, stats: Dictionary, at: Vector2) -> void:
	level = owner_level
	health = stats["health"]
	speed = stats["speed"]
	damage = stats["damage"]
	position = at
	collision_layer = 4
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	shape.position = Vector2(0, -SIZE.y / 2.0)
	add_child(shape)
	_sprite = PixelArt.standing(PixelArt.enemy(stats), Vector2.ZERO)
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	if level.is_finished():
		return
	var to_player := level.player.position - position
	var chasing := absf(to_player.x) < CHASE_RANGE and absf(to_player.y) < CHASE_HEIGHT
	if chasing and absf(to_player.x) > 2.0:
		direction = 1 if to_player.x > 0.0 else -1
	elif not chasing and is_on_floor() and (is_on_wall() or not _ground_ahead()):
		direction = -direction
	var blocked := is_on_floor() and not _ground_ahead()
	velocity.x = 0.0 if chasing and blocked else direction * speed
	velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
	move_and_slide()
	_sprite.flip_h = direction < 0
	if box().intersects(level.player.box()):
		level.player.hurt(damage)
	_update_flash(delta)
	if position.y > ScavengeScreen.KILL_Y:
		level.on_enemy_killed(self)


func box() -> Rect2:
	return Rect2(position - Vector2(SIZE.x / 2.0, SIZE.y), SIZE)


func hit(amount: int, push_direction: int) -> void:
	health -= amount
	_flash = FLASH_TIME
	position.x += push_direction * KNOCKBACK
	if health <= 0:
		level.on_enemy_killed(self)


func _update_flash(delta: float) -> void:
	if _flash <= 0.0:
		return
	_flash -= delta
	_sprite.modulate = Color(1, 0.4, 0.4) if _flash > 0.0 else Color.WHITE


func _ground_ahead() -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = position + Vector2(direction * 7.0, 4.0)
	query.collision_mask = 1
	return not get_world_2d().direct_space_state.intersect_point(query, 1).is_empty()

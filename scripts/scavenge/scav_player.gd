class_name ScavPlayer
extends CharacterBody2D
## The survivor you control in a scavenging level: run, jump, shoot (or
## swing when out of ammo) and switch to another party member.

const GRAVITY := 900.0
const MAX_FALL_SPEED := 400.0
const SHORT_HOP_SPEED := 90.0
const HURT_COOLDOWN := 0.8
const MELEE_COOLDOWN := 0.45
const FALL_DAMAGE := 20
const SIZE := Vector2(8, 14)

var level: ScavengeScreen
var facing := 1
var _fire_timer := 0.0
var _hurt_timer := 0.0
var _last_safe := Vector2.ZERO
var _sprite: Sprite2D


func setup(owner_level: ScavengeScreen, start: Vector2) -> void:
	level = owner_level
	position = start
	_last_safe = start
	collision_layer = 2
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE
	shape.shape = rect
	shape.position = Vector2(0, -SIZE.y / 2.0)
	add_child(shape)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	refresh_look()


func refresh_look() -> void:
	var texture := Trip.active().sprite()
	_sprite.texture = texture
	_sprite.offset = Vector2(0, -texture.get_height() / 2.0)


func box() -> Rect2:
	return Rect2(position - Vector2(SIZE.x / 2.0, SIZE.y), SIZE)


func _physics_process(delta: float) -> void:
	if level.is_finished():
		return
	var survivor := Trip.active()
	_move(survivor, delta)
	_fire_timer -= delta
	_hurt_timer -= delta
	if Input.is_action_pressed("fire") and _fire_timer <= 0.0:
		_fire(survivor)
	if Input.is_action_just_pressed("switch_survivor") and Trip.switch_to_next_standing():
		refresh_look()
	if position.y > ScavengeScreen.KILL_Y:
		_fell()


func _move(survivor: Survivor, delta: float) -> void:
	var steer := Controls.horizontal()
	velocity.x = steer * survivor.move_speed()
	if steer != 0.0:
		facing = 1 if steer > 0.0 else -1
		_sprite.flip_h = facing < 0
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = -survivor.jump_speed()
	# Letting go of jump early gives a smaller hop.
	if Input.is_action_just_released("jump") and velocity.y < -SHORT_HOP_SPEED:
		velocity.y = -SHORT_HOP_SPEED
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)
	move_and_slide()
	if is_on_floor():
		_last_safe = position


func _fire(survivor: Survivor) -> void:
	if Trip.ammo > 0:
		Trip.ammo -= 1
		level.spawn_bullet(position + Vector2(facing * 6.0, -9.0), facing, survivor.shot_damage())
		_fire_timer = survivor.fire_cooldown()
	else:
		level.melee(position, facing, survivor.shot_damage())
		_fire_timer = MELEE_COOLDOWN


func hurt(amount: int) -> void:
	if _hurt_timer > 0.0 or level.is_finished():
		return
	_hurt_timer = HURT_COOLDOWN
	_take_damage(amount)


func _take_damage(amount: int) -> void:
	var survivor := Trip.active()
	survivor.hurt(amount)
	_sprite.modulate = Color(1, 0.4, 0.4)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.3)
	if survivor.is_downed():
		level.on_survivor_downed(survivor)


## Falling into a pit hurts and puts you back on the last solid ground.
func _fell() -> void:
	position = _last_safe + Vector2(-facing * 10.0, -4.0)
	velocity = Vector2.ZERO
	_take_damage(FALL_DAMAGE)

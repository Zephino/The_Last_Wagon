class_name ScavPlayer
extends CharacterBody2D
## The survivor you control in a scavenging level: run, jump, climb ladders,
## use the held weapon, and switch weapons or party members. Hazards can slow
## you down (water, toxic puddles, quicksand).

const GRAVITY := 900.0
const MAX_FALL_SPEED := 400.0
const SHORT_HOP_SPEED := 90.0
const HURT_COOLDOWN := 0.8
const FALL_DAMAGE := 20
const SIZE := Vector2(8, 14)
const CLIMB_SPEED := 70.0
const CLIMB_SIDE_SPEED := 40.0
const LADDER_TOP_HOP := 170.0

var level: ScavengeScreen
var facing := 1
var climbing := false
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
	_switch_weapons()
	if Input.is_action_pressed("fire") and _fire_timer <= 0.0:
		_fire(survivor)
	if Input.is_action_just_pressed("switch_survivor") and Trip.switch_to_next_standing():
		refresh_look()
	if position.y > ScavengeScreen.KILL_Y:
		_fell()


func _move(survivor: Survivor, delta: float) -> void:
	var steer := Controls.horizontal()
	var slow := level.hazards.affect(box()) if level.hazards != null else 1.0
	if _climb(steer):
		return
	velocity.x = steer * survivor.move_speed() * slow
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


## Climbing: up/down on a ladder grabs it; jump sideways or step off to let go.
## Returns true while climbing (normal movement is skipped).
func _climb(steer: float) -> bool:
	var on_ladder := level.ladder_at(box())
	var vertical := Input.get_axis("move_up", "move_down")
	if on_ladder and not climbing and vertical != 0.0 and not (vertical > 0.0 and is_on_floor()):
		climbing = true
	if climbing and (not on_ladder or (Input.is_action_just_pressed("jump") and steer != 0.0)):
		climbing = false
		# Reaching the top while still climbing: hop up so you can step onto the roof.
		if not on_ladder and vertical < 0.0:
			velocity.y = -LADDER_TOP_HOP
	if not climbing:
		return false
	if steer != 0.0:
		facing = 1 if steer > 0.0 else -1
		_sprite.flip_h = facing < 0
	velocity = Vector2(steer * CLIMB_SIDE_SPEED, vertical * CLIMB_SPEED)
	move_and_slide()
	return true


func _fire(survivor: Survivor) -> void:
	var wait := level.fire_weapon(position, facing, survivor)
	if wait < 0.0:
		# Out of what this weapon needs: grab the crowbar instead.
		Trip.select_weapon("crowbar")
		wait = level.fire_weapon(position, facing, survivor)
	_fire_timer = wait


func _switch_weapons() -> void:
	if Input.is_action_just_pressed("prev_weapon"):
		Trip.cycle_weapon(-1)
	if Input.is_action_just_pressed("next_weapon"):
		Trip.cycle_weapon(1)
	for index: int in Weapons.ORDER.size():
		if Input.is_action_just_pressed("weapon_%d" % (index + 1)):
			Trip.select_weapon(Weapons.ORDER[index])


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

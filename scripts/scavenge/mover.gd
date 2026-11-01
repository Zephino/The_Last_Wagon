class_name Mover
extends AnimatableBody2D
## A moving platform in a scavenging level. The player rides it automatically.
##   elevator / slider - glides back and forth along `travel` and back again
##   falling           - shakes, then drops a moment after you land on it,
##                       and comes back a few seconds later

const SHAKE_TIME := 0.5
const FALL_SPEED := 260.0
const RESPAWN_TIME := 3.0

var kind := "slider"
var travel := Vector2.ZERO
var period := 4.0
var level: ScavengeScreen
var _origin := Vector2.ZERO
var _time := 0.0
var _shake := -1.0
var _fallen := -1.0
var _size := Vector2.ZERO
var _sprite: Sprite2D


func setup(owner_level: ScavengeScreen, data: Dictionary) -> void:
	level = owner_level
	var rect: Rect2 = data["rect"]
	kind = data["kind"]
	travel = data["travel"]
	period = maxf(0.1, float(data["period"]))
	_size = rect.size
	_origin = rect.position
	position = _origin
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = _size
	shape.shape = box
	shape.position = _size / 2.0
	if kind != "elevator":
		shape.one_way_collision = true
	add_child(shape)
	var color := Color("8a6a3a") if kind == "falling" else Color("7a8a9a")
	_sprite = PixelArt.tiled(PixelArt.plank_tile(color), Vector2.ZERO, _size)
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	_time += delta
	match kind:
		"falling":
			_update_falling(delta)
		_:
			var t := 0.5 - 0.5 * cos(_time * TAU / period)
			position = _origin + travel * t


func _update_falling(delta: float) -> void:
	if _fallen >= 0.0:
		_fallen += delta
		position.y += FALL_SPEED * delta
		if _fallen >= RESPAWN_TIME:
			_fallen = -1.0
			_shake = -1.0
			position = _origin
			_sprite.modulate = Color.WHITE
		return
	if _shake < 0.0 and _player_standing_on():
		_shake = 0.0
	if _shake >= 0.0:
		_shake += delta
		_sprite.position.x = randf_range(-1.0, 1.0)
		_sprite.modulate = Color(1, 0.8, 0.7)
		if _shake >= SHAKE_TIME:
			_sprite.position.x = 0.0
			_fallen = 0.0


func _player_standing_on() -> bool:
	if level == null or level.player == null:
		return false
	var feet := level.player.position
	return level.player.is_on_floor() and absf(feet.y - position.y) < 2.0 \
		and feet.x > position.x - 3.0 and feet.x < position.x + _size.x + 3.0


func is_falling() -> bool:
	return _fallen >= 0.0

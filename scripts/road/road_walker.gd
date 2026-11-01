class_name RoadWalker
extends Node2D
## An enemy on the road. It shuffles toward the party; the car can run it
## over, and on foot you shoot it before it reaches you.

const FLASH_TIME := 0.12

var health := 1
var speed := 30.0
var damage := 10
var _sprite: Sprite2D
var _flash := 0.0


func setup(stats: Dictionary, at_x: float) -> void:
	health = stats["health"]
	speed = stats["speed"]
	damage = stats["damage"]
	position = Vector2(at_x, 0)
	_sprite = PixelArt.standing(PixelArt.enemy(stats), Vector2.ZERO)
	add_child(_sprite)


func _process(delta: float) -> void:
	if _flash <= 0.0:
		return
	_flash -= delta
	_sprite.modulate = Color(1, 0.4, 0.4) if _flash > 0.0 else Color.WHITE


## Returns true when this hit finished it off.
func hit(amount: int) -> bool:
	health -= amount
	_flash = FLASH_TIME
	return health <= 0


func is_alive() -> bool:
	return health > 0

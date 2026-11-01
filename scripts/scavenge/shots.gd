class_name Shots
extends Node2D
## Everything that flies in a scavenging level: the player's shots (bullets,
## pellets, rifle rounds that go through enemies, flames, nails) and enemy
## projectiles (spit, globs, bombs, shockwaves) that hurt the player.

const ENEMY_MASK := 4
const WORLD_MASK := 1

var level: ScavengeScreen
var _player_shots: Array[Dictionary] = []
var _enemy_shots: Array[Dictionary] = []


func _physics_process(delta: float) -> void:
	if level == null or level.is_finished():
		return
	_update_player_shots(delta)
	_update_enemy_shots(delta)


## Fires the held weapon's projectiles from `from`, facing `direction` (+1/-1).
func fire_player(from: Vector2, direction: int, weapon: Dictionary, damage: int) -> void:
	var pellets: int = weapon["pellets"]
	var spread: float = weapon["spread"]
	for index: int in pellets:
		var angle := deg_to_rad(randf_range(-spread, spread)) if pellets > 1 or spread > 0.0 else 0.0
		var velocity := Vector2(direction * float(weapon["speed"]), 0).rotated(angle * direction)
		var sprite := _dot(weapon["color"], Vector2(3, 1) if spread < 10.0 else Vector2(3, 3))
		sprite.position = from
		add_child(sprite)
		_player_shots.append({"node": sprite, "velocity": velocity, "damage": damage,
			"left": float(weapon["range"]), "pierce": int(weapon["pierce"]), "hit": []})


## An enemy projectile. gravity > 0 makes it arc (globs, bombs).
func fire_enemy(from: Vector2, velocity: Vector2, damage: int, color: Color, gravity := 0.0, size := Vector2(4, 4)) -> void:
	var sprite := _dot(color, size)
	sprite.position = from
	add_child(sprite)
	_enemy_shots.append({"node": sprite, "velocity": velocity, "damage": damage, "gravity": gravity, "life": 4.0})


func clear_all() -> void:
	for shot: Dictionary in _player_shots + _enemy_shots:
		(shot["node"] as Node).queue_free()
	_player_shots.clear()
	_enemy_shots.clear()


func enemy_shot_count() -> int:
	return _enemy_shots.size()


func _update_player_shots(delta: float) -> void:
	var space := get_world_2d().direct_space_state
	for shot: Dictionary in _player_shots.duplicate():
		var node: Sprite2D = shot["node"]
		var step: Vector2 = shot["velocity"] * delta
		var to := node.position + step
		var spent := false
		var exclude: Array[RID] = []
		exclude.assign(shot["hit"])
		while true:
			var query := PhysicsRayQueryParameters2D.create(node.position, to, WORLD_MASK | ENEMY_MASK, exclude)
			var hit := space.intersect_ray(query)
			if hit.is_empty():
				break
			var enemy := hit["collider"] as ScavEnemy
			if enemy == null:
				spent = true
				break
			enemy.hit(int(shot["damage"]), 1 if step.x > 0.0 else -1)
			exclude.append(hit["rid"])
			shot["hit"] = exclude
			shot["pierce"] = int(shot["pierce"]) - 1
			if int(shot["pierce"]) <= 0:
				spent = true
				break
		shot["left"] = float(shot["left"]) - step.length()
		if spent or float(shot["left"]) <= 0.0:
			_player_shots.erase(shot)
			node.queue_free()
		else:
			node.position = to


func _update_enemy_shots(delta: float) -> void:
	var space := get_world_2d().direct_space_state
	var player_box := level.player.box()
	for shot: Dictionary in _enemy_shots.duplicate():
		var node: Sprite2D = shot["node"]
		var velocity: Vector2 = shot["velocity"]
		velocity.y += float(shot["gravity"]) * delta
		shot["velocity"] = velocity
		node.position += velocity * delta
		shot["life"] = float(shot["life"]) - delta
		var query := PhysicsPointQueryParameters2D.new()
		query.position = node.position
		query.collision_mask = WORLD_MASK
		var into_wall := not space.intersect_point(query, 1).is_empty()
		var hit_player := player_box.has_point(node.position)
		if hit_player:
			level.player.hurt(int(shot["damage"]))
		if hit_player or into_wall or float(shot["life"]) <= 0.0 or node.position.y > ScavengeScreen.KILL_Y:
			_enemy_shots.erase(shot)
			node.queue_free()


func _dot(color: Color, size: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = PixelArt.solid(color)
	sprite.scale = size
	return sprite

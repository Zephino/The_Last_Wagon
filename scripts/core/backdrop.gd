class_name Backdrop
extends RefCounted
## Shared scenery: a sky, a ruined skyline and a camera. Colors follow the
## current apocalypse so every run looks a little different.

const ZOOM := 2.0


## A camera that shows the world at chunky pixel size, centered at pos.
static func add_camera(parent: Node, pos: Vector2) -> Camera2D:
	var camera := Camera2D.new()
	camera.zoom = Vector2(ZOOM, ZOOM)
	camera.position = pos
	parent.add_child(camera)
	camera.make_current()
	return camera


## A sky that stays behind everything, filling the whole screen.
static func add_sky(parent: Node, apocalypse: Apocalypse) -> void:
	var layer := CanvasLayer.new()
	layer.layer = -10
	parent.add_child(layer)
	var sky := TextureRect.new()
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.texture = _sky_texture(apocalypse.sky_color(), apocalypse.horizon_color())
	layer.add_child(sky)


## Ruined buildings from x_from to x_to with their bottoms at base_y.
## parallax: 0 = moves with the world, 0.8 = barely moves (far away).
static func add_skyline(parent: Node, x_from: float, x_to: float, base_y: float,
		color: Color, rng: RandomNumberGenerator, parallax := 0.0) -> Node2D:
	var holder: Node2D = Parallax2D.new() if parallax > 0.0 else Node2D.new()
	if holder is Parallax2D:
		(holder as Parallax2D).scroll_scale = Vector2(1.0 - parallax, 1.0)
	parent.add_child(holder)
	var x := x_from
	while x < x_to:
		var width := rng.randf_range(18, 46)
		var height := rng.randf_range(20, 90)
		var block := PixelArt.tiled(PixelArt.solid(color), Vector2(x, base_y - height), Vector2(width, height))
		holder.add_child(block)
		_add_windows(holder, block.position, Vector2(width, height), color, rng)
		x += width + rng.randf_range(0, 14)
	return holder


## Region scenery from x_from to x_to, standing on base_y: city skylines,
## farms, mountain peaks with pines, desert mesas with cacti, or swamp trees.
## parallax works as in add_skyline.
static func add_scenery(parent: Node, region: String, x_from: float, x_to: float, base_y: float,
		color: Color, rng: RandomNumberGenerator, parallax := 0.0) -> Node2D:
	var kind: String = Regions.info(region)["scenery"]
	if kind == "city":
		return add_skyline(parent, x_from, x_to, base_y, color, rng, parallax)
	var holder: Node2D = Parallax2D.new() if parallax > 0.0 else Node2D.new()
	if holder is Parallax2D:
		(holder as Parallax2D).scroll_scale = Vector2(1.0 - parallax, 1.0)
	parent.add_child(holder)
	var x := x_from
	while x < x_to:
		match kind:
			"farms":
				x = _add_farm_piece(holder, x, base_y, color, rng)
			"peaks":
				x = _add_mountain_piece(holder, x, base_y, color, rng)
			"mesas":
				x = _add_desert_piece(holder, x, base_y, color, rng)
			_:
				x = _add_swamp_piece(holder, x, base_y, color, rng)
	return holder


static func _block(holder: Node2D, color: Color, pos: Vector2, size: Vector2) -> void:
	holder.add_child(PixelArt.tiled(PixelArt.solid(color), pos, size))


static func _shape(holder: Node2D, color: Color, points: PackedVector2Array) -> void:
	var polygon := Polygon2D.new()
	polygon.color = color
	polygon.polygon = points
	holder.add_child(polygon)


static func _add_farm_piece(holder: Node2D, x: float, base_y: float, color: Color, rng: RandomNumberGenerator) -> float:
	match rng.randi_range(0, 3):
		0:
			var w := rng.randf_range(26, 40)
			var h := rng.randf_range(16, 24)
			_block(holder, color, Vector2(x, base_y - h), Vector2(w, h))
			_shape(holder, color, PackedVector2Array([Vector2(x - 3, base_y - h), Vector2(x + w / 2.0, base_y - h - 12), Vector2(x + w + 3, base_y - h)]))
			return x + w + rng.randf_range(20, 60)
		1:
			var h := rng.randf_range(30, 48)
			_block(holder, color, Vector2(x, base_y - h), Vector2(10, h))
			_shape(holder, color, PackedVector2Array([Vector2(x, base_y - h), Vector2(x + 5, base_y - h - 6), Vector2(x + 10, base_y - h)]))
			return x + 14 + rng.randf_range(10, 50)
		_:
			for post: int in rng.randi_range(4, 8):
				_block(holder, color, Vector2(x + post * 8, base_y - 7), Vector2(2, 7))
			_block(holder, color, Vector2(x, base_y - 5), Vector2(rng.randi_range(4, 8) * 8, 1))
			return x + 70 + rng.randf_range(10, 60)


static func _add_mountain_piece(holder: Node2D, x: float, base_y: float, color: Color, rng: RandomNumberGenerator) -> float:
	if rng.randf() < 0.55:
		var w := rng.randf_range(90, 170)
		var h := rng.randf_range(60, 120)
		_shape(holder, color, PackedVector2Array([Vector2(x, base_y), Vector2(x + w * 0.5, base_y - h), Vector2(x + w, base_y)]))
		var snow := color.lightened(0.45)
		_shape(holder, snow, PackedVector2Array([Vector2(x + w * 0.5 - w * 0.08, base_y - h * 0.84),
			Vector2(x + w * 0.5, base_y - h), Vector2(x + w * 0.5 + w * 0.08, base_y - h * 0.84)]))
		return x + w * rng.randf_range(0.5, 0.9)
	var trees := rng.randi_range(2, 5)
	var tree_color := color.darkened(0.2)
	for index: int in trees:
		var tx := x + index * 11.0
		var th := rng.randf_range(18, 30)
		_shape(holder, tree_color, PackedVector2Array([Vector2(tx, base_y - 3), Vector2(tx + 5, base_y - th), Vector2(tx + 10, base_y - 3)]))
		_block(holder, tree_color, Vector2(tx + 4, base_y - 4), Vector2(2, 4))
	return x + trees * 11.0 + rng.randf_range(10, 40)


static func _add_desert_piece(holder: Node2D, x: float, base_y: float, color: Color, rng: RandomNumberGenerator) -> float:
	if rng.randf() < 0.5:
		var w := rng.randf_range(60, 140)
		var h := rng.randf_range(28, 70)
		_shape(holder, color, PackedVector2Array([Vector2(x, base_y), Vector2(x + 14, base_y - h), Vector2(x + w - 14, base_y - h), Vector2(x + w, base_y)]))
		_block(holder, color.lightened(0.15), Vector2(x + 14, base_y - h), Vector2(w - 28, 2))
		return x + w + rng.randf_range(10, 70)
	var cactus := color.lerp(Color("4a6a3a"), 0.5)
	var h := rng.randf_range(14, 24)
	_block(holder, cactus, Vector2(x, base_y - h), Vector2(4, h))
	_block(holder, cactus, Vector2(x - 5, base_y - h * 0.6), Vector2(5, 2))
	_block(holder, cactus, Vector2(x - 5, base_y - h * 0.85), Vector2(2, h * 0.25))
	_block(holder, cactus, Vector2(x + 4, base_y - h * 0.45), Vector2(5, 2))
	_block(holder, cactus, Vector2(x + 7, base_y - h * 0.7), Vector2(2, h * 0.25))
	return x + 12 + rng.randf_range(20, 90)


static func _add_swamp_piece(holder: Node2D, x: float, base_y: float, color: Color, rng: RandomNumberGenerator) -> float:
	if rng.randf() < 0.7:
		var h := rng.randf_range(30, 60)
		_block(holder, color, Vector2(x + 6, base_y - h), Vector2(4, h))
		_shape(holder, color, PackedVector2Array([Vector2(x + 6, base_y - 3), Vector2(x, base_y), Vector2(x + 16, base_y), Vector2(x + 10, base_y - 3)]))
		for blob: int in 3:
			_block(holder, color, Vector2(x - 4 + blob * 6, base_y - h - 4 + blob % 2 * 3), Vector2(12, 7))
		return x + 18 + rng.randf_range(4, 30)
	var w := rng.randf_range(24, 34)
	_block(holder, color, Vector2(x, base_y - 26), Vector2(w, 16))
	_shape(holder, color, PackedVector2Array([Vector2(x - 2, base_y - 26), Vector2(x + w / 2.0, base_y - 34), Vector2(x + w + 2, base_y - 26)]))
	_block(holder, color, Vector2(x + 2, base_y - 10), Vector2(2, 10))
	_block(holder, color, Vector2(x + w - 4, base_y - 10), Vector2(2, 10))
	return x + w + rng.randf_range(20, 60)


static func _add_windows(holder: Node2D, top_left: Vector2, size: Vector2, color: Color, rng: RandomNumberGenerator) -> void:
	var lit := color.lightened(0.25)
	var y := top_left.y + 5
	while y < top_left.y + size.y - 6:
		var x := top_left.x + 4
		while x < top_left.x + size.x - 5:
			if rng.randf() < 0.18:
				holder.add_child(PixelArt.tiled(PixelArt.solid(lit), Vector2(x, y), Vector2(3, 4)))
			x += 7
		y += 9


static func _sky_texture(top: Color, bottom: Color) -> Texture2D:
	var key := "sky_%s_%s" % [top.to_html(), bottom.to_html()]
	return PixelArt.painted(key, 1, 32, func(_x: int, y: int) -> Color:
		var t := float(y) / 31.0
		var stepped := floorf(t * 8.0) / 8.0
		return top.lerp(bottom, stepped))

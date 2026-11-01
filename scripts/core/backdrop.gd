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

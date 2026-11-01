class_name MapPainter
extends RefCounted
## Paints a small pixel-art map of the USA with the route drawn on it.
## The outline is a rough hand-made shape of the lower 48 states.

const LON_MIN := -125.0
const LON_MAX := -66.0
const LAT_MIN := 24.0
const LAT_MAX := 50.0
const PX_PER_LON := 3.2
const PX_PER_LAT := 4.0
const WIDTH := 189
const HEIGHT := 104

const OCEAN := Color("16222e")
const ROUTE := Color("d8c8a0")
const VISITED := Color("f0b040")
const UPCOMING := Color("e8e8e8")

## Rough outline of the lower 48 states as (longitude, latitude) points.
const OUTLINE: Array[Vector2] = [
	Vector2(-124.7, 48.4), Vector2(-123.0, 49.0), Vector2(-95.2, 49.0), Vector2(-89.6, 48.0),
	Vector2(-84.8, 46.5), Vector2(-82.4, 45.3), Vector2(-82.5, 41.7), Vector2(-79.0, 42.9),
	Vector2(-76.0, 44.2), Vector2(-74.7, 45.0), Vector2(-71.5, 45.0), Vector2(-70.0, 46.7),
	Vector2(-67.8, 47.1), Vector2(-67.0, 44.8), Vector2(-70.6, 43.1), Vector2(-70.0, 41.8),
	Vector2(-71.9, 41.3), Vector2(-74.0, 40.6), Vector2(-74.0, 39.0), Vector2(-75.5, 38.5),
	Vector2(-76.0, 37.0), Vector2(-75.7, 35.2), Vector2(-77.9, 33.9), Vector2(-79.2, 33.2),
	Vector2(-81.0, 31.5), Vector2(-81.4, 30.2), Vector2(-80.0, 26.9), Vector2(-80.4, 25.2),
	Vector2(-81.1, 25.1), Vector2(-81.8, 26.7), Vector2(-82.7, 28.0), Vector2(-83.0, 29.1),
	Vector2(-84.2, 30.0), Vector2(-86.5, 30.4), Vector2(-89.6, 30.2), Vector2(-89.4, 29.0),
	Vector2(-91.0, 29.3), Vector2(-93.8, 29.7), Vector2(-97.2, 27.6), Vector2(-97.4, 25.9),
	Vector2(-99.5, 27.5), Vector2(-101.4, 29.8), Vector2(-103.1, 29.0), Vector2(-104.5, 29.6),
	Vector2(-106.5, 31.8), Vector2(-108.2, 31.3), Vector2(-111.1, 31.3), Vector2(-114.8, 32.5),
	Vector2(-117.1, 32.5), Vector2(-118.5, 34.0), Vector2(-120.6, 34.6), Vector2(-121.9, 36.6),
	Vector2(-122.5, 37.8), Vector2(-123.8, 39.8), Vector2(-124.2, 41.9), Vector2(-124.5, 43.0),
	Vector2(-123.9, 46.2),
]


## Pixel position on the map image for a longitude/latitude (y grows downward).
static func to_pixel(lon: float, lat: float) -> Vector2i:
	return Vector2i(roundi((lon - LON_MIN) * PX_PER_LON), roundi((LAT_MAX - lat) * PX_PER_LAT))


static func paint(stops: Array, reached_index: int, land: Color) -> ImageTexture:
	var image := Image.create_empty(WIDTH, HEIGHT, false, Image.FORMAT_RGBA8)
	_paint_land(image, land)
	for index: int in range(1, stops.size()):
		var color := VISITED if index <= reached_index else ROUTE
		_line(image, _stop_pixel(stops[index - 1]), _stop_pixel(stops[index]), color)
	for index: int in stops.size():
		var color := VISITED if index <= reached_index else UPCOMING
		_dot(image, _stop_pixel(stops[index]), color)
	return ImageTexture.create_from_image(image)


static func _stop_pixel(stop: Dictionary) -> Vector2i:
	return to_pixel(float(stop["lon"]), float(stop["lat"]))


static func _paint_land(image: Image, land: Color) -> void:
	var polygon := PackedVector2Array()
	for point: Vector2 in OUTLINE:
		polygon.append(Vector2(to_pixel(point.x, point.y)))
	var coast := land.lightened(0.25)
	for y: int in HEIGHT:
		for x: int in WIDTH:
			var center := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(center, polygon):
				var shade := land.darkened(0.08) if (x * 7 + y * 13) % 11 == 0 else land
				image.set_pixel(x, y, shade)
			else:
				image.set_pixel(x, y, OCEAN)
	# A lighter coastline: land pixels that touch the ocean.
	var copy := image.duplicate() as Image
	for y: int in range(1, HEIGHT - 1):
		for x: int in range(1, WIDTH - 1):
			if copy.get_pixel(x, y) == OCEAN:
				continue
			for offset: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				if copy.get_pixel(x + offset.x, y + offset.y) == OCEAN:
					image.set_pixel(x, y, coast)
					break


static func _line(image: Image, from: Vector2i, to: Vector2i, color: Color) -> void:
	var steps := maxi(absi(to.x - from.x), absi(to.y - from.y))
	for step: int in steps + 1:
		var t := float(step) / maxf(1.0, steps)
		var point := Vector2(from).lerp(Vector2(to), t)
		_set_safe(image, roundi(point.x), roundi(point.y), color)


static func _dot(image: Image, center: Vector2i, color: Color) -> void:
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			_set_safe(image, center.x + dx, center.y + dy, color)


static func _set_safe(image: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < WIDTH and y < HEIGHT:
		image.set_pixel(x, y, color)

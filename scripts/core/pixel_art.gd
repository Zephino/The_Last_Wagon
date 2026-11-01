class_name PixelArt
extends RefCounted
## Placeholder pixel art drawn from text grids, so the game needs no image
## files yet. Each letter in a grid is a palette color; "." is see-through.
## Textures are cached so each look is only built once.

const PERSON_ROWS: Array[String] = [
	"...hhhh...",
	"..hhhhhh..",
	"..hssssh..",
	"..sessse..",
	"..ssssss..",
	"...ssss...",
	"..cccccc..",
	".cccccccc.",
	".sccccccs.",
	".sccccccs.",
	"..cccccc..",
	"..pppppp..",
	"..pp..pp..",
	"..pp..pp..",
	"..pp..pp..",
	".bbb..bbb.",
]

const CAR_ROWS: Array[String] = [
	"..........bbbbbbbbbbb...........",
	".........bwwwwbwwwwwwb..........",
	"........bwwwwwbwwwwwwwb.........",
	".bbbbbbbbbbbbbbbbbbbbbbbbbbbbb..",
	"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbl",
	"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
	"bddddddddddddddddddddddddddddddb",
	"bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
	"bbbbbtttbbbbbbbbbbbbbbbbtttbbbbb",
	"....ttrtt..............ttrtt....",
	"....trrrt..............trrrt....",
	".....ttt................ttt.....",
]

const CRATE_ROWS: Array[String] = [
	"dddddddddd",
	"dwwwwwwwwd",
	"dwdwwwwdwd",
	"dwwdwwdwwd",
	"dwwwddwwwd",
	"dwwwddwwwd",
	"dwwdwwdwwd",
	"dwdwwwwdwd",
	"dwwwwwwwwd",
	"dddddddddd",
]

const SIGN_ROWS: Array[String] = [
	"gggggggggggg",
	"ggggggggwggg",
	"ggwwwwwwwwgg",
	"ggggggggwggg",
	"gggggggggggg",
	".....pp.....",
	".....pp.....",
	".....pp.....",
	".....pp.....",
	".....pp.....",
	".....pp.....",
	".....pp.....",
]

static var _cache: Dictionary = {}


## Builds (or reuses) a texture from rows of palette letters.
static func from_rows(key: String, rows: Array[String], palette: Dictionary) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var height := rows.size()
	var width := rows[0].length()
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for y: int in height:
		var row := rows[y]
		for x: int in width:
			var letter := row[x]
			image.set_pixel(x, y, palette.get(letter, Color(0, 0, 0, 0)))
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture


## Builds (or reuses) a texture by calling painter(x, y) for every pixel.
static func painted(key: String, width: int, height: int, painter: Callable) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var image := Image.create_empty(width, height, false, Image.FORMAT_RGBA8)
	for y: int in height:
		for x: int in width:
			image.set_pixel(x, y, painter.call(x, y))
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture


static func person(skin: Color, hair: Color, shirt: Color, pants: Color, eye := Color("1a1a1a")) -> Texture2D:
	var key := "person_%s_%s_%s_%s_%s" % [skin.to_html(), hair.to_html(), shirt.to_html(), pants.to_html(), eye.to_html()]
	var palette := {"h": hair, "s": skin, "e": eye, "c": shirt, "p": pants, "b": Color("2a201a")}
	return from_rows(key, PERSON_ROWS, palette)


static func enemy(stats: Dictionary) -> Texture2D:
	var skin: Color = stats["skin"]
	return person(skin, skin.darkened(0.35), stats["cloth"], Color(stats["cloth"]).darkened(0.3), stats["eye"])


static func car(body: Color) -> Texture2D:
	var palette := {
		"b": body, "w": Color("9fc4d8"), "d": body.darkened(0.35),
		"t": Color("1c1c1c"), "r": Color("8a8a8a"), "l": Color("ffe08a"),
	}
	return from_rows("car_" + body.to_html(), CAR_ROWS, palette)


static func crate() -> Texture2D:
	return from_rows("crate", CRATE_ROWS, {"d": Color("5a3a1e"), "w": Color("a8743a")})


static func exit_sign() -> Texture2D:
	return from_rows("exit_sign", SIGN_ROWS, {"g": Color("2f7a3a"), "w": Color("f0f0e0"), "p": Color("6a6a6a")})


static func bullet() -> Texture2D:
	return painted("bullet", 3, 1, func(_x: int, _y: int) -> Color: return Color("ffe070"))


## A 16x16 speckled dirt tile (no top edge; see ground_block).
static func ground_tile(dirt: Color) -> Texture2D:
	return painted("ground_" + dirt.to_html(), 16, 16, func(x: int, y: int) -> Color:
		var speck := _hash(x, y) % 7
		if speck == 0:
			return dirt.darkened(0.25)
		if speck == 1:
			return dirt.lightened(0.1)
		return dirt)


## A block of ground: speckled dirt with a 2-pixel lighter top edge.
static func ground_block(top: Color, dirt: Color, pos: Vector2, size: Vector2) -> Node2D:
	var block := Node2D.new()
	block.add_child(tiled(ground_tile(dirt), pos, size))
	block.add_child(tiled(solid(top), pos, Vector2(size.x, 2)))
	return block


static func brick_tile(color: Color) -> Texture2D:
	return painted("brick_" + color.to_html(), 16, 8, func(x: int, y: int) -> Color:
		var offset := 0 if y < 4 else 8
		if y == 3 or y == 7 or (x + offset) % 16 == 0:
			return color.darkened(0.4)
		return color)


static func plank_tile(color: Color) -> Texture2D:
	return painted("plank_" + color.to_html(), 16, 6, func(x: int, y: int) -> Color:
		if y == 0:
			return color.lightened(0.2)
		if y == 5 or x % 16 == 15:
			return color.darkened(0.4)
		return color)


static func solid(color: Color) -> Texture2D:
	return painted("solid_" + color.to_html(), 1, 1, func(_x: int, _y: int) -> Color: return color)


## Makes a Sprite2D that tiles a texture over a w x h pixel area, top-left at pos.
static func tiled(texture: Texture2D, pos: Vector2, size: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.position = pos
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2.ZERO, size)
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	return sprite


## Makes a Sprite2D whose bottom-center sits at pos (feet on the ground).
static func standing(texture: Texture2D, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = true
	sprite.offset = Vector2(0, -texture.get_height() / 2.0)
	sprite.position = pos
	return sprite


static func _hash(x: int, y: int) -> int:
	return absi((x * 73856093) ^ (y * 19349663)) % 1000

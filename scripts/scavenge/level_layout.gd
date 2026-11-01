class_name LevelLayout
extends RefCounted
## Builds a random side-scrolling scavenging level out of chunks: flat
## ground, gaps, steps, floating platforms and buildings with a roof to
## climb. It only decides where things go; ScavengeScreen draws them.
## Sizes are checked against the jump: about 50 px high and 60 px across.
## About half the levels hide a secret stash: faint ledges climbing high
## above the street, with a golden crate at the top.
## Level pieces: hazards (fire, spikes, toxic puddles, live wires, quicksand,
## water), moving platforms (elevators, sliders over pits, platforms that
## fall when you stand on them), ladders up tall buildings, indoor rooms, and
## region pieces (subway trenches, hay bales and barns, cliffs, dunes, swamps).

const TILE := 16.0
const GROUND_BOTTOM := 200.0
const STASH_CHANCE := 0.5
## How far each hidden ledge is above the one below (the jump reaches ~50).
const STASH_STEP_RISE := 40.0

## Each solid: {"rect": Rect2, "kind": "ground" | "platform" | "building" | "secret"}.
var solids: Array[Dictionary] = []
var enemy_spots: Array[Vector2] = []
var crate_spots: Array[Vector2] = []
## Where the golden crate sits, if this level has a hidden stash.
var stash_spots: Array[Vector2] = []
## {"rect": Rect2, "kind": "fire" | "spikes" | "toxic" | "wire" | "quicksand" | "water"}
var hazards: Array[Dictionary] = []
## {"rect": Rect2, "kind": "elevator" | "slider" | "falling", "travel": Vector2, "period": float}
var movers: Array[Dictionary] = []
var ladders: Array[Rect2] = []
## Dark backgrounds behind indoor rooms.
var rooms: Array[Rect2] = []
## Things drawn but not solid: {"rect": Rect2, "kind": "rails"}.
var decor: Array[Dictionary] = []
var player_start := Vector2(16, 0)
## Boss levels: a short run of chunks, then a wide arena where the boss waits.
var has_boss := false
var boss_spot := Vector2.ZERO
var arena := Rect2()
var exit_spot := Vector2.ZERO
var width := 0.0


## Chunk kinds and how often they come up.
const CHUNK_WEIGHTS: Dictionary = {
	"flat": 3.0, "gap": 2.0, "step": 2.0, "platform": 2.0, "building": 2.0,
	"hazard": 2.0, "elevator": 1.0, "slider": 1.0, "falling": 1.0, "ladder": 1.0, "room": 1.5, "region": 2.5,
}
const HAZARD_KINDS: Array[String] = ["fire", "spikes", "toxic", "wire"]


static func generate(rng: RandomNumberGenerator, difficulty: int, boss := false, region := "") -> LevelLayout:
	var layout := LevelLayout.new()
	var x := -64.0
	var height := 0
	layout._ground(x, 224.0, height)
	x = 160.0
	var enemy_chance := minf(0.55 + difficulty * 0.04, 0.9)
	var chunks := 4 if boss else 9 + mini(difficulty, 7)
	var stash_chunk := rng.randi_range(1, chunks - 2) if rng.randf() < STASH_CHANCE else -1
	for index: int in chunks:
		if index == stash_chunk:
			x = layout._stash_chunk(rng, x, height)
			continue
		match _pick_chunk(rng):
			"flat":
				x = layout._flat_chunk(rng, x, height, enemy_chance)
			"gap":
				x = layout._gap_chunk(rng, x, height, enemy_chance)
			"step":
				height = clampi(height + (1 if rng.randf() < 0.5 else -1), 0, 3)
				x = layout._flat_chunk(rng, x, height, enemy_chance)
			"platform":
				x = layout._platform_chunk(rng, x, height, enemy_chance)
			"building":
				x = layout._building_chunk(rng, x, height, enemy_chance)
			"hazard":
				x = layout._hazard_chunk(rng, x, height, HAZARD_KINDS[rng.randi_range(0, HAZARD_KINDS.size() - 1)])
			"elevator":
				x = layout._elevator_chunk(rng, x, height, enemy_chance)
			"slider":
				x = layout._slider_chunk(rng, x, height)
			"falling":
				x = layout._falling_chunk(rng, x, height)
			"ladder":
				x = layout._ladder_chunk(rng, x, height, enemy_chance)
			"room":
				x = layout._room_chunk(rng, x, height, enemy_chance, "brick")
			_:
				x = layout._region_chunk(rng, x, height, enemy_chance, region)
	if boss:
		x = layout._boss_arena(x, height)
	var final_width := 14 * TILE
	layout._ground(x, final_width, height)
	layout.exit_spot = Vector2(x + 10 * TILE, _top(height))
	layout.width = x + final_width
	return layout


static func _top(height: int) -> float:
	return -height * TILE


func _ground(x: float, w: float, height: int) -> void:
	var top := _top(height)
	solids.append({"rect": Rect2(x, top, w, GROUND_BOTTOM - top), "kind": "ground"})


func _solid(rect: Rect2, kind: String) -> void:
	solids.append({"rect": rect, "kind": kind})


func _maybe_enemy(rng: RandomNumberGenerator, spot: Vector2, chance: float) -> void:
	if rng.randf() < chance:
		enemy_spots.append(spot)


func _flat_chunk(rng: RandomNumberGenerator, x: float, height: int, enemy_chance: float) -> float:
	var w := rng.randi_range(6, 10) * TILE
	_ground(x, w, height)
	_maybe_enemy(rng, Vector2(x + w * 0.5, _top(height)), enemy_chance)
	if rng.randf() < 0.4:
		crate_spots.append(Vector2(x + w * 0.75, _top(height)))
	return x + w


func _gap_chunk(rng: RandomNumberGenerator, x: float, height: int, enemy_chance: float) -> float:
	x += rng.randi_range(2, 3) * TILE
	var w := rng.randi_range(5, 8) * TILE
	_ground(x, w, height)
	_maybe_enemy(rng, Vector2(x + w * 0.6, _top(height)), enemy_chance)
	return x + w


func _platform_chunk(rng: RandomNumberGenerator, x: float, height: int, enemy_chance: float) -> float:
	var w := 10 * TILE
	var top := _top(height)
	_ground(x, w, height)
	var platform := Rect2(x + 3 * TILE, top - 2 * TILE, 3 * TILE, 6)
	_solid(platform, "platform")
	crate_spots.append(Vector2(platform.get_center().x, platform.position.y))
	_maybe_enemy(rng, Vector2(x + w * 0.85, top), enemy_chance)
	return x + w


func _building_chunk(rng: RandomNumberGenerator, x: float, height: int, enemy_chance: float) -> float:
	var w := 12 * TILE
	var top := _top(height)
	_ground(x, w, height)
	_solid(Rect2(x + 2 * TILE, top - 2 * TILE, 2 * TILE, 6), "platform")
	var building := Rect2(x + 5 * TILE, top - 4 * TILE, 5 * TILE, 4 * TILE)
	_solid(building, "building")
	crate_spots.append(Vector2(building.position.x + building.size.x * 0.7, building.position.y))
	_maybe_enemy(rng, Vector2(building.position.x + building.size.x * 0.3, building.position.y), enemy_chance * 0.7)
	_maybe_enemy(rng, Vector2(x + w - TILE, top), enemy_chance * 0.5)
	return x + w


## Flat ground with faint ledges zig-zagging up to a golden crate.
func _stash_chunk(rng: RandomNumberGenerator, x: float, height: int) -> float:
	var w := 12 * TILE
	var top := _top(height)
	_ground(x, w, height)
	var ledge_x := x + 2 * TILE
	var ledge_y := top
	var direction := 1.0
	for step: int in 3:
		ledge_y -= STASH_STEP_RISE
		ledge_x += direction * 40.0
		direction = -direction
		_solid(Rect2(ledge_x, ledge_y, 24, 6), "secret")
	stash_spots.append(Vector2(ledge_x + 12, ledge_y))
	if rng.randf() < 0.5:
		enemy_spots.append(Vector2(x + w - TILE, top))
	return x + w


## A wide, flat arena with two ledges to dodge onto. The boss waits in the middle.
func _boss_arena(x: float, height: int) -> float:
	var w := 32 * TILE
	var top := _top(height)
	_ground(x, w, height)
	_solid(Rect2(x + 6 * TILE, top - 2 * TILE, 4 * TILE, 6), "platform")
	_solid(Rect2(x + w - 10 * TILE, top - 2 * TILE, 4 * TILE, 6), "platform")
	has_boss = true
	boss_spot = Vector2(x + w * 0.6, top - 1)
	arena = Rect2(x, top - 8 * TILE, w, 8 * TILE)
	return x + w


static func _pick_chunk(rng: RandomNumberGenerator) -> String:
	var total := 0.0
	for kind: String in CHUNK_WEIGHTS:
		total += float(CHUNK_WEIGHTS[kind])
	var roll := rng.randf() * total
	for kind: String in CHUNK_WEIGHTS:
		roll -= float(CHUNK_WEIGHTS[kind])
		if roll <= 0.0:
			return kind
	return "flat"


func _hazard(rect: Rect2, kind: String) -> void:
	hazards.append({"rect": rect, "kind": kind})


## Flat ground with a strip of hazard to jump over (about 3 tiles wide).
func _hazard_chunk(rng: RandomNumberGenerator, x: float, height: int, kind: String) -> float:
	var w := 10 * TILE
	var top := _top(height)
	_ground(x, w, height)
	var strip := rng.randi_range(2, 3) * TILE
	_hazard(Rect2(x + (w - strip) / 2.0, top - 6, strip, 6), kind)
	return x + w


## A building too tall to jump onto, with an elevator beside it. Crate on the roof.
func _elevator_chunk(rng: RandomNumberGenerator, x: float, height: int, enemy_chance: float) -> float:
	var w := 12 * TILE
	var top := _top(height)
	_ground(x, w, height)
	var building := Rect2(x + 5 * TILE, top - 5 * TILE, 5 * TILE, 5 * TILE)
	_solid(building, "building")
	movers.append({"rect": Rect2(x + 2 * TILE, top - 6, 2 * TILE, 6), "kind": "elevator",
		"travel": Vector2(0, -5 * TILE), "period": 4.0})
	crate_spots.append(Vector2(building.get_center().x, building.position.y))
	_maybe_enemy(rng, Vector2(building.position.x + building.size.x - 8, building.position.y), enemy_chance * 0.6)
	return x + w


## A pit too wide to jump, with a platform sliding back and forth across it.
func _slider_chunk(rng: RandomNumberGenerator, x: float, height: int) -> float:
	var top := _top(height)
	_ground(x, 4 * TILE, height)
	var pit := rng.randi_range(6, 7) * TILE
	var start := x + 4 * TILE
	movers.append({"rect": Rect2(start, top - 6, 2 * TILE, 6), "kind": "slider",
		"travel": Vector2(pit - 2 * TILE, 0), "period": 5.0})
	_ground(start + pit, 5 * TILE, height)
	return start + pit + 5 * TILE


## A pit with two stepping platforms that drop soon after you land on them.
func _falling_chunk(_rng: RandomNumberGenerator, x: float, height: int) -> float:
	var top := _top(height)
	_ground(x, 4 * TILE, height)
	var start := x + 4 * TILE
	for step: int in 2:
		movers.append({"rect": Rect2(start + 2 * TILE + step * 4 * TILE, top - 6, 2 * TILE, 6), "kind": "falling",
			"travel": Vector2.ZERO, "period": 0.0})
	var pit := 10 * TILE
	_ground(start + pit, 5 * TILE, height)
	return start + pit + 5 * TILE


## A tall building with a ladder up its side, and loot on the roof.
func _ladder_chunk(rng: RandomNumberGenerator, x: float, height: int, enemy_chance: float) -> float:
	var w := 12 * TILE
	var top := _top(height)
	_ground(x, w, height)
	var building := Rect2(x + 4 * TILE, top - 6 * TILE, 6 * TILE, 6 * TILE)
	_solid(building, "building")
	ladders.append(Rect2(building.position.x - 12, building.position.y - 14, 12, building.size.y + 14))
	crate_spots.append(Vector2(building.position.x + building.size.x * 0.6, building.position.y))
	_maybe_enemy(rng, Vector2(building.end.x - 8, building.position.y), enemy_chance * 0.6)
	return x + w


## A building you can walk into: doors on both sides, a roof to stand on,
## a darker room with loot and an enemy inside. style: "brick" or "barn".
func _room_chunk(rng: RandomNumberGenerator, x: float, height: int, enemy_chance: float, style: String) -> float:
	var w := 14 * TILE
	var top := _top(height)
	_ground(x, w, height)
	var room := Rect2(x + 2 * TILE, top - 4 * TILE, 10 * TILE, 4 * TILE)
	rooms.append(room)
	var wall_kind := "barn" if style == "barn" else "building"
	_solid(Rect2(room.position.x, room.position.y - 8, room.size.x, 8), wall_kind)
	_solid(Rect2(room.position.x, room.position.y, 8, room.size.y - 28), wall_kind)
	_solid(Rect2(room.end.x - 8, room.position.y, 8, room.size.y - 28), wall_kind)
	_solid(Rect2(x, top - 2 * TILE - 4, 2 * TILE, 6), "platform")
	crate_spots.append(Vector2(room.position.x + room.size.x * 0.35, top))
	if rng.randf() < 0.5:
		crate_spots.append(Vector2(room.position.x + room.size.x * 0.7, top))
	_maybe_enemy(rng, Vector2(room.get_center().x, top), enemy_chance)
	return x + w


## A piece that belongs to the region the level is in.
func _region_chunk(rng: RandomNumberGenerator, x: float, height: int, enemy_chance: float, region: String) -> float:
	match region:
		"northeast":
			return _subway_chunk(rng, x, height, enemy_chance)
		"midwest":
			return _hay_chunk(rng, x, height, enemy_chance) if rng.randf() < 0.5 else _room_chunk(rng, x, height, enemy_chance, "barn")
		"mountains":
			return _cliff_chunk(rng, x, height, enemy_chance)
		"desert":
			return _dunes_chunk(rng, x, height)
		"south":
			return _swamp_chunk(rng, x, height)
	return _flat_chunk(rng, x, height, enemy_chance)


## A sunken subway trench: steps down, rails along the bottom, steps up.
func _subway_chunk(rng: RandomNumberGenerator, x: float, height: int, enemy_chance: float) -> float:
	_ground(x, 2 * TILE, height - 1)
	var floor_width := 10 * TILE
	_ground(x + 2 * TILE, floor_width, height - 2)
	decor.append({"rect": Rect2(x + 2 * TILE, _top(height - 2) - 2, floor_width, 2), "kind": "rails"})
	if rng.randf() < 0.5:
		_hazard(Rect2(x + 6 * TILE, _top(height - 2) - 6, 2 * TILE, 6), "wire")
	crate_spots.append(Vector2(x + 4 * TILE, _top(height - 2)))
	_maybe_enemy(rng, Vector2(x + 10 * TILE, _top(height - 2)), enemy_chance)
	_ground(x + 12 * TILE, 2 * TILE, height - 1)
	return x + 14 * TILE


## Stacks of hay bales to hop across.
func _hay_chunk(rng: RandomNumberGenerator, x: float, height: int, enemy_chance: float) -> float:
	var w := 12 * TILE
	var top := _top(height)
	_ground(x, w, height)
	var bale_x := x + 2 * TILE
	for stack: int in 3:
		var bales := rng.randi_range(1, 2)
		for level: int in bales:
			_solid(Rect2(bale_x, top - (level + 1) * 12, 20, 12), "hay")
		bale_x += 3 * TILE
	crate_spots.append(Vector2(x + 2 * TILE + 10, top - 24))
	_maybe_enemy(rng, Vector2(x + w - TILE, top), enemy_chance)
	return x + w


## A cliff three tiles high: climb the ladder (or find another way up).
func _cliff_chunk(rng: RandomNumberGenerator, x: float, height: int, enemy_chance: float) -> float:
	_ground(x, 5 * TILE, height)
	var cliff_x := x + 5 * TILE
	ladders.append(Rect2(cliff_x - 12, _top(height + 3) - 14, 12, 3 * TILE + 14))
	_ground(cliff_x, 6 * TILE, height + 3)
	crate_spots.append(Vector2(cliff_x + 3 * TILE, _top(height + 3)))
	_maybe_enemy(rng, Vector2(cliff_x + 5 * TILE, _top(height + 3)), enemy_chance)
	# Steps back down to the normal height.
	_ground(cliff_x + 6 * TILE, 2 * TILE, height + 2)
	_ground(cliff_x + 8 * TILE, 2 * TILE, height + 1)
	return cliff_x + 10 * TILE


## Rolling dunes with a patch of quicksand in a dip.
func _dunes_chunk(rng: RandomNumberGenerator, x: float, height: int) -> float:
	var heights: Array[int] = [height, height + 1, height, height - 1, height, height + 1, height]
	for index: int in heights.size():
		_ground(x + index * 2 * TILE, 2 * TILE, heights[index])
	_hazard(Rect2(x + 6 * TILE, _top(height - 1) - 6, 2 * TILE, 6), "quicksand")
	if rng.randf() < 0.5:
		crate_spots.append(Vector2(x + 2 * TILE + 16, _top(height + 1)))
	return x + heights.size() * 2 * TILE


## Swamp: shallow water that slows you down, and a boardwalk over a deeper pit.
func _swamp_chunk(rng: RandomNumberGenerator, x: float, height: int) -> float:
	var top := _top(height)
	_ground(x, 8 * TILE, height)
	_hazard(Rect2(x + 2 * TILE, top - 6, 5 * TILE, 6), "water")
	var start := x + 8 * TILE
	var pit := 6 * TILE
	_solid(Rect2(start + 2 * TILE, top - 4, 2 * TILE, 6), "platform")
	_hazard(Rect2(start, top + 3 * TILE, pit, 6), "water")
	_ground(start + pit, 4 * TILE, height)
	if rng.randf() < 0.5:
		crate_spots.append(Vector2(start + 3 * TILE, top - 4))
	return start + pit + 4 * TILE

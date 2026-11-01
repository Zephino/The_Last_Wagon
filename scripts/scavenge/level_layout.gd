class_name LevelLayout
extends RefCounted
## Builds a random side-scrolling scavenging level out of chunks: flat
## ground, gaps, steps, floating platforms and buildings with a roof to
## climb. It only decides where things go; ScavengeScreen draws them.
## Sizes are checked against the jump: about 50 px high and 60 px across.
## About half the levels hide a secret stash: faint ledges climbing high
## above the street, with a golden crate at the top.

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
var player_start := Vector2(16, 0)
## Boss levels: a short run of chunks, then a wide arena where the boss waits.
var has_boss := false
var boss_spot := Vector2.ZERO
var arena := Rect2()
var exit_spot := Vector2.ZERO
var width := 0.0


static func generate(rng: RandomNumberGenerator, difficulty: int, boss := false) -> LevelLayout:
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
		match rng.randi_range(0, 4):
			0:
				x = layout._flat_chunk(rng, x, height, enemy_chance)
			1:
				x = layout._gap_chunk(rng, x, height, enemy_chance)
			2:
				height = clampi(height + (1 if rng.randf() < 0.5 else -1), 0, 3)
				x = layout._flat_chunk(rng, x, height, enemy_chance)
			3:
				x = layout._platform_chunk(rng, x, height, enemy_chance)
			_:
				x = layout._building_chunk(rng, x, height, enemy_chance)
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

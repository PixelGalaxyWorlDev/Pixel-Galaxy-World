# =====================================================================
# PIXEL GALAXY FRONTIER — RimWorld-inspired colony survival (Android)
# Single-file architecture for Godot Android Editor compatibility.
# Godot 4.3 · GL Compatibility · landscape touch UI
# =====================================================================
extends Node2D

# ========================================================== CONFIG =====
const VIEW_SIZE := Vector2(909.0, 513.0)
const WORLD_SIZE := Vector2(64, 36)          # grid cells
const TILE := 32.0
const WORLD_PX := Vector2(64.0 * 32.0, 36.0 * 32.0)  # 2048 x 1152

const DAY_LENGTH := 300.0                    # seconds (game time) per day
const NIGHT_START := 0.70
const NIGHT_END := 0.98
const WIN_DAY := 30

const SAVE_PATH := "user://pixel_galaxy_frontier.save"

const COLONIST_SPEED := 55.0                 # px/sec walk
const NEED_DECAY_HUNGER := 0.55              # per game-second
const NEED_DECAY_SLEEP := 0.45
const NEED_DECAY_MOOD := 0.022               # ~6.6/day: gentle baseline
const MOOD_HUNGER_PENALTY := 2.5             # extra mood drain when starving
const MOOD_SLEEP_PENALTY := 2.0
const MOOD_RECOVER := 0.05                   # mood regen when fed & rested
const MENTAL_BREAK_MOOD := 12.0              # below this -> binging/wander
const EAT_HUNGER_TRIGGER := 32.0
const EAT_AMOUNT := 45.0
const SLEEP_TRIGGER := 25.0
const HEAL_RATE := 0.6                       # hp per game-second when resting
const DOWNED_HP := 0.0
const MEDKIT_HEAL := 35.0

const COLONIST_ATTACK_RANGE := 34.0
const COLONIST_ATTACK_CD := 0.9
const COLONIST_DMG := 10.0

const MONSTER_STATS := {
	"slime":   {"hp": 46.0,  "dmg": 8.0,  "speed": 30.0, "cd": 1.2, "atk_range": 30.0, "wall_dmg": 8.0},
	"zapper":  {"hp": 38.0,  "dmg": 12.0, "speed": 48.0, "cd": 1.4, "atk_range": 34.0, "wall_dmg": 5.0},
	"golem":   {"hp": 120.0, "dmg": 22.0, "speed": 18.0, "cd": 2.0, "atk_range": 32.0, "wall_dmg": 25.0},
	"stalker": {"hp": 55.0,  "dmg": 14.0, "speed": 60.0, "cd": 1.0, "atk_range": 34.0, "wall_dmg": 6.0},
	"bat":     {"hp": 26.0,  "dmg": 7.0,  "speed": 75.0, "cd": 1.1, "atk_range": 28.0, "wall_dmg": 3.0},
}
const MONSTER_WALL_RANGE := 36.0

const BUILDINGS := {
	"wall_wood":  {"tex": "wall",       "cost": {"wood": 4},                     "hp": 80.0,  "name": "Dinding Kayu",  "block": true,  "size": Vector2i(1, 1)},
	"wall_stone": {"tex": "wall_stone", "cost": {"stone": 5},                    "hp": 180.0, "name": "Dinding Batu", "block": true,  "size": Vector2i(1, 1)},
	"door":       {"tex": "door",       "cost": {"wood": 3},                     "hp": 60.0,  "name": "Pintu",        "block": false, "size": Vector2i(1, 1)},
	"bed":        {"tex": "bed",        "cost": {"wood": 6},                     "hp": 50.0,  "name": "Kasur",        "block": false, "size": Vector2i(1, 2)},
	"farm":       {"tex": "farm",       "cost": {"wood": 2},                     "hp": 40.0,  "name": "Kebun",        "block": false, "size": Vector2i(2, 2)},
	"stove":      {"tex": "stove",      "cost": {"stone": 6, "wood": 2},         "hp": 70.0,  "name": "Tungku",       "block": true,  "size": Vector2i(1, 1)},
	"storage":    {"tex": "storage",    "cost": {"wood": 5},                     "hp": 60.0,  "name": "Gudang",       "block": false, "size": Vector2i(2, 2)},
	"turret":     {"tex": "turret",     "cost": {"metal": 4, "stone": 2},        "hp": 90.0,  "name": "Turret",       "block": true,  "size": Vector2i(1, 1)},
	"lamp":       {"tex": "lamp",       "cost": {"metal": 1, "crystal": 1},      "hp": 30.0,  "name": "Lampu",        "block": false, "size": Vector2i(1, 1)},
}

# --- Resource nodes ---
const NODE_DEF := {
	"tree":    {"tex": "tree",    "hp": 40.0,  "yield": {"wood": 5},     "regrow": 180.0, "blockish": true},
	"rock":    {"tex": "rock",    "hp": 60.0,  "yield": {"stone": 4},    "regrow": 0.0,   "blockish": true},
	"metal":   {"tex": "metal",   "hp": 80.0,  "yield": {"metal": 3},    "regrow": 0.0,   "blockish": false},
	"crystal": {"tex": "crystal", "hp": 100.0, "yield": {"crystal": 2},  "regrow": 0.0,   "blockish": false},
	"berry":   {"tex": "berry",   "hp": 20.0,  "yield": {"raw_food": 4}, "regrow": 150.0, "blockish": false},
}

# ============================================================ STATE ======
var mode := "menu"                          # menu | game | over
var paused := false
var game_speed := 1.0
var audio_enabled := true
var day := 1
var time_of_day := 0.25
var danger_level := 0.0

var camera_offset := Vector2(300.0, 300.0)
var build_mode := ""                        # "" or building key
var build_valid := false
var build_pos := Vector2i(-1, -1)
var selected_colonist := 0
var open_menu := ""                         # "" | "build" | "help"

var wood := 24
var stone := 12
var metal := 0
var crystal := 0
var raw_food := 8
var food := 4
var medkits := 2

var rng := RandomNumberGenerator.new()
var textures: Dictionary = {}
var audio_bus_ok := false

var ground := {}                            # Vector2i -> "grass"/"dirt"/"sand"...
var resource_nodes: Array = []              # [{kind,pos,cell,hp,regrow_t}]
var buildings: Array = []                   # [{kind,cell,hp,...}]
var drops: Array = []                       # [{res,pos,qty,cell}] on-ground drops
var monsters: Array = []                    # [{kind,pos,hp,cd,path,path_i,...}]
var colonists: Array = []                   # see _make_colonist
var bullets: Array = []                     # [{pos,vel,ttl,dmg}]
var effects: Array = []                     # [{pos,tex,t,ttl}]

var blocked: Dictionary = {}                # Vector2i -> true (walls + solid nodes)
var night_spawn_timer := 6.0
var raid_timer := 240.0
var alert_text := ""
var alert_sub := ""
var alert_time := 0.0
var autosave_timer := 10.0
var tutorial_seen := false
var tuto_step := 0
var stat_kills := 0

var dragging := false
var drag_start := Vector2.ZERO
var drag_cam_start := Vector2.ZERO
var last_tap_time := 0.0
var last_tap_pos := Vector2.ZERO

# ====================================================== ASSET LOADING ===
func _load_assets() -> void:
	var base := "res://project/resources/"
	var required := {
		"menu_bg": base + "menu/menu-background.png",
		"title": base + "menu/title-art.png",
		"grass": base + "tiles/grass.png",
		"grass_flowers": base + "tiles/grass-flowers.png",
		"grass_mushroom": base + "tiles/grass-mushroom.png",
		"dirt": base + "tiles/dirt.png",
		"dirt_pebbles": base + "tiles/dirt-pebbles.png",
		"sand": base + "tiles/sand.png",
		"rocky": base + "tiles/rocky.png",
		"path_stone": base + "tiles/path-stone.png",
		"water": base + "tiles/water.png",
		"wall": base + "buildings/building-10.png",
		"wall_stone": base + "buildings/building-2.png",
		"door": base + "buildings/building-12.png",
		"bed": base + "buildings/building-18.png",
		"farm": base + "buildings/building-13.png",
		"stove": base + "buildings/building-11.png",
		"storage": base + "buildings/building-20.png",
		"turret": base + "buildings/building-5.png",
		"lamp": base + "buildings/building-15.png",
		"campfire": base + "buildings/building-8.png",
		"pod": base + "buildings/building-9.png",
		"tree": base + "items/item-0.png",
		"rock": base + "items/item-1.png",
		"metal": base + "items/item-2.png",
		"crystal": base + "items/item-3.png",
		"berry": base + "items/item-4.png",
		"drop_wood": base + "items/item-19.png",
		"drop_stone": base + "items/item-14.png",
		"drop_metal": base + "items/item-18.png",
		"drop_crystal": base + "items/item-6.png",
		"drop_food": base + "items/item-7.png",
		"drop_raw": base + "items/item-16.png",
		"medkit": base + "items/item-17.png",
		"fx_hit": base + "effects/fx-0.png",
		"fx_boom": base + "effects/fx-2.png",
		"fx_zap": base + "effects/fx-10.png",
		"bullet": base + "effects/fx-6.png",
	}
	for key in required.keys():
		var t = load(required[key])
		if t != null:
			textures[key] = t
		else:
			push_warning("Missing asset: " + required[key])
	# character frames: rex/luna/bolt 0..5
	for who in ["rex", "luna", "bolt"]:
		for i in range(6):
			var t = load(base + "characters/%s-%d.png" % [who, i])
			if t != null:
				textures["%s%d" % [who, i]] = t
	# monsters frames 0..5
	for m in MONSTER_STATS.keys():
		for i in range(6):
			var t = load(base + "monsters/%s-%d.png" % [m, i])
			if t != null:
				textures["%s%d" % [m, i]] = t

# ============================================================ READY ======
func _ready() -> void:
	rng.seed = 1337
	_load_assets()
	_setup_audio()
	_show_menu()

func _setup_audio() -> void:
	if not has_node("MusicPlayer"):
		var p := AudioStreamPlayer.new()
		p.name = "MusicPlayer"
		add_child(p)
	if not has_node("SfxPlayer"):
		var s := AudioStreamPlayer.new()
		s.name = "SfxPlayer"
		add_child(s)

func _play_music(file_name: String) -> void:
	if not audio_enabled:
		return
	var p := get_node_or_null("MusicPlayer")
	if p == null:
		return
	var stream = load("res://project/resources/audio/" + file_name)
	if stream == null:
		return
	p.stream = stream
	p.volume_db = -6.0
	p.play()

func _stop_music() -> void:
	var p := get_node_or_null("MusicPlayer")
	if p != null:
		p.stop()

func _play_sfx(file_name: String, vol_db := -8.0) -> void:
	if not audio_enabled:
		return
	var p := get_node_or_null("SfxPlayer")
	if p == null:
		return
	var stream = load("res://project/resources/audio/" + file_name)
	if stream == null:
		return
	p.stream = stream
	p.volume_db = vol_db
	p.play()

# ========================================================= MENU / MODE ===
func _show_menu() -> void:
	mode = "menu"
	_play_music("menu.wav")

func _start_new_game() -> void:
	_reset_world()
	mode = "game"
	_play_music("ambient.wav")
	_set_alert("HARI 1", "Bertahan sampai hari %d. Tap kolonis, lalu tap tujuan." % WIN_DAY)
	if not tutorial_seen:
		tutorial_seen = true
		tuto_step = 1
	_save_game()

func _finish_game(title: String, sub: String) -> void:
	mode = "over"
	paused = true
	alert_text = title
	alert_sub = sub
	_play_sfx("alert.wav", -4.0)

# ====================================================== WORLD GENERATION =
func _reset_world() -> void:
	ground.clear()
	resource_nodes.clear()
	buildings.clear()
	drops.clear()
	monsters.clear()
	bullets.clear()
	effects.clear()
	blocked.clear()
	day = 1
	time_of_day = 0.25
	paused = false
	game_speed = 1.0
	wood = 24
	stone = 12
	metal = 0
	crystal = 0
	raw_food = 8
	food = 4
	medkits = 2
	stat_kills = 0
	selected_colonist = 0
	build_mode = ""
	open_menu = ""
	raid_timer = 240.0
	night_spawn_timer = 6.0
	camera_offset = Vector2(320.0, 320.0)
	alert_text = ""
	alert_sub = ""
	# --- terrain: grass base with patches ---
	for x in range(int(WORLD_SIZE.x)):
		for y in range(int(WORLD_SIZE.y)):
			var n := _noise2(x, y)
			var kind := "grass"
			if n > 0.82:
				kind = "rocky"
			elif n > 0.74:
				kind = "dirt"
			elif n < 0.12:
				kind = "sand"
			if kind == "grass":
				var r := rng.randf()
				if r < 0.06:
					kind = "grass_flowers"
				elif r < 0.10:
					kind = "grass_mushroom"
				elif r < 0.16:
					kind = "dirt_pebbles"
			ground[Vector2i(x, y)] = kind
	# water border lake top-right (visual, not blocking)
	for x in range(48, 64):
		for y in range(0, 7):
			if Vector2(x, y).distance_to(Vector2(60, 3)) < 6.5:
				ground[Vector2i(x, y)] = "water"
	# --- resource nodes ---
	_spawn_resource_field("tree", 26, Vector2i(6, 6), Vector2i(58, 30), true)
	_spawn_resource_field("rock", 10, Vector2i(4, 4), Vector2i(60, 32), false)
	_spawn_resource_field("metal", 7, Vector2i(40, 20), Vector2i(62, 34), false)
	_spawn_resource_field("crystal", 5, Vector2i(44, 24), Vector2i(62, 34), false)
	_spawn_resource_field("berry", 8, Vector2i(8, 8), Vector2i(50, 30), true)
	# --- starting buildings: crash pod + campfire ---
	_place_building("pod", Vector2i(12, 16))       # decorative spawn beacon
	_place_building("campfire", Vector2i(14, 16))
	# --- colonists ---
	colonists = [
		_make_colonist("Rex", "fighter", Vector2(13.5 * TILE, 14.5 * TILE)),
		_make_colonist("Luna", "harvester", Vector2(14.5 * TILE, 15.5 * TILE)),
		_make_colonist("Bolt", "builder", Vector2(15.5 * TILE, 16.5 * TILE)),
	]
	for i in range(colonists.size()):
		colonists[i]["index"] = i
	_rebuild_blocked()

func _make_colonist(cname: String, role: String, pos: Vector2) -> Dictionary:
	return {
		"name": cname,
		"role": role,
		"pos": pos,
		"hp": 100.0,
		"max_hp": 100.0,
		"hunger": 100.0,
		"sleep": 100.0,
		"mood": 100.0,
		"downed": false,
		"dead": false,
		"job": "",
		"target": -1,
		"work_t": 0.0,
		"path": [],
		"path_i": 0,
		"frame_t": 0.0,
		"face": 1,
		"anim": "idle",
		"break_t": 0.0,
		"break_kind": "",
		"binge_t": 0.0,
		"downed_t": 0.0,
		"index": 0,
	}

# simple deterministic hash noise for terrain patches
func _noise2(x: int, y: int) -> float:
	var h := 2166136261
	var v := Vector2i(x, y)
	for i in range(2):
		var vv: int = v.x if i == 0 else v.y
		h = (h ^ (vv * 16777619)) % 2147483647
		h = (h * 31 + 17) % 2147483647
	return float(h % 1000) / 1000.0

func _spawn_resource_field(kind: String, count: int, lo: Vector2i, hi: Vector2i, avoid_center: bool) -> void:
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 30:
		tries += 1
		var cell := Vector2i(rng.randi_range(lo.x, hi.x), rng.randi_range(lo.y, hi.y))
		if avoid_center and cell.x >= 9 and cell.x <= 19 and cell.y >= 13 and cell.y <= 19:
			continue
		if ground.get(cell, "grass") == "water":
			continue
		if blocked.has(cell):
			continue
		var occupied := false
		for node in resource_nodes:
			if node["cell"] == cell:
				occupied = true
				break
		if occupied:
			continue
		var d: Dictionary = NODE_DEF[kind]
		resource_nodes.append({
			"kind": kind,
			"cell": cell,
			"pos": _cell_center(cell),
			"hp": float(d["hp"]),
			"regrow_t": 0.0,
		})
		placed += 1

# ============================================================ GRID =======
func _in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < int(WORLD_SIZE.x) and cell.y < int(WORLD_SIZE.y)

func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) * TILE + Vector2(TILE * 0.5, TILE * 0.5)

func _world_to_cell(p: Vector2) -> Vector2i:
	return Vector2i(int(floor(p.x / TILE)), int(floor(p.y / TILE)))

func _rebuild_blocked() -> void:
	blocked.clear()
	for node in resource_nodes:
		if node["hp"] > 0.0 and bool(NODE_DEF[node["kind"]].get("blockish", false)):
			blocked[node["cell"]] = true
	for b in buildings:
		var def: Dictionary = BUILDINGS.get(b["kind"], {})
		if not def.is_empty() and bool(def.get("block", false)) and b["hp"] > 0.0:
			blocked[b["cell"]] = true

func _place_building(kind: String, cell: Vector2i) -> void:
	if not _in_bounds(cell):
		return
	# pod & campfire are decorative world objects
	if kind == "pod" or kind == "campfire":
		buildings.append({"kind": kind, "cell": cell, "hp": 999999.0})
		return
	var def: Dictionary = BUILDINGS.get(kind, {})
	if def.is_empty():
		return
	var entry := {
		"kind": kind,
		"cell": cell,
		"hp": float(def["hp"]),
		"needs_build": true,
		"progress": 0.0,
	}
	match kind:
		"farm":
			entry["planted"] = true
			entry["growth"] = 0.0
			entry["grown"] = false
		"door":
			entry["open"] = false
		"turret":
			entry["cd"] = 0.0
	buildings.append(entry)
	_rebuild_blocked()

func _building_at(cell: Vector2i) -> Dictionary:
	for b in buildings:
		if b["cell"] == cell and b["hp"] > 0.0:
			return b
	return {}

func _node_at(cell: Vector2i) -> Dictionary:
	for node in resource_nodes:
		if node["cell"] == cell and node["hp"] > 0.0:
			return node
	return {}

func _can_build_at(cell: Vector2i, size: Vector2i) -> bool:
	for dx in range(size.x):
		for dy in range(size.y):
			var c := cell + Vector2i(dx, dy)
			if not _in_bounds(c):
				return false
			if ground.get(c, "grass") == "water":
				return false
			if blocked.has(c):
				return false
			if not _node_at(c).is_empty():
				return false
			var b: Dictionary = _building_at(c)
			if not b.is_empty() and b["kind"] != "pod" and b["kind"] != "campfire":
				return false
	return true

func _can_afford(cost: Dictionary) -> bool:
	for key in cost.keys():
		if _get_res(key) < int(cost[key]):
			return false
	return true

func _pay_cost(cost: Dictionary) -> void:
	for key in cost.keys():
		_add_res(key, -int(cost[key]))

func _get_res(key: String) -> int:
	match key:
		"wood":
			return wood
		"stone":
			return stone
		"metal":
			return metal
		"crystal":
			return crystal
		"raw_food":
			return raw_food
		"food":
			return food
		"medkits":
			return medkits
	return 0

func _add_res(key: String, amount: int) -> void:
	match key:
		"wood":
			wood += amount
		"stone":
			stone += amount
		"metal":
			metal += amount
		"crystal":
			crystal += amount
		"raw_food":
			raw_food += amount
		"food":
			food += amount
		"medkits":
			medkits += amount

# ====================================================== PATHFINDING ======
func _find_path(from_cell: Vector2i, to_cell: Vector2i, no_fallback := false) -> Array:
	if not _in_bounds(to_cell):
		return []
	if from_cell == to_cell:
		return [to_cell]
	var open: Array = [[_cell_dist(from_cell, to_cell), 0.0, from_cell, from_cell]]
	var g_score := {from_cell: 0.0}
	var came_from := {}
	var iter := 0
	while not open.is_empty() and iter < 2000:
		iter += 1
		# pop lowest f
		var best_i := 0
		var best_f := float(open[0][0])
		for i in range(open.size()):
			if float(open[i][0]) < best_f:
				best_f = float(open[i][0])
				best_i = i
		var current_entry: Array = open[best_i]
		open.remove_at(best_i)
		var current: Vector2i = current_entry[2]
		if current == to_cell:
			# reconstruct
			var path: Array = [current]
			var cur: Vector2i = current
			while came_from.has(cur):
				cur = came_from[cur]
				path.push_front(cur)
			return path
		var nb_dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for dir in nb_dirs:
			var nb: Vector2i = current + dir
			if not _in_bounds(nb):
				continue
			if blocked.has(nb):
				continue
			if ground.get(nb, "grass") == "water":
				continue
			var tentative := float(g_score[current]) + 1.0
			if not g_score.has(nb) or tentative < float(g_score[nb]):
				g_score[nb] = tentative
				came_from[nb] = current
				open.append([tentative + _cell_dist(nb, to_cell), tentative, nb, current])
	# no path: nearest reachable open cell to target (strict mode: give up)
	if no_fallback:
		return []
	return _nearest_open(from_cell, to_cell)

func _nearest_open(from_cell: Vector2i, to_cell: Vector2i) -> Array:
	# A* failed -> to_cell is unreachable (enclosed or water-locked).
	# Find the reachable open cell closest to the target; walk there instead.
	# NOTE: the target cell itself is excluded from the scan - returning it
	# would create a fake 1-hop path that phases actors through walls.
	var best: Vector2i = from_cell
	var best_d := 1e9
	for r in range(1, 6):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if dx == 0 and dy == 0:
					continue
				var c: Vector2i = to_cell + Vector2i(dx, dy)
				if not _in_bounds(c) or blocked.has(c):
					continue
				if ground.get(c, "grass") == "water":
					continue
				var d: float = _cell_dist(c, from_cell)
				if d < best_d:
					best_d = d
					best = c
		if best_d < 1e9:
			break
	if best == from_cell:
		return []
	# strict: if the from-cell is itself enclosed, this returns [] (no recursion)
	return _find_path(from_cell, best, true)

func _cell_dist(a: Vector2i, b: Vector2i) -> float:
	var dx: float = absf(a.x - b.x)
	var dy: float = absf(a.y - b.y)
	return maxf(dx, dy) + 0.42 * minf(dx, dy)

# ============================================================ JOBS =======
const JOB_WORK := {
	"harvest": 1.6, "build": 1.4, "haul": 0.8, "rescue": 1.2,
	"farm": 1.5, "cook": 2.0, "heal": 2.2,
}

func _assign_jobs() -> void:
	for i in range(colonists.size()):
		var c: Dictionary = colonists[i]
		if c["dead"] or c["downed"] or float(c["break_t"]) > 0.0:
			continue
		var job: String = c["job"]
		if job == "attack" or job == "rescue" or job == "heal" or job == "sleep" or job == "move":
			continue
		if (job == "build" or job == "haul" or job == "farm" or job == "cook") and _job_target_valid(c):
			continue
		if not _job_target_valid(c):
			var picked: Dictionary = _pick_job(c)
			c["job"] = picked["job"]
			c["target"] = picked["target"]
			c["work_t"] = 0.0
			c["path"] = []
			c["path_i"] = 0

func _job_target_valid(c: Dictionary) -> bool:
	var job: String = c["job"]
	var t: int = c["target"]
	match job:
		"harvest":
			return t >= 0 and t < resource_nodes.size() and resource_nodes[t]["hp"] > 0.0
		"build":
			return t >= 0 and t < buildings.size() and bool(buildings[t].get("needs_build", false))
		"haul":
			return t >= 0 and t < drops.size()
		"attack":
			return t >= 0 and t < monsters.size() and monsters[t]["hp"] > 0.0
		"heal":
			return t >= 0 and t < colonists.size() and (colonists[t]["downed"] or float(colonists[t]["hp"]) < float(colonists[t]["max_hp"]) * 0.75)
		"rescue":
			return t >= 0 and t < colonists.size() and bool(colonists[t]["downed"])
		"farm":
			return t >= 0 and t < buildings.size() and buildings[t]["kind"] == "farm" and bool(buildings[t].get("grown", false))
		"cook":
			return t >= 0 and t < buildings.size() and buildings[t]["kind"] == "stove" and raw_food >= 3
		"move":
			return not (c["path"] as Array).is_empty()
		"sleep":
			return t >= 0 and t < buildings.size() and buildings[t]["kind"] == "bed" and float(c["sleep"]) < 99.5
	return false

func _pick_job(c: Dictionary) -> Dictionary:
	# 1) rescue downed colonists
	for j in range(colonists.size()):
		if j != int(c["index"]) and bool(colonists[j]["downed"]) and not bool(colonists[j]["dead"]):
			return {"job": "rescue", "target": j}
	# 2) heal injured (medkits available)
	if medkits > 0:
		for j in range(colonists.size()):
			if j != int(c["index"]) and not bool(colonists[j]["dead"]) and float(colonists[j]["hp"]) < float(colonists[j]["max_hp"]) * 0.55:
				return {"job": "heal", "target": j}
	# 3) fighter auto-defense: engage monster within ~5 cells
	if c["role"] == "fighter":
		for m in range(monsters.size()):
			if float(monsters[m]["hp"]) <= 0.0:
				continue
			var md: float = c["pos"].distance_to(monsters[m]["pos"])
			if md < 170.0:
				return {"job": "attack", "target": m}
	# 4) farm harvest ready
	for b in range(buildings.size()):
		var bd: Dictionary = buildings[b]
		if bd["kind"] == "farm" and bool(bd.get("grown", false)):
			return {"job": "farm", "target": b}
	# 5) cook if raw food plenty and meals low
	if raw_food >= 6 and food <= 6:
		for b in range(buildings.size()):
			if buildings[b]["kind"] == "stove":
				return {"job": "cook", "target": b}
	# 6) haul drops
	if drops.size() > 0:
		return {"job": "haul", "target": 0}
	# 7) harvest by role preference
	var want: Array = ["wood", "stone"]
	if c["role"] == "harvester":
		want = ["raw_food", "wood"]
	elif c["role"] == "builder":
		want = ["wood", "stone"]
	elif c["role"] == "fighter":
		want = ["metal", "stone"]
	var best_job := ""
	var best_target := -1
	var best_d := 1e9
	for n in range(resource_nodes.size()):
		var node: Dictionary = resource_nodes[n]
		if node["hp"] <= 0.0:
			continue
		var res_key := "wood"
		match node["kind"]:
			"tree":
				res_key = "wood"
			"rock":
				res_key = "stone"
			"metal":
				res_key = "metal"
			"crystal":
				res_key = "crystal"
			"berry":
				res_key = "raw_food"
		if not want.has(res_key):
			continue
		var d: float = c["pos"].distance_to(node["pos"])
		if d < best_d:
			best_d = d
			best_job = "harvest"
			best_target = n
	return {"job": best_job, "target": best_target}

func _start_path_to(c: Dictionary, dest_cell: Vector2i) -> void:
	var from := _world_to_cell(c["pos"])
	var path := _find_path(from, dest_cell)
	c["path"] = path
	c["path_i"] = 0

func _move_along_path(c: Dictionary, dt: float) -> bool:
	## returns true when arrived at final cell center
	var path: Array = c["path"]
	if path.is_empty():
		return true
	var idx: int = c["path_i"]
	if idx >= path.size():
		return true
	var target_cell: Vector2i = path[idx]
	var dest := _cell_center(target_cell)
	var speed := COLONIST_SPEED * _role_speed_mult(c)
	var to_dest: Vector2 = dest - c["pos"]
	var dist: float = to_dest.length()
	if dist < 2.0:
		c["path_i"] = int(c["path_i"]) + 1
		if int(c["path_i"]) >= path.size():
			c["path"] = []
			c["path_i"] = 0
			return true
		return false
	var step: float = speed * dt
	if step >= dist:
		c["pos"] = dest
		c["path_i"] = int(c["path_i"]) + 1
		if int(c["path_i"]) >= path.size():
			c["path"] = []
			c["path_i"] = 0
			return true
		return false
	c["pos"] = c["pos"] + to_dest / dist * step
	c["face"] = 1 if to_dest.x >= 0.0 else -1
	c["anim"] = "walk"
	return false

func _role_speed_mult(c: Dictionary) -> float:
	match c["role"]:
		"harvester":
			return 1.1
		"fighter":
			return 1.0
		"builder":
			return 0.9
	return 1.0

# ========================================================== GAME LOOP ====
func _process(delta: float) -> void:
	if mode == "game":
		if not paused:
			_update_game(delta * game_speed)
	elif mode == "menu" or mode == "over":
		pass
	if alert_time > 0.0:
		alert_time -= delta
		if alert_time <= 0.0:
			alert_text = ""
			alert_sub = ""
	autosave_timer -= delta
	if mode == "game" and autosave_timer <= 0.0:
		autosave_timer = 10.0
		_save_game()
	queue_redraw()

func _update_game(dt: float) -> void:
	# --- day/night ---
	time_of_day += dt / DAY_LENGTH
	if time_of_day >= 1.0:
		time_of_day -= 1.0
		day += 1
		_set_alert("HARI %d" % day, "Bertahan sampai hari %d." % WIN_DAY)
		if day > WIN_DAY:
			_finish_game("KOLONI SELAMAT!", "Kamu bertahan %d hari. Kolonis: %s" % [WIN_DAY, _alive_names()])
			return
	danger_level = 0.0
	if _is_night():
		danger_level = clampf((time_of_day - NIGHT_START) / maxf(0.01, NIGHT_END - NIGHT_START), 0.0, 1.0)

	# --- needs ---
	for c in colonists:
		_update_needs(c, dt)
	# --- jobs ---
	_assign_jobs()
	for i in range(colonists.size()):
		_update_colonist(colonists[i], dt)
	# --- world systems ---
	_update_buildings(dt)
	_update_monsters(dt)
	_update_bullets(dt)
	_update_effects(dt)
	_update_drops(dt)
	# --- spawning ---
	_update_spawns(dt)
	# --- lose check ---
	var all_dead := true
	for c in colonists:
		if not c["dead"]:
			all_dead = false
	if all_dead:
		_finish_game("KOLONI HANCUR", "Semua kolonis tumbang pada hari %d." % day)

func _is_night() -> bool:
	return time_of_day > NIGHT_START and time_of_day < NIGHT_END

func _alive_names() -> String:
	var names := []
	for c in colonists:
		if not c["dead"]:
			names.append(str(c["name"]))
	if names.is_empty():
		return "-"
	return ", ".join(names)

# ============================================================ NEEDS ======
func _update_needs(c: Dictionary, dt: float) -> void:
	if c["dead"]:
		return
	if c["downed"]:
		c["downed_t"] = float(c["downed_t"]) + dt
		# bleed out slowly; rescue chance
		if float(c["downed_t"]) > 240.0:
			c["dead"] = true
			_set_alert("%s meninggal" % c["name"], "Tidak sempat ditolong.")
			return
	c["hunger"] = maxf(0.0, float(c["hunger"]) - NEED_DECAY_HUNGER * dt)
	if c["job"] != "" and c["job"] != "sleep":
		c["sleep"] = maxf(0.0, float(c["sleep"]) - NEED_DECAY_SLEEP * dt)
	else:
		c["sleep"] = minf(100.0, float(c["sleep"]) + 4.5 * dt)
	# mood drains slowly; extra drain when starving/exhausted; recovers when content
	var mood_rate := -NEED_DECAY_MOOD
	if float(c["hunger"]) < 25.0:
		mood_rate -= MOOD_HUNGER_PENALTY
	if float(c["sleep"]) < 22.0:
		mood_rate -= MOOD_SLEEP_PENALTY
	if danger_level > 0.5:
		mood_rate -= 1.0
	if float(c["hunger"]) > 55.0 and float(c["sleep"]) > 40.0:
		mood_rate += MOOD_RECOVER
	c["mood"] = clampf(float(c["mood"]) + mood_rate * dt, 0.0, 100.0)
	# --- eat: cooked meal preferred, raw food as fallback ---
	if float(c["hunger"]) < EAT_HUNGER_TRIGGER:
		if food > 0:
			food -= 1
			c["hunger"] = minf(100.0, float(c["hunger"]) + EAT_AMOUNT)
			c["mood"] = minf(100.0, float(c["mood"]) + 5.0)
		elif raw_food > 0 and float(c["hunger"]) < 18.0:
			raw_food -= 1
			c["hunger"] = minf(100.0, float(c["hunger"]) + 30.0)
			c["mood"] = maxf(0.0, float(c["mood"]) - 4.0)
	# --- mental break ---
	if float(c["mood"]) < MENTAL_BREAK_MOOD and float(c["break_t"]) <= 0.0:
		c["break_t"] = 12.0
		c["binge_t"] = 0.0
		c["break_kind"] = "binge" if float(c["hunger"]) < 50.0 else "wander"
		c["job"] = ""
		c["target"] = -1
		c["path"] = []
		_set_alert("%s mental break!" % c["name"], "Mood terlalu rendah. Beri makan & tidur.")
	if float(c["break_t"]) > 0.0:
		c["break_t"] = maxf(0.0, float(c["break_t"]) - dt)
		if c["break_kind"] == "binge":
			# rate-limited binge eating: 1 meal per ~4s (not per frame!)
			c["binge_t"] = float(c.get("binge_t", 0.0)) + dt
			if float(c["binge_t"]) >= 4.0 and food > 0:
				c["binge_t"] = 0.0
				food -= 1
				c["mood"] = minf(100.0, float(c["mood"]) + 18.0)
			c["mood"] = minf(100.0, float(c["mood"]) + 3.0 * dt)
		elif c["break_kind"] == "wander":
			c["mood"] = minf(100.0, float(c["mood"]) + 6.0 * dt)
		if float(c["break_t"]) <= 0.0:
			c["break_kind"] = ""
		return
	# --- go sleep at night if very tired (auto): bed, or ground ---
	if float(c["sleep"]) < SLEEP_TRIGGER and _is_night() and c["job"] != "sleep":
		var bed_idx := _find_free_bed()
		if bed_idx >= 0:
			buildings[bed_idx]["claimed_by"] = c["name"]
			c["job"] = "sleep"
			c["target"] = bed_idx
			_start_path_to(c, buildings[bed_idx]["cell"])
		else:
			# no bed: collapse and rest on the ground (RimWorld-style)
			c["job"] = "sleep"
			c["target"] = -1
			c["path"] = []
	# sleeping progress
	if c["job"] == "sleep":
		if float(c["sleep"]) >= 99.0 or not _is_night():
			_release_bed(c)
			c["job"] = ""
			c["target"] = -1

func _find_free_bed() -> int:
	for b in range(buildings.size()):
		var bd: Dictionary = buildings[b]
		if bd["kind"] == "bed" and not bd.get("needs_build", false) and not bd.has("claimed_by"):
			return b
	return -1

func _release_bed(c: Dictionary) -> void:
	for bd in buildings:
		if bd.has("claimed_by") and bd["claimed_by"] == c["name"]:
			bd.erase("claimed_by")

func _update_colonist(c: Dictionary, dt: float) -> void:
	if c["dead"]:
		return
	c["frame_t"] = float(c["frame_t"]) + dt
	if c["downed"]:
		return
	if float(c["break_t"]) > 0.0:
		# wander randomly during break
		if c["path"].is_empty() and rng.randf() < 0.02:
			var dest := Vector2i(rng.randi_range(8, 22), rng.randi_range(12, 20))
			_start_path_to(c, dest)
		_move_along_path(c, dt)
		return
	var job: String = c["job"]
	match job:
		"sleep":
			var bed_idx: int = c["target"]
			if bed_idx >= 0 and bed_idx < buildings.size():
				var bed: Dictionary = buildings[bed_idx]
				if not _move_along_path(c, dt):
					return
				if _world_to_cell(c["pos"]) == bed["cell"] or _world_to_cell(c["pos"]).distance_to(bed["cell"]) <= 1:
					c["sleep"] = minf(100.0, float(c["sleep"]) + 6.0 * dt)
					c["hp"] = minf(float(c["max_hp"]), float(c["hp"]) + HEAL_RATE * dt)
					c["mood"] = minf(100.0, float(c["mood"]) + 1.5 * dt)
					c["anim"] = "sleep"
			else:
				# sleeping on the ground: slower recovery, no mood bonus
				c["sleep"] = minf(100.0, float(c["sleep"]) + 4.5 * dt)
				c["hp"] = minf(float(c["max_hp"]), float(c["hp"]) + HEAL_RATE * 0.5 * dt)
				c["anim"] = "sleep"
		"harvest":
			_do_work_at(c, dt, resource_nodes, c["target"], "harvest")
		"build":
			_do_work_at(c, dt, buildings, c["target"], "build")
		"haul":
			_do_work_at(c, dt, drops, c["target"], "haul")
		"farm":
			_do_work_at(c, dt, buildings, c["target"], "farm")
		"cook":
			_do_work_at(c, dt, buildings, c["target"], "cook")
		"heal":
			_do_heal(c, dt)
		"rescue":
			_do_rescue(c, dt)
		"attack":
			_do_attack(c, dt)
		"move":
			if not _move_along_path(c, dt):
				c["anim"] = "walk"
			else:
				c["job"] = ""
				c["anim"] = "idle"
		_:
			c["anim"] = "idle"

func _do_work_at(c: Dictionary, dt: float, arr: Array, target: int, kind: String) -> void:
	if target < 0 or target >= arr.size():
		c["job"] = ""
		c["target"] = -1
		return
	var obj: Dictionary = arr[target]
	var obj_cell: Vector2i = obj["cell"]
	var interact_dist := 40.0
	var my_cell := _world_to_cell(c["pos"])
	if _cell_dist(my_cell, obj_cell) > 1 and c["pos"].distance_to(_cell_center(obj_cell)) > interact_dist:
		if c["path"].is_empty():
			_start_path_to(c, obj_cell)
		if not _move_along_path(c, dt):
			return
	# arrived: work
	c["anim"] = "work"
	c["work_t"] = float(c["work_t"]) + dt
	var needed: float = float(JOB_WORK.get(kind, 1.5)) * (0.8 if c["role"] == "builder" and kind == "build" else 1.0)
	if float(c["work_t"]) >= needed:
		c["work_t"] = 0.0
		_complete_work(c, arr, target, kind)

func _complete_work(c: Dictionary, arr: Array, target: int, kind: String) -> void:
	match kind:
		"harvest":
			if target >= resource_nodes.size():
				return
			var node: Dictionary = resource_nodes[target]
			node["hp"] = float(node["hp"]) - 25.0
			_spark(node["pos"], "fx_hit")
			if float(node["hp"]) <= 0.0:
				var d: Dictionary = NODE_DEF[node["kind"]]
				var y: Dictionary = d["yield"]
				drops.append({"res": y.keys()[0], "pos": node["pos"], "qty": int(y.values()[0]), "cell": node["cell"]})
				node["regrow_t"] = float(d["regrow"])
				_rebuild_blocked()
				c["job"] = ""
				c["target"] = -1
		"build":
			if target >= buildings.size():
				return
			var bd: Dictionary = buildings[target]
			bd["progress"] = float(bd.get("progress", 0.0)) + 34.0
			_spark(_cell_center(bd["cell"]), "fx_hit")
			if float(bd["progress"]) >= 100.0:
				bd["needs_build"] = false
				bd["progress"] = 100.0
				_play_sfx("build.wav")
				_rebuild_blocked()
				c["job"] = ""
				c["target"] = -1
		"haul":
			if target >= drops.size():
				return
			var drop: Dictionary = drops[target]
			_add_res(drop["res"], int(drop["qty"]))
			drops.remove_at(target)
			# fix indices of haul jobs
			for cc in colonists:
				if cc["job"] == "haul" and int(cc["target"]) > target:
					cc["target"] = int(cc["target"]) - 1
			c["job"] = ""
			c["target"] = -1
		"farm":
			if target >= buildings.size():
				return
			var fd: Dictionary = buildings[target]
			if bool(fd.get("grown", false)):
				raw_food += 5
				fd["grown"] = false
				fd["growth"] = 0.0
				fd["planted"] = true
				_spark(_cell_center(fd["cell"]), "fx_hit")
				c["job"] = ""
				c["target"] = -1
		"cook":
			if target >= buildings.size():
				return
			var sd: Dictionary = buildings[target]
			if raw_food >= 3:
				raw_food -= 3
				food += 2
				_spark(_cell_center(sd["cell"]), "fx_boom")
				c["job"] = ""
				c["target"] = -1

func _do_heal(c: Dictionary, dt: float) -> void:
	var t: int = c["target"]
	if t < 0 or t >= colonists.size():
		c["job"] = ""
		c["target"] = -1
		return
	var patient: Dictionary = colonists[t]
	var dist: float = (c["pos"] as Vector2).distance_to(patient["pos"])
	if dist > 30.0:
		if c["path"].is_empty():
			_start_path_to(c, _world_to_cell(patient["pos"]))
		_move_along_path(c, dt)
		return
	c["anim"] = "work"
	c["work_t"] = float(c["work_t"]) + dt
	if float(c["work_t"]) >= JOB_WORK["heal"]:
		c["work_t"] = 0.0
		if medkits > 0:
			medkits -= 1
			patient["hp"] = minf(float(patient["max_hp"]), float(patient["hp"]) + MEDKIT_HEAL)
			patient["mood"] = minf(100.0, float(patient["mood"]) + 10.0)
			if bool(patient["downed"]) and float(patient["hp"]) > 35.0:
				patient["downed"] = false
				patient["downed_t"] = 0.0
			_spark(patient["pos"], "fx_zap")
			c["job"] = ""
			c["target"] = -1

func _do_rescue(c: Dictionary, dt: float) -> void:
	var t: int = c["target"]
	if t < 0 or t >= colonists.size():
		c["job"] = ""
		c["target"] = -1
		return
	var victim: Dictionary = colonists[t]
	if not bool(victim["downed"]):
		c["job"] = ""
		c["target"] = -1
		return
	var dist: float = (c["pos"] as Vector2).distance_to(victim["pos"])
	if dist > 26.0:
		if c["path"].is_empty():
			_start_path_to(c, _world_to_cell(victim["pos"]))
		_move_along_path(c, dt)
		return
	# rescue: carry to bed or campfire
	victim["downed"] = false
	victim["downed_t"] = 0.0
	victim["hp"] = maxf(float(victim["hp"]), 22.0)
	victim["mood"] = minf(100.0, float(victim["mood"]) + 15.0)
	var bed_idx := _find_free_bed()
	if bed_idx >= 0:
		buildings[bed_idx]["claimed_by"] = victim["name"]
		victim["pos"] = _cell_center(buildings[bed_idx]["cell"])
		victim["job"] = "sleep"
		victim["target"] = bed_idx
	else:
		victim["pos"] = _campfire_pos()
		victim["job"] = ""
		victim["target"] = -1
	_spark(victim["pos"], "fx_zap")
	c["job"] = ""
	c["target"] = -1

func _campfire_pos() -> Vector2:
	for bd in buildings:
		if bd["kind"] == "campfire":
			return _cell_center(bd["cell"]) + Vector2(TILE, 0.0)
	return Vector2(14.0 * TILE, 16.0 * TILE)

func _do_attack(c: Dictionary, dt: float) -> void:
	var t: int = c["target"]
	if t < 0 or t >= monsters.size() or monsters[t]["hp"] <= 0.0:
		c["job"] = ""
		c["target"] = -1
		return
	var m: Dictionary = monsters[t]
	var dist: float = (c["pos"] as Vector2).distance_to(m["pos"])
	if dist > COLONIST_ATTACK_RANGE:
		if c["path"].is_empty() or _world_to_cell(m["pos"]) != c.get("last_path_target", Vector2i(-9, -9)):
			c["last_path_target"] = _world_to_cell(m["pos"])
			_start_path_to(c, _world_to_cell(m["pos"]))
		_move_along_path(c, dt)
		return
	# in range: swing
	c["anim"] = "attack"
	c["work_t"] = float(c["work_t"]) + dt
	if float(c["work_t"]) >= COLONIST_ATTACK_CD:
		c["work_t"] = 0.0
		var dmg := COLONIST_DMG * (1.35 if c["role"] == "fighter" else 1.0)
		m["hp"] = float(m["hp"]) - dmg
		_spark(m["pos"], "fx_hit")
		if float(m["hp"]) <= 0.0:
			_kill_monster(t)

func _kill_monster(idx: int) -> void:
	if idx < 0 or idx >= monsters.size():
		return
	var m: Dictionary = monsters[idx]
	_spark(m["pos"], "fx_boom")
	stat_kills += 1
	# drop loot
	if rng.randf() < 0.45:
		drops.append({"res": "raw_food", "pos": m["pos"], "qty": 2, "cell": _world_to_cell(m["pos"])})
	elif rng.randf() < 0.3:
		drops.append({"res": "crystal", "pos": m["pos"], "qty": 1, "cell": _world_to_cell(m["pos"])})
	monsters.remove_at(idx)
	# fix attack targets
	for c in colonists:
		if c["job"] == "attack" and int(c["target"]) > idx:
			c["target"] = int(c["target"]) - 1

# ===================================================== BUILDING UPDATES ==
func _update_buildings(dt: float) -> void:
	for b in buildings:
		var kind: String = b["kind"]
		if kind == "farm" and not bool(b.get("needs_build", false)):
			if not bool(b.get("grown", false)) and bool(b.get("planted", false)):
				b["growth"] = float(b.get("growth", 0.0)) + dt
				if float(b["growth"]) >= 70.0:
					b["grown"] = true
		elif kind == "turret" and not bool(b.get("needs_build", false)):
			b["cd"] = maxf(0.0, float(b.get("cd", 0.0)) - dt)
			if float(b["cd"]) <= 0.0:
				var tpos := _cell_center(b["cell"])
				var best := -1
				var best_d := 200.0
				for m in range(monsters.size()):
					var d: float = tpos.distance_to(monsters[m]["pos"])
					if d < best_d:
						best_d = d
						best = m
				if best >= 0:
					b["cd"] = 1.4
					var target: Dictionary = monsters[best]
					var dir: Vector2 = ((target["pos"] as Vector2) - tpos).normalized()
					bullets.append({"pos": tpos, "vel": dir * 240.0, "ttl": 1.2, "dmg": 9.0})

func _update_bullets(dt: float) -> void:
	for i in range(bullets.size() - 1, -1, -1):
		var bl: Dictionary = bullets[i]
		bl["pos"] = bl["pos"] + bl["vel"] * dt
		bl["ttl"] = float(bl["ttl"]) - dt
		var hit := false
		for m in monsters:
			if bl["pos"].distance_to(m["pos"]) < 20.0:
				m["hp"] = float(m["hp"]) - float(bl["dmg"])
				_spark(bl["pos"], "fx_hit")
				if float(m["hp"]) <= 0.0:
					_kill_monster(monsters.find(m))
					hit = true
					break
		if hit or float(bl["ttl"]) <= 0.0 or bl["pos"].x < 0.0 or bl["pos"].y < 0.0 or bl["pos"].x > WORLD_PX.x or bl["pos"].y > WORLD_PX.y:
			bullets.remove_at(i)

func _update_effects(dt: float) -> void:
	for i in range(effects.size() - 1, -1, -1):
		var e: Dictionary = effects[i]
		e["t"] = float(e["t"]) + dt
		if float(e["t"]) >= float(e["ttl"]):
			effects.remove_at(i)

func _spark(pos: Vector2, tex: String) -> void:
	effects.append({"pos": pos, "tex": tex, "t": 0.0, "ttl": 0.35})

func _update_drops(dt: float) -> void:
	pass  # drops are static until hauled

# ============================================================ MONSTERS ===
func _update_monsters(dt: float) -> void:
	for mi in range(monsters.size() - 1, -1, -1):
		var m: Dictionary = monsters[mi]
		if float(m["hp"]) <= 0.0:
			continue
		m["frame_t"] = float(m["frame_t"]) + dt
		var stats: Dictionary = MONSTER_STATS[m["kind"]]
		var speed := float(stats["speed"])
		# --- pick target: nearest living colonist (prefer not-downed) ---
		var target: Dictionary = {}
		var best_d := 1e9
		for c in colonists:
			if c["dead"]:
				continue
			var d: float = (c["pos"] as Vector2).distance_to(m["pos"])
			if d < best_d:
				best_d = d
				target = c
		if target.is_empty():
			continue
		var dist := (target["pos"] as Vector2).distance_to(m["pos"])
		var atk_range := float(stats["atk_range"])
		m["cd"] = maxf(0.0, float(m["cd"]) - dt)
		if dist <= atk_range:
			# attack colonist
			if float(m["cd"]) <= 0.0:
				m["cd"] = float(stats["cd"])
				target["hp"] = maxf(0.0, float(target["hp"]) - float(stats["dmg"]))
				_spark(target["pos"], "fx_hit")
				if float(target["hp"]) <= 0.0 and not bool(target["dead"]):
					_colonist_downed(target)
			continue
		# --- move: pathfind to target; if blocked by wall, attack wall ---
		var mcell := _world_to_cell(m["pos"])
		var tcell := _world_to_cell(target["pos"])
		var path: Array = m["path"]
		var repath := false
		if path.is_empty() or int(m.get("path_target_x", -99)) != tcell.x or int(m.get("path_target_y", -99)) != tcell.y:
			repath = true
		if repath:
			m["path"] = _find_path(mcell, tcell)
			m["path_i"] = 0
			m["path_target_x"] = tcell.x
			m["path_target_y"] = tcell.y
			path = m["path"]
		if path.is_empty():
			# no path: wall in the way -> attack adjacent wall
			_monster_attack_wall(m, dt, stats)
			continue
		# walk along path
		var idx: int = m["path_i"]
		if idx >= path.size():
			m["path"] = []
			continue
		var dest := _cell_center(path[idx])
		var to_dest := dest - (m["pos"] as Vector2)
		var dl := to_dest.length()
		if dl < 2.0:
			m["path_i"] = int(m["path_i"]) + 1
			continue
		var step: float = speed * dt
		if step >= dl:
			m["pos"] = dest
		else:
			m["pos"] = (m["pos"] as Vector2) + to_dest / dl * step
		# if next cell is a blocking wall on the way, chew it
		var next_cell: Vector2i = path[min(int(m["path_i"]), path.size() - 1)]
		if blocked.has(next_cell) and float(m["cd"]) <= 0.0:
			_monster_hit_wall(m, next_cell, stats)

func _monster_attack_wall(m: Dictionary, dt: float, stats: Dictionary) -> void:
	# find adjacent wall/building and damage it
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var c: Vector2i = _world_to_cell(m["pos"]) + dir
		var b: Dictionary = _building_at(c)
		if not b.is_empty() and b["kind"] != "pod" and b["kind"] != "campfire":
			_monster_hit_wall(m, c, stats)
			return
	# also try nodes (chew through trees)
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var c: Vector2i = _world_to_cell(m["pos"]) + dir
		var node: Dictionary = _node_at(c)
		if not node.is_empty():
			if float(m["cd"]) <= 0.0:
				m["cd"] = 1.0
				node["hp"] = float(node["hp"]) - 12.0
				_spark(node["pos"], "fx_hit")
				if float(node["hp"]) <= 0.0:
					node["regrow_t"] = float(NODE_DEF[node["kind"]]["regrow"])
					_rebuild_blocked()
				return
	m["cd"] = maxf(0.0, float(m["cd"]) - dt)

func _monster_hit_wall(m: Dictionary, cell: Vector2i, stats: Dictionary) -> void:
	if float(m["cd"]) > 0.0:
		return
	m["cd"] = 1.0
	var b: Dictionary = _building_at(cell)
	if b.is_empty():
		return
	b["hp"] = float(b["hp"]) - float(stats["wall_dmg"])
	_spark(_cell_center(cell), "fx_hit")
	if float(b["hp"]) <= 0.0:
		_spark(_cell_center(cell), "fx_boom")
		buildings.erase(b)
		_rebuild_blocked()
		# claimers lose beds
		for c in colonists:
			if c["job"] == "sleep" and int(c["target"]) >= 0 and int(c["target"]) < buildings.size() and buildings[int(c["target"])] == b:
				c["job"] = ""
				c["target"] = -1

func _colonist_downed(c: Dictionary) -> void:
	c["downed"] = true
	c["downed_t"] = 0.0
	c["job"] = ""
	c["target"] = -1
	c["path"] = []
	_set_alert("%s tumbang!" % c["name"], "Kolonis lain akan menolong (rescue).")

# ============================================================ SPAWNS =====
func _update_spawns(dt: float) -> void:
	# night ambient spawns
	if _is_night():
		night_spawn_timer -= dt
		if night_spawn_timer <= 0.0:
			night_spawn_timer = maxf(4.0, 9.0 - day * 0.15)
			_spawn_monster(_pick_ambient_kind())
	# resource regrow
	for node in resource_nodes:
		if float(node["hp"]) <= 0.0 and float(node["regrow_t"]) > 0.0:
			node["regrow_t"] = float(node["regrow_t"]) - dt
			if float(node["regrow_t"]) <= 0.0:
				node["hp"] = float(NODE_DEF[node["kind"]]["hp"]) * 0.6
	# raids
	raid_timer -= dt
	if raid_timer <= 0.0:
		raid_timer = maxf(150.0, 240.0 - day * 4.0)
		_start_raid()

func _pick_ambient_kind() -> String:
	var roll := rng.randf()
	if day < 3:
		return "slime" if roll < 0.7 else "bat"
	elif day < 6:
		if roll < 0.4:
			return "slime"
		elif roll < 0.7:
			return "bat"
		return "zapper"
	elif day < 10:
		if roll < 0.25:
			return "slime"
		elif roll < 0.45:
			return "zapper"
		elif roll < 0.8:
			return "stalker"
		return "bat"
	if roll < 0.3:
		return "zapper"
	elif roll < 0.55:
		return "stalker"
	elif roll < 0.8:
		return "golem"
	return "bat"

func _start_raid() -> void:
	var count := 2 + int(day / 6.0)
	for i in range(count):
		var kind := "slime"
		var roll := rng.randf()
		if day < 4:
			kind = "slime" if roll < 0.7 else "zapper"
		elif day < 8:
			if roll < 0.4:
				kind = "slime"
			elif roll < 0.7:
				kind = "zapper"
			else:
				kind = "stalker"
		elif day < 15:
			if roll < 0.3:
				kind = "zapper"
			elif roll < 0.55:
				kind = "stalker"
			else:
				kind = "golem"
		else:
			if roll < 0.2:
				kind = "stalker"
			elif roll < 0.6:
				kind = "golem"
			else:
				kind = "zapper"
		_spawn_monster(kind, true)
	_set_alert("RAID!", "%d monster menyerang!" % count)
	_play_sfx("alert.wav", -4.0)

func _spawn_monster(kind: String, edge_spawn := false) -> void:
	var stats: Dictionary = MONSTER_STATS[kind]
	var spawn_cell := Vector2i.ZERO
	if edge_spawn:
		spawn_cell = _raid_edge_cell()
	else:
		# spawn off-screen near map edge but away from colony center
		for i in range(20):
			var c := Vector2i(rng.randi_range(1, int(WORLD_SIZE.x) - 2), rng.randi_range(1, int(WORLD_SIZE.y) - 2))
			if ground.get(c, "grass") == "water":
				continue
			var colony := Vector2i(14, 16)
			if _cell_dist(c, colony) > 12:
				spawn_cell = c
				break
	monsters.append({
		"kind": kind,
		"pos": _cell_center(spawn_cell),
		"hp": float(stats["hp"]),
		"cd": 0.0,
		"path": [],
		"path_i": 0,
		"path_target_x": -99,
		"path_target_y": -99,
		"frame_t": rng.randf() * 2.0,
	})

func _raid_edge_cell() -> Vector2i:
	var side := rng.randi_range(0, 3)
	match side:
		0:
			return Vector2i(rng.randi_range(2, int(WORLD_SIZE.x) - 3), 1)
		1:
			return Vector2i(rng.randi_range(2, int(WORLD_SIZE.x) - 3), int(WORLD_SIZE.y) - 2)
		2:
			return Vector2i(1, rng.randi_range(2, int(WORLD_SIZE.y) - 3))
	return Vector2i(int(WORLD_SIZE.x) - 2, rng.randi_range(2, int(WORLD_SIZE.y) - 3))

# ============================================================ INPUT ======
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_pointer_down(event.position)
		else:
			_pointer_up(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pointer_down(event.position)
		else:
			_pointer_up(event.position)
	elif event is InputEventScreenDrag:
		_pointer_drag(event.position)
	elif event is InputEventMouseMotion:
		if dragging:
			_pointer_drag(event.position)

func _pointer_down(screen_pos: Vector2) -> void:
	dragging = true
	drag_start = screen_pos
	drag_cam_start = camera_offset

func _pointer_drag(screen_pos: Vector2) -> void:
	if not dragging:
		return
	var delta := screen_pos - drag_start
	if delta.length() > 8.0:
		var max_off := WORLD_PX - VIEW_SIZE
		camera_offset = (drag_cam_start - delta).clamp(Vector2.ZERO, max_off)

func _pointer_up(screen_pos: Vector2) -> void:
	var was_drag := (screen_pos - drag_start).length() > 10.0
	dragging = false
	if was_drag:
		return
	_handle_tap(screen_pos)

func _handle_tap(screen_pos: Vector2) -> void:
	if mode == "menu":
		if Rect2(330, 250, 250, 60).has_point(screen_pos):
			_start_new_game()
		elif _has_save() and Rect2(330, 330, 250, 50).has_point(screen_pos):
			if not _load_game():
				_start_new_game()
		return
	if mode == "over":
		if Rect2(330, 350, 250, 60).has_point(screen_pos):
			_start_new_game()
		elif Rect2(330, 430, 250, 60).has_point(screen_pos):
			mode = "menu"
			_play_music("menu.wav")
		return
	# --- game mode ---
	# UI top bar
	if screen_pos.y < 52.0:
		if Rect2(742, 6, 42, 42).has_point(screen_pos):
			open_menu = "" if open_menu != "" else "build"
		elif Rect2(870, 6, 38, 40).has_point(screen_pos):
			paused = true
		elif Rect2(790, 6, 38, 40).has_point(screen_pos):
			paused = false
			game_speed = 1.0
		elif Rect2(830, 6, 38, 40).has_point(screen_pos):
			paused = false
			game_speed = 3.0
		return
	# speed / pause also via buttons bottom
	if Rect2(700, 445, 70, 30).has_point(screen_pos):
		audio_enabled = not audio_enabled
		_set_alert("Audio %s" % ("ON" if audio_enabled else "OFF"), "")
		if audio_enabled:
			_play_music("ambient.wav")
		else:
			_stop_music()
		return
	# build menu panel
	if open_menu == "build" and Rect2(120, 60, 660, 120).has_point(screen_pos):
		_tap_build_menu(screen_pos)
		return
	if open_menu == "help" and Rect2(120, 60, 660, 200).has_point(screen_pos):
		open_menu = ""
		return
	# colonist portraits (bottom)
	for i in range(colonists.size()):
		var x := 14.0 + i * 120.0
		if Rect2(x, 440, 112, 66).has_point(screen_pos) and not bool(colonists[i]["dead"]):
			selected_colonist = i
			open_menu = ""
			return
	# build placement
	if build_mode != "":
		_try_place_building(screen_pos)
		return
	# world interactions
	var world_pos := screen_pos + camera_offset
	# select colonist
	for i in range(colonists.size()):
		if not bool(colonists[i]["dead"]) and not bool(colonists[i]["downed"]):
			if world_pos.distance_to(colonists[i]["pos"]) < 34.0:
				selected_colonist = i
				return
	# order: attack monster
	for m in range(monsters.size()):
		if world_pos.distance_to(monsters[m]["pos"]) < 36.0:
			_order_attack(m)
			return
	# order: harvest node
	for n in range(resource_nodes.size()):
		if resource_nodes[n]["hp"] > 0.0 and world_pos.distance_to(resource_nodes[n]["pos"]) < 34.0:
			_order_harvest(n)
			return
	# order: rescue downed colonist
	for j in range(colonists.size()):
		if bool(colonists[j]["downed"]) and world_pos.distance_to(colonists[j]["pos"]) < 34.0:
			_order_rescue(j)
			return
	# order: heal injured colonist
	for j in range(colonists.size()):
		if not bool(colonists[j]["dead"]) and float(colonists[j]["hp"]) < float(colonists[j]["max_hp"]) * 0.75 and world_pos.distance_to(colonists[j]["pos"]) < 34.0:
			_order_heal(j)
			return
	# order: harvest farm / cook at stove (tap building)
	var hit_b: Dictionary = _building_at(_world_to_cell(world_pos))
	if not hit_b.is_empty():
		if hit_b["kind"] == "farm" and bool(hit_b.get("grown", false)):
			_order_farm(buildings.find(hit_b))
			return
		if hit_b["kind"] == "stove" and raw_food >= 3:
			_order_cook(buildings.find(hit_b))
			return
		if hit_b["kind"] == "bed" and not bool(hit_b.get("needs_build", false)) and _is_night():
			_order_sleep(buildings.find(hit_b))
			return
	# move order (tap ground) -> selected colonist moves
	_order_move(world_pos)

func _order_attack(m_idx: int) -> void:
	var c: Dictionary = colonists[selected_colonist]
	if bool(c["dead"]) or bool(c["downed"]):
		return
	c["job"] = "attack"
	c["target"] = m_idx
	c["work_t"] = 0.0
	c["path"] = []
	c["anim"] = "walk"

func _order_harvest(n_idx: int) -> void:
	var c: Dictionary = colonists[selected_colonist]
	if bool(c["dead"]) or bool(c["downed"]):
		return
	c["job"] = "harvest"
	c["target"] = n_idx
	c["work_t"] = 0.0
	c["path"] = []
	c["anim"] = "walk"

func _order_rescue(j: int) -> void:
	var c: Dictionary = colonists[selected_colonist]
	if bool(c["dead"]) or bool(c["downed"]):
		return
	c["job"] = "rescue"
	c["target"] = j
	c["work_t"] = 0.0
	c["path"] = []
	c["anim"] = "walk"

func _order_heal(j: int) -> void:
	var c: Dictionary = colonists[selected_colonist]
	if bool(c["dead"]) or bool(c["downed"]):
		return
	if medkits <= 0:
		_set_alert("Medkit habis!", "Buat/kumpulkan lebih banyak.")
		return
	c["job"] = "heal"
	c["target"] = j
	c["work_t"] = 0.0
	c["path"] = []
	c["anim"] = "walk"

func _order_farm(b_idx: int) -> void:
	var c: Dictionary = colonists[selected_colonist]
	if bool(c["dead"]) or bool(c["downed"]):
		return
	c["job"] = "farm"
	c["target"] = b_idx
	c["work_t"] = 0.0
	c["path"] = []
	c["anim"] = "walk"

func _order_cook(b_idx: int) -> void:
	var c: Dictionary = colonists[selected_colonist]
	if bool(c["dead"]) or bool(c["downed"]):
		return
	c["job"] = "cook"
	c["target"] = b_idx
	c["work_t"] = 0.0
	c["path"] = []
	c["anim"] = "walk"

func _order_sleep(b_idx: int) -> void:
	var c: Dictionary = colonists[selected_colonist]
	if bool(c["dead"]) or bool(c["downed"]):
		return
	var bed: Dictionary = buildings[b_idx]
	if bed.has("claimed_by") and bed["claimed_by"] != c["name"]:
		_set_alert("Kasur dipakai", "Cari kasur lain atau tunggu.")
		return
	bed["claimed_by"] = c["name"]
	c["job"] = "sleep"
	c["target"] = b_idx
	c["work_t"] = 0.0
	c["path"] = []

func _order_move(world_pos: Vector2) -> void:
	var c: Dictionary = colonists[selected_colonist]
	if bool(c["dead"]) or bool(c["downed"]):
		return
	_release_bed(c)
	c["job"] = "move"
	c["target"] = -1
	c["work_t"] = 0.0
	_start_path_to(c, _world_to_cell(world_pos))
	c["anim"] = "walk"

func _tap_build_menu(screen_pos: Vector2) -> void:
	# grid of build buttons: 3 rows x 4 cols in panel (120,60)-(780,180)
	var keys: Array = BUILDINGS.keys()
	var cols := 4
	var cell_w := 660.0 / float(cols)
	var cell_h := 40.0
	var col := int((screen_pos.x - 120.0) / cell_w)
	var row := int((screen_pos.y - 60.0) / cell_h)
	if col < 0 or col >= cols or row < 0 or row >= 3:
		return
	var idx := row * cols + col
	if idx >= keys.size():
		return
	var kind: String = keys[idx]
	var def: Dictionary = BUILDINGS[kind]
	if _can_afford(def["cost"]):
		build_mode = kind
		open_menu = ""
		_set_alert("Bangun: %s" % def["name"], "Tap lokasi kosong. Tap tombol palu lagi untuk batal.")
	else:
		_set_alert("Bahan kurang!", "Butuh: " + _cost_text(def["cost"]))

func _cost_text(cost: Dictionary) -> String:
	var parts := []
	for key in cost.keys():
		var label: String = {"wood": "Kayu", "stone": "Batu", "metal": "Logam", "crystal": "Kristal"}.get(key, key)
		parts.append("%s %d" % [label, int(cost[key])])
	return ", ".join(parts)

func _try_place_building(screen_pos: Vector2) -> void:
	var world_pos := screen_pos + camera_offset
	var def: Dictionary = BUILDINGS[build_mode]
	var size: Vector2i = def["size"]
	var cell := _world_to_cell(world_pos)
	if not _can_build_at(cell, size):
		_set_alert("Tidak bisa bangun di sini", "Area harus kosong.")
		return
	if not _can_afford(def["cost"]):
		_set_alert("Bahan kurang!", "Butuh: " + _cost_text(def["cost"]))
		build_mode = ""
		return
	_pay_cost(def["cost"])
	_place_building(build_mode, cell)
	var builder := _find_builder()
	if builder >= 0:
		colonists[builder]["job"] = "build"
		colonists[builder]["target"] = buildings.size() - 1
		colonists[builder]["work_t"] = 0.0
		colonists[builder]["path"] = []
	_set_alert("%s dibangun (perlu dikerjakan)" % def["name"], "")
	build_mode = ""

func _find_builder() -> int:
	for i in range(colonists.size()):
		if colonists[i]["role"] == "builder" and not bool(colonists[i]["dead"]) and not bool(colonists[i]["downed"]) and colonists[i]["job"] != "attack":
			return i
	for i in range(colonists.size()):
		if not bool(colonists[i]["dead"]) and not bool(colonists[i]["downed"]) and colonists[i]["job"] == "":
			return i
	return -1

# ======================================================== SAVE / LOAD ====
func _save_game() -> void:
	if mode != "game":
		return
	var data := {
		"day": day,
		"time_of_day": time_of_day,
		"wood": wood, "stone": stone, "metal": metal,
		"crystal": crystal, "raw_food": raw_food, "food": food, "medkits": medkits,
		"camera": {"x": camera_offset.x, "y": camera_offset.y},
		"selected": selected_colonist,
		"raid_timer": raid_timer,
		"night_timer": night_spawn_timer,
		"stat_kills": stat_kills,
		"tutorial_seen": tutorial_seen,
		"colonists": [],
		"nodes": [],
		"buildings": [],
		"monsters": [],
		"drops": [],
		"ground": {},
	}
	for c in colonists:
		data["colonists"].append({
			"name": c["name"], "role": c["role"],
			"px": float(c["pos"].x), "py": float(c["pos"].y),
			"hp": float(c["hp"]), "max_hp": float(c["max_hp"]),
			"hunger": float(c["hunger"]), "sleep": float(c["sleep"]), "mood": float(c["mood"]),
			"downed": bool(c["downed"]), "dead": bool(c["dead"]),
			"job": str(c["job"]), "target": int(c["target"]),
		})
	for n in resource_nodes:
		data["nodes"].append({
			"kind": n["kind"], "cx": n["cell"].x, "cy": n["cell"].y,
			"hp": float(n["hp"]), "rt": float(n["regrow_t"]),
		})
	for b in buildings:
		var entry := {
			"kind": b["kind"], "cx": b["cell"].x, "cy": b["cell"].y,
			"hp": float(b["hp"]),
		}
		if b.has("needs_build"):
			entry["nb"] = bool(b["needs_build"])
			entry["pr"] = float(b.get("progress", 0.0))
		match b["kind"]:
			"farm":
				entry["pl"] = bool(b.get("planted", true))
				entry["gr"] = float(b.get("growth", 0.0))
				entry["gn"] = bool(b.get("grown", false))
			"door":
				pass
			"turret":
				pass
		if b.has("claimed_by"):
			entry["cl"] = str(b["claimed_by"])
		data["buildings"].append(entry)
	for m in monsters:
		data["monsters"].append({
			"kind": m["kind"], "px": float(m["pos"].x), "py": float(m["pos"].y),
			"hp": float(m["hp"]),
		})
	for d in drops:
		data["drops"].append({
			"res": d["res"], "px": float(d["pos"].x), "py": float(d["pos"].y),
			"qty": int(d["qty"]),
		})
	for key in ground.keys():
		data["ground"]["%d,%d" % [key.x, key.y]] = ground[key]
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
	file.close()

func _load_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var txt := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	if not parsed.has("colonists"):
		return false
	mode = "game"
	day = int(parsed.get("day", 1))
	time_of_day = float(parsed.get("time_of_day", 0.25))
	wood = int(parsed.get("wood", 24))
	stone = int(parsed.get("stone", 12))
	metal = int(parsed.get("metal", 0))
	crystal = int(parsed.get("crystal", 0))
	raw_food = int(parsed.get("raw_food", 8))
	food = int(parsed.get("food", 4))
	medkits = int(parsed.get("medkits", 2))
	stat_kills = int(parsed.get("stat_kills", 0))
	tutorial_seen = bool(parsed.get("tutorial_seen", true))
	var cam: Dictionary = parsed.get("camera", {})
	camera_offset = Vector2(float(cam.get("x", 300.0)), float(cam.get("y", 300.0)))
	selected_colonist = int(parsed.get("selected", 0))
	raid_timer = float(parsed.get("raid_timer", 240.0))
	night_spawn_timer = float(parsed.get("night_timer", 6.0))
	colonists.clear()
	for cd in parsed.get("colonists", []):
		var c := _make_colonist(str(cd.get("name", "?")), str(cd.get("role", "fighter")), Vector2(float(cd.get("px", 0.0)), float(cd.get("py", 0.0))))
		c["hp"] = float(cd.get("hp", 100.0))
		c["hunger"] = float(cd.get("hunger", 100.0))
		c["sleep"] = float(cd.get("sleep", 100.0))
		c["mood"] = float(cd.get("mood", 100.0))
		c["downed"] = bool(cd.get("downed", false))
		c["dead"] = bool(cd.get("dead", false))
		c["job"] = str(cd.get("job", ""))
		c["target"] = int(cd.get("target", -1))
		c["index"] = colonists.size()
		colonists.append(c)
	resource_nodes.clear()
	for nd in parsed.get("nodes", []):
		var cell := Vector2i(int(nd.get("cx", 0)), int(nd.get("cy", 0)))
		resource_nodes.append({
			"kind": str(nd.get("kind", "tree")), "cell": cell,
			"pos": _cell_center(cell), "hp": float(nd.get("hp", 40.0)),
			"regrow_t": float(nd.get("rt", 0.0)),
		})
	buildings.clear()
	for bd in parsed.get("buildings", []):
		var cell := Vector2i(int(bd.get("cx", 0)), int(bd.get("cy", 0)))
		var entry := {"kind": str(bd.get("kind", "wall_wood")), "cell": cell, "hp": float(bd.get("hp", 50.0))}
		if bd.get("nb", false):
			entry["needs_build"] = true
			entry["progress"] = float(bd.get("pr", 0.0))
		match entry["kind"]:
			"farm":
				entry["planted"] = bool(bd.get("pl", true))
				entry["growth"] = float(bd.get("gr", 0.0))
				entry["grown"] = bool(bd.get("gn", false))
			"door":
				entry["open"] = false
			"turret":
				entry["cd"] = 0.0
		if str(bd.get("cl", "")) != "":
			entry["claimed_by"] = str(bd.get("cl", ""))
		buildings.append(entry)
	monsters.clear()
	for md in parsed.get("monsters", []):
		var kind := str(md.get("kind", "slime"))
		var stats: Dictionary = MONSTER_STATS.get(kind, MONSTER_STATS["slime"])
		monsters.append({
			"kind": kind, "pos": Vector2(float(md.get("px", 0.0)), float(md.get("py", 0.0))),
			"hp": float(md.get("hp", stats["hp"])), "cd": 0.0,
			"path": [], "path_i": 0, "path_target_x": -99, "path_target_y": -99,
			"frame_t": 0.0,
		})
	drops.clear()
	for dd in parsed.get("drops", []):
		var pos := Vector2(float(dd.get("px", 0.0)), float(dd.get("py", 0.0)))
		drops.append({"res": str(dd.get("res", "wood")), "pos": pos, "qty": int(dd.get("qty", 1)), "cell": _world_to_cell(pos)})
	ground.clear()
	var g: Dictionary = parsed.get("ground", {})
	for key in g.keys():
		var parts: Array = key.split(",")
		if parts.size() == 2:
			ground[Vector2i(int(parts[0]), int(parts[1]))] = str(g[key])
	if ground.is_empty():
		_generate_ground()
	_rebuild_blocked()
	_play_music("ambient.wav")
	return true

func _generate_ground() -> void:
	# fallback ground generation for old/corrupt saves
	for x in range(int(WORLD_SIZE.x)):
		for y in range(int(WORLD_SIZE.y)):
			var n := _noise2(x, y)
			var kind := "grass"
			if n > 0.82:
				kind = "rocky"
			elif n > 0.74:
				kind = "dirt"
			elif n < 0.12:
				kind = "sand"
			ground[Vector2i(x, y)] = kind

# ============================================================ DRAW =======
func _draw() -> void:
	if mode == "menu":
		_draw_menu()
	elif mode == "over":
		_draw_over()
	else:
		_draw_game()

func _draw_menu() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("0b1020"))
	if textures.has("menu_bg"):
		draw_texture_rect(textures["menu_bg"], Rect2(Vector2.ZERO, VIEW_SIZE), false)
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.02, 0.03, 0.1, 0.35))
	if textures.has("title"):
		var t: Texture2D = textures["title"]
		var scale := 300.0 / float(t.get_height())
		var w := float(t.get_width()) * scale
		draw_texture_rect(t, Rect2((VIEW_SIZE.x - w) * 0.5, 60.0, w, 300.0), false)
	draw_string(ThemeDB.fallback_font, Vector2(250, 400), "Koloni pixel di galaksi asing - bertahan 30 hari", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("c4d4f2"))
	_draw_button(Rect2(330, 250, 250, 60), "MULAI", Color("3869a8"))
	if _has_save():
		_draw_button(Rect2(330, 330, 250, 50), "LANJUTKAN", Color("2e7d4f"))

func _has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func _draw_over() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("160d24"))
	draw_string(ThemeDB.fallback_font, Vector2(360, 120), alert_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("ffe65a"))
	draw_string(ThemeDB.fallback_font, Vector2(280, 170), alert_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("f2f5ff"))
	draw_string(ThemeDB.fallback_font, Vector2(330, 230), "Monster dikalahkan: %d   |   Hari: %d" % [stat_kills, day], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("c4d4f2"))
	_draw_button(Rect2(330, 350, 250, 60), "MAIN LAGI", Color("3869a8"))
	_draw_button(Rect2(330, 430, 250, 60), "MENU UTAMA", Color("5b466e"))

func _draw_game() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("101828"))
	_draw_world()
	_draw_night_overlay()
	_draw_hud()
	if open_menu == "build":
		_draw_build_menu()
	if build_mode != "":
		_draw_build_preview()

func _draw_world() -> void:
	var cam := camera_offset
	# tiles (cull to viewport)
	var x0 := int(cam.x / TILE) - 1
	var y0 := int(cam.y / TILE) - 1
	var x1 := int((cam.x + VIEW_SIZE.x) / TILE) + 1
	var y1 := int((cam.y + VIEW_SIZE.y) / TILE) + 1
	for ty in range(y0, y1):
		for tx in range(x0, x1):
			var cell := Vector2i(tx, ty)
			if not _in_bounds(cell):
				continue
			var kind: String = ground.get(cell, "grass")
			var key := kind
			if not textures.has(key):
				key = "grass"
			var rect := Rect2(Vector2(cell) * TILE - cam, Vector2(TILE, TILE))
			draw_texture_rect(textures[key], rect, false)
	# drops
	for d in drops:
		var key := "drop_" + str(d["res"])
		if textures.has(key):
			draw_texture_rect(textures[key], Rect2(d["pos"] - cam - Vector2(12, 12), Vector2(24, 24)), false)
	# buildings
	for b in buildings:
		var kind: String = b["kind"]
		var tex_key := _building_tex(kind)
		var rect := Rect2(_cell_center(b["cell"]) - cam - Vector2(TILE * 0.5, TILE * 0.5), Vector2(TILE, TILE))
		if kind == "farm" or kind == "storage" or kind == "bed":
			rect = Rect2(_cell_center(b["cell"]) - cam - Vector2(TILE, TILE * 0.75), Vector2(TILE * 2.0, TILE * 1.5))
		if textures.has(tex_key):
			if bool(b.get("needs_build", false)):
				draw_rect(rect, Color(0.4, 0.4, 0.45, 0.55), true)
			draw_texture_rect(textures[tex_key], rect, false)
			if bool(b.get("needs_build", false)):
				# progress bar
				var p := float(b.get("progress", 0.0)) / 100.0
				draw_rect(Rect2(rect.position + Vector2(0, rect.size.y - 5), Vector2(rect.size.x * p, 4)), Color("6ee06e"))
			if b["kind"] == "farm" and bool(b.get("grown", false)):
				draw_string(ThemeDB.fallback_font, rect.position + Vector2(6, 16), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffe65a"))
	# resource nodes
	for n in resource_nodes:
		if float(n["hp"]) <= 0.0:
			continue
		var key: String = NODE_DEF[n["kind"]]["tex"]
		if textures.has(key):
			var s := Vector2(34, 34) if n["kind"] != "tree" else Vector2(30, 44)
			draw_texture_rect(textures[key], Rect2(n["pos"] - cam - s * 0.5, s), false)
	# monsters
	for m in monsters:
		var frame := int(float(m["frame_t"]) * 5.0) % 3
		var key := "%s%d" % [m["kind"], frame]
		if textures.has(key):
			var mp: Vector2 = m["pos"]
			draw_texture_rect(textures[key], Rect2(mp - cam - Vector2(18, 18), Vector2(36, 36)), false)
		# hp bar
		var stats: Dictionary = MONSTER_STATS[m["kind"]]
		var frac := float(m["hp"]) / float(stats["hp"])
		var hp_rect := Rect2(m["pos"] - cam - Vector2(14, 24), Vector2(28.0 * frac, 3))
		draw_rect(hp_rect, Color("ff5555"))
	# bullets
	for bl in bullets:
		if textures.has("bullet"):
			draw_texture_rect(textures["bullet"], Rect2(bl["pos"] - cam - Vector2(6, 6), Vector2(12, 12)), false)
	# effects
	for e in effects:
		if textures.has(e["tex"]):
			var alpha := 1.0 - float(e["t"]) / float(e["ttl"])
			draw_texture_rect(textures[e["tex"]], Rect2(e["pos"] - cam - Vector2(14, 14), Vector2(28, 28)), false, Color(1, 1, 1, alpha))
	# colonists
	for i in range(colonists.size()):
		var c: Dictionary = colonists[i]
		if bool(c["dead"]):
			continue
		var who := str(c["name"]).to_lower()
		var frame := _colonist_frame(c)
		var key := "%s%d" % [who, frame]
		if not textures.has(key):
			key = "%s2" % who
		if textures.has(key):
			var cp: Vector2 = c["pos"]
			var tint := Color(1, 1, 1, 0.55) if bool(c["downed"]) else Color.WHITE
			draw_texture_rect(textures[key], Rect2(cp - cam - Vector2(14, 26), Vector2(28, 46)), false, tint)
		if bool(c["downed"]):
			draw_string(ThemeDB.fallback_font, c["pos"] - cam - Vector2(28, 30), "TUMBANG", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ff7777"))
		elif float(c["break_t"]) > 0.0:
			draw_string(ThemeDB.fallback_font, c["pos"] - cam - Vector2(24, 30), "!GILA!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ff77ff"))
		if i == selected_colonist:
			draw_arc(c["pos"] - cam, 20.0, 0.0, TAU, 20, Color("ffe65a"), 1.5)
		# job icon
		var job_txt := _job_label(c)
		if job_txt != "":
			draw_string(ThemeDB.fallback_font, c["pos"] - cam - Vector2(20, 34), job_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color("aee9ff"))

func _colonist_frame(c: Dictionary) -> int:
	var anim: String = c["anim"]
	match anim:
		"walk":
			return int(float(c["frame_t"]) * 6.0) % 2
		"work":
			return 4
		"attack":
			return 5
		"sleep":
			return 3
	return 2

func _job_label(c: Dictionary) -> String:
	match str(c["job"]):
		"harvest":
			return "panen"
		"build":
			return "bangun"
		"haul":
			return "angkut"
		"farm":
			return "kebun"
		"cook":
			return "masak"
		"heal":
			return "obati"
		"rescue":
			return "tolong"
		"attack":
			return "serang"
		"sleep":
			return "ZZZ"
		"move":
			return "jalan"
	return ""

func _building_tex(kind: String) -> String:
	match kind:
		"wall_wood":
			return "wall"
		"wall_stone":
			return "wall_stone"
		"door", "bed", "farm", "stove", "storage", "turret", "lamp", "campfire", "pod":
			return kind
	return "wall"

func _draw_night_overlay() -> void:
	if _is_night():
		var alpha := 0.25 + danger_level * 0.2
		draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.04, 0.06, 0.2, alpha))

func _draw_build_preview() -> void:
	if build_mode == "":
		return
	var vp := get_viewport()
	if vp == null:
		return
	var mouse := vp.get_mouse_position()
	var world_pos := mouse + camera_offset
	var cell := _world_to_cell(world_pos)
	var def: Dictionary = BUILDINGS[build_mode]
	var size: Vector2i = def["size"]
	var ok := _can_build_at(cell, size) and _can_afford(def["cost"])
	var rect := Rect2(Vector2(cell) * TILE - camera_offset, Vector2(float(size.x) * TILE, float(size.y) * TILE))
	draw_rect(rect, Color(0.3, 1.0, 0.4, 0.25) if ok else Color(1.0, 0.3, 0.3, 0.25), true)
	draw_rect(rect, Color(0.6, 1.0, 0.7, 0.9) if ok else Color(1.0, 0.5, 0.5, 0.9), false, 1.5)

func _draw_hud() -> void:
	# top bar
	draw_rect(Rect2(0, 0, VIEW_SIZE.x, 52), Color(0.04, 0.07, 0.14, 0.95))
	draw_rect(Rect2(0, 52, VIEW_SIZE.x, 2), Color("26436b"))
	var clock := "%02d:00" % int(time_of_day * 24.0)
	draw_string(ThemeDB.fallback_font, Vector2(10, 32), "Hari %d/%d  %s%s" % [day, WIN_DAY, clock, "  MALAM" if _is_night() else ""], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("ffe65a") if not _is_night() else Color("9fb6ff"))
	# resources
	var res_line := "Kayu %d  Batu %d  Logam %d  Kristal %d" % [wood, stone, metal, crystal]
	draw_string(ThemeDB.fallback_font, Vector2(200, 22), res_line, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("ffe08b"))
	var res_line2 := "Mentah %d  Matang %d  Medkit %d" % [raw_food, food, medkits]
	draw_string(ThemeDB.fallback_font, Vector2(200, 42), res_line2, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("9fe8a0"))
	# buttons top-right: build | 1x | 3x | pause
	_draw_button(Rect2(742, 6, 42, 42), "B", Color("7b5534") if open_menu != "build" else Color("a97b4a"))
	_draw_button(Rect2(790, 6, 38, 40), ">", Color("3869a8") if game_speed == 1.0 and not paused else Color("26436b"))
	_draw_button(Rect2(830, 6, 38, 40), ">>", Color("3869a8") if game_speed == 3.0 and not paused else Color("26436b"))
	_draw_button(Rect2(870, 6, 38, 40), "||", Color("a83838") if paused else Color("26436b"))
	# bottom panel
	draw_rect(Rect2(0, 435, VIEW_SIZE.x, 78), Color(0.04, 0.07, 0.14, 0.95))
	draw_rect(Rect2(0, 435, VIEW_SIZE.x, 2), Color("26436b"))
	for i in range(colonists.size()):
		var c: Dictionary = colonists[i]
		var x := 14.0 + i * 120.0
		var sel := i == selected_colonist
		draw_rect(Rect2(x, 440, 112, 66), Color(0.1, 0.16, 0.28, 0.9) if sel else Color(0.07, 0.1, 0.18, 0.8))
		if sel:
			draw_rect(Rect2(x, 440, 112, 66), Color("ffe65a"), false, 1.5)
		var status_color := Color("c4d4f2")
		if bool(c["dead"]):
			status_color = Color("666a77")
		elif bool(c["downed"]):
			status_color = Color("ff7777")
		elif float(c["break_t"]) > 0.0:
			status_color = Color("ff77ff")
		draw_string(ThemeDB.fallback_font, Vector2(x + 6, 456), str(c["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, status_color)
		# bars: hp, hunger, sleep, mood
		_draw_bar(Vector2(x + 6, 462), 100.0, 6.0, float(c["hp"]) / float(c["max_hp"]), Color("e05555"), Color("39222a"))
		_draw_bar(Vector2(x + 6, 471), 100.0, 6.0, float(c["hunger"]) / 100.0, Color("e0a030"), Color("392f1f"))
		_draw_bar(Vector2(x + 6, 480), 100.0, 6.0, float(c["sleep"]) / 100.0, Color("7090e0"), Color("1f2439"))
		_draw_bar(Vector2(x + 6, 489), 100.0, 6.0, float(c["mood"]) / 100.0, Color("70d080"), Color("1f392a"))
		if bool(c["dead"]):
			draw_string(ThemeDB.fallback_font, Vector2(x + 40, 490), "MENINGGAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("888888"))
	# audio button
	_draw_button(Rect2(700, 445, 70, 26), "AUDIO", Color("3869a8") if audio_enabled else Color("26436b"))
	# alert
	if alert_text != "":
		var a_color := Color("ff7777") if alert_text.begins_with("RAID") or alert_text.begins_with("!") else Color("ffe65a")
		draw_string(ThemeDB.fallback_font, Vector2(470, 460), alert_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, a_color)
		if alert_sub != "":
			draw_string(ThemeDB.fallback_font, Vector2(470, 478), alert_sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("dbe7ff"))

func _draw_bar(pos: Vector2, width: float, height: float, frac: float, col: Color, bg: Color) -> void:
	draw_rect(Rect2(pos, Vector2(width, height)), bg, true)
	draw_rect(Rect2(pos, Vector2(width * clampf(frac, 0.0, 1.0), height)), col, true)

func _draw_build_menu() -> void:
	# panel (120,60) to (780,180): 4 cols x 3 rows
	draw_rect(Rect2(120, 60, 660, 120), Color(0.06, 0.09, 0.17, 0.97))
	draw_rect(Rect2(120, 60, 660, 120), Color("26436b"), false, 1.5)
	var keys: Array = BUILDINGS.keys()
	var cols := 4
	var cell_w := 660.0 / float(cols)
	for idx in range(keys.size()):
		var kind: String = keys[idx]
		var def: Dictionary = BUILDINGS[kind]
		var col := idx % cols
		var row := idx / cols
		var r := Rect2(120.0 + float(col) * cell_w + 4.0, 60.0 + float(row) * 40.0 + 3.0, cell_w - 8.0, 34.0)
		var afford: bool = _can_afford(def["cost"])
		draw_rect(r, Color(0.12, 0.18, 0.3, 0.95) if afford else Color(0.1, 0.1, 0.13, 0.95))
		var icon_key: String = _building_tex(kind)
		if textures.has(icon_key):
			draw_texture_rect(textures[icon_key], Rect2(r.position + Vector2(2, 1), Vector2(32, 32)), false)
		var label: String = "%s  %s" % [def["name"], _cost_text(def["cost"])]
		draw_string(ThemeDB.fallback_font, r.position + Vector2(38, 21), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("ffe08b") if afford else Color("888888"))

func _draw_button(rect: Rect2, label: String, color: Color) -> void:
	draw_rect(rect, color, true)
	draw_rect(rect, Color(1, 1, 1, 0.15), false, 1.0)
	var font_size := 18 if label.length() <= 3 else 15
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(rect.size.x * 0.5 - float(label.length()) * font_size * 0.3, rect.size.y * 0.5 + font_size * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("ffffff"))

func _set_alert(text: String, sub: String) -> void:
	alert_text = text
	alert_sub = sub
	alert_time = 3.0

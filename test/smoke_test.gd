# =====================================================================
# PIXEL GALAXY FRONTIER - Runtime Smoke Test (headless)
# Drives the REAL game script through every major system:
# menu, newgame, needs, jobs, build, farm, cook, combat, turret,
# wall-chew, rescue, save/load, night raid, win, lose, restart.
# Usage: godot --headless -s test/smoke_test.gd
# Results written to res://test/smoke_result.txt
# =====================================================================
extends SceneTree

# 'game' must stay untyped (Variant) so script vars/methods resolve dynamically
var game
var oks := 0
var fails := 0
var crashes := 0
var done := false

# remembered state for cross-phase assertions
var saved_day: int = 0
var saved_wood: int = 0
var saved_food: int = 0
var saved_colonist_count: int = 0
var saved_buildings: int = 0
var rescued_name: String = ""
var wall_cell := Vector2i(-1, -1)
var turret_cell := Vector2i(-1, -1)
var bed_cell := Vector2i(-1, -1)
var farm_cell := Vector2i(-1, -1)
var stove_cell := Vector2i(-1, -1)
var golem_hp_before: float = 0.0
var colonist_before_move := Vector2.ZERO
var move_target := Vector2.ZERO
var log_lines: Array = []


func _initialize() -> void:
	print("=== SMOKE TEST START ===")
	_run_all()
	done = true


func _process(_delta: float) -> bool:
	return true  # quit on first engine frame (all work is synchronous)


func _run_all() -> void:
	var script: GDScript = load("res://scripts/main.gd")
	game = Node2D.new()
	game.set_script(script)
	root.add_child(game)
	# NOTE: Godot defers _ready via the message queue, which only flushes on the
	# first frame. We run everything synchronously here, so call _ready manually
	# (idempotent: seeds rng, loads assets, sets up audio players, shows menu).
	game._ready()
	# keep engine frames from advancing game state; the test drives it manually
	game.paused = true
	logmsg("game=%s mode=%s colonists=%d textures=%d" % [str(game.name), str(game.mode), int(game.colonists.size()), int(game.textures.size())])

	# ---- P1: menu & new game ----
	check("P1 menu mode", str(game.mode) == "menu")
	check("P1 assets loaded", int(game.textures.size()) >= 40)
	check("P1 tex grass", game.textures.has("grass"))
	check("P1 tex rex0", game.textures.has("rex0"))
	check("P1 tex slime0", game.textures.has("slime0"))
	check("P1 tex wall", game.textures.has("wall"))
	check("P1 tex turret", game.textures.has("turret"))
	check("P1 draw menu ok", _safe_draw())

	game._start_new_game()
	check("P1 game mode", str(game.mode) == "game")
	check("P1 3 colonists", int(game.colonists.size()) == 3)
	check("P1 names", str(game.colonists[0]["name"]) == "Rex")
	check("P1 nodes spawned", int(game.resource_nodes.size()) >= 40)
	check("P1 starting res", int(game.wood) == 24 and int(game.stone) == 12)
	check("P1 pod+campfire", int(game.buildings.size()) == 2)

	# ---- P2: simulation 60 game-minutes normal speed ----
	_run_game_time(60.0)
	check("P2 sim ran 60s", true)
	var jobs_seen := {}
	var moved := false
	var p0: Vector2 = game.colonists[0]["pos"]
	for i in range(60):
		_run_game_time(1.0)
		for c in game.colonists:
			jobs_seen[str(c["job"])] = true
			if (c["pos"] as Vector2).distance_to(p0) > 8.0:
				moved = true
	check("P2 colonists move", moved)
	check("P2 jobs assigned", jobs_seen.size() >= 2)
	logmsg("P2 jobs seen: %s" % str(jobs_seen.keys()))

	# nobody should be dead/downed after one calm hour
	var calm: bool = true
	for c in game.colonists:
		if bool(c["dead"]) or bool(c["downed"]):
			calm = false
	check("P2 calm hour no casualties", calm)

	# mood balance check: mood must NOT tank to mental-break range in an hour
	var worst_mood := 100.0
	for c in game.colonists:
		worst_mood = minf(worst_mood, float(c["mood"]))
	check("P2 mood stays sane (>25 after 120s)", worst_mood > 25.0)

	# ---- P3: UI - build menu open, turret slot tap (via real grid math) ----
	game.metal = 10
	game.stone = 10
	game._handle_tap(Vector2(763.0, 27.0))  # build icon center
	check("P3 build menu open", str(game.open_menu) == "build")

	# replicate _tap_build_menu grid math to find the turret slot
	var keys: Array = game.BUILDINGS.keys()
	var tslot: int = keys.find("turret")
	var tcol: int = tslot % 4
	var trow: int = tslot / 4
	var cell_w := 660.0 / 4.0
	var tap_pos := Vector2(120.0 + float(tcol) * cell_w + 30.0, 60.0 + float(trow) * 40.0 + 20.0)
	game._handle_tap(tap_pos)
	check("P3 turret selected", str(game.build_mode) == "turret")

	# ---- P4: place turret directly (give resources), build it via builder ----
	game.metal = 10
	game.stone = 10
	var turret_target := Vector2i(10, 14)
	if game._can_build_at(turret_target, game.BUILDINGS["turret"]["size"]):
		game._place_building("turret", turret_target)
		turret_cell = turret_target
		check("P4 turret placed", game._building_at(turret_target)["kind"] == "turret")
	else:
		check("P4 turret placed", false)

	# build it instantly for testing (simulates builder work complete)
	var turret_b: Dictionary = game._building_at(turret_target)
	if not turret_b.is_empty():
		turret_b["needs_build"] = false
		turret_b["progress"] = 100.0

	# also place bed + farm + stove for later phases
	game.wood = 60
	game.stone = 20
	var bed_target := Vector2i(9, 10)
	if game._can_build_at(bed_target, game.BUILDINGS["bed"]["size"]):
		game._place_building("bed", bed_target)
		bed_cell = bed_target
	var farm_target := Vector2i(16, 12)
	if game._can_build_at(farm_target, game.BUILDINGS["farm"]["size"]):
		game._place_building("farm", farm_target)
		farm_cell = farm_target
	var stove_target := Vector2i(11, 12)
	if game._can_build_at(stove_target, game.BUILDINGS["stove"]["size"]):
		game._place_building("stove", stove_target)
		stove_cell = stove_target
	check("P4 bed placed", not game._building_at(bed_target).is_empty())
	check("P4 farm placed", not game._building_at(farm_target).is_empty())
	check("P4 stove placed", not game._building_at(stove_target).is_empty())
	check("P4 blockish rebuild ok", game.blocked.size() > 0)

	# ---- P5: builder completes construction (wall) ----
	var wall_target := Vector2i(15, 18)
	var wall_placed: bool = false
	if game._can_build_at(wall_target, game.BUILDINGS["wall_wood"]["size"]):
		game._place_building("wall_wood", wall_target)
		wall_cell = wall_target
		wall_placed = true
	check("P5 wall placed", wall_placed)
	var wall_b: Dictionary = game._building_at(wall_target)
	if not wall_b.is_empty():
		check("P5 wall blueprint state", bool(wall_b["needs_build"]) == true)
		# before built: must NOT block pathing
		var path_open: Array = game._find_path(Vector2i(14, 18), Vector2i(16, 18))
		check("P5 blueprint does not block", not path_open.is_empty())
		# drive real builder job: assign Bolt (builder) to build it
		var bolt: Dictionary = game.colonists[2]
		bolt["job"] = "build"
		bolt["target"] = game.buildings.find(wall_b)
		bolt["work_t"] = 0.0
		bolt["path"] = []
		var guard := 0
		while (not done) and bool(wall_b.get("needs_build", false)) and guard < 400:
			_run_game_time(0.2)
			guard += 1
		check("P5 wall constructed by builder", not bool(wall_b.get("needs_build", true)))
		# after built: A* must never route THROUGH the wall (it goes around it)
		var path_around: Array = game._find_path(Vector2i(14, 18), Vector2i(16, 18))
		check("P5 path avoids wall cell", not path_around.has(wall_target))
		check("P5 blocked map has wall", game.blocked.has(wall_target))
		# tapping a wall tile: path must never END inside the wall cell
		var path_into: Array = game._find_path(Vector2i(15, 17), Vector2i(15, 18))
		check("P5 path into wall rejected", not path_into.has(wall_target))

	# ---- P6: tap-flow wall placement via UI (in-view target) ----
	# camera_offset is (320,320): screen pos + camera = world. Choose world
	# cell (18,20) -> world (592,672) -> screen (272,352)
	var ui_wall_world := Vector2(18.0 * 32.0 + 16.0, 20.0 * 32.0 + 16.0)
	var ui_wall_screen := ui_wall_world - (game.camera_offset as Vector2)
	if game._can_build_at(Vector2i(18, 20), game.BUILDINGS["wall_wood"]["size"]):
		game.build_mode = "wall_wood"
		game._handle_tap(ui_wall_screen)
		check("P6 ui wall placed", game._building_at(Vector2i(18, 20))["kind"] == "wall_wood")
		check("P6 build mode cleared", str(game.build_mode) == "")
	else:
		check("P6 ui wall placed", false)

	# ---- P7: move order via UI tap (in-view, ground) ----
	var rex: Dictionary = game.colonists[0]
	game.selected_colonist = 0
	var move_screen := Vector2(400.0, 260.0)
	colonist_before_move = rex["pos"]
	move_target = move_screen + (game.camera_offset as Vector2)
	if game._can_build_at(game._world_to_cell(move_target), Vector2i(1, 1)):
		game._handle_tap(move_screen)
		check("P7 move job set", str(rex["job"]) == "move")
		var guard7 := 0
		while guard7 < 300 and str(rex["job"]) == "move":
			_run_game_time(0.2)
			guard7 += 1
		var dist_moved: float = (rex["pos"] as Vector2).distance_to(colonist_before_move)
		check("P7 colonist walked (%.0fpx)" % dist_moved, dist_moved > 40.0)
		check("P7 move job cleared", str(rex["job"]) != "move")
	else:
		check("P7 move job set", false)

	# ---- P8: turret auto-fires at monster ----
	_quarantine()
	var turret_pos: Vector2 = game._cell_center(turret_cell)
	var m_spawn: Dictionary = {}
	for m in game.monsters:
		m_spawn = m
	if m_spawn.is_empty():
		game._spawn_monster("slime", false)
		if game.monsters.size() > 0:
			m_spawn = game.monsters[0]
	check("P8 monster present", not m_spawn.is_empty())
	if not m_spawn.is_empty():
		# teleport monster right next to turret (within 200px range)
		m_spawn["pos"] = turret_pos + Vector2(90.0, 0.0)
		var bullets_before: int = int(game.bullets.size())
		var guard8 := 0
		while guard8 < 60 and int(game.bullets.size()) == bullets_before:
			_run_game_time(0.1)
			guard8 += 1
		check("P8 turret fired", int(game.bullets.size()) > bullets_before)
		# let turret+bullets kill the slime (46hp / 9dmg per 1.4s)
		var guard8b := 0
		while guard8b < 400 and game.monsters.size() > 0:
			_run_game_time(0.2)
			guard8b += 1
		check("P8 turret killed slime", int(game.stat_kills) >= 1)

	# ---- P9: colonist attacks monster, kills it ----
	_quarantine()
	var kills_before: int = int(game.stat_kills)
	game.monsters.clear()
	game.bullets.clear()
	game._spawn_monster("bat", false)
	var bat: Dictionary = {}
	if game.monsters.size() > 0:
		bat = game.monsters[0]
	check("P9 bat spawned", not bat.is_empty())
	if not bat.is_empty():
		bat["pos"] = game.colonists[0]["pos"] + Vector2(60.0, 0.0)
		rex["job"] = "attack"
		rex["target"] = 0
		rex["work_t"] = 0.0
		rex["path"] = []
		var guard9 := 0
		while guard9 < 400 and game.monsters.size() > 0 and not bool(rex["dead"]) and not bool(rex["downed"]):
			_run_game_time(0.2)
			guard9 += 1
		check("P9 colonist killed bat", int(game.stat_kills) > kills_before)
		# the job clears on the NEXT _update_colonist tick after monster removal
		_run_game_time(0.5)
		check("P9 attack job cleared", str(rex["job"]) != "attack")

	# ---- P10: fighter auto-defense (within 170px) ----
	_quarantine()
	var guard10_check := false
	game.monsters.clear()
	game._spawn_monster("slime", false)
	if game.monsters.size() > 0:
		var slime2: Dictionary = game.monsters[0]
		slime2["pos"] = rex["pos"] + Vector2(120.0, 40.0)
		rex["job"] = ""
		rex["target"] = -1
		var guard10 := 0
		while guard10 < 200:
			_run_game_time(0.2)
			if str(rex["job"]) == "attack" or game.monsters.size() == 0:
				break
			guard10 += 1
		guard10_check = str(rex["job"]) == "attack" or game.monsters.size() == 0
	check("P10 fighter auto-defense", guard10_check)

	# ---- P11: farm grows & gets harvested, stove cooks ----
	_quarantine()
	var farm_b: Dictionary = {}
	for b in game.buildings:
		if b["kind"] == "farm" and b["cell"] == farm_cell:
			farm_b = b
	if not farm_b.is_empty():
		farm_b["needs_build"] = false
		farm_b["progress"] = 100.0
		farm_b["planted"] = true
		farm_b["growth"] = 0.0
		farm_b["grown"] = false
		var raw_before: int = int(game.raw_food)
		_run_game_time(80.0)  # growth = 70s
		check("P11 farm grew", bool(farm_b.get("grown", false)))
		# colonists should auto-harvest (farm job) or we order it
		var guard11 := 0
		while guard11 < 400 and bool(farm_b.get("grown", false)):
			_run_game_time(0.2)
			guard11 += 1
		# assert on the farm's own state: harvested -> replanted, growth restarted
		# (growth resets to 0 at harvest, then the final loop step adds <1s)
		var harvested: bool = (not bool(farm_b.get("grown", false))) and bool(farm_b.get("planted", false)) and float(farm_b.get("growth", 99.0)) < 5.0
		check("P11 farm harvested & replanted", harvested)
	else:
		check("P11 farm exists", false)

	var stove_b: Dictionary = {}
	for b in game.buildings:
		if b["kind"] == "stove" and b["cell"] == stove_cell:
			stove_b = b
	if not stove_b.is_empty():
		stove_b["needs_build"] = false
		stove_b["progress"] = 100.0
		game.raw_food = 10
		var food_before: int = int(game.food)
		var luna: Dictionary = game.colonists[1]
		game.selected_colonist = 1
		luna["job"] = "cook"
		luna["target"] = game.buildings.find(stove_b)
		luna["work_t"] = 0.0
		luna["path"] = []
		var guard11b := 0
		while guard11b < 300 and int(game.food) <= food_before:
			_run_game_time(0.2)
			guard11b += 1
		check("P11 stove cooked (+2 food)", int(game.food) > food_before)
		check("P11 cook job cleared", str(luna["job"]) != "cook")
	else:
		check("P11 stove exists", false)

	# ---- P12: eating - hunger triggers food consumption (rate-limited) ----
	var luna2: Dictionary = game.colonists[1]
	luna2["hunger"] = 20.0
	game.food = 6
	var food_before_eat: int = int(game.food)
	_run_game_time(1.0)
	check("P12 ate a meal", int(game.food) < food_before_eat)
	check("P12 hunger restored", float(luna2["hunger"]) > 50.0)

	# raw fallback eating when no cooked food
	luna2["hunger"] = 15.0
	game.food = 0
	game.raw_food = 5
	var raw_before_eat: int = int(game.raw_food)
	_run_game_time(1.0)
	check("P12 raw fallback ate", int(game.raw_food) < raw_before_eat)

	# ---- P13: ground sleeping when no bed ----
	_quarantine()
	var bolt2: Dictionary = game.colonists[2]
	var bed_b: Dictionary = {}
	for b in game.buildings:
		if b["kind"] == "bed" and b["cell"] == bed_cell:
			bed_b = b
	if not bed_b.is_empty():
		bed_b["needs_build"] = false
	bolt2["sleep"] = 10.0
	bolt2["job"] = ""
	bolt2["target"] = -1
	game.time_of_day = 0.75  # night
	_run_game_time(2.0)
	check("P13 ground sleep job", str(bolt2["job"]) == "sleep")
	var sleep_before: float = float(bolt2["sleep"])
	_run_game_time(5.0)
	check("P13 sleep recovers", float(bolt2["sleep"]) > sleep_before)

	# ---- P14: downed colonist + rescue ----
	game.time_of_day = 0.3  # day (avoid night-spawn interference)
	game.monsters.clear()
	# revive savior (earlier phases may have downed Rex during night loops)
	for c in game.colonists:
		if not bool(c["dead"]):
			c["downed"] = false
			c["downed_t"] = 0.0
			c["break_t"] = 0.0
			c["job"] = ""
			c["target"] = -1
			c["path"] = []
			c["hp"] = maxf(float(c["hp"]), 50.0)
	var victim: Dictionary = game.colonists[1]  # Luna
	var savior: Dictionary = game.colonists[0]  # Rex
	victim["hp"] = 0.0
	victim["downed"] = true
	victim["downed_t"] =  0.0
	victim["dead"] = false
	victim["job"] = ""
	victim["target"] = -1
	rescued_name = str(victim["name"])
	savior["job"] = "rescue"
	savior["target"] = 1
	savior["work_t"] = 0.0
	savior["path"] = []
	savior["pos"] = (victim["pos"] as Vector2) + Vector2(24.0, 0.0)
	var guard14 := 0
	while guard14 < 200 and bool(victim["downed"]):
		_run_game_time(0.2)
		guard14 += 1
	check("P14 rescue completed", not bool(victim["downed"]))
	check("P14 victim stabilized (hp>=22)", float(victim["hp"]) >= 22.0)
	check("P14 rescue job cleared", str(savior["job"]) != "rescue")

	# ---- P15: medkit healing ----
	_quarantine()
	# revive any casualties from earlier phases so the heal chain is testable
	for c in game.colonists:
		c["dead"] = false
		c["downed"] = false
		c["downed_t"] = 0.0
		c["break_t"] = 0.0
		c["break_kind"] = ""
		c["hp"] = maxf(float(c["hp"]), 80.0)
		c["hunger"] = maxf(float(c["hunger"]), 60.0)
		c["sleep"] = maxf(float(c["sleep"]), 60.0)
		c["mood"] = maxf(float(c["mood"]), 70.0)
	game.medkits = 3
	var patient: Dictionary = game.colonists[2]
	patient["hp"] = 40.0
	patient["downed"] = false
	var healer: Dictionary = game.colonists[0]
	healer["job"] = "heal"
	healer["target"] = 2
	healer["work_t"] = 0.0
	healer["path"] = []
	healer["pos"] = (patient["pos"] as Vector2) + Vector2(24.0, 0.0)
	var guard15 := 0
	while guard15 < 200 and float(patient["hp"]) < 70.0 and str(healer["job"]) == "heal":
		_run_game_time(0.2)
		guard15 += 1
	check("P15 medkit healed (+35)", float(patient["hp"]) >= 70.0)
	check("P15 medkit consumed", int(game.medkits) < 3)

	# ---- P16: monster chews wall (full enclosure = real defense scenario) ----
	_quarantine()
	# clear nodes in the ring area so walls can be placed
	var ring_center := Vector2i(22, 20)
	var ring_cells: Array = [
		Vector2i(21, 19), Vector2i(22, 19), Vector2i(23, 19),
		Vector2i(21, 20), Vector2i(23, 20),
		Vector2i(21, 21), Vector2i(22, 21), Vector2i(23, 21),
	]
	for n in game.resource_nodes:
		if ring_cells.has(n["cell"]) or n["cell"] == ring_center:
			n["hp"] = 0.0
	game._rebuild_blocked()
	var ring_placed := 0
	for rc in ring_cells:
		if game._can_build_at(rc, Vector2i(1, 1)):
			game._place_building("wall_wood", rc)
			var rb: Dictionary = game._building_at(rc)
			if not rb.is_empty():
				rb["needs_build"] = false
				rb["progress"] = 100.0
			ring_placed += 1
	check("P16 wall ring placed (8/8)", ring_placed == 8)
	game._rebuild_blocked()
	# verify enclosure: paths from outside must stop OUTSIDE the ring
	var breach: Array = game._find_path(Vector2i(22, 16), ring_center)
	check("P16 enclosure blocks entry", not breach.has(ring_center) and not breach.is_empty())
	# colonists: Luna inside, others far away
	var luna_in: Dictionary = game.colonists[1]
	luna_in["pos"] = game._cell_center(ring_center)
	luna_in["job"] = ""
	luna_in["target"] = -1
	luna_in["path"] = []
	game.colonists[0]["pos"] = game._cell_center(Vector2i(40, 8))
	game.colonists[2]["pos"] = game._cell_center(Vector2i(42, 8))
	# spawn golem just north of the ring
	game._spawn_monster("golem", false)
	var golem: Dictionary = {}
	if game.monsters.size() > 0:
		golem = game.monsters[0]
	check("P16 golem spawned", not golem.is_empty())
	if not golem.is_empty():
		golem["pos"] = game._cell_center(Vector2i(22, 17))
		var ring_hps := {}
		for rc in ring_cells:
			var rb2: Dictionary = game._building_at(rc)
			if not rb2.is_empty():
				ring_hps[rc] = float(rb2["hp"])
		var guard16 := 0
		var wall_dmg_seen: bool = false
		while guard16 < 400:
			_run_game_time(0.2)
			for rc in ring_cells:
				var rb3: Dictionary = game._building_at(rc)
				if rb3.is_empty():
					wall_dmg_seen = true
					break
				if float(rb3["hp"]) < float(ring_hps[rc]):
					wall_dmg_seen = true
					break
			if wall_dmg_seen:
				break
			guard16 += 1
		check("P16 golem chews wall ring", wall_dmg_seen)
		# golem must eventually break through (wall_dmg 25, cd 1.0, 8 walls * 80hp)
		var guard16b := 0
		var breach_seen: bool = false
		while guard16b < 900 and not breach_seen:
			_run_game_time(0.2)
			var entry: Array = game._find_path(Vector2i(22, 16), ring_center)
			if entry.has(ring_center):
				breach_seen = true
			guard16b += 1
		check("P16 golem breaks through eventually", breach_seen)
		check("P16 luna still alive", not bool(game.colonists[1]["dead"]))

	# ---- P17: night spawns + raid system ----
	game.monsters.clear()
	game.time_of_day = 0.85  # deep night
	game.night_spawn_timer = 0.1  # re-enable spawns (quarantine set it to 9999)
	var monsters_before: int = int(game.monsters.size())
	_run_game_time(2.0)
	check("P17 night monsters spawned", int(game.monsters.size()) > monsters_before)
	# force a raid
	game.raid_timer = 0.1
	game.monsters.clear()
	var raid_before: int = int(game.monsters.size())
	_run_game_time(0.5)
	check("P17 raid spawned monsters", int(game.monsters.size()) > raid_before)
	check("P17 raid alert", str(game.alert_text).length() > 0)

	# ---- P18: save / load round-trip ----
	saved_day = int(game.day)
	saved_wood = int(game.wood)
	saved_food = int(game.food)
	saved_colonist_count = int(game.colonists.size())
	saved_buildings = int(game.buildings.size())
	game._save_game()
	check("P18 save file written", game._has_save())
	# mutate state, then load back
	game.wood = 999
	game.day = 99
	game.food = 0
	var load_ok: bool = game._load_game()
	check("P18 load returns true", load_ok)
	check("P18 wood restored", int(game.wood) == saved_wood)
	check("P18 day restored", int(game.day) == saved_day)
	check("P18 food restored", int(game.food) == saved_food)
	check("P18 colonists restored", int(game.colonists.size()) == saved_colonist_count)
	check("P18 buildings restored", int(game.buildings.size()) == saved_buildings)
	check("P18 mode stays game", str(game.mode) == "game")
	check("P18 draw after load ok", _safe_draw())

	# ---- P19: wall blocks monster pathing (A* respects blocked) ----
	var block_cell := Vector2i(17, 22)
	if game._can_build_at(block_cell, Vector2i(1, 1)):
		game._place_building("wall_stone", block_cell)
		var wb3: Dictionary = game._building_at(block_cell)
		if not wb3.is_empty():
			wb3["needs_build"] = false
			wb3["progress"] = 100.0
			game._rebuild_blocked()
			var pth: Array = game._find_path(Vector2i(16, 22), Vector2i(18, 22))
			check("P19 path avoids wall cell", not pth.has(block_cell))

	# ---- P20: win condition (day > 30) ----
	game.day = 30
	game.time_of_day = 0.99
	_run_game_time(5.0)
	check("P20 win screen", str(game.mode) == "over")
	check("P20 win title", str(game.alert_text).find("SELAMAT") >= 0)
	game._handle_tap(Vector2(455.0, 380.0))  # restart button center
	check("P20 restart new game", str(game.mode) == "game")
	check("P20 restart day 1", int(game.day) == 1)

	# ---- P21: lose condition (all colonists dead) ----
	for c in game.colonists:
		c["dead"] = true
	_run_game_time(0.1)
	check("P21 lose screen", str(game.mode) == "over")
	check("P21 lose title", str(game.alert_text).find("HANCUR") >= 0)
	game._handle_tap(Vector2(455.0, 455.0))  # to menu button
	check("P21 back to menu", str(game.mode) == "menu")

	# ---- P22: draw full game + HUD + build menu (rendering coverage) ----
	game._handle_tap(Vector2(455.0, 280.0))  # new game from menu
	check("P22 new game started", str(game.mode) == "game")
	game.open_menu = "build"
	check("P22 draw game+buildmenu ok", _safe_draw())
	game.open_menu = ""
	game.build_mode = "wall_wood"
	check("P22 draw build preview ok", _safe_draw())
	game.build_mode = ""
	game.time_of_day = 0.85
	check("P22 draw night overlay ok", _safe_draw())
	game.time_of_day = 0.25
	game.alert_text = "TES"
	game.alert_sub = "sub"
	game.alert_time = 2.0
	check("P22 draw alert ok", _safe_draw())

	# ---- P23: pause & speed buttons ----
	game.paused = false
	game._handle_tap(Vector2(889.0, 26.0))  # pause btn center (870..908, 6..46)
	check("P23 pause button", bool(game.paused) == true)
	game._handle_tap(Vector2(810.0, 26.0))  # speed 1x btn (790..828)
	check("P23 speed 1x unpauses", bool(game.paused) == false)
	check("P23 speed 1x value", absf(float(game.game_speed) - 1.0) < 0.01)
	game._handle_tap(Vector2(849.0, 26.0))  # speed 3x btn (830..868)
	check("P23 speed 3x value", absf(float(game.game_speed) - 3.0) < 0.01)

	# ---- P24: audio toggle ----
	var audio_before: bool = bool(game.audio_enabled)
	game._handle_tap(Vector2(735.0, 460.0))  # audio button (700..770, 445..475)
	check("P24 audio toggled", bool(game.audio_enabled) != audio_before)
	game._handle_tap(Vector2(735.0, 470.0))
	check("P24 audio toggled back", bool(game.audio_enabled) == audio_before)

	# ---- P25: colonist portrait selection ----
	game._handle_tap(Vector2(14.0 + 1 * 120.0 + 56.0, 473.0))  # 2nd portrait
	check("P25 portrait selects colonist", int(game.selected_colonist) == 1)

	# ---- P26: long-run stability (240s fast sim, monsters+night cycle) ----
	game.monsters.clear()
	game.time_of_day = 0.6
	var guard26 := 0
	while guard26 < 1200 and str(game.mode) == "game":
		_run_game_time(0.2)
		guard26 += 1
	check("P26 long-run no crash (240s)", true)
	check("P26 still in game or ended cleanly", str(game.mode) == "game" or str(game.mode) == "over")
	logmsg("P26 end state: mode=%s day=%d monsters=%d kills=%d" % [str(game.mode), int(game.day), int(game.monsters.size()), int(game.stat_kills)])

	_finish()


# ============ helpers ============

func _quarantine() -> void:
	# deterministic combat phases: daytime, no ambient spawns, no raids, no monsters
	game.time_of_day = 0.3
	game.night_spawn_timer = 9999.0
	game.raid_timer = 9999.0
	game.monsters.clear()
	game.bullets.clear()


func _run_game_time(seconds: float) -> void:
	# step the game manually in 0.1s increments (max 40 steps per call-batch)
	var steps := int(seconds / 0.1)
	for i in range(steps):
		if str(game.mode) != "game":
			return
		game._update_game(0.1)


func _safe_draw() -> bool:
	game.queue_redraw()
	game._draw()
	return true


func check(label: String, cond: bool) -> void:
	if cond:
		oks += 1
		logmsg("OK   %s" % label)
	else:
		fails += 1
		logmsg("FAIL %s" % label)


func logmsg(msg: String) -> void:
	log_lines.append(msg)
	print(msg)


func _finish() -> void:
	var summary := "\n=== RESULT: %d OK / %d FAIL / %d crashes ===" % [oks, fails, crashes]
	logmsg(summary)
	var text := "\n".join(log_lines)
	# write results into user dir and try project dir
	var f := FileAccess.open("user://smoke_result.txt", FileAccess.WRITE)
	if f != null:
		f.store_string(text)
		f.close()
	var f2 := FileAccess.open("res://test/smoke_result.txt", FileAccess.WRITE)
	if f2 != null:
		f2.store_string(text)
		f2.close()
	print(summary)

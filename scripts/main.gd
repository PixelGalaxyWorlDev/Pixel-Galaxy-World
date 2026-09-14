extends Node2D

const VIEW_SIZE := Vector2(909.0, 513.0)
const WORLD_SIZE := Vector2(3200.0, 1800.0)
const TILE_SIZE := 32.0
const DAY_LENGTH := 480.0
const NIGHT_START := 0.70
const NIGHT_END := 0.98
const SAVE_PATH := "user://pixel_galaxy_world.save"
const BUILD_COST_WALL := 5
const BASE_RESOURCE_GAIN := 1

var mode := "menu"
var paused := false
var game_speed := 1.0
var audio_enabled := true
var master_volume := 1.0
var day := 1
var time_of_day := 0.2
var camera_offset := Vector2(0.0, 0.0)
var dragging := false
var drag_start := Vector2.ZERO
var drag_camera_start := Vector2.ZERO
var build_mode := false
var raid_timer := 300.0
var night_spawn_timer := 8.0
var harvest_timer := 0.0
var attack_timer := 0.0
var save_timer := 8.0
var alert_text := ""
var alert_time := 0.0
var selected_colonist := 0
var tutorial_seen := false
var build_preview_pos := Vector2.ZERO
var build_preview_active := false
var danger_level := 0.0
var wood := 20
var stone := 10
var metal := 0
var crystal := 0
var food := 10
var rng := RandomNumberGenerator.new()
var textures: Dictionary = {}
var audio_player: AudioStreamPlayer

var colonists := [
	{"name": "Rex", "role": "fighter", "pos": Vector2(300, 330), "hp": 100.0, "hunger": 100.0, "sleep": 100.0, "mood": 100.0, "job": "", "target": -1},
	{"name": "Luna", "role": "harvester", "pos": Vector2(340, 360), "hp": 100.0, "hunger": 100.0, "sleep": 100.0, "mood": 100.0, "job": "", "target": -1},
	{"name": "Bolt", "role": "builder", "pos": Vector2(380, 400), "hp": 100.0, "hunger": 100.0, "sleep": 100.0, "mood": 100.0, "job": "", "target": -1},
]

var resource_nodes: Array[Dictionary] = []
var buildings: Array[Dictionary] = []
var monsters: Array[Dictionary] = []

func _ready() -> void:
	rng.seed = 42
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	_load_assets()
	if not _load_game():
		_reset_world()
		_show_tutorial()
	queue_redraw()

func _load_assets() -> void:
	var required_assets := {
		"menu_background": "res://project/resources/menu/menu-background.png",
		"grass": "res://project/resources/tiles/grass.png",
		"dirt": "res://project/resources/tiles/dirt.png",
		"crash_pod": "res://project/resources/buildings/building-9.png",
		"wall": "res://project/resources/buildings/building-10.png",
		"tree": "res://project/resources/items/item-0.png",
		"rock": "res://project/resources/items/item-1.png",
		"metal": "res://project/resources/items/item-2.png",
		"crystal": "res://project/resources/items/item-3.png",
		"food": "res://project/resources/items/item-4.png",
	}
	for key in required_assets.keys():
		var asset := load(required_assets[key])
		if asset != null:
			textures[key] = asset
		else:
			push_warning("Missing required asset: %s" % required_assets[key])
	for character in ["rex", "luna", "bolt"]:
		for frame in range(6):
			var path := "res://project/resources/characters/%s-%d.png" % [character, frame]
			var asset := load(path)
			if asset != null:
				textures[character + str(frame)] = asset
			else:
				push_warning("Missing character asset: %s" % path)
	for monster_name in ["slime", "zapper", "golem", "stalker", "bat"]:
		for frame in range(6):
			var path := "res://project/resources/monsters/%s-%d.png" % [monster_name, frame]
			var asset := load(path)
			if asset != null:
				textures[monster_name + str(frame)] = asset
			else:
				push_warning("Missing monster asset: %s" % path)

func _get_active_colonist_index() -> int:
	for i in range(colonists.size()):
		if colonists[i].hp > 0.0:
			return i
	return -1

func _vector_to_dict(value: Vector2) -> Dictionary:
	return {"x": value.x, "y": value.y}

func _dict_to_vector(value: Dictionary) -> Vector2:
	if value.is_empty():
		return Vector2.ZERO
	return Vector2(float(value.get("x", 0.0)), float(value.get("y", 0.0)))

func _reset_world() -> void:
	resource_nodes.clear()
	buildings.clear()
	monsters.clear()
	day = 1
	time_of_day = 0.2
	paused = false
	game_speed = 1.0
	raid_timer = 300.0
	night_spawn_timer = 8.0
	harvest_timer = 0.0
	attack_timer = 0.0
	save_timer = 8.0
	wood = 20
	stone = 10
	metal = 0
	crystal = 0
	food = 10
	selected_colonist = 0
	build_mode = false
	build_preview_active = false
	build_preview_pos = Vector2.ZERO
	danger_level = 0.0
	alert_text = ""
	for i in range(colonists.size()):
		var colonist: Dictionary = colonists[i]
		colonist.pos = Vector2(300 + i * 40, 330 + i * 30)
		colonist.hp = 100.0
		colonist.hunger = 100.0
		colonist.sleep = 100.0
		colonist.mood = 100.0
		colonist.job = ""
		colonist.target = -1
		if not colonist.has("role"):
			colonist["role"] = ["fighter", "harvester", "builder"][i]
		colonists[i] = colonist
	var spots := [Vector2(300, 200), Vector2(500, 150), Vector2(700, 250), Vector2(250, 400), Vector2(600, 420), Vector2(900, 180), Vector2(1100, 300), Vector2(1400, 200), Vector2(1600, 380), Vector2(1200, 500), Vector2(200, 700), Vector2(450, 900), Vector2(800, 800), Vector2(1500, 700), Vector2(1800, 500), Vector2(2100, 300), Vector2(2400, 600), Vector2(2700, 400), Vector2(400, 1200), Vector2(1000, 1100), Vector2(1700, 1000), Vector2(2300, 1100), Vector2(2900, 900), Vector2(2600, 1400)]
	var kinds := ["tree", "rock", "metal", "crystal", "food"]
	for i in range(spots.size()):
		var kind: String = kinds[i % kinds.size()]
		var amount := 5
		if kind == "metal": amount = 4
		if kind == "crystal": amount = 3
		resource_nodes.append({"kind": kind, "pos": spots[i] + Vector2(rng.randf_range(-45, 45), rng.randf_range(-45, 45)), "amount": amount})
	buildings.append({"kind": "crash_pod", "pos": Vector2(380, 260)})

func _show_tutorial() -> void:
	if tutorial_seen:
		return
	tutorial_seen = true
	_set_alert("Panduan:\n1. Tap kolonis\n2. Tap sumber daya\n3. Tekan PALU untuk bangun")

func _can_place_wall(pos: Vector2) -> bool:
	for building in buildings:
		if building.get("kind", "") == "wall" and building.get("pos", Vector2.ZERO).distance_to(pos) < 10.0:
			return false
	return true

func _get_colonist_role(colonist: Dictionary) -> String:
	if colonist.has("role") and typeof(colonist["role"]) == TYPE_STRING:
		return colonist["role"]
	return "fighter"

func _role_bonus_damage(colonist: Dictionary) -> float:
	match _get_colonist_role(colonist):
		"fighter":
			return 1.35
		"harvester":
			return 1.0
		"builder":
			return 1.15
		_:
			return 1.0

func _role_bonus_harvest(colonist: Dictionary) -> int:
	match _get_colonist_role(colonist):
		"harvester":
			return 2
		"builder":
			return 1
		_:
			return 1

func _find_best_resource_for_colonist(colonist: Dictionary) -> int:
	var best_index := -1
	var best_distance := INF
	for i in range(resource_nodes.size()):
		var node: Dictionary = resource_nodes[i]
		if node.get("amount", 0) <= 0: continue
		if _get_colonist_role(colonist) == "fighter" and node.get("kind", "") == "food":
			continue
		var distance: float = colonist.pos.distance_to(node.get("pos", Vector2.ZERO))
		if distance < best_distance:
			best_distance = distance
			best_index = i
	return best_index

func _auto_assign_tasks() -> void:
	for i in range(colonists.size()):
		var colonist: Dictionary = colonists[i]
		if colonist.hp <= 0.0: continue
		if colonist.job == "attack":
			continue
		if colonist.hunger < 35.0 and food > 0:
			colonist.hunger = minf(100.0, colonist.hunger + 25.0)
			food -= 1
		if colonist.sleep < 30.0 and time_of_day > 0.8:
			colonist.job = ""
			colonist.target = -1
			continue
		var nearest_monster_index := -1
		var nearest_monster_distance := 999999.0
		for j in range(monsters.size()):
			var monster: Dictionary = monsters[j]
			if monster.hp <= 0.0: continue
			var d: float = colonist.pos.distance_to(monster.pos)
			if d < nearest_monster_distance:
				nearest_monster_index = j
				nearest_monster_distance = d
		if _get_colonist_role(colonist) == "fighter" and nearest_monster_index >= 0 and nearest_monster_distance < 180.0:
			colonist.job = "attack"
			continue
		var target_index := _find_best_resource_for_colonist(colonist)
		if target_index >= 0:
			colonist.job = "harvest"
			colonist.target = target_index
		else:
			colonist.job = ""
			colonist.target = -1
		colonists[i] = colonist

func _save_game() -> void:
	var save_data := {
		"mode": mode,
		"paused": paused,
		"game_speed": game_speed,
		"day": day,
		"time_of_day": time_of_day,
		"camera_offset": _vector_to_dict(camera_offset),
		"selected_colonist": selected_colonist,
		"wood": wood,
		"stone": stone,
		"metal": metal,
		"crystal": crystal,
		"food": food,
		"tutorial_seen": tutorial_seen,
		"raid_timer": raid_timer,
		"night_spawn_timer": night_spawn_timer,
		"harvest_timer": harvest_timer,
		"attack_timer": attack_timer,
		"colonists": [],
		"resource_nodes": [],
		"buildings": [],
		"monsters": [],
	}
	for colonist in colonists:
		save_data["colonists"].append({
			"name": colonist.get("name", ""),
			"pos": _vector_to_dict(colonist.get("pos", Vector2.ZERO)),
			"hp": colonist.get("hp", 0.0),
			"hunger": colonist.get("hunger", 0.0),
			"sleep": colonist.get("sleep", 0.0),
			"mood": colonist.get("mood", 0.0),
			"job": colonist.get("job", ""),
			"target": colonist.get("target", -1),
		})
	for node in resource_nodes:
		save_data["resource_nodes"].append({
			"kind": node.get("kind", ""),
			"pos": _vector_to_dict(node.get("pos", Vector2.ZERO)),
			"amount": node.get("amount", 0),
		})
	for building in buildings:
		save_data["buildings"].append({
			"kind": building.get("kind", ""),
			"pos": _vector_to_dict(building.get("pos", Vector2.ZERO)),
		})
	for monster in monsters:
		save_data["monsters"].append({
			"kind": monster.get("kind", ""),
			"pos": _vector_to_dict(monster.get("pos", Vector2.ZERO)),
			"hp": monster.get("hp", 0.0),
			"damage": monster.get("damage", 0),
			"speed": monster.get("speed", 0),
			"frame_time": monster.get("frame_time", 0.0),
			"attack_timer": monster.get("attack_timer", 0.0),
		})
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Save failed: %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(save_data))
	file.close()

func _load_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var contents := file.get_as_text()
	file.close()
	if contents.strip_edges() == "":
		return false
	var parsed = JSON.parse_string(contents)
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	if not parsed.has("day"):
		return false
	mode = parsed.get("mode", "game")
	paused = bool(parsed.get("paused", false))
	game_speed = float(parsed.get("game_speed", 1.0))
	day = int(parsed.get("day", 1))
	time_of_day = float(parsed.get("time_of_day", 0.2))
	camera_offset = _dict_to_vector(parsed.get("camera_offset", {"x": 0.0, "y": 0.0}))
	selected_colonist = int(parsed.get("selected_colonist", 0))
	wood = int(parsed.get("wood", 20))
	stone = int(parsed.get("stone", 10))
	metal = int(parsed.get("metal", 0))
	crystal = int(parsed.get("crystal", 0))
	food = int(parsed.get("food", 10))
	tutorial_seen = bool(parsed.get("tutorial_seen", false))
	raid_timer = float(parsed.get("raid_timer", 300.0))
	night_spawn_timer = float(parsed.get("night_spawn_timer", 8.0))
	harvest_timer = float(parsed.get("harvest_timer", 0.0))
	attack_timer = float(parsed.get("attack_timer", 0.0))
	colonists.clear()
	for colonist_data in parsed.get("colonists", []):
		colonists.append({
			"name": str(colonist_data.get("name", "")),
			"pos": _dict_to_vector(colonist_data.get("pos", {"x": 0.0, "y": 0.0})),
			"hp": float(colonist_data.get("hp", 100.0)),
			"hunger": float(colonist_data.get("hunger", 100.0)),
			"sleep": float(colonist_data.get("sleep", 100.0)),
			"mood": float(colonist_data.get("mood", 100.0)),
			"job": str(colonist_data.get("job", "")),
			"target": int(colonist_data.get("target", -1)),
		})
	resource_nodes.clear()
	for node_data in parsed.get("resource_nodes", []):
		resource_nodes.append({
			"kind": str(node_data.get("kind", "")),
			"pos": _dict_to_vector(node_data.get("pos", {"x": 0.0, "y": 0.0})),
			"amount": int(node_data.get("amount", 0)),
		})
	buildings.clear()
	for building_data in parsed.get("buildings", []):
		buildings.append({
			"kind": str(building_data.get("kind", "")),
			"pos": _dict_to_vector(building_data.get("pos", {"x": 0.0, "y": 0.0})),
		})
	monsters.clear()
	for monster_data in parsed.get("monsters", []):
		monsters.append({
			"kind": str(monster_data.get("kind", "")),
			"pos": _dict_to_vector(monster_data.get("pos", {"x": 0.0, "y": 0.0})),
			"hp": float(monster_data.get("hp", 0.0)),
			"damage": int(monster_data.get("damage", 0)),
			"speed": int(monster_data.get("speed", 0)),
			"frame_time": float(monster_data.get("frame_time", 0.0)),
			"attack_timer": float(monster_data.get("attack_timer", 0.0)),
		})
	return true

func _process(delta: float) -> void:
	if mode == "game":
		if not tutorial_seen:
			_show_tutorial()
		if not paused:
			_update_game(delta * game_speed)
	if build_mode:
		var mouse_pos := get_viewport().get_mouse_position()
		if mouse_pos.x >= 0.0 and mouse_pos.x <= VIEW_SIZE.x and mouse_pos.y >= 0.0 and mouse_pos.y <= VIEW_SIZE.y:
			build_preview_pos = (mouse_pos + camera_offset) / TILE_SIZE
			build_preview_pos = Vector2(floor(build_preview_pos.x), floor(build_preview_pos.y)) * TILE_SIZE
	if alert_time > 0.0:
		alert_time -= delta
		if alert_time <= 0.0: alert_text = ""
	save_timer -= delta
	if mode == "game" and save_timer <= 0.0:
		save_timer = 8.0
		_save_game()
	queue_redraw()

func _update_game(delta: float) -> void:
	danger_level = 0.0 if not _is_night() else clampf((time_of_day - NIGHT_START) / (NIGHT_END - NIGHT_START), 0.0, 1.0)
	time_of_day += delta / DAY_LENGTH
	if time_of_day >= 1.0:
		time_of_day = 0.0
		day += 1
		if day >= 30:
			_finish_game("KOLONI SELAMAT!", "Bertahan sampai hari 30. Misi selesai!")
		return
	raid_timer -= delta
	night_spawn_timer -= delta
	harvest_timer -= delta
	attack_timer -= delta
	for i in range(colonists.size()):
		var colonist: Dictionary = colonists[i]
		if colonist.hp <= 0.0: continue
		colonist.hunger = maxf(0.0, colonist.hunger - delta * 0.3)
		colonist.sleep = maxf(0.0, colonist.sleep - delta * 0.2)
		colonist.mood = clampf(colonist.mood - delta * 0.1, 0.0, 100.0)
		if colonist.hunger < 30.0 and food > 0:
			colonist.hunger = minf(100.0, colonist.hunger + 50.0)
			food -= 1
		if time_of_day > 0.8 and colonist.job == "":
			colonist.sleep = minf(100.0, colonist.sleep + delta * 5.0)
			colonist.mood = minf(100.0, colonist.mood + delta * 2.0)
		_update_colonist(colonist, delta)
		colonists[i] = colonist
	_auto_assign_tasks()
	_update_monsters(delta)
	if _is_night() and night_spawn_timer <= 0.0:
		night_spawn_timer = 8.0
		_spawn_monster("slime")
	if raid_timer <= 0.0:
		raid_timer = 300.0
		_spawn_monster("slime")
		_spawn_monster("slime")
		_spawn_monster("zapper")
		_set_alert("RAID! Monster menyerang!")
	var all_down := true
	for colonist in colonists:
		if colonist.hp > 0.0: all_down = false
	if all_down:
		_finish_game("KOLONI HANCUR", "Semua kolonis tumbang pada hari %d." % day)

func _update_colonist(colonist: Dictionary, delta: float) -> void:
	if colonist.job == "attack":
		var nearest_monster: Dictionary = {}
		var nearest_distance := INF
		for monster in monsters:
			var distance: float = colonist.pos.distance_to(monster.pos)
			if monster.hp > 0.0 and distance < nearest_distance:
				nearest_monster = monster
				nearest_distance = distance
		if not nearest_monster.is_empty() and nearest_distance > 45.0:
			colonist.pos = colonist.pos.move_toward(nearest_monster.pos, 120.0 * delta)
		return
	if colonist.job == "" or colonist.target < 0 or colonist.target >= resource_nodes.size(): return
	var node: Dictionary = resource_nodes[colonist.target]
	if node.amount <= 0:
		colonist.job = ""
		colonist.target = -1
		return
	var distance: float = colonist.pos.distance_to(node.pos)
	if distance > 42.0:
		colonist.pos = colonist.pos.move_toward(node.pos, 120.0 * delta)
	elif harvest_timer <= 0.0:
		harvest_timer = 1.2
		var gain_amount := _role_bonus_harvest(colonist) + BASE_RESOURCE_GAIN
		if node.kind in ["tree", "rock", "food"]:
			gain_amount += 1
		node.amount -= 1
		resource_nodes[colonist.target] = node
		_match_resource(node.kind, gain_amount)
		colonist.mood = minf(100.0, colonist.mood + 1.0)

func _match_resource(kind: String, amount: int) -> void:
	match kind:
		"tree": wood += amount
		"rock": stone += amount
		"metal": metal += amount
		"crystal": crystal += amount
		"food": food += amount

func _update_monsters(delta: float) -> void:
	var active_colonist_index := _get_active_colonist_index()
	if active_colonist_index < 0:
		_finish_game("KOLONI HANCUR", "Semua kolonis tumbang pada hari %d." % day)
		return
	for monster in monsters:
		if monster.hp <= 0.0: continue
		var target: Dictionary = colonists[active_colonist_index]
		var nearest := INF
		for colonist in colonists:
			if colonist.hp <= 0.0: continue
			var distance: float = monster.pos.distance_to(colonist.pos)
			if distance < nearest:
				target = colonist
				nearest = distance
		if nearest == INF:
			continue
		if nearest > 38.0:
			monster.pos = monster.pos.move_toward(target.pos, float(monster.speed) * delta)
		elif monster.attack_timer <= 0.0:
			monster.attack_timer = 1.0
			target.hp = maxf(0.0, target.hp - float(monster.damage))
			_set_alert("%s terluka!" % target.name)
		monster.frame_time += delta
	for i in range(monsters.size()):
		monsters[i] = monsters[i]
	if attack_timer <= 0.0:
		for colonist in colonists:
			if colonist.job != "attack": continue
			for monster in monsters:
				if monster.hp > 0.0 and colonist.pos.distance_to(monster.pos) < 55.0:
					monster.hp -= 12.0 * _role_bonus_damage(colonist)
					attack_timer = 0.8
		monsters = monsters.filter(func(m): return m.hp > 0.0)

func _spawn_monster(kind: String) -> void:
	var stats := {"slime": [40, 5, 60], "zapper": [30, 8, 90], "golem": [150, 15, 40], "stalker": [80, 20, 100], "bat": [25, 6, 110]}
	var data: Array = stats[kind]
	var spawn := Vector2(clampf(camera_offset.x + rng.randf_range(80, 829), 0.0, WORLD_SIZE.x), clampf(camera_offset.y + rng.randf_range(70, 443), 0.0, WORLD_SIZE.y))
	monsters.append({"kind": kind, "pos": spawn, "hp": float(data[0]), "damage": data[1], "speed": data[2], "frame_time": 0.0, "attack_timer": 0.0})

func _finish_game(title: String, detail: String) -> void:
	mode = "over"
	paused = true
	alert_text = title + "\n" + detail

func _is_night() -> bool:
	return time_of_day > NIGHT_START and time_of_day < NIGHT_END

func _set_alert(text: String) -> void:
	alert_text = text
	alert_time = 3.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed: _pointer_down(event.position)
		else: _pointer_up(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed: _pointer_down(event.position)
		else: _pointer_up(event.position)
	elif event is InputEventScreenDrag:
		_pointer_drag(event.position)
	elif event is InputEventMouseMotion and dragging:
		_pointer_drag(event.position)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				if mode == "game": paused = not paused
			KEY_R:
				if mode == "game" or mode == "over":
					_reset_world(); mode = "game"
			KEY_M:
				audio_enabled = not audio_enabled
				_set_alert("Audio %s" % ("ON" if audio_enabled else "OFF"))
			KEY_ESCAPE:
				if mode == "game": paused = true

func _pointer_down(screen_pos: Vector2) -> void:
	dragging = true
	drag_start = screen_pos
	drag_camera_start = camera_offset

func _pointer_drag(screen_pos: Vector2) -> void:
	if not dragging or mode != "game": return
	if drag_start.distance_to(screen_pos) > 6.0:
		camera_offset = (drag_camera_start - (screen_pos - drag_start)).clamp(Vector2.ZERO, WORLD_SIZE - VIEW_SIZE)

func _pointer_up(screen_pos: Vector2) -> void:
	var was_drag := drag_start.distance_to(screen_pos) > 6.0
	dragging = false
	if was_drag: return
	if mode == "menu":
		if Rect2(330, 250, 250, 60).has_point(screen_pos):
			mode = "game"
			_play_audio("ambient.wav")
			_show_tutorial()
			_save_game()
		return
	if mode == "over":
		if Rect2(330, 350, 250, 60).has_point(screen_pos):
			_reset_world()
			mode = "game"
			_show_tutorial()
			_save_game()
		return
	if screen_pos.y < 52.0:
		if Rect2(830, 4, 38, 40).has_point(screen_pos): paused = true
		elif Rect2(790, 4, 38, 40).has_point(screen_pos): paused = false; game_speed = 1.0
		elif Rect2(748, 4, 38, 40).has_point(screen_pos): paused = false; game_speed = 3.0
		return
	if Rect2(700, 445, 70, 28).has_point(screen_pos):
		audio_enabled = not audio_enabled
		_set_alert("Audio %s" % ("ON" if audio_enabled else "OFF"))
		if audio_enabled: _play_audio("ambient.wav")
		return
	if screen_pos.y > 435.0 and Rect2(790, 435, 100, 78).has_point(screen_pos):
		build_mode = true
		build_preview_active = true
		build_preview_pos = (screen_pos + camera_offset) / TILE_SIZE
		_set_alert("Bangun dinding: tap tanah (5 kayu)")
		return
	if selected_colonist < 0 or selected_colonist >= colonists.size():
		selected_colonist = _get_active_colonist_index()
	if selected_colonist < 0:
		return
	var world_pos := screen_pos + camera_offset
	if build_mode:
		build_preview_active = false
		var wall_pos := (world_pos / TILE_SIZE).round() * TILE_SIZE
		if wood >= BUILD_COST_WALL and _can_place_wall(wall_pos):
			buildings.append({"kind": "wall", "pos": wall_pos})
			wood -= BUILD_COST_WALL
			build_mode = false
			_play_audio("build.wav")
			_save_game()
		else:
			build_mode = false
			_set_alert("Kayu kurang atau lokasi dinding penuh!")
		return
	for i in range(colonists.size()):
		if world_pos.distance_to(colonists[i].pos) < 36.0 and colonists[i].hp > 0.0:
			selected_colonist = i
			return
	for i in range(resource_nodes.size()):
		if world_pos.distance_to(resource_nodes[i].pos) < 45.0 and resource_nodes[i].amount > 0:
			colonists[selected_colonist].job = "harvest"
			colonists[selected_colonist].target = i
			_save_game()
			return
	for monster in monsters:
		if world_pos.distance_to(monster.pos) < 55.0:
			colonists[selected_colonist].job = "attack"
			_save_game()
			return

func _play_audio(file_name: String) -> void:
	if not audio_enabled:
		return
	var stream = load("res://project/resources/audio/" + file_name)
	if stream:
		audio_player.stream = stream
		audio_player.volume_db = 0.0
		audio_player.play()

func _draw() -> void:
	if mode == "menu": _draw_menu()
	elif mode == "over": _draw_over()
	else: _draw_game()

func _draw_menu() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("10152b"))
	_draw_texture("menu_background", Rect2(Vector2.ZERO, VIEW_SIZE))
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.03, 0.04, 0.12, 0.25))
	draw_string(ThemeDB.fallback_font, Vector2(220, 125), "PIXEL GALAXY WORLD", HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color("ffe65a"))
	draw_string(ThemeDB.fallback_font, Vector2(270, 158), "Koloni Pixel di Planet Kepler-Pixel 7", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("c4d4f2"))
	_draw_button(Rect2(330, 250, 250, 60), "MULAI PERMAINAN", Color("3869a8"))
	draw_string(ThemeDB.fallback_font, Vector2(315, 420), "Bertahan sampai hari ke-30", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("dbe7ff"))

func _draw_game() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("162232"))
	_draw_world()
	_draw_hud()

func _draw_over() -> void:
	draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color("160d24"))
	draw_string(ThemeDB.fallback_font, Vector2(270, 150), "HASIL KOLONI", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, Color("ffe65a"))
	var lines := alert_text.split("\n")
	for i in range(lines.size()):
		draw_string(ThemeDB.fallback_font, Vector2(250, 220 + i * 28), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("f2f5ff"))
	_draw_button(Rect2(330, 350, 250, 60), "MAIN LAGI", Color("3869a8"))

func _draw_world() -> void:
	var start_x := int(camera_offset.x / TILE_SIZE) * int(TILE_SIZE)
	var start_y := int(camera_offset.y / TILE_SIZE) * int(TILE_SIZE)
	for y in range(start_y, int(camera_offset.y + VIEW_SIZE.y) + 32, 32):
		for x in range(start_x, int(camera_offset.x + VIEW_SIZE.x) + 32, 32):
			var tile := "dirt" if int(x / 32 + y / 32) % 13 == 0 else "grass"
			_draw_texture(tile, Rect2(Vector2(x, y) - camera_offset, Vector2(32, 32)))
	for building in buildings:
		_draw_texture(building.kind, Rect2(building.pos - camera_offset - Vector2(24, 24), Vector2(48, 48)))
	for node in resource_nodes:
		if node.amount > 0:
			_draw_texture(node.kind, Rect2(node.pos - camera_offset - Vector2(20, 20), Vector2(40, 40)))
	for i in range(colonists.size()):
		var colonist: Dictionary = colonists[i]
		var frame := 4 if colonist.hp <= 0.0 else (int(Time.get_ticks_msec() / 180) % 4)
		_draw_texture(colonist.name.to_lower() + str(frame), Rect2(colonist.pos - camera_offset - Vector2(16, 24), Vector2(32, 48)))
		if i == selected_colonist:
			draw_arc(colonist.pos - camera_offset, 22.0, 0.0, TAU, 24, Color("ffe65a"), 2.0)
	for monster in monsters:
		var frame := int(monster.frame_time * 5.0) % 4
		_draw_texture(monster.kind + str(frame), Rect2(monster.pos - camera_offset - Vector2(32, 32), Vector2(64, 64)))
	if build_mode and build_preview_active:
		var preview_rect := Rect2((build_preview_pos * TILE_SIZE) - camera_offset - Vector2(24, 24), Vector2(48, 48))
		draw_rect(preview_rect, Color(0.8, 0.95, 1.0, 0.25), true)
		draw_rect(preview_rect, Color(0.95, 0.98, 1.0, 0.85), false, 2.0)
	if _is_night(): draw_rect(Rect2(Vector2.ZERO, VIEW_SIZE), Color(0.03, 0.06, 0.18, 0.40))

func _draw_hud() -> void:
	draw_rect(Rect2(0, 0, VIEW_SIZE.x, 48), Color(0.04, 0.07, 0.14, 0.94))
	draw_string(ThemeDB.fallback_font, Vector2(12, 30), "Hari %d  %02d:00" % [day, int(time_of_day * 24.0)], HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(220, 30), "Kayu %d   Batu %d   Logam %d   Kristal %d   Makanan %d" % [wood, stone, metal, crystal, food], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffe08b"))
	_draw_button(Rect2(748, 4, 38, 40), ">>", Color("5b466e"))
	_draw_button(Rect2(790, 4, 38, 40), ">", Color("3869a8"))
	_draw_button(Rect2(830, 4, 38, 40), "||", Color("3869a8"))
	draw_rect(Rect2(0, 435, VIEW_SIZE.x, 78), Color(0.04, 0.07, 0.14, 0.94))
	for i in range(colonists.size()):
		var colonist: Dictionary = colonists[i]
		var x := 20.0 + i * 155.0
		var color := Color("ffe65a") if i == selected_colonist else Color("c4d4f2")
		var role_text := "Fighter"
		var job_text := "kosong"
		if _get_colonist_role(colonist) == "harvester": role_text = "Harvester"
		elif _get_colonist_role(colonist) == "builder": role_text = "Builder"
		if colonist.job != "": job_text = colonist.job
		draw_string(ThemeDB.fallback_font, Vector2(x, 458), "%s  HP %d  %s" % [colonist.name, int(colonist.hp), role_text], HORIZONTAL_ALIGNMENT_LEFT, -1, 14, color)
		draw_string(ThemeDB.fallback_font, Vector2(x, 480), "Lapar %d  Tidur %d  Job %s" % [int(colonist.hunger), int(colonist.sleep), job_text], HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("dbe7ff"))
	_draw_button(Rect2(790, 445, 100, 58), "PALU", Color("7b5534"))
	_draw_button(Rect2(700, 445, 70, 28), "AUDIO %s" % ("ON" if audio_enabled else "OFF"), Color("3869a8"))
	if _is_night():
		draw_string(ThemeDB.fallback_font, Vector2(560, 20), "NIGHT DANGER %.0f%%" % (danger_level * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ff8f7d"))
	if alert_text != "":
		var lines := alert_text.split("\n")
		for i in range(lines.size()):
			draw_string(ThemeDB.fallback_font, Vector2(500, 470 + i * 18), lines[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("ff7777"))

func _draw_texture(key: String, rect: Rect2) -> void:
	if textures.has(key) and textures[key] != null: draw_texture_rect(textures[key], rect, false)

func _draw_button(rect: Rect2, label: String, color: Color) -> void:
	draw_rect(rect, color)
	draw_rect(rect, Color("dbe7ff"), false, 2.0)
	draw_string(ThemeDB.fallback_font, rect.position + Vector2(10, rect.size.y * 0.62), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
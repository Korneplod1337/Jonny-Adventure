extends Node

const DungeonGenerator = 	preload("uid://btqj5883lt4m8")
const Room = 				preload("uid://dyph656r88f3r")
var generator := DungeonGenerator.new()

var hud_instance: Node = null

@export var player_scene: Dictionary = {
	"Jonny": 		preload("uid://c2ej24f1hgto1"),
	"Jonnytta": 		preload("uid://c2ej24f1hgto1"),
	"Jovita": 		preload("uid://c2ej24f1hgto1"),
	"JonnyAlt": 		preload("uid://c2ej24f1hgto1"),
	"JonnyttaAlt": 	preload("uid://c2ej24f1hgto1"),
	"Jo": 			preload("uid://c2ej24f1hgto1"),
	"John": 			preload("uid://c2ej24f1hgto1"),
	"Joker": 		preload("uid://c2ej24f1hgto1"),
	"Joab": 			preload("uid://c2ej24f1hgto1"),
	"Joaquin": 		preload("uid://c2ej24f1hgto1"),
	}
var char_name := DungeonManager.selected_character
var player : CharacterBody2D = player_scene[char_name].instantiate()


var current_floor: int = 0
enum RoomType {	START, STANDARD, SHOP, ARMORY, BLOOD_TRIBUTE, 
				TREASURE, BANK, GAMBLING, BOSS, SECRET}
				## shop - shop armory, buff = bank treasure, dop = blood gambling secret
var floors_config: Array[Dictionary] = [
# локация 1
{"total_rooms": 5, 	"shop_rooms": 2, 		"buff_rooms": 0, 			"dop_rooms": 0}, 
#{"total_rooms": 7, 	"shop_rooms": 1, 		"buff_rooms": 0, 			"dop_rooms": 0}, 
{"total_rooms": 7, 	"shop_rooms": 1, 		"buff_rooms": 0, 			"dop_rooms": 0}, 
# локация 2
{"total_rooms": 8, 	"shop_rooms": randi()%3, "buff_rooms": randi()%2, 	"dop_rooms": 0}, 
{"total_rooms": 12, 	"shop_rooms": randi()%3, "buff_rooms": randi()%2, 	"dop_rooms": randi()%2}, 
# локация 3
{"total_rooms": 10, 	"shop_rooms": randi()%3, "buff_rooms": randi()%2, 	"dop_rooms": randi()%2}, 
{"total_rooms": 14, 	"shop_rooms": randi()%3, "buff_rooms": randi()%3, 	"dop_rooms": randi()%2}, 
# локация 4
{"total_rooms": 12, 	"shop_rooms": randi()%3, "buff_rooms": randi()%2, 	"dop_rooms": randi()%2}, 
{"total_rooms": 16, 	"shop_rooms": 2, 		"buff_rooms": randi()%3, 	"dop_rooms": randi()%2}, 
# локация 5
{"total_rooms": 14, 	"shop_rooms": randi()%3, "buff_rooms": randi()%3, 	"dop_rooms": randi()%3}, 
{"total_rooms": 18, 	"shop_rooms": randi()%3, "buff_rooms": randi()%3, 	"dop_rooms": randi()%3}, 
# локация 6
{"total_rooms": 14, 	"shop_rooms": randi()%3, "buff_rooms": randi()%3, 	"dop_rooms": randi()%3}, 
{"total_rooms": 18, 	"shop_rooms": randi()%3, "buff_rooms": randi()%3, 	"dop_rooms": randi()%4}, 
# локация 7
{"total_rooms": 8, 	"shop_rooms": 2,			"buff_rooms": randi()%2, 	"dop_rooms": randi()%2}, 
{"total_rooms": 2, 	"shop_rooms": 0, 		"buff_rooms": 0, 	"dop_rooms": 0}, 
]

@onready var room_presets_by_floor: Array = [
	standard_room_presets_floor1,
	standard_room_presets_floor1,
	standard_room_presets_floor2,
	standard_room_presets_floor2,
	standard_room_presets_floor3,
	standard_room_presets_floor3,
	standard_room_presets_floor4,
	standard_room_presets_floor4,
	standard_room_presets_floor5,
	standard_room_presets_floor5,
	standard_room_presets_floor6,
	standard_room_presets_floor6,
	standard_room_presets_floor7,
	standard_room_presets_floor7,
]

@export var standard_room_presets_floor1: Array[PackedScene]
@export var standard_room_presets_floor2: Array[PackedScene]
@export var standard_room_presets_floor3: Array[PackedScene]
@export var standard_room_presets_floor4: Array[PackedScene]
@export var standard_room_presets_floor5: Array[PackedScene]
@export var standard_room_presets_floor6: Array[PackedScene]
@export var standard_room_presets_floor7: Array[PackedScene]

@export var start_room_preset: 		Array[PackedScene]
@export var shop_room_preset: 		Array[PackedScene]
@export var boss_room_preset: 		Array[PackedScene]
@export var armory_room_preset: 		Array[PackedScene]
@export var blood_room_preset: 		Array[PackedScene]
@export var treasure_room_preset: 	Array[PackedScene]
@export var bank_room_preset: 		Array[PackedScene]
@export var gambling_room_preset: 	Array[PackedScene]
@export var secret_room_preset: 		Array[PackedScene]


# Размер комнаты в мире и отступ между комнатами
@export var room_world_size: Vector2 = Vector2(1280*2, 720*2)
@export var room_gap: Vector2 = Vector2(200, 200)
var last_door_dir: Vector2 = Vector2.ZERO

const FLOOR_ENTER_DROP := 100.0


var rooms := {} # Все сгенерированные комнаты: ключ — Vector2 позиции, значение — Room
var directions := [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]


func _ready():
	seed(Time.get_unix_time_from_system())
	GameState.obnulenie()
	GameState._clear_level_bufs()
	GameState.random_level_bufs()
		
	$Arcade_music.play()
	rooms = generator.generate(
		floors_config[current_floor]['total_rooms'], 
		floors_config[current_floor]['shop_rooms'], 
		floors_config[current_floor]['buff_rooms'], 
		floors_config[current_floor]['dop_rooms'])
	var start_instance := spawn_rooms()
	spawn_player_in_start(start_instance)
	print_map()
	var hud_scene := preload("uid://n5dvgu5we2gn")
	hud_instance = hud_scene.instantiate()
	add_child(player)
	_ensure_player_draw_order()
	player.update_level_buffs()
	add_child(hud_instance)


func instance_room(room: Room) -> Node:
	match room.type:
		RoomType.START:
			return start_room_preset		[current_floor / 2].instantiate()
		RoomType.BOSS:
			var boss_index := clampi(current_floor / 2, 0, boss_room_preset.size() - 1)
			return boss_room_preset[boss_index].instantiate()
		RoomType.STANDARD:
			var standard_presets = room_presets_by_floor[current_floor]
			return standard_presets[randi() % standard_presets.size()].instantiate()
		RoomType.SHOP:
			return shop_room_preset		[current_floor / 2].instantiate()
		RoomType.GAMBLING:
			return gambling_room_preset	[current_floor / 2].instantiate()
		RoomType.ARMORY:
			return armory_room_preset	[current_floor / 2].instantiate()
		RoomType.TREASURE:
			return treasure_room_preset	[current_floor / 2].instantiate()
		RoomType.BLOOD_TRIBUTE:
			return blood_room_preset		[current_floor / 2].instantiate()
		RoomType.BANK:
			return bank_room_preset		[current_floor / 2].instantiate()
		RoomType.SECRET:
			return secret_room_preset		[current_floor / 2].instantiate()
		
	return null


func spawn_rooms() -> Node:
	var start_instance: Node = null

	for room in rooms.values():
		var scene := instance_room(room)
		# «шаг» сетки в мировых координатах: размер комнаты + отступ
		scene.position = room.pos * room_world_size + room.pos * room_gap
		add_child(scene)
		
		room.scene = scene
		
		configure_doors_for_room(room, scene)
		
		if room.type == RoomType.START:
			start_instance = scene
	
	_ensure_player_draw_order()
	return start_instance


func _ensure_player_draw_order() -> void:
	if not is_instance_valid(player) or player.get_parent() != self:
		return
	player.z_index = 10
	move_child(player, get_child_count() - 1)


func spawn_player_in_start(start_instance: Node) -> void:
	player.global_position = start_instance.global_position
	player.set_room(start_instance)

func configure_doors_for_room(room: Room, scene: Node2D) -> void:
# направление -> имя узла двери в пресете
	var dir_to_name := {
	Vector2(1,0): "Door_Right",
	Vector2(-1,0): "Door_Left",
	Vector2(0,-1): "Door_Up",
	Vector2(0,1): "Door_Down" }

	for dir in dir_to_name.keys():
		var door_node := scene.get_node_or_null(dir_to_name[dir])
		if door_node == null:
			continue
			
		var shape: CollisionShape2D = null
		if door_node.has_node("Area2D/CollisionShape2D"):
			shape = door_node.get_node("Area2D/CollisionShape2D")
			
		# если в логике генератора нет выхода в этом направлении
		if not room.exits.has(dir):
			# полностью прячем/отключаем дверь
			door_node.visible = false
			door_node.set_process(false)
			door_node.set_physics_process(false)
			if shape:
				shape.disabled = true
			continue
			
		door_node.visible = true
		door_node.set_process(true)
		door_node.set_physics_process(true)
		if shape:
			shape.disabled = false

		var target_pos: Vector2 = room.exits[dir]
		var target_room: Room = rooms[target_pos]
		door_node.configure(dir, target_pos, target_room.type, -dir * 64.0)


func teleport_player(door: Node, body: Node2D) -> void:
	
	last_door_dir = door.dir
	
	var target_pos: Vector2 = door.target_room_pos
	var target_room: Room = rooms.get(target_pos)
	if target_room == null:
		print('teleport room empty')
		return

	var target_scene: Node2D = target_room.scene
	if target_scene == null:
		print('teleport scene empty')
		return

	var opposite_dir := -last_door_dir
	var opposite_name := ""
	if opposite_dir == Vector2(1,0):
		opposite_name = "Door_Right"
	elif opposite_dir == Vector2(-1,0):
		opposite_name = "Door_Left"
	elif opposite_dir == Vector2(0,1):
		opposite_name = "Door_Down"
	elif opposite_dir == Vector2(0,-1):
		opposite_name = "Door_Up"

	var spawn_door: Node2D = null
	if opposite_name != "":
		spawn_door = target_scene.get_node_or_null(opposite_name)

	var spawn_pos: Vector2 = door.global_position
	if spawn_door != null:
		spawn_pos = spawn_door.global_position

	# временно отключаем эту дверь
	spawn_door.call_deferred("set_temporarily_inactive")
	body.global_position = spawn_pos

	if body.has_method("set_room"): #камера тп
		body.set_room(target_scene)


func print_map():
	var xs = rooms.keys().map(func(v): return v.x)
	var ys = rooms.keys().map(func(v): return v.y)

	var min_x = int(xs.min())
	var max_x = int(xs.max())
	var min_y = int(ys.min())
	var max_y = int(ys.max())

	var output = ""
	for y in range(min_y, max_y + 1):
		var line_room = ""
		var line_conn = ""
		for x in range(min_x, max_x + 1):
			var key = Vector2(x,y)
			if rooms.has(key):
				match rooms[key].type: 
					RoomType.START: 			line_room += "()"
					RoomType.STANDARD: 		line_room += "S"
					RoomType.SHOP: 			line_room += "M"
					RoomType.ARMORY: 		line_room += "A"
					RoomType.BLOOD_TRIBUTE:	line_room += "K" #
					RoomType.TREASURE: 		line_room += "T"
					RoomType.BANK: 			line_room += "J" #
					RoomType.GAMBLING: 		line_room += "G" #
					RoomType.BOSS: 			line_room += "B" #
					RoomType.SECRET: 		line_room += "H" #
				if rooms[key].exits.has(Vector2(1,0)):
					line_room += "-"
				else:
					line_room += " "
			else:
				line_room += "  "
			if rooms.has(key):
				if rooms[key].exits.has(Vector2(0,1)):
					line_conn += "| "
				else:
					line_conn += "  "
			else:
				line_conn += "  "
		output += line_room.rstrip(" \t") + "\n"
		output += line_conn.rstrip(" \t") + "\n"
	print(output)

func go_to_next_floor(hatch: Node2D) -> void:
	var next_floor := current_floor + 1
	if next_floor >= floors_config.size():
		push_warning("Dungeon: no more floors after %d" % current_floor)
		return

	_reset_player_interactions()
	var hatch_center := hatch.global_position

	if player.has_method("play_hatch_exit"):
		await player.play_hatch_exit(hatch_center)

	player.visible = false
	await _load_floor(next_floor)

	var start_instance := _get_start_room_instance()
	if start_instance == null:
		player.visible = true
		if player.has_method("end_floor_transition"):
			player.end_floor_transition()
		return

	var land_pos = start_instance.global_position
	player.global_position = land_pos + Vector2(0, -FLOOR_ENTER_DROP)
	player.rotation = 0.0
	player.visible = true
	_ensure_player_draw_order()
	player.set_room(start_instance)

	if player.has_method("play_hatch_enter"):
		await player.play_hatch_enter(land_pos)
	else:
		player.global_position = land_pos
		if player.has_method("end_floor_transition"):
			player.end_floor_transition()

	_reset_player_interactions()
	print_map()


func regenerate_floor(new_floor: int) -> void:
	await _load_floor(new_floor)
	var start_instance := _get_start_room_instance()
	if start_instance:
		spawn_player_in_start(start_instance)
	if player.has_method("end_floor_transition") and player.movement_locked:
		player.end_floor_transition()
	_reset_player_interactions()
	print_map()


func _load_floor(new_floor: int) -> void:
	current_floor = new_floor
	_reset_player_interactions()
	clear_floor_content()
	await get_tree().process_frame
	await get_tree().physics_frame

	GameState._clear_level_bufs()
	GameState.random_level_bufs()

	var config := floors_config[current_floor]
	rooms = generator.generate(
		config['total_rooms'],
		config['shop_rooms'],
		config['buff_rooms'],
		config['dop_rooms'])

	spawn_rooms()
	player.update_level_buffs()
	ItemManager.recharge_floor_items(player)

	if hud_instance and hud_instance.has_method("bufs_render"):
		hud_instance.bufs_render()


func _get_start_room_instance() -> Node:
	for room in rooms.values():
		if room.type == RoomType.START and room.scene:
			return room.scene
	return null


func _reset_player_interactions() -> void:
	if not is_instance_valid(player):
		return
	var ic := player.get_node_or_null("InteractingComponents")
	if ic and ic.has_method("reset_interaction_state"):
		ic.reset_interaction_state()


func clear_floor_content() -> void:
	rooms.clear()
	for child in get_children():
		if child == player or child == hud_instance:
			continue
		if child is AudioStreamPlayer:
			continue
		child.queue_free()

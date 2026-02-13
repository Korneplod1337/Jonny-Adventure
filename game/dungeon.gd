extends Node

const DungeonGenerator = 	preload("uid://btqj5883lt4m8")
const Room = 				preload("uid://dyph656r88f3r")
var generator := DungeonGenerator.new()
enum RoomType { START, STANDARD, SHOP, ARMORY, BLOOD_TRIBUTE, 
				TREASURE, BANK, GAMBLING, BOSS, SECRET}

@export var floors_config: Array[Dictionary] = [
	{"total_rooms": 4, "shop_rooms": 0}, 
	{"total_rooms": 8, "shop_rooms": 1}, 
	{"total_rooms": 8, "shop_rooms": 1},
	{"total_rooms": 12, "shop_rooms": 1},
	{"total_rooms": 12, "shop_rooms": 1},
	{"total_rooms": 16, "shop_rooms": 1},
	{"total_rooms": 16, "shop_rooms": 1},
	{"total_rooms": 20, "shop_rooms": 1},
]
var current_floor: int = 0


# Сцены пресетов
var hud_instance: Node = null
@export var player_scene: Dictionary = {
	"Jonny": 		preload("uid://ctxdqxo8mr54o"),
	"Jonnytta": 		preload("uid://ctxdqxo8mr54o"),
	"": 			preload("uid://ctxdqxo8mr54o"),
	}
var char_name := DungeonManager.selected_character
var player : CharacterBody2D = player_scene[char_name].instantiate()

@export var standard_room_presets_floor1: Array[PackedScene]
@export var standard_room_presets_floor2: Array[PackedScene]


@export var start_room_preset: PackedScene
@export var shop_room_preset: PackedScene
@export var boss_room_preset: PackedScene


# Размер комнаты в мире и отступ между комнатами
@export var room_world_size: Vector2 = Vector2(1280*2, 720*2)
@export var room_gap: Vector2 = Vector2(200, 200)
var last_door_dir: Vector2 = Vector2.ZERO


# Все сгенерированные комнаты: ключ — Vector2 позиции, значение — Room
var rooms := {}
# Возможные направления для генерации соседей
var directions := [Vector2(1,0), Vector2(-1,0), Vector2(0,1), Vector2(0,-1)]


func _ready():
	seed(1)
	seed(Time.get_unix_time_from_system())
	GameState.obnulenie()
	$Arcade_music.play()
	rooms = generator.generate(
		floors_config[current_floor]['total_rooms'], 
		floors_config[current_floor]['shop_rooms'])
	var start_instance := spawn_rooms()
	spawn_player_in_start(start_instance)
	print_map()
	var hud_scene := preload("uid://n5dvgu5we2gn")
	hud_instance = hud_scene.instantiate()
	add_child(player)
	add_child(hud_instance)


func instance_room(room: Room) -> Node:
	
	var standard_room_presets = standard_room_presets_floor1 if current_floor == 0 else standard_room_presets_floor2

	match room.type:
		RoomType.START:
			return start_room_preset.instantiate()
		RoomType.STANDARD:
			return standard_room_presets[randi() % standard_room_presets.size()].instantiate()
		RoomType.SHOP:
			return shop_room_preset.instantiate()
		RoomType.BOSS:
			return boss_room_preset.instantiate()
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
	
	return start_instance


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

		# door.gd: target_room_pos и entrance_offset
		door_node.dir = dir
		door_node.target_room_pos = room.exits[dir]
		door_node.entrance_offset = -dir * 64.0


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
					RoomType.BLOOD_TRIBUTE:	line_room += "K"
					RoomType.TREASURE: 		line_room += "T"
					RoomType.BANK: 			line_room += "J"
					RoomType.GAMBLING: 		line_room += "G"
					RoomType.BOSS: 			line_room += "B"
					RoomType.SECRET: 		line_room += "H"
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

func regenerate_floor(new_floor: int) -> void:
	current_floor = new_floor
	clear_rooms()
	rooms = generator.generate(
		floors_config[current_floor].total_rooms, 
		floors_config[current_floor].shop_rooms )
	var start_instance := spawn_rooms()
	spawn_player_in_start(start_instance)
	print_map()

func clear_rooms() -> void:
	for room in rooms.values():
		if room.scene:
			room.scene.queue_free()
	rooms.clear()

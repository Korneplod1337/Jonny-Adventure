extends "res://game/presets/RoomScript.gd" #no enemy

const ChestScene := preload("uid://tsiccout8ibv")
var tiers_array := [[0, 1], [0, 1], [0, 1, 2], [0, 1, 2], [0, 1, 2, 3], [0, 1, 2, 3], [1, 2, 3], [2, 3]]

func _ready() -> void:
	tabels_spawn()
	call_deferred("init_room")

func tabels_spawn() -> void:
	var dungeon = get_tree().current_scene
	var current_floor = dungeon.current_floor
	
	var Chest = ChestScene.instantiate()
	Chest.position = self.position
	Chest.item_tier = tiers_array[current_floor]
	Chest.equip_tier = tiers_array[current_floor]
	#Chest.set_scale(Vector2i(2, 2))
	get_tree().current_scene.add_child(Chest)

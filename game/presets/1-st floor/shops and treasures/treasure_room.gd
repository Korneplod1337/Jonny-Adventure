extends "res://game/presets/RoomScript.gd" #no enemy

const ChestScene := preload("uid://tsiccout8ibv")
var tiers_array := [[1], [1], [1, 2], [1, 2], [1, 2, 3], [2, 3], [2, 3, 4], [3, 4]]

func _ready() -> void:
	tabels_spawn()
	call_deferred("init_room")

func tabels_spawn() -> void:
	var dungeon = get_tree().current_scene
	var current_floor = dungeon.current_floor
	
	var Chest = ChestScene.instantiate()
	Chest.position = self.position
	Chest.item_tier = tiers_array[randi_range(0, current_floor / 2) + 1]
	Chest.equip_tier = tiers_array[randi() % min(current_floor+1, 4)]
	#Chest.set_scale(Vector2i(2, 2))
	get_tree().current_scene.add_child(Chest)

extends "res://game/presets/RoomScript_enemy.gd"

const ChestScene := preload("res://game/objects/chests/Chest_treasure.tscn")

var _reward_spawned := false


func show_doors() -> void:
	super()
	if _reward_spawned:
		return
	_reward_spawned = true
	spawn_reward_chest()


func spawn_reward_chest() -> void:
	var dungeon = get_tree().current_scene
	var current_floor: int = dungeon.current_floor

	var chest = ChestScene.instantiate()
	chest.position = Vector2.ZERO
	call_deferred('add_child', chest)

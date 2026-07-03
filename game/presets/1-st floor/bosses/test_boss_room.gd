extends "res://game/presets/RoomScript_enemy.gd"

const ChestScene := preload("uid://tsiccout8ibv")
const TIERS_EQUIP := [[0, 1], [0, 1, 2], [0, 1, 2], [0, 1, 2, 3], [0, 2, 3], [2, 3], [2, 3]]
const TIERS_ITEM := [[0, 1], [0, 1, 2, 4], [0, 1, 2, 4], [0, 1, 2, 3, 4], [0, 2, 3, 4], [2, 3], [2, 3]]
	

var _reward_spawned := false
@onready var _hatch: Node2D = $Hatch


func init_room() -> void:
	super()
	spawn_clear_reward = false
	if _hatch and _hatch.has_method("hide_hatch"):
		_hatch.hide_hatch()


func show_doors() -> void:
	super()
	call_deferred("_show_hatch_and_reward")


func _show_hatch_and_reward() -> void:
	if _hatch and _hatch.has_method("show_hatch"):
		_hatch.show_hatch()
	if _reward_spawned:
		return
	_reward_spawned = true
	spawn_reward_chest()


func spawn_reward_chest() -> void:
	var dungeon = get_tree().current_scene
	var floor_index := clampi(int(dungeon.current_floor) / 2, 0, TIERS_ITEM.size() - 1)

	var chest = ChestScene.instantiate()
	chest.position = Vector2.ZERO
	chest.item_tier = TIERS_ITEM[floor_index]
	chest.equip_tier = TIERS_EQUIP[floor_index]
	call_deferred("add_child", chest)

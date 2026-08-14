## Miromir's Gift — спавнит 1 случайный сундук рядом с игроком (как Opulence). CD: этаж.
class_name MiromirGiftAbility
extends BaseAbility

const CHEST_SMALL := preload("res://game/objects/chests/Chest_small.tscn")
const CHEST_BIG := preload("res://game/objects/chests/Chest_big.tscn")
const CHEST_WEAPON := preload("res://game/objects/chests/Chest_weapon.tscn")
const CHEST_TREASURE := preload("res://game/objects/chests/Chest_treasure.tscn")
const CHEST_OFFSET := 80.0


func _init() -> void:
	ability_id = "MiromirGift"
	cooldown_type = CooldownType.FLOOR


func activate() -> bool:
	var chest_scene := _pick_random_chest()
	var dungeon = player.get_tree().current_scene
	if dungeon != null and ("rooms" in dungeon) and dungeon.rooms.has(dungeon.current_room_pos):
		var room = dungeon.rooms[dungeon.current_room_pos]
		if room.scene != null:
			var local: Vector2 = room.scene.to_local(player.global_position) + Vector2(CHEST_OFFSET, 0)
			var chest := chest_scene.instantiate()
			chest.position = local
			room.scene.call_deferred("add_child", chest)
			return true

	var chest := chest_scene.instantiate()
	chest.global_position = player.global_position + Vector2(CHEST_OFFSET, 0)
	player.get_tree().current_scene.call_deferred("add_child", chest)
	return true


func _pick_random_chest() -> PackedScene:
	var scenes: Array[PackedScene] = [CHEST_SMALL, CHEST_BIG, CHEST_WEAPON, CHEST_TREASURE]
	return scenes[randi() % scenes.size()]

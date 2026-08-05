extends Item

const CHEST_SMALL := preload("res://game/objects/chests/Chest_small.tscn")
const CHEST_BIG := preload("res://game/objects/chests/Chest_big.tscn")
const CHEST_WEAPON := preload("res://game/objects/chests/Chest_weapon.tscn")
const CHEST_TREASURE := preload("res://game/objects/chests/Chest_treasure.tscn")
const CHEST_OFFSET := 80.0


func apply_item_effect() -> void:
	player.fire_rate_bonus += 1
	player.fire_rate = StatManager.get_stat(player, "fire_rate")
	player._emit_stats_changed()

	var dungeon := get_tree().current_scene
	if dungeon == null:
		_spawn_at_global(player.global_position)
		return

	var rooms = dungeon.get("rooms")
	if rooms == null:
		_spawn_at_global(player.global_position)
		return

	var room = rooms.get(dungeon.current_room_pos)
	if room == null or room.scene == null:
		_spawn_at_global(player.global_position)
		return

	var local = room.scene.to_local(player.global_position)
	_spawn_chest_in_room(room.scene, local + Vector2(-CHEST_OFFSET, 0))
	_spawn_chest_in_room(room.scene, local + Vector2(CHEST_OFFSET, 0))


func _spawn_at_global(origin: Vector2) -> void:
	_spawn_chest_global(origin + Vector2(-CHEST_OFFSET, 0))
	_spawn_chest_global(origin + Vector2(CHEST_OFFSET, 0))


func _spawn_chest_in_room(room_scene: Node2D, local_pos: Vector2) -> void:
	var chest := _pick_random_chest().instantiate()
	chest.position = local_pos
	room_scene.call_deferred("add_child", chest)


func _spawn_chest_global(global_pos: Vector2) -> void:
	var chest := _pick_random_chest().instantiate()
	chest.global_position = global_pos
	get_tree().current_scene.call_deferred("add_child", chest)


func _pick_random_chest() -> PackedScene:
	var scenes: Array[PackedScene] = [CHEST_SMALL, CHEST_BIG, CHEST_WEAPON, CHEST_TREASURE]
	return scenes[randi() % scenes.size()]

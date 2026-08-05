extends Item

const CHEST_SMALL := preload("res://game/objects/chests/Chest_small.tscn")
const CHEST_BIG := preload("res://game/objects/chests/Chest_big.tscn")
const CHEST_WEAPON := preload("res://game/objects/chests/Chest_weapon.tscn")
const CHEST_OFFSET := 80.0


func apply_item_effect() -> void:
	var dungeon := get_tree().current_scene
	if dungeon == null:
		return
	var rooms = dungeon.get("rooms")
	if rooms == null:
		return

	var candidates: Array = []
	for room in rooms.values():
		if room.type == dungeon.RoomType.STANDARD and room.scene != null:
			candidates.append(room)
	if candidates.is_empty():
		return

	var room = candidates[randi() % candidates.size()]
	var spawn_pos := Vector2.ZERO
	var marker := room.scene.get_node_or_null("ChestSpawnPoint") as Marker2D
	if marker:
		spawn_pos = marker.position
	spawn_pos.x += CHEST_OFFSET if randf() < 0.5 else -CHEST_OFFSET

	var chest := _pick_clear_reward_chest().instantiate()
	chest.position = spawn_pos
	room.scene.call_deferred("add_child", chest)


func _pick_clear_reward_chest() -> PackedScene:
	var luck := 0.1
	if player:
		luck = StatManager.get_stat(player, "luck")
	var t := clampf((luck - 0.1) / 1.9, 0.0, 1.0)
	var weights: Array[float] = [
		lerpf(0.70, 0.0, t),
		lerpf(0.30, 0.70, t),
		lerpf(0.0, 0.30, t),
	]
	var scenes: Array[PackedScene] = [CHEST_SMALL, CHEST_BIG, CHEST_WEAPON]
	var total := 0.0
	for w in weights:
		total += w
	if total <= 0.0:
		return CHEST_BIG
	var roll := randf() * total
	var acc := 0.0
	for i in weights.size():
		acc += weights[i]
		if roll <= acc:
			return scenes[i]
	return CHEST_BIG

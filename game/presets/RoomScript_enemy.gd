extends "res://game/presets/RoomScript.gd" #no enemy

const CHEST_SMALL := preload("res://game/objects/chests/Chest_small.tscn")
const CHEST_BIG := preload("res://game/objects/chests/Chest_big.tscn")
const CHEST_WEAPON := preload("res://game/objects/chests/Chest_weapon.tscn")
const SHRINE_SCENE_PATH := "res://game/presets/shrines/shrine.tscn"
const SHRINE_REMOVE_CHANCE := 0.5

@export var spawn_clear_reward := true
var _clear_reward_spawned := false
var _skip_wave2_trigger := false


func init_room() -> void:
	super()
	if randf() < SHRINE_REMOVE_CHANCE:
		for child in get_children():
			if child.scene_file_path == SHRINE_SCENE_PATH:
				child.queue_free()
	cache_active_doors()
	hide_doors()
	
	if GameState.level_bufs[1][1] == true:   # Invasion
		for enemy in get_tree().get_nodes_in_group("Enemy"):
			enemy.visible = true
	connect_enemies()


# хуйня с дверьми и врагами (рот её ебал)
func connect_enemies() -> void:
	enemy_count = 0

	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if not is_ancestor_of(enemy):
			continue
		if not enemy.is_visible_in_tree():
			enemy.queue_free()
			continue
		connect_single_enemy(enemy, true)


func connect_single_enemy(enemy: Node, increment_count := true) -> void:
	if increment_count:
		enemy_count += 1
	if enemy.has_signal("_enemy_die"):
		enemy._enemy_die.connect(_on_enemy_die, CONNECT_ONE_SHOT)


func reserve_enemy_slot() -> void:
	enemy_count += 1


func mark_wave2_spawn_death() -> void:
	_skip_wave2_trigger = true


func spawn_wave2_enemy(scene: PackedScene, spawn_pos: Vector2, spawn_scale: Vector2) -> void:
	var enemy := scene.instantiate()
	add_child(enemy)
	enemy.global_position = spawn_pos
	enemy.scale = spawn_scale
	connect_single_enemy(enemy, false)


func cache_active_doors() -> void:
	active_doors.clear()

	for child in get_children():
		if child.is_in_group("Door") and child.visible and child.is_processing():
			active_doors.append(child)

func hide_doors() -> void:
	for door in active_doors:
		door.visible = false
		call_deferred("_update_door_collision", door, false)

func show_doors() -> void:
	for door in active_doors:
		door.visible = true
		call_deferred("_update_door_collision", door, true)
		door.reactivate_after_room_clear()

	if spawn_clear_reward and not _clear_reward_spawned:
		_clear_reward_spawned = true
		if not GameState.has_level_buf("Barren"):
			_spawn_clear_reward_chest()

func _get_player_luck_factor() -> float:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return 0.0
	var luck := StatManager.get_stat(player, "luck")
	return clampf((luck - 0.1) / 1.9, 0.0, 1.0)

func _get_chest_weights() -> Array[float]:
	var t := _get_player_luck_factor()
	return [
		lerpf(0.70, 0.0, t),
		lerpf(0.30, 0.70, t),
		lerpf(0.0, 0.30, t),
	]

func _pick_chest_scene() -> PackedScene:
	var weights := _get_chest_weights()
	var scenes: Array[PackedScene] = [CHEST_SMALL, CHEST_BIG, CHEST_WEAPON]
	var total_weight := 0.0
	for weight in weights:
		total_weight += weight

	if total_weight <= 0.0:
		return CHEST_BIG

	var roll := randf() * total_weight
	var accumulated := 0.0
	for i in weights.size():
		accumulated += weights[i]
		if roll <= accumulated:
			return scenes[i]

	return CHEST_BIG

func _get_clear_reward_spawn_position() -> Vector2:
	var spawn_marker := get_node_or_null("ChestSpawnPoint") as Marker2D
	if spawn_marker:
		return spawn_marker.position
	return Vector2.ZERO

func _spawn_clear_reward_chest() -> void:
	var chest := _pick_chest_scene().instantiate()
	chest.position = _get_clear_reward_spawn_position()
	call_deferred("add_child", chest)

func _update_door_collision(door: Node, hide: bool) -> void:
	var area := door.get_node_or_null("Area2D")
	if area:
		area.monitoring = hide
		area.monitorable = hide

func _on_enemy_die(damage: int) -> void:
	enemy_count = maxi(enemy_count - damage, 0)
	print('enemy left: ', enemy_count)
	if not _skip_wave2_trigger:
		_try_release_wave2_spawns()
	_skip_wave2_trigger = false

	if enemy_count == 0 and not _has_wave2_release_in_progress():
		show_doors()


func _get_wave2_spawns_in_room() -> Array:
	var spawns: Array = []
	for enemy in get_tree().get_nodes_in_group("EnemyWave2Spawn"):
		if is_ancestor_of(enemy) and is_instance_valid(enemy):
			spawns.append(enemy)
	return spawns


func _has_first_wave_enemies_alive() -> bool:
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if not is_ancestor_of(enemy) or not is_instance_valid(enemy):
			continue
		if enemy.is_in_group("EnemyWave2Spawn"):
			continue
		if not enemy.is_visible_in_tree() or enemy.get("is_dead"):
			continue
		return true
	return false


func _has_wave2_release_in_progress() -> bool:
	for spawn in _get_wave2_spawns_in_room():
		if spawn.get("_releasing_wave2"):
			return true
	return false


func _try_release_wave2_spawns() -> void:
	if _has_first_wave_enemies_alive():
		return
	call_deferred("_release_wave2_spawns")


func _release_wave2_spawns() -> void:
	for spawn in _get_wave2_spawns_in_room():
		if spawn.get("is_dead"):
			continue
		spawn.die()

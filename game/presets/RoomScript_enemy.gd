extends "res://game/presets/RoomScript.gd" #no enemy


func init_room() -> void:
	super()
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
		if not enemy.is_visible_in_tree():
			enemy.queue_free()
			continue
		if not is_ancestor_of(enemy):
			continue

		enemy_count += 1

		if enemy.has_signal("_enemy_die"):
			enemy._enemy_die.connect(_on_enemy_die)

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

func _update_door_collision(door: Node, hide: bool) -> void:
	var area := door.get_node_or_null("Area2D")
	if area:
		area.monitoring = hide
		area.monitorable = hide

func _on_enemy_die(damage: int) -> void:
	enemy_count -= damage
	print('enemy left: ', enemy_count)

	if enemy_count <= 0:
		show_doors()

extends Node2D

var enemy_count: int
var active_doors: Array[Node] = []
@onready var tile_map_layer: TileMapLayer = $TileMapLayer


func _ready() -> void:
	call_deferred("init_room")


func init_room() -> void:
	randomize()
	_shuffle_tilemap_layer()
	await get_tree().process_frame
	connect_enemies()
	cache_active_doors()
	hide_doors()

func _shuffle_tilemap_layer() -> void:
	var used_cells: Array[Vector2i] = tile_map_layer.get_used_cells()
	if used_cells.is_empty():
		return

	var source_id := 0
	var weighted_tiles: Array = [
		# Базовый пол (ряд 0, самые частые)
		{ "coord": Vector2i(0, 0), "weight": 1.0 },
		{ "coord": Vector2i(1, 0), "weight": 1.0 },
		{ "coord": Vector2i(2, 0), "weight": 1.0 },
		{ "coord": Vector2i(3, 0), "weight": 1.0 },
		{ "coord": Vector2i(4, 0), "weight": 1.0 },
		{ "coord": Vector2i(5, 0), "weight": 1.0 },

		# Редкие вариации (ряд 1, probability = 0.01)
		{ "coord": Vector2i(0, 1), "weight": 0.01 },
		{ "coord": Vector2i(1, 1), "weight": 0.01 },
		{ "coord": Vector2i(2, 1), "weight": 0.01 },
		{ "coord": Vector2i(3, 1), "weight": 0.01 },
		{ "coord": Vector2i(4, 1), "weight": 0.01 },
		{ "coord": Vector2i(5, 1), "weight": 0.01 },

		# Очень редкие (ряд 2, probability = 0.002)
		{ "coord": Vector2i(0, 2), "weight": 0.002 },
		{ "coord": Vector2i(1, 2), "weight": 0.002 },
		{ "coord": Vector2i(2, 2), "weight": 0.002 },
		{ "coord": Vector2i(3, 2), "weight": 0.002 },
		{ "coord": Vector2i(4, 2), "weight": 0.002 },
		{ "coord": Vector2i(5, 2), "weight": 0.002 },
	]

	for cell in used_cells:
		var coord := _pick_weighted(weighted_tiles)
		tile_map_layer.set_cell(cell, source_id, coord)

func _pick_weighted(weighted_tiles: Array) -> Vector2i:
	var total_weight := 0.0
	for t in weighted_tiles:
		total_weight += t.weight

	if total_weight <= 0.0:
		return weighted_tiles.back().coord

	var r := randf() * total_weight
	var sum := 0.0
	for t in weighted_tiles:
		sum += t.weight
		if r <= sum:
			return t.coord

	return weighted_tiles.back().coord


# хуйня с дверьми и врагами (рот её ебал)
func connect_enemies() -> void:
	enemy_count = 0

	for enemy in get_tree().get_nodes_in_group("Enemy"):
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
	if enemy_count <= 0:
		show_doors()

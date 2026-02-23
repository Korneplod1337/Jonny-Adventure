extends Node2D

var enemy_count: int
var active_doors: Array[Node] = []
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
const ChestScene := preload("uid://tsiccout8ibv")
var tiers_array := [[1], [1], [1, 2], [1, 2], [1, 2, 3], [2, 3], [2, 3, 4], [3, 4]]

func _ready() -> void:
	tabels_spawn()
	call_deferred("init_room")

func init_room() -> void:
	randomize()
	_shuffle_tilemap_layer()
	await get_tree().process_frame

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

func tabels_spawn() -> void:
	var dungeon = get_tree().current_scene
	var current_floor = dungeon.current_floor
	
	var Chest = ChestScene.instantiate()
	Chest.position = self.position
	Chest.item_tier = tiers_array[current_floor + 1]
	Chest.equip_tier = tiers_array[current_floor + 1]
	#Chest.set_scale(Vector2i(2, 2))
	get_tree().current_scene.add_child(Chest)

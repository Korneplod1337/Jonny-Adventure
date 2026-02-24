extends Node2D

var enemy_count: int
var active_doors: Array[Node] = []
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
var loyality = StatsManager.get_stat_display("shop_loyalty")["value"]

func _ready() -> void:
	print('loyality = ', loyality)
	tabels_spawn()
	call_deferred("init_room")
	animated_sprite_2d.animation_finished.connect(_on_sprite_animation_finished)

func tabels_spawn():
	var TableScene = preload("uid://pk82t1kne84x")
	
	var table1 = TableScene.instantiate()
	table1.position = self.position + Vector2(100, 0)
	table1.cost = 2
	table1.tier = [1] as Array[int]
	table1.pool = 'shop'
	get_tree().current_scene.add_child(table1)
	
	if loyality > 10:
		var table2 = TableScene.instantiate()
		table2.position = self.position + Vector2(200, 0)
		table2.cost = 3
		table2.tier = [1] as Array[int]
		table2.pool = 'shop'
		get_tree().current_scene.add_child(table2)
	
	if loyality > 20:
		var table3 = TableScene.instantiate()
		table3.position = self.position + Vector2(300, 0)
		table3.cost = 5
		table3.tier = [1] as Array[int]
		table3.pool = 'shop'
		get_tree().current_scene.add_child(table3)
	
	if loyality > 40:
		var table4 = TableScene.instantiate()
		table4.position = self.position + Vector2(400, 0)
		table4.cost = 10
		table4.tier = [1] as Array[int]
		table4.pool = 'shop'
		get_tree().current_scene.add_child(table4)
	
	if loyality > 80:
		var table5 = TableScene.instantiate()
		table5.position = self.position + Vector2(500, 0)
		table5.cost = 15
		table5.tier = [1] as Array[int]
		table5.pool = 'shop'
		get_tree().current_scene.add_child(table5)


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


var enteredFlag = true

func bounds_body_entered(body: Node2D) -> void:
	if enteredFlag and body.is_in_group('player'):
		print(body, 'entered in shop= ', enteredFlag)
		animated_sprite_2d.play()
		StatsManager.add_statistic_progress('visited_shops', 1)
		enteredFlag = false

func _on_sprite_animation_finished()-> void:
	if loyality >= 100:
		animated_sprite_2d.animation = 'love'

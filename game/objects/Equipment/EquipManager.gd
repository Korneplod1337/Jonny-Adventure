extends Node

# Пулы эквипмента
const POOLS := {
	"treasure": [
		{"id": "Jonny_shot",   "scene": preload("res://game/objects/Items/test_item.tscn"),
		 "tier": 1, "weight": 10.0},
		{"id": "test_shot", "scene": preload("res://game/objects/Items/test_item.tscn"),
		 "tier": 2, "weight": 10.0},
		{"id": "test_shot2", "scene": preload("res://game/objects/Items/test_item.tscn"),
		 "tier": 1, "weight": 10.0},
	],
	"shop": [
		{"id": "test_shot3", "scene": preload("res://game/objects/Items/test_item.tscn"),
		 "tier": 1, "weight": 10.0},
	],
}

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func random_pick(pool_type: String, tiers: Array[int]) -> Dictionary:
	# Фильтруем по типу пула и тиру
	var pool: Array = POOLS.get(pool_type, []).filter(
		func(e): return e.tier in tiers
	)
	if pool.is_empty():
		return {}

	# Собираем кандидатов с весами из данных
	var candidates: Array = []
	for equipment in pool:
		var w := float(equipment.get("weight", 1.0))
		if w <= 0.0:
			continue
		candidates.append({"equipment": equipment, "weight": w})

	if candidates.is_empty():
		return {}

	# Взвешенный рандом
	var total := 0.0
	for c in candidates:
		total += c.weight

	var r := rng.randf() * total
	var acc := 0.0
	for c in candidates:
		acc += c.weight
		if r <= acc:
			return c.equipment

	return candidates[0].equipment

func spawn(pool_type: String, tiers: Array[int], pos: Vector2) -> void:
	var equipment := random_pick(pool_type, tiers)
	if equipment.is_empty():
		print("No equipment for pool:", pool_type, "tiers:", tiers)
		return
	var inst = equipment.scene.instantiate()
	inst.position = pos
	get_tree().current_scene.add_child(inst)

func debug_spawn(id: String, pos: Vector2) -> void:
	for pool in POOLS.values():
		for equipment in pool:
			if equipment.id == id:
				var inst = equipment.scene.instantiate()
				inst.position = pos
				get_tree().current_scene.add_child(inst)
				return


func weapon(player) :#  -> PackedScene:
	pass
	

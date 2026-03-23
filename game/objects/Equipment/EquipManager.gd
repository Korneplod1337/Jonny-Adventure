extends Node

const ENCHANTMENT_TEMPLATES: Array[EnchantmentResource] = [
	preload("uid://8pwbn1wjmvu1"), # ice enchant
	preload("uid://1t58a5xdtapu"), # poison
	
]

# Пулы эквипмента
'''
Тир 0- бафы 4-х атакующих квадрантов
Тир 1- начальные оружки/слабый эквип
Тир 2- обычные оружки/обычный эквип
Тир 3- имбовые оружки/имба эквип 
'''

const POOLS := {
	"treasure": [
		{"id": "Jonny_shot",   "scene": preload("uid://bwiytmmsxjtk5"), #эквип
		 "tier": 0, "weight": 10.0},
		{"id": "test_shot", "scene": preload("uid://bhswv1jdia8i8"),
		 "tier": 1, "weight": 10.0},
		{"id": "test_shot2", "scene": preload("uid://bwiytmmsxjtk5"),
		 "tier": 2, "weight": 10.0},
		{"id": "test_shot3", "scene": preload("uid://bwiytmmsxjtk5"),
		 "tier": 3, "weight": 10.0},
	],
	"armory": [
		{"id": "Jonny_shot",   "scene": preload("uid://bwiytmmsxjtk5"), #эквип
		 "tier": 0, "weight": 10.0},
		{"id": "test_shot", "scene": preload("uid://bhswv1jdia8i8"),
		 "tier": 1, "weight": 10.0},
		{"id": "test_shot2", "scene": preload("uid://bwiytmmsxjtk5"),
		 "tier": 2, "weight": 10.0},
		{"id": "test_shot3", "scene": preload("uid://bwiytmmsxjtk5"),
		 "tier": 3, "weight": 10.0},
	],
	"weapon": [
		{"id": "Jonny_shot",   "scene": preload("uid://bwiytmmsxjtk5"), #эквип
		 "tier": 0, "weight": 10.0},
		{"id": "test_shot", "scene": preload("uid://bhswv1jdia8i8"),
		 "tier": 1, "weight": 10.0},
		{"id": "Sword", "scene": preload("uid://dke6t1j0r80ny"),
		 "tier": 2, "weight": 10.0},
		{"id": "test_shot3", "scene": preload("uid://bwiytmmsxjtk5"),
		 "tier": 3, "weight": 10.0},
	]
}

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()

func random_pick(pool_type: String, tiers: Array) -> Dictionary:
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

func roll_enchantment() -> EnchantmentResource:
	var template: EnchantmentResource = ENCHANTMENT_TEMPLATES[rng.randi_range(0, ENCHANTMENT_TEMPLATES.size() - 1)]
	var e: EnchantmentResource = template.duplicate(true)
	e.level = rng.randi_range(1, 3)
	

	print(e)
	print(e.get_tooltip_text())


	
	if randi() % 100 > 0: #80
		return e
	return null

func spawn(pool_type: String, tiers: Array, pos: Vector2, cost: int = -1) -> void:
	var equipment := random_pick(pool_type, tiers)
	if equipment.is_empty():
		print("No equipment for pool:", pool_type, " tiers:", tiers)
		return

	var inst = equipment.scene.instantiate()
	inst.position = pos
	inst.enchantment = roll_enchantment()

	if cost != -1:
		inst.cost = cost

	get_tree().current_scene.add_child(inst)


func certain_spawn(id: String, pos: Vector2, enchantment: EnchantmentResource = null) -> void:
	for pool in POOLS.values():
		for equipment in pool:
			if equipment.id == id:
				var inst = equipment.scene.instantiate()
				inst.position = pos
				inst.cost = 0
				if enchantment:
					inst.enchantment = enchantment.duplicate(true)
				get_tree().current_scene.add_child(inst)
				return

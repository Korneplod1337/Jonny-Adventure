extends Node

const ENCHANTMENT_TEMPLATES: Array[EnchantmentResource] = [
	preload("uid://8pwbn1wjmvu1"), # ice enchant
	#preload("uid://1t58a5xdtapu"), # poison
	#preload("uid://b5olpo70xaavd"), # punch
	#preload("uid://c8hfht7lr6kje"), # fire
]

# Пулы эквипмента
'''
Тир 0- бафы 4-х атакующих квадрантов
Тир 1- начальные оружки/слабый эквип
Тир 2- обычные оружки/обычный эквип
Тир 3- имбовые оружки/имба эквип 
'''

var POOLS := {
	"treasure": [ ## временно только шмотки
		{"id": "Death_shield", "scene": preload("uid://bgibadaeek4on"),
		 "tier": 2, "weight": 10.0},
		{"id": "Kaliya_star_hat", "scene": preload("uid://bi5g2vqe6xdek"),
		 "tier": 2, "weight": 10.0},
		{"id": "Poison_boots", "scene": preload("uid://c1fiyctd2xrli"),
		 "tier": 2, "weight": 10.0},
		
	
	],
	"armory": [ ## временно хуета
		{"id": "test_shot", "scene": preload("uid://dyq3vlj4jlml5"),
		 "tier": 1, "weight": 10.0},
		{"id": "Jonny_shot",   "scene": preload("uid://bwiytmmsxjtk5"), # магазин
		 "tier": 1, "weight": 10.0},
		{"id": "EXSpear", "scene": preload("uid://dwqy4pk0blosi"),
		 "tier": 1, "weight": 0.0},
		
		{"id": "test_chest", "scene": preload("uid://bgibadaeek4on"),
		 "tier": 2, "weight": 10.0},
		
		{"id": "test_shot2", "scene": preload("uid://bwiytmmsxjtk5"),
		 "tier": 2, "weight": 10.0},
		{"id": "test_shot3", "scene": preload("uid://bwiytmmsxjtk5"),
		 "tier": 3, "weight": 10.0},
	],
	"weapon": [
		{"id": "Jonny_shot",   "scene": preload("uid://bwiytmmsxjtk5"), # Оружейный кейс
		 "tier": 1, "weight": 10.0},
		{"id": "test_shot", "scene": preload("uid://dyq3vlj4jlml5"),
		 "tier": 1, "weight": 10.0},
		{"id": "tome_of_fairy_tales", "scene": preload("uid://2dtjjer8eim8"),
		 "tier": 2, "weight": 10.0},
		{"id": "CardWeapon", "scene": preload("uid://6ngyovpkns22"),
		 "tier": 3, "weight": 10.0},
		
		{"id": "Spear", "scene": preload("uid://d153rj7fiouha"),
		 "tier": 1, "weight": 10.0},
		{"id": "EXSpear", "scene": preload("uid://dwqy4pk0blosi"),
		 "tier": 3, "weight": 0.0},
		{"id": "Sword", "scene": preload("uid://dke6t1j0r80ny"),
		 "tier": 2, "weight": 10.0},
		{"id": "Nunchucks", "scene": preload("uid://buh4o48vfo1ln"),
		 "tier": 2, "weight": 0.0},
		
		{"id": "Base_Gun", "scene": preload("uid://clqoo37e0j35j"),
		 "tier": 2, "weight": 10.0},
		{"id": "ShotGun", "scene": preload("uid://xi3j7etugnhg"),
		 "tier": 3, "weight": 10.0},
		
	]
}


var equip_visuals := {
	# HEAD
	"Kaliya_star_hat":
		preload("uid://cpdenuif162v0"),
	"test_chest2":
		preload("uid://bupakre411yu6"),
	
	# CHEST
	"Death_shield":
		preload("uid://bupakre411yu6"),
	
	# BOOTS
	"Poison_boots":
		preload("uid://bo8mktvnh36np"),
	
}

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	update_unlocks()

func random_pick(pool_type: String, tiers: Array) -> Dictionary:
	update_unlocks()
	
	# Фильтруем по типу пула и тиру
	var pool: Array = POOLS.get(pool_type, []).filter(
		func(e): return e["tier"] in tiers
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
	
	if randi() % 100 > 80: #80 / 0
		return e
	return null

func spawn(pool_type: String, tiers: Array, pos: Vector2, cost: int = -1) -> void:
	var equipment := random_pick(pool_type, tiers)
	if equipment.is_empty():
		print("No equipment for pool:", pool_type, " tiers:", tiers)
		return

	var inst = equipment["scene"].instantiate()
	inst.position = pos
	if inst.type == 'weapon':
		inst.enchantment = roll_enchantment()

	if cost != -1:
		inst.cost = cost
	#else :
		#inst.cost = 0

	get_tree().current_scene.add_child(inst)

# certain_spawn спавнить любой предмет по его id на определённой позиции с нужным зачарованием
# !И! выключает эффект этого предмета, независимо от того надет он или нет
func certain_spawn(id: String, pos: Vector2, enchantment: EnchantmentResource = null) -> void:
	for pool in POOLS.values():
		for equipment in pool:
			if equipment["id"] == id:
				var inst = equipment["scene"].instantiate()
				inst.position = pos
				inst.cost = 0
				if enchantment:
					inst.enchantment = enchantment.duplicate(true)
				if inst.type != 'weapon':
					inst.effect_off()
				get_tree().current_scene.add_child(inst)
				return


func update_unlocks() -> void:
	var unlocked = AchievementManager.achievements["bad_spear_kills"]["unlocked"]
	
	for pool_name in POOLS.keys():
		var pool = POOLS[pool_name]
		for equipment in pool:
			if equipment["id"] == "EXSpear":
				equipment["weight"] = 10.0 if unlocked else 0.0
				
	
	

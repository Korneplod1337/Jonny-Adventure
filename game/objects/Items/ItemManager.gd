extends Node

# Статические данные (замена класса ItemData)
var unlocked_items: Dictionary = {}
var picked_items: Dictionary = {}
var SAVE_PATH := "user://items.cfg"
var DEFAULT_UNLOCKED := ["heal", "healblack", "healalt", 'healbig', 'lvlup', 'storybook']
var DEFAULT_PICK := ["heal"]
'''
Тир 0- дорогие бафы 4-х квадрантов, хилки
Тир 1- обычные предметы/ статбафы
Тир 2- сильные предметы
Тир 3- меняющие геймплей предметы и хуй пойми что, решафлы 

unlock items это те, которые вообще не могут попасться до того, как их не анлокнет что-то
'''


# Пулы предметов
var POOLS := {
	"treasure": [
		{"id": "heal", "scene": preload("uid://baga6mxgrpf1s"), "tier": 0},
		{"id": "healalt", "scene": preload("uid://ujleakh3r3l0"), "tier": 0},
		{"id": "healblack", "scene": preload("uid://c83w3v5l3edwc"), "tier": 0},
		{"id": "healbig", "scene": preload("uid://bvy7i2nw65tyy"), "tier": 0},
		{"id": "storybook", "scene": preload("uid://m6oyxodimxew"), "tier": 2},
		
		{"id": "ring", "scene": preload("uid://baga6mxgrpf1s"), "tier": 3},
		{"id": "cool_ring", "scene": preload("uid://baga6mxgrpf1s"), "tier": 3}
	],
	"shop": [
		{"id": "lvlup", "scene": preload("uid://ywfb4cg1rk1u"), "tier": 0},
		
		{"id": "shield", "scene": preload("uid://baga6mxgrpf1s"), "tier": 2},
		{"id": "ring", "scene": preload("uid://baga6mxgrpf1s"), "tier": 3},
		{"id": "cool_ring", "scene": preload("uid://baga6mxgrpf1s"), "tier": 1},
	],
	"chest": [
		{"id": "heal", "scene": preload("uid://baga6mxgrpf1s"), "tier": 0},
		{"id": "shield", "scene": preload("uid://baga6mxgrpf1s"), "tier": 2},
		{"id": "ring", "scene": preload("uid://baga6mxgrpf1s"), "tier": 3},
		{"id": "cool_ring", "scene": preload("uid://baga6mxgrpf1s"), "tier": 1},
	],
	"armory": [
		{"id": "lvlup", "scene": preload("uid://ywfb4cg1rk1u"), "tier": 0}
	],
}

var rng := RandomNumberGenerator.new()

func unlock_item(id: String) -> void:
	unlocked_items[id] = true
	save_config()

func mark_picked(id: String) -> void:
	if unlocked_items.get(id):
		picked_items[id] = true
		save_config()
	

func is_unlocked(id: String) -> bool:
	return unlocked_items.get(id, false)

func is_picked(id: String) -> bool:
	return picked_items.get(id, false)

func get_item_unlock_counts() -> String:
	var unique_items = {}
	for pool in POOLS.values():
		for item in pool:
			unique_items[item.id] = true
	
	var total = unique_items.size()
	var unlocked_count = 0
	
	for id in unique_items.keys():
		if is_unlocked(id):
			unlocked_count += 1
			
	return str(unlocked_count) + '/' + str(total)

func save_config() -> void:
	var cfg := ConfigFile.new()
	for k in unlocked_items:
		cfg.set_value("unlocks", k, true)
	for k in picked_items:
		cfg.set_value("picked", k, true)
	cfg.save(SAVE_PATH)

func load_config() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)

	# Дефолтные разблокированные всегда добавляем
	for id in DEFAULT_UNLOCKED:
		unlocked_items[id] = true
	for id in DEFAULT_PICK:
		picked_items[id] = true

	if err == OK:
		for sec in ["unlocks", "picked"]:
			for k in cfg.get_section_keys(sec):
				match sec:
					"unlocks":
						unlocked_items[k] = true
					"picked":
						picked_items[k] = true
	else:
		save_config()

func _ready() -> void:
	load_config()

func random_pick(pool_type: String, tiers: Array) -> Dictionary:
	var pool: Array = POOLS.get(pool_type, []).filter(
		func(i): return i.tier in tiers
	)
	if pool.is_empty():
		return {}

	var candidates: Array = []
	for item in pool:
		if not is_unlocked(item.id):
			continue
		var w := 1.0
		if is_picked(item.id):
			w += 1.0
		candidates.append({"item": item, "weight": w})

	# Fallback: любой unlocked из пула
	if candidates.is_empty():
		for item in pool:
			if is_unlocked(item.id):
				return item
		return {}

	var total := 0.0
	for c in candidates:
		total += c.weight

	var r := rng.randf() * total
	var acc := 0.0
	for c in candidates:
		acc += c.weight
		if r <= acc:
			return c.item

	return candidates[0].item

func spawn(	pool_type: String, 	tiers: Array, 
			pos: Vector2, 		cost:int = -1)	 -> void:
	var item := random_pick(pool_type, tiers)
	if item.is_empty():
		print("No unlocked items for pool:", pool_type, "tiers:", tiers)
		return
	var inst = item.scene.instantiate()
	inst.position = pos
	inst.where = pool_type
	if cost != -1:
		inst.cost = cost
	get_tree().current_scene.add_child(inst)

func certain_spawn(id: String, pos: Vector2) -> void:
	for pool in POOLS.values():
		for item in pool:
			if item.id == id:
				var inst = item.scene.instantiate()
				inst.position = pos
				inst.cost = 0
				get_tree().current_scene.add_child(inst)
				return

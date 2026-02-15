extends Node

# Статические данные (замена класса ItemData)
var unlocked_items: Dictionary = {}
var picked_items: Dictionary = {}
var SAVE_PATH := "user://items.cfg"
var DEFAULT_UNLOCKED := ["hpup", "shield"]

# Пулы предметов
const POOLS := {
	"treasure": [
		{"id": "hpup",  "scene": preload("res://game/objects/Items/Item.tscn"), "tier": 1},
		{"id": "potion", "scene": preload("res://game/objects/Items/Item.tscn"), "tier": 2},
		{"id": "shield", "scene": preload("res://game/objects/Items/Item.tscn"), "tier": 1},
	],
	"shop": [
		{"id": "ring", "scene": preload("res://game/objects/Items/Item.tscn"), "tier": 1},
		{"id": "hpup",  "scene": preload("res://game/objects/Items/Item.tscn"), "tier": 1},
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

func random_pick(pool_type: String, tiers: Array[int]) -> Dictionary:
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

func spawn(pool_type: String, tiers: Array[int], pos: Vector2, cost:int = -1) -> void:
	var item := random_pick(pool_type, tiers)
	if item.is_empty():
		print("No unlocked items for pool:", pool_type, "tiers:", tiers)
		return
	var inst = item.scene.instantiate()
	inst.position = pos
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

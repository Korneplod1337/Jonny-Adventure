extends Node

class ItemData:
	static var unlocked_items: Dictionary = {}
	static var picked_items: Dictionary = {}
	static var SAVE_PATH := "user://items.cfg"
	static var DEFAULT_UNLOCKED := ["hpup", "shield"]

	static func _init() -> void:
		load_config()

	static func unlock_item(id: String) -> void:
		unlocked_items[id] = true
		save_config()

	static func mark_picked(id: String) -> void:
		if unlocked_items.get(id):
			picked_items[id] = true
			save_config()

	static func is_unlocked(id: String) -> bool:
		return unlocked_items.get(id, false)

	static func is_picked(id: String) -> bool:
		return picked_items.get(id, false)

	static func save_config() -> void:
		var cfg := ConfigFile.new()
		for k in unlocked_items:
			cfg.set_value("unlocks", k, true)
		for k in picked_items:
			cfg.set_value("picked", k, true)
		cfg.save(SAVE_PATH)

	static func load_config() -> void:
		var cfg := ConfigFile.new()
		var err := cfg.load(SAVE_PATH)

		# дефолтные разблокированные
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
			# первый запуск — сразу создаём файл с дефолтами
			save_config()

# Пулы
const POOLS := {
	"treasure": [
		{"id": "hpup",  "scene": preload("res://game/objects/Items/test_item.tscn"), "tier": 1},
		{"id": "potion", "scene": preload("res://game/objects/Items/test_item.tscn"), "tier": 2},
		{"id": "shield", "scene": preload("res://game/objects/Items/test_item.tscn"), "tier": 1},
	],
	"shop": [
		{"id": "ring", "scene": preload("res://game/objects/Items/test_item.tscn"), "tier": 3},
	],
}

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	ItemData._init()

func random_pick(pool_type: String, tiers: Array[int]) -> Dictionary:
	var pool: Array = POOLS.get(pool_type, []).filter(
		func(i): return i.tier in tiers
	)
	if pool.is_empty():
		return {}

	var candidates: Array = []
	for item in pool:
		if not ItemData.is_unlocked(item.id):
			continue
		var w := 1.0
		if ItemData.is_picked(item.id):
			w += 1.0
		candidates.append({"item": item, "weight": w})

	# fallback: если по какой-то причине нет кандидатов, но есть unlocked
	if candidates.is_empty():
		for item in pool:
			if ItemData.is_unlocked(item.id):
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

	return candidates[0].item  # безопасный финальный fallback

func spawn(pool_type: String, tiers: Array[int], pos: Vector2) -> void:
	var item := random_pick(pool_type, tiers)
	if item.is_empty():
		print("No unlocked items for pool:", pool_type, "tiers:", tiers)
		return
	var inst = item.scene.instantiate()
	inst.position = pos
	get_tree().current_scene.add_child(inst)

func unlock_item(id: String) -> void:
	ItemData.unlock_item(id)

func debug_spawn(id: String, pos: Vector2) -> void:
	for pool in POOLS.values():
		for item in pool:
			if item.id == id:
				var inst = item.scene.instantiate()
				inst.position = pos
				get_tree().current_scene.add_child(inst)
				return

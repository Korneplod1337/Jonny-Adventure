extends Node

# Внутренний класс для данных (ConfigFile)
class GameData:
	static var unlocked_items: Dictionary = {}
	static var picked_items: Dictionary = {}
	static var SAVE_PATH = "user://items.cfg"
	
	static func _init():
		load_config()
	
	static func unlock_item(id: String):
		unlocked_items[id] = true
		save_config()
	
	static func mark_picked(id: String):
		if unlocked_items.get(id): 
			picked_items[id] = true
			save_config()
	
	static func is_unlocked(id: String) -> bool:
		return unlocked_items.get(id, false)
	
	static func is_picked(id: String) -> bool:
		return picked_items.get(id, false)
	
	static func save_config():
		var cfg = ConfigFile.new()
		for k in unlocked_items: cfg.set_value("unlocks", k, true)
		for k in picked_items: cfg.set_value("picked", k, true)
		cfg.save(SAVE_PATH)
	
	static func load_config():
		var cfg = ConfigFile.new()
		if cfg.load(SAVE_PATH) != OK: return
		for sec in ["unlocks", "picked"]:
			for k in cfg.get_section_keys(sec):
				match sec:
					"unlocks": unlocked_items[k] = true
					"picked": picked_items[k] = true

# Пулы — ДОБАВЛЕНО!
const POOLS = {
	"treasure": [
		{"id": "sword", "scene": preload("res://game/objects/Items/test_item.tscn"), "tier": 1},
		{"id": "potion", "scene": preload("res://game/objects/Items/test_item.tscn"), "tier": 2},
		{"id": "shield", "scene": preload("res://game/objects/Items/test_item.tscn"), "tier": 1}
	],
	"shop": [
		{"id": "ring", "scene": preload("res://game/objects/Items/test_item.tscn"), "tier": 3}
	]
}

var rng = RandomNumberGenerator.new()

func _ready():
	unlock_item("sword")
	GameData._init()

func random_pick(pool_type: String, tiers: Array[int]) -> Dictionary:
	var pool = POOLS.get(pool_type, []).filter(func(i): return i.tier in tiers)
	var candidates = []
	for item in pool:
		if not GameData.is_unlocked(item.id): continue
		var w = 1.0 + (1.0 if GameData.is_picked(item.id) else 0.0)
		candidates.append({"item": item, "weight": w})
	
	if candidates.is_empty():
		# fallback: любой unlocked в пуле
		for item in pool:
			if GameData.is_unlocked(item.id): return item
	
	var total = 0.0
	for c in candidates: total += c.weight
	var r = rng.randf() * total
	var acc = 0.0
	for c in candidates:
		acc += c.weight
		if r <= acc:
			GameData.mark_picked(c.item.id)
			return c.item
	return candidates[0].item

func spawn(pool_type: String, tiers: Array[int], pos: Vector2):
	var item = random_pick(pool_type, tiers)
	var inst = item.scene.instantiate()
	inst.position = pos
	get_tree().current_scene.add_child(inst)

func unlock_item(id: String):
	GameData.unlock_item(id)

func debug_spawn(id: String, pos: Vector2):
	for pool in POOLS.values():
		for item in pool:
			if item.id == id:
				var inst = item.scene.instantiate()
				inst.position = pos
				get_tree().current_scene.add_child(inst)
				return

'''
Спавн: ItemManager.spawn("treasure", [1], pos) — всегда спавнит unlocked (ролл или fallback).
Разблокировка: ItemManager.unlock_item("potion") (статично).
Дебаг: ItemManager.debug_spawn("sword", pos).
test_item.tscn/gd: export var item_id: String = "sword" (заполните в редакторе).
'''

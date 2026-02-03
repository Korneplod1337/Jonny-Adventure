# EquipManager.gd
extends Node
class_name EquipManager

class EquipData:
	static var unlocked: Dictionary = {}
	static var SAVE_PATH := "user://equip.cfg"
	static var DEFAULT_UNLOCKED_EQUIP := [
		"hat_basic",
		"gloves_basic",
		"armor_basic",
		"gun_basic",
	]

	static func _init() -> void:
		load_config()

	static func unlock(id: String) -> void:
		unlocked[id] = true
		save_config()

	static func is_unlocked(id: String) -> bool:
		return unlocked.get(id, false)

	static func save_config() -> void:
		var cfg := ConfigFile.new()
		for k in unlocked.keys():
			cfg.set_value("unlocks", k, true)
		cfg.save(SAVE_PATH)

	static func load_config() -> void:
		var cfg := ConfigFile.new()
		var err := cfg.load(SAVE_PATH)

		unlocked.clear()

		# дефолтные эквипы
		for id in DEFAULT_UNLOCKED_EQUIP:
			unlocked[id] = true

		if err == OK and cfg.has_section("unlocks"):
			for k in cfg.get_section_keys("unlocks"):
				unlocked[k] = true
		else:
			# первый запуск — сразу создаём файл с дефолтами
			save_config()

func _ready() -> void:
	EquipData._init()

enum SlotType { HEAD, GLOVES, ARMOR, WEAPON }

const EQUIP_ITEMS := [
	{"id": "hat_basic", 			"scene": preload("uid://c0wi0y0m87i5u"),
	 "tier": 1, 				"slot": SlotType.HEAD },
	{"id": "gloves_basic", 		"scene": preload("uid://c0wi0y0m87i5u"), 
	"tier": 1, 				"slot": SlotType.GLOVES },
	{"id": "armor_basic", 		"scene": preload("uid://c0wi0y0m87i5u"), 
	"tier": 1, 				"slot": SlotType.ARMOR },
	{"id": "gun_basic", 			"scene": preload("uid://c0wi0y0m87i5u"), 
	"tier": 1, 				"slot": SlotType.WEAPON },
]

var rng := RandomNumberGenerator.new()

func spawn_random(tiers: Array[int], pos: Vector2) -> void:
	rng.randomize()

	var candidates: Array = []
	for item in EQUIP_ITEMS:
		if item.tier in tiers and EquipData.is_unlocked(item.id):
			candidates.append(item)

	if candidates.is_empty():
		print("No unlocked equip for tiers: ", tiers)
		return

	var data = candidates[rng.randi() % candidates.size()]
	var inst = data.scene.instantiate()
	inst.position = pos
	get_tree().current_scene.add_child(inst)

# например, после убийства врага EquipManager.spawn_random([1], global_position)

func debug_spawn(id: String, pos: Vector2) -> void:
	for item in EQUIP_ITEMS:
		if item.id == id:
			var inst = item.scene.instantiate()
			inst.position = pos
			get_tree().current_scene.add_child(inst)
			return
	print("Equip item not found: ", id)

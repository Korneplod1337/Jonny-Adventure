extends Node

var unlocked_items: Dictionary = {}
var picked_items: Dictionary = {}
var run_picked_items: Dictionary = {}
var SAVE_PATH := "user://items.cfg"
var DEFAULT_UNLOCKED := ["heal", "healblack", "healalt", 'healbig', 'lvlup', 'spiderweb',
 "mindseye", "storybook", "boomerang", 'aegis', 'cross', 'bone', 'meat', 'beard',
 'homuncules', 'seed', 'shine', 'pocketwatch', 'bomb', 'jetfuel', 'broom', 'sandclock',
 'powerofdamage', 'cauldron', 'harmony', 'fountain', 'grail', 'stardust', 'sextant',
 'exorcism', 'virus', 'basilisk',
 'guillotine', 'wraith', 'target', 'radar',
 'luckycoin', 'ez', 'petroglyph', 'forceshield', 'blueprint',
 'card6', 'card7', 'card8', 'card9', 'card10', 'cardjack', 'cardqueen', 'cardking', 'cardace',]
var DEFAULT_PICK := ["heal"]

const CARD_IDS := [
	"card6", "card7", "card8", "card9", "card10",
	"cardjack", "cardqueen", "cardking", "cardace",
]
# Карты, подобранные за забег, усиливают выпадение остальных (кроме туза как источника)
const CARD_SYNERGY_SOURCES := [
	"card6", "card7", "card8", "card9", "card10",
	"cardjack", "cardqueen", "cardking",
]
const CARD_PICK_SYNERGY_ADD := 3.0

'''
Тир 0- дорогие бафы 4-х квадрантов, хилки
Тир 1- обычные предметы/ статбафы
Тир 2- сильные предметы
Тир 3- меняющие геймплей предметы и хуй пойми что, решафлы 
Тир 4- карты

unlock items это те, которые вообще не могут попасться до того, как их не анлокнет что-то

Вес спавна:
- weight в POOLS — базовый вес (по умолчанию 1.0)
- UNIQUE_ONCE_ITEMS — после подбора вес = 0, больше не выпадают
- REPEAT_PICKED_BONUS — бонус к весу для повторяемых предметов, уже подобранных ранее
- WEIGHT_SYNERGIES — если подобран source, меняется вес targets (для карт-синергий)
'''

# Выпадают один раз за забег — после подбора вес становится 0
const UNIQUE_ONCE_ITEMS := [
	"mindseye",
	
]

# Бонус к весу, если предмет уже подбирали (только для не-уникальных)
const REPEAT_PICKED_BONUS := 1.0

# Синергии: подобранный source усиливает выпадение targets
# multiplier — умножает вес, add — прибавляет после умножения
const WEIGHT_SYNERGIES := [
	# {"source": "some_card", "targets": ["aegis", "cross"], "multiplier": 3.0},
]

# настроить пулы
var POOLS := {
	"treasure": [
		{"id": "heal", 		"scene": preload("uid://baga6mxgrpf1s"), 	"tier": 0},
		{"id": "healalt", 	"scene": preload("uid://ujleakh3r3l0"), 		"tier": 0},
		{"id": "healblack", 	"scene": preload("uid://c83w3v5l3edwc"), 	"tier": 0},
		{"id": "healbig", 	"scene": preload("uid://bvy7i2nw65tyy"), 	"tier": 0},
		{"id": "spiderweb", 	"scene": preload("uid://cgcss4ubm0tjd"), 	"tier": 1},
		{"id": "mindseye", 	"scene": preload("uid://b2l04uommikl0"), 	"tier": 1},
		{"id": "aegis", 		"scene": preload("uid://ccrdfupi8hyq2"), 	"tier": 1}, 
		{"id": "cross", 		"scene": preload("uid://dk3m8x2nq7wp4"), 	"tier": 1},
		{"id": "bone", 		"scene": preload("uid://el4n9y3or8xq5"), 	"tier": 1},
		{"id": "meat", 		"scene": preload("uid://fm5o0z4ps9yr6"), 	"tier": 1},
		{"id": "beard", 		"scene": preload("uid://gn6p1a5qt0zs7"), 	"tier": 1},
		{"id": "homuncules", "scene": preload("uid://ho7q2b6ru1at8"), 	"tier": 1},
		{"id": "seed", 		"scene": preload("uid://ip8r3c7sv2bu9"), 	"tier": 1},
		{"id": "shine", 		"scene": preload("uid://jq9s4d8tw3cv0"), 	"tier": 1},
		{"id": "pocketwatch","scene": preload("uid://kr0t5e9ux4dw1"), 	"tier": 1},
		{"id": "bomb", 		"scene": preload("uid://ls1u6f0vy5ex2"), 	"tier": 1},
		{"id": "jetfuel", 	"scene": preload("uid://mt2v7g1wz6fy3"), 	"tier": 1},
		{"id": "broom", 		"scene": preload("uid://nu3w8h2xa7gz4"), 	"tier": 1},
		{"id": "sandclock", 	"scene": preload("uid://ov4x9i3yb8ha5"), 	"tier": 1},
		{"id": "powerofdamage", "scene": preload("uid://pw5y0j4zc9ib6"), "tier": 1},
		{"id": "torch", 		"scene": preload("uid://qx6z1k5ad0jc7"), 	"tier": 1},
		{"id": "cauldron", 	"scene": preload("uid://ry7a2l6be1kd8"), 	"tier": 1},
		{"id": "harmony", 	"scene": preload("uid://sz8b3m7cf2le9"), 	"tier": 1},
		{"id": "fountain", 	"scene": preload("uid://ta9c4n8dg3mf0"), 	"tier": 1},
		{"id": "grail", 		"scene": preload("uid://ub0d5o9eh4ng1"), 	"tier": 1},
		{"id": "stardust", 	"scene": preload("uid://vc1e6p0fi5oh2"), 	"tier": 1},
		{"id": "sextant", 	"scene": preload("uid://wd2f7q1gj6pi3"), 	"tier": 1},
		{"id": "exorcism", 	"scene": preload("uid://bspi32myt8j6q"), 	"tier": 1},
		{"id": "virus", 		"scene": preload("uid://dex02b4e0mukt"), 	"tier": 1},
		{"id": "basilisk", 	"scene": preload("uid://dxwwacpt1rply"), 	"tier": 1},
		{"id": "guillotine", "scene": preload("res://game/objects/items/scenes/tier 1/Guillotine.tscn"), "tier": 1},
		{"id": "wraith", 	"scene": preload("res://game/objects/items/scenes/tier 1/Wraith.tscn"), 	"tier": 1},
		{"id": "target", 	"scene": preload("res://game/objects/items/scenes/tier 1/Target.tscn"), 	"tier": 1},
		{"id": "radar", 		"scene": preload("res://game/objects/items/scenes/tier 1/Radar.tscn"), 	"tier": 1},
		{"id": "luckycoin", 	"scene": preload("res://game/objects/items/scenes/tier 1/LuckyCoin.tscn"), "tier": 1},
		{"id": "ez", 		"scene": preload("res://game/objects/items/scenes/tier 1/EZ.tscn"), 		"tier": 1},
		{"id": "petroglyph",	"scene": preload("res://game/objects/items/scenes/tier 1/Petroglyph.tscn"), "tier": 1},
		{"id": "forceshield","scene": preload("res://game/objects/items/scenes/tier 1/ForceShield.tscn"), "tier": 1},
		{"id": "blueprint", 	"scene": preload("res://game/objects/items/scenes/tier 1/Blueprint.tscn"), "tier": 1},
		
		{"id": "storybook", 	"scene": preload("uid://m6oyxodimxew"), 		"tier": 2},
		{"id": "boomerang", 	"scene": preload("uid://duqt5c8r3bui4"), 	"tier": 3},

		{"id": "card6", 		"scene": preload("res://game/objects/items/scenes/tier 4/Card6.tscn"), 		"tier": 4},
		{"id": "card7", 		"scene": preload("res://game/objects/items/scenes/tier 4/Card7.tscn"), 		"tier": 4},
		{"id": "card8", 		"scene": preload("res://game/objects/items/scenes/tier 4/Card8.tscn"), 		"tier": 4},
		{"id": "card9", 		"scene": preload("res://game/objects/items/scenes/tier 4/Card9.tscn"), 		"tier": 4},
		{"id": "card10", 	"scene": preload("res://game/objects/items/scenes/tier 4/Card10.tscn"), 		"tier": 4},
		{"id": "cardjack", 	"scene": preload("res://game/objects/items/scenes/tier 4/CardJack.tscn"), 	"tier": 4},
		{"id": "cardqueen", 	"scene": preload("res://game/objects/items/scenes/tier 4/CardQueen.tscn"), 	"tier": 4},
		{"id": "cardking", 	"scene": preload("res://game/objects/items/scenes/tier 4/CardKing.tscn"), 	"tier": 4},
		{"id": "cardace", 	"scene": preload("res://game/objects/items/scenes/tier 4/CardAce.tscn"), 	"tier": 4},
		
	],
	"shop": [
		{"id": "lvlup", 		"scene": preload("uid://ywfb4cg1rk1u"), "tier": 0},
		
		{"id": "shield", 	"scene": preload("uid://baga6mxgrpf1s"), "tier": 2},
		{"id": "ring", 		"scene": preload("uid://baga6mxgrpf1s"), "tier": 3},
		{"id": "cool_ring", "scene": preload("uid://baga6mxgrpf1s"), "tier": 1},
	],
	"chest": [
		{"id": "heal", 		"scene": preload("uid://baga6mxgrpf1s"), "tier": 0},
		{"id": "shield", 	"scene": preload("uid://baga6mxgrpf1s"), "tier": 2},
		{"id": "ring", 		"scene": preload("uid://baga6mxgrpf1s"), "tier": 3},
		{"id": "cool_ring", "scene": preload("uid://baga6mxgrpf1s"), "tier": 1},
	],
	"armory": [
		{"id": "lvlup", 		"scene": preload("uid://ywfb4cg1rk1u"), "tier": 0}
	],
}

var rng := RandomNumberGenerator.new()
var last_picked_item_id: String = ""

func unlock_item(id: String) -> void:
	unlocked_items[id] = true
	save_config()

func mark_picked(id: String) -> void:
	if not unlocked_items.get(id):
		return
	run_picked_items[id] = true
	if id != "blueprint":
		last_picked_item_id = id
	if id not in UNIQUE_ONCE_ITEMS:
		picked_items[id] = true
		save_config()

func reset_run() -> void:
	run_picked_items.clear()
	last_picked_item_id = ""

func apply_item_effect_by_id(id: String, player: Node) -> bool:
	if id.is_empty() or id == "blueprint":
		return false
	for pool in POOLS.values():
		for item in pool:
			if item.id == id:
				var inst = item.scene.instantiate()
				inst.player = player
				inst.apply_item_effect()
				inst.queue_free()
				return true
	return false

func apply_last_item_effect(player: Node) -> bool:
	return apply_item_effect_by_id(last_picked_item_id, player)

func recharge_floor_items(player: Node) -> void:
	if player.has_method("recharge_force_shield"):
		player.recharge_force_shield()

func is_unlocked(id: String) -> bool:
	return unlocked_items.get(id, false)

func is_picked(id: String) -> bool:
	return picked_items.get(id, false)

func is_picked_this_run(id: String) -> bool:
	return run_picked_items.get(id, false)

func get_item_unlock_counts() -> String:
	update_unlocks()
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

	var cleaned_unique := false
	for id in UNIQUE_ONCE_ITEMS:
		if picked_items.erase(id):
			cleaned_unique = true
	if cleaned_unique:
		save_config()

func _ready() -> void:
	load_config()
	update_unlocks()
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

func _on_achievement_unlocked(_popup_path: String) -> void:
	update_unlocks()
	save_config()

func update_unlocks() -> void:
	for ach_id in AchivStatsRegistry.ITEM_UNLOCKS.keys():
		if not AchievementManager.is_unlocked(ach_id):
			continue
		for item_id in AchivStatsRegistry.ITEM_UNLOCKS[ach_id]:
			unlocked_items[item_id] = true

func get_spawn_weight(item: Dictionary) -> float:
	if not is_unlocked(item.id):
		return 0.0

	if item.id in UNIQUE_ONCE_ITEMS and is_picked_this_run(item.id):
		return 0.0

	var w := float(item.get("weight", 1.0))

	if is_picked(item.id) and item.id not in UNIQUE_ONCE_ITEMS:
		w += REPEAT_PICKED_BONUS

	for rule in WEIGHT_SYNERGIES:
		if not is_picked(rule.source):
			continue
		if item.id in rule.targets:
			w *= float(rule.get("multiplier", 1.0))
			w += float(rule.get("add", 0.0))

	if item.id in CARD_IDS:
		for source_id in CARD_SYNERGY_SOURCES:
			if source_id == item.id:
				continue
			if is_picked_this_run(source_id):
				w += CARD_PICK_SYNERGY_ADD

	return maxf(w, 0.0)

func random_pick(pool_type: String, tiers: Array) -> Dictionary:
	update_unlocks()
	var pool: Array = POOLS.get(pool_type, []).filter(
		func(i): return i.tier in tiers
	)
	if pool.is_empty():
		return {}

	var candidates: Array = []
	for item in pool:
		var w := get_spawn_weight(item)
		if w <= 0.0:
			continue
		candidates.append({"item": item, "weight": w})

	if candidates.is_empty():
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

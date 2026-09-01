extends Node

const ENCHANTMENT_TEMPLATES: Array[EnchantmentResource] = [
	preload("uid://8pwbn1wjmvu1"), # ice enchant
	#preload("uid://1t58a5xdtapu"), # poison
	#preload("uid://b5olpo70xaavd"), # punch
	#preload("uid://c8hfht7lr6kje"), # fire
] #сделать молнии

# Пулы эквипмента
'''
Тир 0- бафы 4-х атакующих квадрантов
Тир 1- начальные оружки/слабый эквип
Тир 2- обычные оружки/обычный эквип
Тир 3- имбовые оружки/имба эквип 
'''

var POOLS := {
	"treasure": [ ## только шмотки
		#{"id": "Death_shield", "scene": preload("uid://bgibadaeek4on"),
		 #"tier": 3, "weight": 10.0},
		#{"id": "Cleaving", "scene": preload("uid://bdx03qht6dlwl"),
		 #"tier": 2, "weight": 10.0},
		#{"id": "Accelerator_Cloak", "scene": preload("uid://c6snhkx0masi2"),
		 #"tier": 3, "weight": 10.0},
		#{"id": "Kaliya_star_hat", "scene": preload("uid://bi5g2vqe6xdek"),
		 #"tier": 2, "weight": 10.0},
		#{"id": "Poison_boots", "scene": preload("uid://c1fiyctd2xrli"),
		 #"tier": 2, "weight": 10.0},
		#{"id": "Kaliya_boots", "scene": preload("uid://by8qnvewpw3v3"),
		 #"tier": 3, "weight": 10.0},
		{"id": "Speed_boots", "scene": preload("uid://lcbyc42s480y"),
		 "tier": 1, "weight": 10.0},
		{"id": "Alchemists_glasses", "scene": preload("uid://8nlac1wigti"),
		 "tier": 1, "weight": 10.0},
		{"id": "Surestrike", "scene": preload("uid://rm084balo4ar"),
		 "tier": 1, "weight": 10.0},
		{"id": "Spread_Shot", "scene": preload("res://game/objects/Equipment/head/Spread_Shot.tscn"),
		 "tier": 1, "weight": 10.0},
		#{"id": "Iron_Maiden", "scene": preload("res://game/objects/Equipment/head/Iron_Maiden.tscn"),
		 #"tier": 1, "weight": 10.0},
		#{"id": "lucky_head", "scene": preload("uid://b6vskrremanrc"),
		 #"tier": 2, "weight": 10.0},
		
		
	
	],
	"armory": [
		{"id": "Jonny_shot",   "scene": preload("uid://bwiytmmsxjtk5"), # Оружейный кейс
		 "tier": 1, "weight": 10.0},
		{"id": "test_shot", "scene": preload("uid://dyq3vlj4jlml5"),
		 "tier": 1, "weight": 10.0},
		{"id": "Matchlock", "scene": preload("uid://d4b16tebiwudm"),
		 "tier": 1, "weight": 10.0},
		{"id": "Speed_boots", "scene": preload("uid://lcbyc42s480y"),
		 "tier": 1, "weight": 10.0},
		{"id": "Alchemists_glasses", "scene": preload("uid://8nlac1wigti"),
		 "tier": 1, "weight": 10.0},
		{"id": "Surestrike", "scene": preload("uid://rm084balo4ar"),
		 "tier": 1, "weight": 10.0},
		{"id": "Iron_Maiden", "scene": preload("res://game/objects/Equipment/head/Iron_Maiden.tscn"),
		 "tier": 1, "weight": 10.0},
		{"id": "Spread_Shot", "scene": preload("res://game/objects/Equipment/head/Spread_Shot.tscn"),
		 "tier": 1, "weight": 10.0},
		
		{"id": "Dash", "scene": preload("res://game/objects/Equipment/Ability/equip/Dash_equip.tscn"),
		 "tier": 1, "weight": 10.0},
		{"id": "CoinRoulette", "scene": preload("res://game/objects/Equipment/Ability/equip/CoinRoulette_equip.tscn"),
		 "tier": 1, "weight": 10.0},
		{"id": "Ember", "scene": preload("res://game/objects/Equipment/Ability/equip/Ember_equip.tscn"),
		 "tier": 1, "weight": 10.0},

	],
	"weapon": [
		{"id": "Jonny_shot",   "scene": preload("uid://bwiytmmsxjtk5"), # Оружейный кейс
		 "tier": 1, "weight": 10.0},
		{"id": "test_shot", "scene": preload("uid://dyq3vlj4jlml5"),
		 "tier": 1, "weight": 10.0},
		#{"id": "Jonny_shot_Alt", "scene": preload("uid://f07ikj132ro1"),
		# "tier": 2, "weight": 10.0},
		#{"id": "tome_of_fairy_tales", "scene": preload("uid://2dtjjer8eim8"),
		 #"tier": 2, "weight": 10.0},
		#{"id": "CardWeapon", "scene": preload("uid://6ngyovpkns22"),
		#"tier": 3, "weight": 0.0},
		#{"id": "arid_membrane", "scene": preload("uid://ck8xe35a25xmt"),
		# "tier": 3, "weight": 10.0},
		
		{"id": "Spear", "scene": preload("uid://d153rj7fiouha"),
		 "tier": 1, "weight": 10.0},
		#{"id": "EXSpear", "scene": preload("uid://dwqy4pk0blosi"),
		 #"tier": 3, "weight": 0.0},
		#{"id": "Sword", "scene": preload("uid://dke6t1j0r80ny"),
		 #"tier": 2, "weight": 10.0},
		#{"id": "Nunchucks", "scene": preload("uid://buh4o48vfo1ln"),
		 #"tier": 2, "weight": 10.0},
		#{"id": "Solaris", "scene": preload("uid://ci4paxr8kkjx2"),
		# "tier": 3, "weight": 10.0},
		#{"id": "Axe", "scene": preload("uid://c8glpvvgfk441"),
		# "tier": 2, "weight": 10.0},
		
		{"id": "Matchlock", "scene": preload("uid://d4b16tebiwudm"),
		 "tier": 1, "weight": 10.0},
		#{"id": "Base_Gun", "scene": preload("uid://clqoo37e0j35j"),
		 #"tier": 2, "weight": 10.0},
		#{"id": "Sniper_Gun", "scene": preload("uid://i6kqba6ow2yq"),
		 #"tier": 2, "weight": 10.0},
		#{"id": "Scatterhand", "scene": preload("uid://ixfqllfdouf6"),
		 #"tier": 2, "weight": 10.0},
		#{"id": "ShotGun", "scene": preload("uid://xi3j7etugnhg"),
		 #"tier": 3, "weight": 10.0},
		#{"id": "Magic pistol", "scene": preload("uid://c6exdflntaqki"),
		 #"tier": 3, "weight": 10.0},
		],
	
	"ability": [ ## дебаг / certain_spawn, пока не в сундуках
		{"id": "Dash", "scene": preload("res://game/objects/Equipment/Ability/equip/Dash_equip.tscn"),
		 "tier": 1, "weight": 10.0},
		{"id": "CoinRoulette", "scene": preload("res://game/objects/Equipment/Ability/equip/CoinRoulette_equip.tscn"),
		 "tier": 1, "weight": 10.0},
		{"id": "CrackedEruption", "scene": preload("res://game/objects/Equipment/Ability/equip/CrackedEruption_equip.tscn"),
		 "tier": 2, "weight": 10.0},
		{"id": "Ember", "scene": preload("res://game/objects/Equipment/Ability/equip/Ember_equip.tscn"),
		 "tier": 1, "weight": 10.0},
		{"id": "Shield", "scene": preload("res://game/objects/Equipment/Ability/equip/Shield_equip.tscn"),
		 "tier": 1, "weight": 10.0},
		{"id": "StealLife", "scene": preload("res://game/objects/Equipment/Ability/equip/StealLife_equip.tscn"),
		 "tier": 2, "weight": 10.0},
		{"id": "TatteredTrade", "scene": preload("res://game/objects/Equipment/Ability/equip/TatteredTrade_equip.tscn"),
		 "tier": 2, "weight": 10.0},
		{"id": "DoomedChance", "scene": preload("res://game/objects/Equipment/Ability/equip/DoomedChance_equip.tscn"),
		 "tier": 2, "weight": 10.0},
		{"id": "MiromirBlessing", "scene": preload("res://game/objects/Equipment/Ability/equip/MiromirBlessing_equip.tscn"),
		 "tier": 2, "weight": 10.0},
		{"id": "BoonOfKeres", "scene": preload("res://game/objects/Equipment/Ability/equip/BoonOfKeres_equip.tscn"),
		 "tier": 2, "weight": 10.0},
		{"id": "Surge", "scene": preload("res://game/objects/Equipment/Ability/equip/Surge_equip.tscn"),
		 "tier": 1, "weight": 10.0},
		{"id": "GoldHoard", "scene": preload("res://game/objects/Equipment/Ability/equip/GoldHoard_equip.tscn"),
		 "tier": 1, "weight": 10.0},
		{"id": "ThePilgrimage", "scene": preload("res://game/objects/Equipment/Ability/equip/ThePilgrimage_equip.tscn"),
		 "tier": 2, "weight": 10.0},
		{"id": "Expedition", "scene": preload("res://game/objects/Equipment/Ability/equip/Expedition_equip.tscn"),
		 "tier": 2, "weight": 10.0},
		{"id": "MiromirGift", "scene": preload("res://game/objects/Equipment/Ability/equip/MiromirGift_equip.tscn"),
		 "tier": 2, "weight": 10.0},
		{"id": "KeresCall", "scene": preload("res://game/objects/Equipment/Ability/equip/KeresCall_equip.tscn"),
		 "tier": 3, "weight": 10.0},
		{"id": "MariaCall", "scene": preload("res://game/objects/Equipment/Ability/equip/MariaCall_equip.tscn"),
		 "tier": 3, "weight": 10.0},
	],
	"all": [ # without ability
		{"id": "Jonny_shot",   "scene": preload("uid://bwiytmmsxjtk5"), # Оружейный кейс
		 "tier": 1, "weight": 10.0},
		{"id": "test_shot", "scene": preload("uid://dyq3vlj4jlml5"),
		 "tier": 1, "weight": 10.0},
		{"id": "tome_of_fairy_tales", "scene": preload("uid://2dtjjer8eim8"),
		 "tier": 2, "weight": 10.0},
		{"id": "CardWeapon", "scene": preload("uid://6ngyovpkns22"),
		 "tier": 3, "weight": 0.0},
		
		{"id": "Spear", "scene": preload("uid://d153rj7fiouha"),
		 "tier": 1, "weight": 10.0},
		{"id": "EXSpear", "scene": preload("uid://dwqy4pk0blosi"),
		 "tier": 3, "weight": 0.0},
		{"id": "Sword", "scene": preload("uid://dke6t1j0r80ny"),
		 "tier": 2, "weight": 10.0},
		{"id": "Nunchucks", "scene": preload("uid://buh4o48vfo1ln"),
		 "tier": 2, "weight": 10.0},
		{"id": "Solaris", "scene": preload("uid://ci4paxr8kkjx2"),
		 "tier": 3, "weight": 10.0},
		{"id": "arid_membrane", "scene": preload("uid://ck8xe35a25xmt"),
		 "tier": 2, "weight": 10.0},
		{"id": "Axe", "scene": preload("res://game/objects/Equipment/Weapon/equip/Axe_equip.tscn"),
		 "tier": 2, "weight": 10.0},
		
		{"id": "Matchlock", "scene": preload("uid://d4b16tebiwudm"),
		 "tier": 1, "weight": 10.0},
		{"id": "Base_Gun", "scene": preload("uid://clqoo37e0j35j"),
		 "tier": 2, "weight": 10.0},
		{"id": "Sniper_Gun", "scene": preload("uid://i6kqba6ow2yq"),
		 "tier": 2, "weight": 10.0},
		{"id": "Scatterhand", "scene": preload("uid://ixfqllfdouf6"),
		 "tier": 2, "weight": 10.0},
		{"id": "ShotGun", "scene": preload("uid://xi3j7etugnhg"),
		 "tier": 3, "weight": 10.0},
		{"id": "Magic pistol", "scene": preload("uid://c6exdflntaqki"),
		 "tier": 3, "weight": 10.0},
		
		{"id": "Death_shield", "scene": preload("uid://bgibadaeek4on"),
		 "tier": 3, "weight": 10.0},
		{"id": "Cleaving", "scene": preload("uid://bdx03qht6dlwl"),
		 "tier": 2, "weight": 10.0},
		{"id": "Accelerator_Cloak", "scene": preload("uid://c6snhkx0masi2"),
		 "tier": 3, "weight": 10.0},
		{"id": "Kaliya_star_hat", "scene": preload("uid://bi5g2vqe6xdek"),
		 "tier": 2, "weight": 10.0},
		{"id": "Poison_boots", "scene": preload("uid://c1fiyctd2xrli"),
		 "tier": 2, "weight": 10.0},
		{"id": "Kaliya_boots", "scene": preload("uid://by8qnvewpw3v3"),
		 "tier": 3, "weight": 10.0},
		{"id": "Speed_boots", "scene": preload("uid://lcbyc42s480y"),
		 "tier": 2, "weight": 10.0},
		{"id": "Alchemists_glasses", "scene": preload("uid://8nlac1wigti"),
		 "tier": 2, "weight": 10.0},
		{"id": "Surestrike", "scene": preload("uid://rm084balo4ar"),
		 "tier": 2, "weight": 10.0},
		{"id": "lucky_head", "scene": preload("uid://b6vskrremanrc"),
		 "tier": 2, "weight": 10.0},
		{"id": "Iron_Maiden", "scene": preload("res://game/objects/Equipment/head/Iron_Maiden.tscn"),
		 "tier": 2, "weight": 10.0},
		{"id": "Spread_Shot", "scene": preload("res://game/objects/Equipment/head/Spread_Shot.tscn"),
		 "tier": 2, "weight": 10.0},
	]
}


var equip_visuals := {
	# HEAD
	"Kaliya_star_hat":
		preload("uid://cpdenuif162v0"),
	"Alchemists_glasses":
		preload("uid://h7lm83qrvm2y"),
	"Surestrike":
		preload("uid://big2quf10m3j8"),
	"lucky_head":
		preload("uid://dfoxvsjwytkk7"),
	"Iron_Maiden":
		preload("res://image/equip/head/Iron_Maiden.tres"),
	"Spread_Shot":
		preload("res://image/equip/head/Spread_shot.tres"),
		
	# CHEST
	"Death_shield":
		preload("uid://bupakre411yu6"),
	"Accelerator_Cloak":
		preload("uid://d1xaywuwy2w1e"),
	"Cleaving":
		preload("uid://ceswef8mjmxf4"),
	
	# BOOTS
	"Poison_boots":
		preload("uid://bo8mktvnh36np"),
	"Kaliya_boots":
		preload("uid://b5n6x6aiv8j01"),
	"Speed_boots":
		preload("uid://37cru6ygwhba"),
	
}

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	update_unlocks()
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)


func _on_achievement_unlocked(_popup_path: String) -> void:
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
	
	
	if randi() % 100 > 75: #80 / 0
		print(e, e.get_tooltip_text())
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
# ability_cd — остаток перезарядки способности, переносится на pickup на земле
func certain_spawn(id: String, pos: Vector2, enchantment: EnchantmentResource = null, ability_cd: Dictionary = {}) -> void:
	for pool in POOLS.values():
		for equipment in pool:
			if equipment["id"] == id:
				var inst = equipment["scene"].instantiate()
				inst.position = pos
				inst.cost = 0
				if enchantment:
					inst.enchantment = enchantment.duplicate(true)
				if inst.type == "ability":
					if not ability_cd.is_empty() and inst.has_method("set_saved_cooldown"):
						inst.set_saved_cooldown(ability_cd)
					inst.effect_off()
				elif inst.type != 'weapon':
					inst.effect_off()
				get_tree().current_scene.add_child(inst)
				return


func update_unlocks() -> void:
	for ach_id in AchivStatsRegistry.EQUIP_UNLOCKS.keys():
		var unlocked := AchievementManager.is_unlocked(ach_id)
		for rule in AchivStatsRegistry.EQUIP_UNLOCKS[ach_id]:
			_set_equipment_weight(rule["pool"], rule["equipment_id"], 10.0 if unlocked else 0.0)


func _set_equipment_weight(pool_name: String, equipment_id: String, weight: float) -> void:
	var pool: Array = POOLS.get(pool_name, [])
	for equipment in pool:
		if equipment["id"] == equipment_id:
			equipment["weight"] = weight

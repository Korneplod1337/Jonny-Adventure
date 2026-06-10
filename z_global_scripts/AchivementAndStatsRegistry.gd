extends Node

## Включить весь трекинг статистики и достижений.
const TRACKING_ENABLED := false

## Единый реестр счётчиков.
##   desc          — подпись в меню статистики
##   show_in_menu  — показывать игроку в меню stats (false = только для разблокировок)
##   custom_display — особый формат значения ("item_unlock_counts" и т.п.)
##   achievement   — опционально: достижение, привязанное к этому счётчику

const STATS := {
	"kills": {
		"desc": "Kills",
		"show_in_menu": true,
		"achievement": {
			"id": "first_kill",
			"name": "First kill",
			"desc": "Kill 1 enemy",
			"goal": 1,
			"menu_icon": "res://image/achievements/menu_achiv/first_enemy.png",
			"hud_popup": "res://image/achievements/hud_achiv/first_enemy_hud.png",
		},
	},
	"lifetime": {
		"desc": "Lifetime",
		"show_in_menu": true,
	},
	"distance_traveled": {
		"desc": "Distance traveled",
		"show_in_menu": true,
		"achievement": {
			"id": "long_distance",
			"name": "Far away...",
			"desc": "Runs of 10 km",
			"goal": 10000,
			"menu_icon": "res://image/achievements/menu_achiv/long_distance.png",
			"hud_popup": "res://image/achievements/hud_achiv/long_distance_hud.png",
		},
	},
	"items_equipped": {
		"desc": "Items equipped",
		"show_in_menu": true,
		"achievement": {
			"id": "first_item",
			"name": "Iron luck",
			"desc": "Put on the 1-st item",
			"goal": 1,
			"menu_icon": "res://image/achievements/menu_achiv/first_item.png",
			"hud_popup": "res://image/achievements/hud_achiv/first_item_hud.png",
		},
	},
	"items_unlock": {
		"desc": "Items unlocked",
		"show_in_menu": true,
		"custom_display": "item_unlock_counts",
	},
	"visited_shops": {
		"desc": "Shops u entered",
		"show_in_menu": true,
	},
	"shop_loyalty": {
		"desc": "Sherochka's loyalty",
		"show_in_menu": true,
		"achievement": {
			"id": "shop_loyality",
			"name": "Sherochka lover",
			"desc": "up shop loyality to max",
			"goal": 100,
			"menu_icon": "res://image/achievements/menu_achiv/shop_loyality.png",
			"hud_popup": "res://image/achievements/hud_achiv/shop_loyality_hud.png",
		},
	},
	"armory_loyalty": {
		"desc": "Pepyaka's loyalty",
		"show_in_menu": true,
		"achievement": {
			"id": "armory_loyality",
			"name": "Pepyaka's friend",
			"desc": "up armory loyality to max",
			"goal": 100,
			"menu_icon": "",
			"hud_popup": "",
		},
	},
	"Mega_crit": {
		"desc": "Count of megacrits",
		"show_in_menu": false,
		"achievement": {
			"id": "Mega_crit",
			"name": "Mega Crit",
			"desc": "Roll five-x critical shot",
			"goal": 1,
			"menu_icon": "res://image/achievements/menu_achiv/mega_crit.png",
			"hud_popup": "res://image/achievements/hud_achiv/mega_crrit_hud.png",
		},
	},
	"bad_spear_kills": {
		"desc": "Kills by weak spear",
		"show_in_menu": false,
		"achievement": {
			"id": "bad_spear_kills",
			"name": "Spear!",
			"desc": "hit enemy by weak spear",
			"goal": 2,
			"menu_icon": "res://image/achievements/menu_achiv/Spear_unlock.png",
			"hud_popup": "res://image/achievements/hud_achiv/Spear_unlock_hud.png",
		},
	},
	"death_potions_picked": {
		"desc": "Death potions picked",
		"show_in_menu": false,
	},
}

## Достижения без привязки к счётчику 
##(разблокируются вручную через AchievementManager.unlock)
const STANDALONE_ACHIEVEMENTS := {
	"Alpha test": {
		"name": "Alpha test",
		"desc": "Survive until game released",
		"goal": 1,
		"menu_icon": "",
		"hud_popup": "",
	},
}

## Привязка item_id → stat при подборе предмета (Item.gd).
const ITEM_PICKUP_STATS := {
	"healblack": "death_potions_picked",
}

## Разблокировка предметов в пулах EquipManager при получении достижения.
## Ключ — id достижения из achievement.id выше.
const EQUIP_UNLOCKS := {
	"bad_spear_kills": [
		{"pool": "armory", "equipment_id": "EXSpear"},
		{"pool": "weapon", "equipment_id": "EXSpear"},
	],
}


func get_menu_stat_keys() -> Array[String]:
	var keys: Array[String] = []
	for key in STATS.keys():
		if STATS[key].get("show_in_menu", false):
			keys.append(key)
	return keys

func build_stat_to_achievements() -> Dictionary:
	var mapping := {}
	for stat_key in STATS.keys():
		var entry: Dictionary = STATS[stat_key]
		if not entry.has("achievement"):
			continue
		var ach_id: String = entry["achievement"]["id"]
		if not mapping.has(stat_key):
			mapping[stat_key] = []
		mapping[stat_key].append(ach_id)
	return mapping

func build_achievements_data() -> Dictionary:
	var result := {}
	for stat_key in STATS.keys():
		var entry: Dictionary = STATS[stat_key]
		if not entry.has("achievement"):
			continue
		var ach_def: Dictionary = entry["achievement"]
		var ach_id: String = ach_def["id"]
		result[ach_id] = _make_achievement_entry(ach_def)
	for ach_id in STANDALONE_ACHIEVEMENTS.keys():
		result[ach_id] = _make_achievement_entry(STANDALONE_ACHIEVEMENTS[ach_id])
	return result

func _make_achievement_entry(def: Dictionary) -> Dictionary:
	return {
		"name": def.get("name", ""),
		"desc": def.get("desc", ""),
		"progress": 0,
		"goal": def.get("goal", 1),
		"unlocked": false,
		"unlocked_icon": def.get("menu_icon", ""),
		"popup_window": def.get("hud_popup", ""),
	}


pass
''' 
 =============================================================================
 ИНСТРУКЦИЯ: как добавлять статы, достижения и разблокировки
 =============================================================================
 ВАЖНО: у каждой записи есть два разных «имени»:
   • id (ключ в словаре)       — технический идентификатор, его передаёшь в код
   • name (поле "name" внутри) — подпись для игрока в меню достижений

 -----------------------------------------------------------------------------
 1. Счётчик БЕЗ достижения (только статистика)
   a) Добавь в STATS:
        "my_stat": {
            "desc": "Подпись в меню",
            "show_in_menu": true,   # false — скрыть от игрока
        },
   b) В игровом коде:
        StatsManager.add_statistic_progress("my_stat", 1)
   c) Прочитать значение:
        StatsManager.get_stat_display("my_stat")["value"]

 -----------------------------------------------------------------------------
 2. Счётчик + достижение (авторазблокировка по порогу)
   a) Добавь в STATS блок achievement (id — ключ достижения в коде и сохранении):
        "my_stat": {
            "desc": "...",
            "show_in_menu": false,
            "achievement": {
                "id": "my_achievement",      # ← этот id используй в коде
                "name": "Красивое имя",      # ← это видит игрок
                "desc": "Условие",
                "goal": 10,
                "menu_icon": "res://...",
                "hud_popup": "res://...",    # пустая строка = без попапа в HUD
            },
        },
   b) В игровом коде только инкремент stat (достижение проверится само):
        StatsManager.add_statistic_progress("my_stat", 1)
   c) Проверить, разблокировано ли:
        AchievementManager.is_unlocked("my_achievement")

 -----------------------------------------------------------------------------
 3. Достижение БЕЗ счётчика (ручная разблокировка)
   a) Добавь в STANDALONE_ACHIEVEMENTS (ключ словаря = id достижения):
        "alpha_test": {
            "name": "Alpha test",
            "desc": "Survive until game released",
            "goal": 1,
            "menu_icon": "",
            "hud_popup": "",
        },
   b) Разблокировать вручную (stat_changed сюда НЕ подключён):
        AchievementManager.unlock_achievement("alpha_test")

 -----------------------------------------------------------------------------
 4. Подбор предмета → счётчик
   a) Добавь stat в STATS (см. п.1).
   b) Добавь в ITEM_PICKUP_STATS:
        "item_id_из_сцены": "my_stat",
   c) Item.gd сам вызовет add_statistic_progress при подборе.

 -----------------------------------------------------------------------------
 5. Достижение → предмет в пуле EquipManager
   a) Добавь в EQUIP_UNLOCKS (ключ = id достижения из achievement.id):
        "my_achievement": [
            {"pool": "weapon", "equipment_id": "EXSpear"},
        ],
   b) EquipManager.update_unlocks() вызывается сам при выборе лута.
   c) Проверка в своём коде:
        AchievementManager.is_unlocked("my_achievement")

 -----------------------------------------------------------------------------
 6. Временно отключить весь трекинг
        TRACKING_ENABLED = false   (в начале этого файла)

 -----------------------------------------------------------------------------
 8. Сброс сохранений для теста
   Статы:        user://stats.cfg
   Достижения:   user://achievements.cfg
   (удали файлы или сбрось через меню reset, если есть)

 =============================================================================
'''

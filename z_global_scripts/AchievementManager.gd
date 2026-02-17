extends Node

const SAVE_PATH = "user://achievements.cfg"

var achievements = {
	"first_kill": {"name": "First kill", "desc": "Kill 1 enemy",
	"progress": 0, "goal": 1, "unlocked": false,
	"unlocked_icon": "res://image/achievements/menu_achiv/first_enemy.png", "popup_window": "res://image/achievements/hud_achiv/first_enemy_hud.png"},
	
	"long_distance": {"name": "Far away...", "desc": "Runs of 10 km",
	"progress": 0, "goal": 10000, "unlocked": false,
	"unlocked_icon": "res://image/achievements/menu_achiv/long_distance.png", "popup_window": "res://image/achievements/hud_achiv/long_distance_hud.png"},
	
	"first_item": {"name": "Iron luck", "desc": "Put on the 1-st item",
	"progress": 0, "goal": 1, "unlocked": false,
	"unlocked_icon": "res://image/achievements/menu_achiv/first_item.png", "popup_window": "res://image/achievements/hud_achiv/first_item.png"},
	
	"shop_loyality": {"name": "Sherocka lover", "desc": "up shop loyality to max", 
	"progress": 0, "goal": 100, "unlocked": false,
	"unlocked_icon": "", "popup_window": ""},
	
	"name": {"name": "Alpha test", "desc": "Survive until game released", 
	"progress": 0, "goal": 1, "unlocked": false,
	"unlocked_icon": "", "popup_window": ""},
	
	}
	
var stat_to_achievements = {
	"kills": ["first_kill"],
	"distance_traveled": ["long_distance"],
	"items_equipped": ["first_item"],
	"sher_loyalty": ["shop_loyality"],
}

signal achievement_unlocked(data: String)

func _ready():
	load_achievements()
	StatsManager.stat_changed.connect(_on_stat_changed)

func _on_stat_changed(stat_name: String, new_value: float):
	if stat_to_achievements.has(stat_name):
		for ach_key in stat_to_achievements[stat_name]:
			check_achievement(ach_key, new_value)

func check_achievement(key: String, stat_value: float):
	var ach = achievements.get(key)
	if ach and not ach["unlocked"] and stat_value >= ach["goal"]:
		ach["unlocked"] = true
		var data = ach["popup_window"]
		achievement_unlocked.emit(data)
		save_achievements()

func load_achievements():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) != OK: return
	for key in achievements.keys():
		achievements[key]["unlocked"] = config.get_value("achievements", key + "_unlocked", false)

func save_achievements():
	var config = ConfigFile.new()
	for key in achievements.keys():
		config.set_value("achievements", key + "_unlocked", achievements[key]["unlocked"])
	config.save(SAVE_PATH)

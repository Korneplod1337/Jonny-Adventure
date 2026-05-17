extends Node

const SAVE_PATH = "user://stats.cfg"

var stats = {
	"kills": 			{"value": 0.0, "disc": "Kills"},
	"lifetime": 			{"value": 0.0, "disc": "Lifetime"},
	"distance_traveled":	{"value": 0.0, "disc": "Distance traveled"},
	"items_equipped": 	{"value": 0.0, "disc": "Items equipped"},
	"items_unlock": 		{"value": 0.0, "disc": "Items unlocked"},
	"visited_shops": 	{"value": 0.0, "disc": "Shops u entered"},
	"shop_loyalty": 		{"value": 0.0, "disc": "Sherochka's loyalty"},
	"armory_loyalty": 	{"value": 0.0, "disc": "Pepyaka's loyalty"},
	"Mega_crit": 		{"value": 0.0, "disc": "Count of megacrits"},
	"bad_spear_kills": 	{"value": 0.0, "disc": "Kills by weak spear"},
}
signal stat_changed(stat_name: String, new_value: float)

func _ready() -> void:
	load_statistic()

func load_statistic() -> void:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		for key in stats.keys():
			if config.has_section_key("stats", key):
				stats[key]["value"] = config.get_value("stats", key, 0)



func save_statistic() -> void:
	var config = ConfigFile.new()
	for key in stats.keys():
		config.set_value("stats", key, stats[key]["value"])
	config.save(SAVE_PATH)

func add_statistic_progress(key: String, value: float) -> void:
	return
	if stats.has(key):
		stats[key]["value"] += value
		stat_changed.emit(key, stats[key]["value"])
		save_statistic()

func get_stat_display(key: String) -> Dictionary:
	return stats.get(key, {})

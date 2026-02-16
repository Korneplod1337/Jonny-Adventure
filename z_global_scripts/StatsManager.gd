extends Node

const SAVE_PATH = "user://stats.cfg"

var stats = {
	"kills": {"value": 0.0, "disc": "Kills"},
	"lifetime": {"value": 0.0, "disc": "Lifetime"},
	"distance_traveled": {"value": 0.0, "disc": "Distance traveled"},
	"items_equipped": {"value": 0.0, "disc": "Items equipped"},
	"visited_shops": {"value": 0.0, "disc": "Shops u entered"}
}
signal stat_changed(stat_name: String, new_value: float)

func _ready():
	load_statistic()

func load_statistic():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		for key in stats.keys():
			if config.has_section_key("stats", key):
				stats[key]["value"] = config.get_value("stats", key, 0)


func save_statistic():
	var config = ConfigFile.new()
	for key in stats.keys():
		config.set_value("stats", key, stats[key]["value"])
	config.save(SAVE_PATH)

func add_statistic_progress(key: String, value: float):
	if stats.has(key):
		stats[key]["value"] += value
		stat_changed.emit(key, stats[key]["value"])
		save_statistic()

func get_stat_display(key: String) -> Dictionary:
	return stats.get(key, {})

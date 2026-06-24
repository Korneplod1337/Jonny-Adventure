extends Button

const SETTINGS_PATH := "user://settings.cfg"

const FILES_TO_WIPE := [
	"user://stats.cfg",
	"user://achievements.cfg",
	"user://items.cfg",
	"user://equip.cfg",
	"user://character_medals.cfg"
]


func _on_pressed() -> void:
	for path in FILES_TO_WIPE:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

	_set_first_time(true)
	get_tree().quit()


func _set_first_time(value: bool) -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("settings", "first", value)
	config.set_value("settings", "easy_unlocked", false)
	config.save(SETTINGS_PATH)

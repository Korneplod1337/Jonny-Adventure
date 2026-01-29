extends Button


func _on_pressed() -> void:
	for path in FILES_TO_WIPE:
		if FileAccess.file_exists(path):
			var err = DirAccess.remove_absolute(path)
	
	get_tree().quit()


const FILES_TO_WIPE := [
	"user://stats.cfg",
	"user://achievements.cfg"
]

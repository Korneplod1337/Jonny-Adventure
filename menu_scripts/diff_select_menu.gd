extends CanvasLayer

const SETTINGS_PATH := "user://settings.cfg"


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_update_easy_button()


func _on_visibility_changed() -> void:
	if visible:
		_update_easy_button()


func _update_easy_button() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	var unlocked: bool = config.get_value("settings", "easy_unlocked", false)
	$easy.disabled = not unlocked
	$easy.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.5, 0.5, 0.5, 0.7)


func _on_exit_pressed() -> void:
	self.hide()
	get_parent().get_node('Char_select_menu').show()


func _on_exit_mouse_entered() -> void:
	$exit/exit_select.show()
func _on_exit_mouse_exited() -> void:
	$exit/exit_select.hide()
	

func _on_easy_pressed() -> void:
	if $easy.disabled:
		return
	DungeonManager.difficulty = 'easy'
	get_tree().change_scene_to_file("res://game/dungeon.tscn")
func _on_med_pressed() -> void:
	DungeonManager.difficulty = 'med'
	get_tree().change_scene_to_file("res://game/dungeon.tscn")
func _on_hard_pressed() -> void:
	DungeonManager.difficulty = 'hard'
	get_tree().change_scene_to_file("res://game/dungeon.tscn")

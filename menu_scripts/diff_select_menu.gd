extends CanvasLayer


func _on_exit_pressed() -> void:
	self.hide()
	get_parent().get_node('Char_select_menu').show()


func _on_exit_mouse_entered() -> void:
	$exit/exit_select.show()
func _on_exit_mouse_exited() -> void:
	$exit/exit_select.hide()
	

func _on_easy_pressed() -> void:
	DungeonManager.difficulty = 'easy'
	get_tree().change_scene_to_file("res://game/dungeon.tscn")
func _on_med_pressed() -> void:
	DungeonManager.difficulty = 'med'
	get_tree().change_scene_to_file("res://game/dungeon.tscn")
func _on_hard_pressed() -> void:
	DungeonManager.difficulty = 'hard'
	get_tree().change_scene_to_file("res://game/dungeon.tscn")

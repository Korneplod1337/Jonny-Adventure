extends CanvasLayer

func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)

func _on_visibility_changed() -> void:
	if visible:
		$GridContainer.update_stats_list()


func _on_exit_button_pressed() -> void:
	self.hide()
	get_parent().get_node('start_menu').show()

func _on_exit_button_mouse_entered() -> void:
	$exit_button/exit_button_sprite.show()
func _on_exit_button_mouse_exited() -> void:
	$exit_button/exit_button_sprite.hide()

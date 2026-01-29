extends CanvasLayer

func _ready() -> void:
	pass # Replace with function body.


func _on_jonny_ch_mouse_entered() -> void:
	$Jonny_ch/jonny_select.show()
func _on_jonny_ch_mouse_exited() -> void:
	$Jonny_ch/jonny_select.hide()

func _on_jonnytta_ch_mouse_entered() -> void:
	$Jonnytta_ch/jonnytta_select.show()
func _on_jonnytta_ch_mouse_exited() -> void:
	$Jonnytta_ch/jonnytta_select.hide()


func _on_exit_pressed() -> void:
	self.hide()
	get_parent().get_node('start_menu').show()

func _on_exit_mouse_entered() -> void:
	$exit/exit_select.show()
func _on_exit_mouse_exited() -> void:
	$exit/exit_select.hide()



func _on_jonny_ch_pressed() -> void:
	get_parent().get_node('Diff_select_menu').show()
	self.hide()
	DungeonManager.selected_character = 'Jonny'

func _on_jonnytta_ch_pressed() -> void:
	get_parent().get_node('Diff_select_menu').show()
	self.hide()
	DungeonManager.selected_character = 'Jonnytta'

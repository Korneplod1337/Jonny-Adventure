extends Control

func _ready() -> void:
	get_parent().get_parent().get_node("Main_menu_music").play()
	get_parent().get_parent().get_node('settings_menu/Settings_layer/Settings_Control/Button_sound').update_audio()


func _on_button_new_game_mouse_entered() -> void:
	$Button_NewGame/Select_NewGame.show()
func _on_button_new_game_mouse_exited() -> void:
	$Button_NewGame/Select_NewGame.hide()


func _on_button_settings_mouse_entered() -> void:
	$Button_Settings/Select_Settings.show()
func _on_button_settings_mouse_exited() -> void:
	$Button_Settings/Select_Settings.hide()


func _on_button_quit_mouse_entered() -> void:
	$Button_Quit/Select_Quit.show()
func _on_button_quit_mouse_exited() -> void:
	$Button_Quit/Select_Quit.hide()


func _on_button_achivement_mouse_entered() -> void:
	$Button_achivement/Select_achivement.show()
func _on_button_achivement_mouse_exited() -> void:
	$Button_achivement/Select_achivement.hide()


func _on_button_quit_pressed() -> void:
	get_tree().quit()

func _on_button_settings_pressed() -> void:
	get_parent().get_parent().get_node('settings_menu/Settings_layer').show()
	get_parent().get_parent().get_node('start_menu').hide()


func _on_button_achivement_pressed() -> void:
	get_parent().get_parent().get_node('start_menu').hide()
	get_parent().get_parent().get_node('Achivements_menu').show()


func _on_button_stats_pressed() -> void:
	get_parent().get_parent().get_node('start_menu').hide()
	get_parent().get_parent().get_node('stats_menu').show()
	
	
func _on_button_stats_mouse_entered() -> void:
	$Button_stats/Select_stats.show()
func _on_button_stats_mouse_exited() -> void:
	$Button_stats/Select_stats.hide()


func _on_button_new_game_pressed() -> void:
	get_parent().get_parent().get_node('start_menu').hide()
	get_parent().get_parent().get_node('Char_select_menu').show()

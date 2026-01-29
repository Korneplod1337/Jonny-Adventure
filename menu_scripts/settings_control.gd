extends Control
var config = ConfigFile.new()
var video_conf: Array = [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1920, 1080)]

func _ready() -> void:
	config.load("user://settings.cfg")

func _process(_delta: float) -> void:
	if Input.is_action_pressed('Escape'):
		_on_button_back_pressed()


func _on_button_video_pressed() -> void:
	$Button_sound/Sound_bar.hide()
	$Button_sound/VScrollBar.hide()
	$Button_video/Button_low.show()
	$Button_video/Button_medium.show()
	$Button_video/Button_high.show()
	
	
func _on_button_sound_pressed() -> void:
	$Button_video/Button_low.hide()
	$Button_video/Button_medium.hide()
	$Button_video/Button_high.hide()
	$Button_sound/Sound_bar.show()
	$Button_sound/VScrollBar.show()
	

func _on_button_back_pressed() -> void:
	get_parent().get_parent().get_node('Settings_layer').hide()
	get_parent().get_parent().get_parent().get_node('start_menu').show()


func _on_button_back_mouse_entered() -> void:
	$Button_back/Select_Button_back.show()


func _on_button_back_mouse_exited() -> void:
	$Button_back/Select_Button_back.hide()


func _on_button_low_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(video_conf[0])
	config.set_value('settings', 'video', 0)
	config.save("user://settings.cfg")

func _on_button_medium_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(video_conf[1])
	config.set_value('settings', 'video', 1)
	config.save("user://settings.cfg")

func _on_button_high_pressed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	DisplayServer.window_set_size(video_conf[2])
	config.set_value('settings', 'video', 2)
	config.save("user://settings.cfg")

func _on_button_low_mouse_entered() -> void:
	$Button_video/Button_low/Select_Button_low.show()
func _on_button_low_mouse_exited() -> void:
	$Button_video/Button_low/Select_Button_low.hide()


func _on_button_medium_mouse_entered() -> void:
	$Button_video/Button_medium/Select_Button_med.show()
func _on_button_medium_mouse_exited() -> void:
	$Button_video/Button_medium/Select_Button_med.hide()


func _on_button_high_mouse_entered() -> void:
	$Button_video/Button_high/Select_Button_high.show()
func _on_button_high_mouse_exited() -> void:
	$Button_video/Button_high/Select_Button_high.hide()

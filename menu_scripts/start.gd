extends Node2D
var video_conf: Array = [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1920, 1080)]

func _ready() -> void:
	var config = ConfigFile.new()
	config.load("user://settings.cfg")
	var volume: float = config.get_value("settings", "volume", 0.4)  # Загружаем громкость
	var video: int = config.get_value("settings", "video", 1)
	set_global_volume_and_video(volume, video)


func set_global_volume_and_video(value: float, value2: int):  # value от 0 до 10
	var db_volume = lerp(-40, 0, value / 10.0)  # Преобразуем диапазон
	if db_volume == -40:
		db_volume = -80
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db_volume)
	DisplayServer.window_set_size(video_conf[value2])
	if value2 == 2:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)



func _process(_delta: float) -> void:
	if Input.is_action_pressed('space'):
		_on_timer_timeout()

func _on_timer_timeout() -> void:
	get_tree().change_scene_to_file("res://menu_scripts/main_menu.tscn")

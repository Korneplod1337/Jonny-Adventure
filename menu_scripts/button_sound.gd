extends Button

var config = ConfigFile.new()

func _ready() -> void:
	config.load("user://settings.cfg")
	
	$VScrollBar.set_value_no_signal(config.get_value("settings", "volume", 0.4))
	
	update_audio()
	_on_value_changed($VScrollBar.get_value())


func _on_value_changed(value: float) -> void:  # Если трогают ползунок звука
	$Sound_bar.set_frame_and_progress(value, 0.0)
	set_global_volume(value)
	
	config.set_value("settings", "volume", $VScrollBar.get_value())
	config.save("user://settings.cfg")


func set_global_volume(value: float):  # value от 0 до 10     Ставит уровень громкости
	var db_volume = lerp(-40, 0, value / 10.0)  # Преобразуем диапазон
	if db_volume == -40: 
		db_volume = -80  
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db_volume) 


func update_audio() ->void:
	set_global_volume($VScrollBar.get_value())
	pass

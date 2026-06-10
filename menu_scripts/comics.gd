extends Node2D

const SETTINGS_PATH := "user://settings.cfg"
const MAIN_MENU_PATH := "res://menu_scripts/main_menu.tscn"

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _current_frame := 0
var _frame_count := 0


func _ready() -> void:
	_sprite.animation = "default"
	_sprite.stop()
	_frame_count = _sprite.sprite_frames.get_frame_count("default")
	_sprite.frame = 0


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance_frame()


func _advance_frame() -> void:
	_current_frame += 1
	if _current_frame >= _frame_count:
		_finish_comics()
	else:
		_sprite.frame = _current_frame


func _finish_comics() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value("settings", "first", false)
	config.save(SETTINGS_PATH)
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

extends Node2D

@onready var _interactable: Area2D = $Interactable
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_interactable.interact = _on_interact
	hide_hatch()


func hide_hatch() -> void:
	visible = false
	_interactable.is_interactable = false
	_set_area_active_deferred(false)
	_set_closed_frame()


func show_hatch() -> void:
	visible = true
	_set_closed_frame()
	_interactable.is_interactable = true
	_set_area_active_deferred(true)


func open_hatch() -> void:
	if _sprite:
		_sprite.stop()
		_sprite.frame = 1


func _set_closed_frame() -> void:
	if _sprite:
		_sprite.stop()
		_sprite.frame = 0


func _set_area_active_deferred(active: bool) -> void:
	_interactable.set_deferred("monitoring", active)
	_interactable.set_deferred("monitorable", active)


func _on_interact() -> void:
	var dungeon := get_tree().current_scene
	if dungeon == null or not dungeon.has_method("go_to_next_floor"):
		return
	_interactable.is_interactable = false
	open_hatch()
	await dungeon.go_to_next_floor(self)

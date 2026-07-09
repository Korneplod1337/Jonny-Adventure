extends Node2D

@onready var _interactable: Area2D = $Interactable
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _area_active := false
var _area_apply_queued := false


func _ready() -> void:
	_interactable.interact = _on_interact
	hide_hatch()


func hide_hatch() -> void:
	visible = false
	_interactable.is_interactable = false
	_set_area_active(false)
	_set_closed_frame()


func show_hatch() -> void:
	visible = true
	_set_closed_frame()
	_interactable.is_interactable = true
	_set_area_active(true)


func open_hatch() -> void:
	if _sprite:
		_sprite.stop()
		_sprite.frame = 1


func _set_closed_frame() -> void:
	if _sprite:
		_sprite.stop()
		_sprite.frame = 0


func _set_area_active(active: bool) -> void:
	_area_active = active
	if not _area_apply_queued:
		_area_apply_queued = true
		call_deferred("_apply_area_active")


func _apply_area_active() -> void:
	_area_apply_queued = false
	if not is_instance_valid(_interactable):
		return
	_interactable.monitoring = _area_active
	_interactable.monitorable = _area_active
	if _area_active:
		_queue_refresh_player_interaction()


func _queue_refresh_player_interaction() -> void:
	if not _area_active or not visible:
		return
	call_deferred("_refresh_player_interaction")


func _refresh_player_interaction() -> void:
	if not _area_active or not visible or not is_instance_valid(_interactable):
		return

	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	var ic := player.get_node_or_null("InteractingComponents")
	if ic == null:
		return

	var interact_range: Area2D = ic.get_node_or_null("InteractRange")
	if interact_range == null:
		return

	if interact_range.overlaps_area(_interactable):
		ic._on_interact_range_area_entered(_interactable)


func _on_interact() -> void:
	var dungeon := get_tree().current_scene
	if dungeon == null or not dungeon.has_method("go_to_next_floor"):
		return
	_interactable.is_interactable = false
	open_hatch()
	await dungeon.go_to_next_floor(self)

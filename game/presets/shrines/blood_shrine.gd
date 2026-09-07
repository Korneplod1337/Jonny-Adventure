extends Node2D

const CHEST_SMALL := preload("res://game/objects/chests/Chest_small.tscn")
const CHEST_BIG := preload("res://game/objects/chests/Chest_big.tscn")
const CHEST_TREASURE := preload("res://game/objects/chests/Chest_treasure.tscn")

@onready var interactable: Area2D = $Interactable
@onready var knife: Node2D = $knife
@onready var marker_chest: Marker2D = $MarkerChest

var _activated := false


func _ready() -> void:
	interactable.interact = _on_interact


func _process(_delta: float) -> void:
	if _activated or not is_instance_valid(knife):
		return
	knife.set_player_near(_is_player_in_interact_range())


func _is_player_in_interact_range() -> bool:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return false
	var comps := player.get_node_or_null("InteractingComponents")
	if comps == null:
		return false
	return interactable in comps.current_interactions


func _on_interact() -> void:
	if _activated or not interactable.is_interactable:
		return
	if not is_instance_valid(knife):
		return

	_activated = true
	interactable.is_interactable = false
	SoundManager.play_shine()
	knife.launch()


func on_sacrifice_complete() -> void:
	_spawn_chest()


func _spawn_chest() -> void:
	var parent := get_parent()
	if parent == null:
		return

	var chest := _pick_chest_scene().instantiate()
	chest.position = parent.to_local(marker_chest.global_position)
	parent.call_deferred("add_child", chest)


func _pick_chest_scene() -> PackedScene:
	var roll := randf()
	if roll < 0.25:
		return CHEST_SMALL
	if roll < 0.50:
		return CHEST_TREASURE
	return CHEST_BIG

extends Node2D

const BLOOD_SHRINE_SCENE := preload("res://game/presets/shrines/bloodShrine.tscn")
const OBLATION_SHRINE_SCENE := preload("res://game/presets/shrines/OblationShrine.tscn")
const BLOOD_SHRINE_CHANCE := 0.12
const OBLATION_SHRINE_CHANCE := 0.08

@onready var interactable: Area2D = $Interactable
@onready var Shrn_animation: AnimatedSprite2D = $AnimatedSprite2D
enum ShrineType {
	hp, move_speed, luck, magic,
	damage, spread, range, fire_rate
}

@export var shrine_type: int = -1
@export var flip := false
var selected_type: ShrineType
var _finalized := false

func _ready() -> void:
	Shrn_animation.flip_h = flip
	interactable.interact = _on_interact
	if GameState.has_level_buf("Destroyed"):
		_make_destroyed()
		_finalized = true
		return
	# Тип выбирает RoomScript_enemy._process_shrines() через finalize_spawn().
	# Нельзя await/process_frame-fallback: после queue_free это даёт
	# "Lambda capture at index 0 was freed".
	visible = false
	interactable.is_interactable = false


func finalize_spawn() -> void:
	if _finalized or not is_inside_tree() or is_queued_for_deletion():
		return
	_finalized = true

	if shrine_type == -1:
		var roll := randf()
		if roll < BLOOD_SHRINE_CHANCE:
			_replace_with_scene(BLOOD_SHRINE_SCENE, "blood")
			return
		if roll < BLOOD_SHRINE_CHANCE + OBLATION_SHRINE_CHANCE:
			_replace_with_scene(OBLATION_SHRINE_SCENE, "oblation")
			return

	_setup_normal_shrine()


func _setup_normal_shrine() -> void:
	visible = true
	interactable.is_interactable = true
	if shrine_type == -1:
		selected_type = ShrineType.values()[randi() % ShrineType.size()]
	else:
		selected_type = ShrineType.values()[shrine_type]
	Shrn_animation.animation = ShrineType.keys()[selected_type]
	Shrn_animation.frame = 0
	print("Шрайн: ", ShrineType.keys()[selected_type])


func _make_destroyed() -> void:
	visible = true
	interactable.is_interactable = false
	Shrn_animation.animation = "broken"
	Shrn_animation.frame = 0
	print("Шрайн: broken")


func _replace_with_scene(scene: PackedScene, label: String) -> void:
	var parent := get_parent()
	if parent == null:
		queue_free()
		return
	var replacement := scene.instantiate()
	replacement.position = position
	parent.add_child(replacement)
	parent.move_child(replacement, get_index())
	visible = false
	interactable.is_interactable = false
	# deferred: не рвём текущий call stack init_room
	call_deferred("queue_free")
	print("Шрайн: ", label)


func _on_interact():
	var player = get_tree().get_first_node_in_group("player")
	if GameState.coins > 0 and interactable.is_interactable:
		SoundManager.play_shine()
		Shrn_animation.animation = ShrineType.keys()[selected_type] + '_active'
		Shrn_animation.play()
		interactable.is_interactable = false
		GameState.add_coins(-1)
		var stat_name: String
		match selected_type:
			ShrineType.hp:          stat_name = "hp"
			ShrineType.move_speed:  stat_name = "move_speed"
			ShrineType.luck:        stat_name = "luck"
			ShrineType.magic:       stat_name = "magic"
			ShrineType.damage:      stat_name = "damage"
			ShrineType.spread:      stat_name = "spread"
			ShrineType.range:       stat_name = "range"
			ShrineType.fire_rate:   stat_name = "fire_rate"
		
		StatManager.upgrade_stat(player, stat_name, 1)

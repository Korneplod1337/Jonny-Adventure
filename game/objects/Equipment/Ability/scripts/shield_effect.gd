extends Node2D

@export var duration: float = 0.6

@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _timer: Timer = $Timer

var _finished: bool = false


func _ready() -> void:
	position = Vector2.ZERO
	var has_anim := _anim.sprite_frames != null and not _anim.sprite_frames.get_animation_names().is_empty()

	if has_anim:
		var anim_name: StringName = _anim.sprite_frames.get_animation_names()[0]
		duration = _compute_anim_duration(anim_name)
		_anim.animation_finished.connect(_on_animation_finished)
		_anim.play(anim_name)
	else:
		_anim.visible = false
		_timer.wait_time = duration
		_timer.one_shot = true
		_timer.timeout.connect(_on_timeout)
		_timer.start()

	var player := get_parent()
	if player and player.has_method("begin_ability_shield"):
		player.begin_ability_shield(duration)


func _compute_anim_duration(anim_name: StringName) -> float:
	var total := 0.0
	var frame_count := _anim.sprite_frames.get_frame_count(anim_name)
	for i in frame_count:
		total += _anim.sprite_frames.get_frame_duration(anim_name, i)
	var speed := _anim.sprite_frames.get_animation_speed(anim_name)
	if speed <= 0.0:
		return duration
	return total / speed


func _on_timeout() -> void:
	_finish_shield()
	queue_free()


func _on_animation_finished() -> void:
	_finish_shield()
	queue_free()


func _exit_tree() -> void:
	_finish_shield()


func _finish_shield() -> void:
	if _finished:
		return
	_finished = true
	var player := get_parent()
	if player and player.has_method("end_ability_shield"):
		player.end_ability_shield()

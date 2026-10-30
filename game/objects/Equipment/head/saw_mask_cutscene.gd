extends Node

const MASK_2 := preload("res://image/equip/head/Saw_mask2.png")
const MASK_3 := preload("res://image/equip/head/Saw_mask3.png")
const MASK_4 := preload("res://image/equip/head/Saw_mask4.png")

const ZOOM_MULT := 2.0
const ZOOM_SEC := 2.0
const FOCUS_OFFSET := Vector2(0, -10)
const SHAKE_SEC := 3.0
const MASK3_AT := 1.0
const RETURN_SEC := 0.5
const SHAKE_MAX_PX := 6.0

var _player: CharacterBody2D
var _cam: Camera2D
var _mask: Sprite2D
var _orig_zoom: Vector2
var _orig_offset: Vector2
var _orig_position: Vector2
var _orig_limit_smoothed: bool
var _cam_hijacked := false


func run(player: CharacterBody2D) -> void:
	_player = player
	name = "SawMaskCutscene"
	_player.add_child(self)
	await _play()
	queue_free()


func _play() -> void:
	if _player == null or not is_instance_valid(_player):
		return

	_player.set_movement_locked(true)
	_player.attack_locked = true
	_player.velocity = Vector2.ZERO
	_player.last_move_dir = 1
	if _player.has_method("play_body"):
		_player.play_body("afk_default")
	if _player.has_method("play_head"):
		_player.play_head("down")
	# Head / AnimatedShot остаются видимыми до конца кат-сцены

	_mask = Sprite2D.new()
	_mask.name = "SawMaskOverlay"
	_mask.texture = MASK_2
	_mask.centered = true
	_mask.position = Vector2(0, -34)
	_mask.z_index = 5
	_player.add_child(_mask)

	_cam = _player.get_node_or_null("Camera2D") as Camera2D
	if _cam:
		_orig_zoom = _cam.zoom
		_orig_offset = _cam.offset
		_orig_position = _cam.position
		_orig_limit_smoothed = _cam.limit_smoothed
		var target_zoom := _orig_zoom * ZOOM_MULT
		var start_center := _cam.get_screen_center_position()
		var focus_center := _player.global_position + FOCUS_OFFSET
		_cam.limit_smoothed = false
		_cam.top_level = true
		_cam.global_position = start_center
		_cam.offset = Vector2.ZERO
		_cam_hijacked = true
		await _tween_camera_look(start_center, focus_center, _orig_zoom, target_zoom, ZOOM_SEC)

	# Зум и 1-я секунда тряски: кадр 2; через 1с тряски → кадр 3
	await _shake_phase()

	# Конец тряски: кадр 4
	if is_instance_valid(_mask):
		_mask.texture = MASK_4
	SoundManager.play_crack()

	if _cam_hijacked and is_instance_valid(_cam) and is_instance_valid(_player):
		var return_center := _player.global_position + _orig_offset
		await _tween_camera_look(_cam.global_position, return_center, _cam.zoom, _orig_zoom, RETURN_SEC)
		_restore_camera()

	if is_instance_valid(_mask):
		_mask.queue_free()
		_mask = null

	if is_instance_valid(_player):
		_player.apply_saw_mask_behead_visuals()
		_player.attack_locked = false
		_player.set_movement_locked(false)


func _shake_phase() -> void:
	var elapsed := 0.0
	var switched_to_3 := false
	while elapsed < SHAKE_SEC:
		if not is_instance_valid(_player):
			return
		var delta := get_process_delta_time()
		elapsed += delta
		if not switched_to_3 and elapsed >= MASK3_AT:
			switched_to_3 = true
			if is_instance_valid(_mask):
				_mask.texture = MASK_3
		var t := clampf(elapsed / SHAKE_SEC, 0.0, 1.0)
		var amp := lerpf(0.5, SHAKE_MAX_PX, t * t)
		if _cam_hijacked and is_instance_valid(_cam):
			_cam.offset = Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
		await get_tree().process_frame
	if _cam_hijacked and is_instance_valid(_cam):
		_cam.offset = Vector2.ZERO




func _tween_camera_look(
	from_center: Vector2,
	to_center: Vector2,
	from_zoom: Vector2,
	to_zoom: Vector2,
	duration: float
) -> void:
	if not is_instance_valid(_cam):
		return
	var tween := create_tween()
	var step := func(t: float) -> void:
		if not is_instance_valid(_cam):
			return
		_cam.zoom = from_zoom.lerp(to_zoom, t)
		_cam.global_position = from_center.lerp(to_center, t)
	tween.tween_method(step, 0.0, 1.0, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _restore_camera() -> void:
	if not is_instance_valid(_cam):
		return
	_cam.top_level = false
	_cam.position = _orig_position
	_cam.offset = _orig_offset
	_cam.zoom = _orig_zoom
	_cam.limit_smoothed = _orig_limit_smoothed
	_cam_hijacked = false


func _exit_tree() -> void:
	if _cam_hijacked:
		_restore_camera()

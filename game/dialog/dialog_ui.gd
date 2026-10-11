extends CanvasLayer

const CHARS_PER_SEC := 20.0
const CHARS_PER_SEC_FAST := 80.0
const CAMERA_DURATION := 1.0
const CAMERA_ZOOM_MULT := 1.2
const VIGNETTE_ALPHA := 0.50
const CHOICE_FONT := preload("res://Fonts/JonnyAdventureFont2.ttf")
const CHOICE_FONT_SIZE := 32

@onready var vignette: ColorRect = $Vignette
@onready var panel: PanelContainer = $Panel
@onready var speaker_label: Label = $Panel/Margin/VBox/Speaker
@onready var text_label: RichTextLabel = $Panel/Margin/VBox/DialogText
@onready var choices_box: VBoxContainer = $Panel/Margin/VBox/Choices

var _trader_id: String = ""
var _dialog_id: String = ""
var _event_id: String = ""
var _focus_node: Node2D = null
var _nodes: Dictionary = {}
var _current_node_id: String = ""

var _chars_per_sec: float = CHARS_PER_SEC
var _full_char_count: int = 0
var _visible_chars: float = 0.0
var _typing: bool = false
var _closing: bool = false
var _intro_done: bool = false

var _player: Node2D = null
var _hud: Node = null
var _cam: Camera2D = null
var _orig_zoom: Vector2 = Vector2.ONE
var _orig_offset: Vector2 = Vector2.ZERO
var _orig_position: Vector2 = Vector2.ZERO
var _orig_limit_smoothed: bool = true
var _cam_hijacked: bool = false

const TRADER_NAMES := {
	"sherochka": "Sherochka",
	"pepyaka": "Pepyaka",
	"erik": "Erik",
}


func begin(trader_id: String, dialog_id: String, event_id: String, focus_node: Node2D) -> void:
	_trader_id = trader_id
	_dialog_id = dialog_id
	_event_id = event_id
	_focus_node = focus_node
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	var dialog: Dictionary = DialogDB.get_dialog(dialog_id)
	_nodes = dialog.get("nodes", {})
	_current_node_id = str(dialog.get("start", ""))

	speaker_label.text = TRADER_NAMES.get(trader_id, trader_id.capitalize())
	text_label.text = ""
	text_label.visible_characters = 0
	_clear_choices()
	vignette.modulate.a = 0.0
	panel.visible = false

	_player = get_tree().get_first_node_in_group("player") as Node2D
	var dungeon = get_tree().current_scene
	_hud = dungeon.hud_instance if dungeon and ("hud_instance" in dungeon) else null

	if _player and _player.has_method("set_movement_locked"):
		_player.set_movement_locked(true)
	if _hud and _hud.has_method("set_ui_locked"):
		_hud.set_ui_locked(true)

	await _play_intro()
	_intro_done = true
	panel.visible = true
	_show_node(_current_node_id)


func _process(delta: float) -> void:
	if _closing or not _intro_done:
		return
	if _typing:
		_visible_chars += _chars_per_sec * delta
		var shown := mini(int(_visible_chars), _full_char_count)
		text_label.visible_characters = shown
		if shown >= _full_char_count:
			_finish_typing()


func _input(event: InputEvent) -> void:
	if _closing or not _intro_done or not _typing:
		return
	## Клик в любое место — ускорить печать до 60 на всё это окно.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_chars_per_sec = CHARS_PER_SEC_FAST
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _closing or not _intro_done:
		return
	if event.is_action_pressed("button_E") and _typing:
		_finish_typing()
		get_viewport().set_input_as_handled()


func _show_node(node_id: String) -> void:
	if node_id.is_empty() or not _nodes.has(node_id):
		_close_dialog()
		return
	_current_node_id = node_id
	var node: Dictionary = _nodes[node_id]
	var enter_actions: Array = node.get("enter_actions", [])
	if not enter_actions.is_empty():
		DialogDB.apply_actions(enter_actions, _focus_node)
	var raw_text := str(node.get("text", ""))
	text_label.text = DialogDB.format_dialog_text(raw_text)
	_full_char_count = text_label.get_total_character_count()
	_visible_chars = 0.0
	_typing = true
	text_label.visible_characters = 0
	_clear_choices()


func _finish_typing() -> void:
	_typing = false
	_visible_chars = float(_full_char_count)
	text_label.visible_characters = -1
	_build_choices()


func _style_choice_button(btn: Button) -> void:
	btn.add_theme_font_override("font", CHOICE_FONT)
	btn.add_theme_font_size_override("font_size", CHOICE_FONT_SIZE)


func _build_choices() -> void:
	_clear_choices()
	var node: Dictionary = _nodes.get(_current_node_id, {})
	var choices: Array = node.get("choices", [])
	if choices.is_empty():
		var leave := Button.new()
		leave.text = "Leave"
		_style_choice_button(leave)
		leave.pressed.connect(func(): _on_choice({"text": "Leave", "next": "", "actions": [{"type": "end"}]}))
		choices_box.add_child(leave)
		return
	for choice in choices:
		if typeof(choice) != TYPE_DICTIONARY:
			continue
		var btn := Button.new()
		btn.text = str(choice.get("text", "..."))
		_style_choice_button(btn)
		var captured: Dictionary = choice
		btn.pressed.connect(func(): _on_choice(captured))
		choices_box.add_child(btn)


func _clear_choices() -> void:
	for child in choices_box.get_children():
		child.queue_free()


func _on_choice(choice: Dictionary) -> void:
	if _closing or _typing:
		return
	var requirements: Array = choice.get("require", [])
	if not DialogDB.check_requirements(requirements):
		## Условие не выполнено — выходим без действий / complete_event.
		_close_dialog()
		return
	var actions: Array = choice.get("actions", [])
	var should_end: bool = DialogDB.apply_actions(actions, _focus_node)
	var next_id: String = str(choice.get("next", ""))
	if should_end or next_id.is_empty():
		_close_dialog()
		return
	_show_node(next_id)


func _play_intro() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(vignette, "modulate:a", VIGNETTE_ALPHA, CAMERA_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if _player == null:
		await tween.finished
		return

	_cam = _player.get_node_or_null("Camera2D") as Camera2D
	if _cam == null or _focus_node == null or not is_instance_valid(_focus_node):
		await tween.finished
		return

	_orig_zoom = _cam.zoom
	_orig_offset = _cam.offset
	_orig_position = _cam.position
	_orig_limit_smoothed = _cam.limit_smoothed
	var target_zoom := _orig_zoom * CAMERA_ZOOM_MULT
	var start_center := _cam.get_screen_center_position()
	var focus_center := _clamp_camera_center(_cam, _focus_node.global_position, target_zoom)

	_cam.limit_smoothed = false
	_cam.top_level = true
	_cam.global_position = start_center
	_cam.offset = Vector2.ZERO
	_cam_hijacked = true

	await _tween_camera_look(_cam, start_center, focus_center, _orig_zoom, target_zoom, CAMERA_DURATION)


func _close_dialog() -> void:
	if _closing:
		return
	_closing = true
	_clear_choices()
	panel.visible = false

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(vignette, "modulate:a", 0.0, CAMERA_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	if _cam_hijacked and is_instance_valid(_cam) and is_instance_valid(_player):
		var return_center := _clamp_camera_center(_cam, _player.global_position + _orig_offset, _orig_zoom)
		await _tween_camera_look(_cam, _cam.global_position, return_center, _cam.zoom, _orig_zoom, CAMERA_DURATION)
		_cam.top_level = false
		_cam.position = _orig_position
		_cam.offset = _orig_offset
		_cam.zoom = _orig_zoom
		_cam.limit_smoothed = _orig_limit_smoothed
		_cam_hijacked = false
	else:
		await tween.finished

	if _player and is_instance_valid(_player) and _player.has_method("set_movement_locked"):
		_player.set_movement_locked(false)
	if _hud and is_instance_valid(_hud) and _hud.has_method("set_ui_locked"):
		_hud.set_ui_locked(false)

	DialogDB.is_dialog_open = false
	DialogDB.evaluate_triggers()
	queue_free()


func _tween_camera_look(cam: Camera2D, from_center: Vector2, to_center: Vector2, from_zoom: Vector2, to_zoom: Vector2, duration: float) -> void:
	var tween := create_tween()
	var step := func(t: float) -> void:
		if not is_instance_valid(cam):
			return
		var z: Vector2 = from_zoom.lerp(to_zoom, t)
		var desired: Vector2 = from_center.lerp(to_center, t)
		cam.zoom = z
		cam.global_position = _clamp_camera_center(cam, desired, z)
	tween.tween_method(step, 0.0, 1.0, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished


func _clamp_camera_center(cam: Camera2D, desired: Vector2, zoom: Vector2) -> Vector2:
	var screen := cam.get_viewport_rect().size
	var half := Vector2(screen.x / zoom.x, screen.y / zoom.y) * 0.5
	var min_x := float(cam.limit_left) + half.x
	var max_x := float(cam.limit_right) - half.x
	var min_y := float(cam.limit_top) + half.y
	var max_y := float(cam.limit_bottom) - half.y
	if min_x > max_x:
		desired.x = (min_x + max_x) * 0.5
	else:
		desired.x = clampf(desired.x, min_x, max_x)
	if min_y > max_y:
		desired.y = (min_y + max_y) * 0.5
	else:
		desired.y = clampf(desired.y, min_y, max_y)
	return desired

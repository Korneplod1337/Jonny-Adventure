@tool
extends Control
class_name BossHpBar

## HP-бар босса. Только _draw — без дочерних TextureRect (они ломались в редакторе).

const DEFAULT_FILL := Color(0.78, 0.32, 0.36, 0.95)
const DEFAULT_TRAIL := Color(1.0, 0.72, 0.72, 0.85)
const DEFAULT_BG := Color(0.12, 0.1, 0.1, 0.65)
const DEFAULT_BORDER := Color(0.05, 0.04, 0.04, 0.9)
const TRAIL_LERP_SPEED := 2.2

@export var style: BossHpBarStyle:
	set(value):
		_unwatch_style()
		style = value
		_watch_style()
		_bump_size()
		queue_redraw()

@export_range(0.0, 1.0, 0.01) var preview_ratio: float = 1.0:
	set(value):
		preview_ratio = clampf(value, 0.0, 1.0)
		if Engine.is_editor_hint():
			_trail_ratio = preview_ratio
			queue_redraw()

var boss: Node = null
var _trail_ratio := 1.0
var _bar_height := 16.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	# Старые слои от прошлых версий могли перекрывать _draw.
	for child in get_children():
		child.queue_free()
	_watch_style()
	_bump_size()
	if Engine.is_editor_hint():
		_trail_ratio = preview_ratio
	set_process(true)
	queue_redraw()


func _exit_tree() -> void:
	_unwatch_style()


func setup(target: Node, bar_height: float = 14.0, bar_style: BossHpBarStyle = null) -> void:
	boss = target
	_bar_height = bar_height
	if bar_style != null:
		style = bar_style
	if style != null and style.preferred_height > 0.0:
		_bar_height = style.preferred_height
	custom_minimum_size = Vector2(72.0, _bar_height + 4.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	if is_instance_valid(boss) and int(boss.get("base_hp")) > 0:
		_trail_ratio = clampf(float(boss.get("current_hp")) / float(boss.get("base_hp")), 0.0, 1.0)
	_bump_size()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if boss == null:
		return
	if not is_instance_valid(boss) or bool(boss.get("is_dead")):
		queue_free()
		return
	var target_ratio := _fill_ratio()
	if _trail_ratio > target_ratio:
		_trail_ratio = move_toward(_trail_ratio, target_ratio, TRAIL_LERP_SPEED * delta)
	else:
		_trail_ratio = target_ratio
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _watch_style() -> void:
	if style != null and not style.changed.is_connected(_on_style_changed):
		style.changed.connect(_on_style_changed)


func _unwatch_style() -> void:
	if style != null and style.changed.is_connected(_on_style_changed):
		style.changed.disconnect(_on_style_changed)


func _on_style_changed() -> void:
	_bump_size()
	queue_redraw()


func _bump_size() -> void:
	var h := _bar_height
	if style != null and style.preferred_height > 0.0:
		h = style.preferred_height
	var min_h := h + 4.0
	if custom_minimum_size.y < min_h:
		custom_minimum_size.y = min_h
	if custom_minimum_size.x < 72.0:
		custom_minimum_size.x = 72.0
	# Важно: _draw клипается по size. В редакторе size часто 0.
	if size.x < custom_minimum_size.x or size.y < custom_minimum_size.y:
		size = Vector2(
			maxf(size.x, custom_minimum_size.x),
			maxf(size.y, custom_minimum_size.y)
		)


func _fill_ratio() -> float:
	if Engine.is_editor_hint() or boss == null:
		return preview_ratio
	if is_instance_valid(boss) and int(boss.get("base_hp")) > 0:
		return clampf(float(boss.get("current_hp")) / float(boss.get("base_hp")), 0.0, 1.0)
	return 0.0


func _draw() -> void:
	var w := maxf(size.x, custom_minimum_size.x)
	var total_h := maxf(size.y, custom_minimum_size.y)
	var h := _bar_height
	if style != null and style.preferred_height > 0.0:
		h = style.preferred_height
	var y := maxf((total_h - h) * 0.5, 0.0)
	var rect := Rect2(0.0, y, w, h)
	var ratio := _fill_ratio()

	var bg_c := DEFAULT_BG
	var trail_c := DEFAULT_TRAIL
	var fill_c := DEFAULT_FILL
	var border_c := DEFAULT_BORDER
	var bg_tex: Texture2D = null
	var fill_tex: Texture2D = null
	var trail_tex: Texture2D = null
	var frame_tex: Texture2D = null
	if style != null:
		bg_c = style.bg_color
		trail_c = style.trail_color
		fill_c = style.fill_color
		border_c = style.border_color
		bg_tex = style.bg_texture
		fill_tex = style.fill_texture
		trail_tex = style.trail_texture if style.trail_texture else fill_tex
		frame_tex = style.frame_texture

	# 1) Фон — всегда (цвет или текстура). Никогда не оставляем пусто.
	if bg_tex != null:
		draw_texture_rect(bg_tex, rect, false)
	else:
		draw_rect(rect, bg_c, true)

	# 2) Trail
	if _trail_ratio > ratio + 0.001:
		var trail_rect := Rect2(rect.position, Vector2(rect.size.x * _trail_ratio, rect.size.y))
		if trail_tex != null:
			draw_texture_rect(trail_tex, trail_rect, false)
		else:
			draw_rect(trail_rect, trail_c, true)

	# 3) Fill — stretch в ширину текущего HP (просто и видно).
	if ratio > 0.001:
		var fill_rect := Rect2(rect.position, Vector2(rect.size.x * ratio, rect.size.y))
		if fill_tex != null:
			draw_texture_rect(fill_tex, fill_rect, false)
		else:
			draw_rect(fill_rect, fill_c, true)

	# 4) Рамка
	if frame_tex != null:
		draw_texture_rect(frame_tex, rect, false)
	else:
		draw_rect(rect, border_c, false, 1.5)

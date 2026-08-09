extends Control
class_name BossHpBar

## Одна полоска HP босса: мягкий красный fill + светлый trail урона.

const FILL_COLOR := Color(0.78, 0.32, 0.36, 0.95)
const TRAIL_COLOR := Color(1.0, 0.72, 0.72, 0.85)
const BG_COLOR := Color(0.12, 0.1, 0.1, 0.65)
const BORDER_COLOR := Color(0.05, 0.04, 0.04, 0.9)
const TRAIL_LERP_SPEED := 2.2

var boss: Boss = null
var _trail_ratio := 1.0
var _bar_height := 16.0


func setup(target: Boss, bar_height: float = 14.0) -> void:
	boss = target
	_bar_height = bar_height
	custom_minimum_size = Vector2(72.0, bar_height + 4.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if is_instance_valid(boss) and boss.base_hp > 0:
		_trail_ratio = clampf(float(boss.current_hp) / float(boss.base_hp), 0.0, 1.0)
	queue_redraw()


func _process(delta: float) -> void:
	if not is_instance_valid(boss) or boss.is_dead:
		queue_free()
		return
	var target_ratio := 0.0
	if boss.base_hp > 0:
		target_ratio = clampf(float(boss.current_hp) / float(boss.base_hp), 0.0, 1.0)
	if _trail_ratio > target_ratio:
		_trail_ratio = move_toward(_trail_ratio, target_ratio, TRAIL_LERP_SPEED * delta)
	else:
		_trail_ratio = target_ratio
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := _bar_height
	var y := (size.y - h) * 0.5
	var rect := Rect2(0, y, w, h)
	draw_rect(rect, BG_COLOR, true)
	var fill_ratio := 0.0
	if is_instance_valid(boss) and boss.base_hp > 0:
		fill_ratio = clampf(float(boss.current_hp) / float(boss.base_hp), 0.0, 1.0)
	if _trail_ratio > fill_ratio + 0.001:
		draw_rect(Rect2(0, y, w * _trail_ratio, h), TRAIL_COLOR, true)
	if fill_ratio > 0.001:
		draw_rect(Rect2(0, y, w * fill_ratio, h), FILL_COLOR, true)
	draw_rect(rect, BORDER_COLOR, false, 1.5)

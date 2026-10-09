extends Button
class_name FloatingMenuButton

## Detachable menu button: drag past a threshold to throw it around,
## bounce lightly off screen edges, then return and re-dock.

enum State { DOCKED, HOLDING, DRAGGING, FREE, RETURNING }

@export var detach_threshold: float = 30.0
@export var return_delay: float = 2.5
@export var return_accel: float = 280.0
@export var return_decel: float = 420.0
@export var return_max_speed: float = 720.0
@export var return_angular_accel: float = 3.0
@export var return_angular_decel: float = 3.5
@export var return_max_angular_speed: float = 3.2
## Fraction of speed kept on each wall bounce (0.75 = lose 25%).
@export_range(0.0, 1.0, 0.01) var bounce_speed_keep: float = 0.75
@export var air_drag: float = 0.55
@export var angular_drag: float = 0.85
@export var max_free_angular_speed: float = 3.6
@export var throw_multiplier: float = 1.15
@export var throw_angular_multiplier: float = 0.002
@export var dock_pos_epsilon: float = 2.5
@export var dock_rot_epsilon: float = 0.015
## Extra room past screen edges (how far buttons may go outside).
@export var horizontal_bounds_extra: float = 28.0
@export var vertical_bounds_extra: float = 28.0

var _state: State = State.DOCKED
var _home_rotation: float = 0.0
var _home_pivot: Vector2 = Vector2.ZERO
var _home_anchor_left: float = 0.0
var _home_anchor_top: float = 0.0
var _home_anchor_right: float = 0.0
var _home_anchor_bottom: float = 0.0
var _home_offset_left: float = 0.0
var _home_offset_top: float = 0.0
var _home_offset_right: float = 0.0
var _home_offset_bottom: float = 0.0
var _home_global: Vector2 = Vector2.ZERO
var _home_size: Vector2 = Vector2.ZERO
var _home_cached: bool = false
var _floating: bool = false

var _grab_offset_global: Vector2 = Vector2.ZERO
var _press_global: Vector2 = Vector2.ZERO
var _velocity: Vector2 = Vector2.ZERO
var _angular_velocity: float = 0.0
var _return_timer: float = 0.0
var _last_mouse_global: Vector2 = Vector2.ZERO
var _mouse_velocity: Vector2 = Vector2.ZERO
var _base_z_index: int = 0


func _ready() -> void:
	_base_z_index = z_index
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	visibility_changed.connect(_on_visibility_changed)
	call_deferred("_cache_home")
	set_process(true)


func _on_visibility_changed() -> void:
	if not visible or not is_visible_in_tree():
		if _state == State.HOLDING or _state == State.DRAGGING:
			_state = State.FREE
			_return_timer = return_delay
			_reset_button_press_state()
		return
	if _home_cached and _state == State.DOCKED:
		_home_global = global_position


func _cache_home() -> void:
	_home_rotation = rotation
	_home_pivot = pivot_offset
	_home_size = size
	_home_anchor_left = anchor_left
	_home_anchor_top = anchor_top
	_home_anchor_right = anchor_right
	_home_anchor_bottom = anchor_bottom
	_home_offset_left = offset_left
	_home_offset_top = offset_top
	_home_offset_right = offset_right
	_home_offset_bottom = offset_bottom
	_home_global = global_position
	_home_cached = true


func _on_button_down() -> void:
	if not _home_cached:
		_cache_home()
	_press_global = get_global_mouse_position()
	_last_mouse_global = _press_global
	_mouse_velocity = Vector2.ZERO
	_grab_offset_global = _press_global - global_position
	_velocity = Vector2.ZERO
	_angular_velocity = 0.0
	_return_timer = 0.0
	_state = State.HOLDING
	z_index = _base_z_index + 20


func _on_button_up() -> void:
	# Only used for short clicks (never detached). Drag release is handled in _input
	# so BaseButton never emits pressed after a throw.
	if _state == State.HOLDING:
		if _is_at_home():
			_state = State.DOCKED
			z_index = _base_z_index
		else:
			_state = State.FREE
			_return_timer = return_delay
			z_index = _base_z_index + 10


func _input(event: InputEvent) -> void:
	if _state != State.DRAGGING:
		return
	if not visible or not is_visible_in_tree():
		return
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed:
		get_viewport().set_input_as_handled()
		_finish_throw()
		_reset_button_press_state()


func _finish_throw() -> void:
	_velocity = _mouse_velocity * throw_multiplier
	var center := _get_global_center()
	var radius := get_global_mouse_position() - center
	if radius.length_squared() > 1.0:
		_angular_velocity = clampf(
			radius.cross(_mouse_velocity) / radius.length_squared() \
					* throw_angular_multiplier * 60.0,
			-max_free_angular_speed,
			max_free_angular_speed
		)
	else:
		_angular_velocity = 0.0
	_state = State.FREE
	_return_timer = return_delay
	z_index = _base_z_index + 10


func _reset_button_press_state() -> void:
	disabled = true
	set_pressed_no_signal(false)
	set_deferred("disabled", false)


func _process(delta: float) -> void:
	if not visible or not is_visible_in_tree():
		return
	if not _home_cached:
		return

	var mouse_global := get_global_mouse_position()
	if _state == State.HOLDING or _state == State.DRAGGING:
		var dt := maxf(delta, 0.0001)
		_mouse_velocity = (mouse_global - _last_mouse_global) / dt
		_last_mouse_global = mouse_global

	match _state:
		State.HOLDING:
			if mouse_global.distance_to(_press_global) >= detach_threshold:
				_begin_drag()
		State.DRAGGING:
			_follow_mouse_hard()
			_constrain_to_screen(false)
		State.FREE:
			_integrate_free(delta)
			_return_timer -= delta
			if _return_timer <= 0.0:
				_begin_return()
		State.RETURNING:
			_return_home(delta)
		State.DOCKED:
			pass


func _begin_drag() -> void:
	_state = State.DRAGGING
	if not _floating:
		_detach_from_anchors()
		_set_center_pivot()
		_floating = true
	# Hard lock to the exact point under the cursor.
	_grab_offset_global = get_global_mouse_position() - global_position
	z_index = _base_z_index + 20


func _begin_return() -> void:
	# Keep current velocity/spin — steer them into an arc toward home.
	_state = State.RETURNING


func _detach_from_anchors() -> void:
	var gp := global_position
	var current_size := size if size.length_squared() > 1.0 else _home_size
	set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 0.0
	anchor_bottom = 0.0
	size = current_size
	global_position = gp


func _set_center_pivot() -> void:
	if pivot_offset.is_equal_approx(size * 0.5):
		return
	var center_before := _get_global_center()
	pivot_offset = size * 0.5
	var center_after := _get_global_center()
	global_position += center_before - center_after


func _follow_mouse_hard() -> void:
	global_position = get_global_mouse_position() - _grab_offset_global


func _integrate_free(delta: float) -> void:
	_velocity = _velocity.lerp(Vector2.ZERO, 1.0 - exp(-air_drag * delta))
	_angular_velocity = lerpf(_angular_velocity, 0.0, 1.0 - exp(-angular_drag * delta))
	_angular_velocity = clampf(_angular_velocity, -max_free_angular_speed, max_free_angular_speed)
	global_position += _velocity * delta
	rotation += _angular_velocity * delta
	_constrain_to_screen(true)


func _get_global_center() -> Vector2:
	return get_global_transform() * (size * 0.5)


func _get_global_aabb() -> Rect2:
	var xform := get_global_transform()
	var p0 := xform * Vector2.ZERO
	var p1 := xform * Vector2(size.x, 0.0)
	var p2 := xform * Vector2(0.0, size.y)
	var p3 := xform * size
	var min_v := p0.min(p1).min(p2).min(p3)
	var max_v := p0.max(p1).max(p2).max(p3)
	return Rect2(min_v, max_v - min_v)


func _get_view_bounds() -> Rect2:
	var view := get_viewport().get_visible_rect()
	view.position.x -= horizontal_bounds_extra
	view.position.y -= vertical_bounds_extra
	view.size.x += horizontal_bounds_extra * 2.0
	view.size.y += vertical_bounds_extra * 2.0
	return view


## Keep the button's visual AABB inside the absolute screen rect.
## If bounce is true, reflect velocity on hit edges.
func _constrain_to_screen(bounce: bool) -> void:
	var view := _get_view_bounds()
	var aabb := _get_global_aabb()
	var shift := Vector2.ZERO

	if aabb.position.x < view.position.x:
		shift.x = view.position.x - aabb.position.x
		if bounce:
			_velocity.x = absf(_velocity.x) * bounce_speed_keep
	elif aabb.end.x > view.end.x:
		shift.x = view.end.x - aabb.end.x
		if bounce:
			_velocity.x = -absf(_velocity.x) * bounce_speed_keep

	if aabb.position.y < view.position.y:
		shift.y = view.position.y - aabb.position.y
		if bounce:
			_velocity.y = absf(_velocity.y) * bounce_speed_keep
	elif aabb.end.y > view.end.y:
		shift.y = view.end.y - aabb.end.y
		if bounce:
			_velocity.y = -absf(_velocity.y) * bounce_speed_keep

	if shift != Vector2.ZERO:
		global_position += shift


func _steer_toward(current: float, desired: float, max_delta: float) -> float:
	return current + clampf(desired - current, -max_delta, max_delta)


func _return_home(delta: float) -> void:
	var to_home := _home_global - global_position
	var dist := to_home.length()

	if dist <= dock_pos_epsilon:
		global_position = _home_global
		_velocity = Vector2.ZERO
	else:
		var dir := to_home / dist
		# Arrive cap near home; far away allow full speed — steer existing velocity into an arc.
		var desired_speed := minf(return_max_speed, sqrt(2.0 * return_decel * dist))
		var desired_vel := dir * desired_speed
		var steer := desired_vel - _velocity
		var max_steer := return_accel * delta
		if steer.length() > max_steer:
			steer = steer.normalized() * max_steer
		_velocity += steer
		global_position += _velocity * delta
		_constrain_to_screen(true)

	var angle_to_home := angle_difference(rotation, _home_rotation)
	var angle_left := absf(angle_to_home)
	if angle_left <= dock_rot_epsilon:
		rotation = _home_rotation
		_angular_velocity = 0.0
	else:
		var desired_ang := signf(angle_to_home) * minf(
			return_max_angular_speed,
			sqrt(2.0 * return_angular_decel * angle_left)
		)
		_angular_velocity = _steer_toward(
			_angular_velocity, desired_ang, return_angular_accel * delta
		)
		rotation += _angular_velocity * delta

	if global_position.distance_to(_home_global) <= dock_pos_epsilon \
			and absf(angle_difference(rotation, _home_rotation)) <= dock_rot_epsilon:
		_dock()


func _dock() -> void:
	_state = State.DOCKED
	_floating = false
	_velocity = Vector2.ZERO
	_angular_velocity = 0.0
	_return_timer = 0.0
	z_index = _base_z_index
	rotation = _home_rotation
	pivot_offset = _home_pivot
	# Restore only anchors/offsets — never assign position/size (breaks anchored exit/back).
	anchor_left = _home_anchor_left
	anchor_top = _home_anchor_top
	anchor_right = _home_anchor_right
	anchor_bottom = _home_anchor_bottom
	offset_left = _home_offset_left
	offset_top = _home_offset_top
	offset_right = _home_offset_right
	offset_bottom = _home_offset_bottom
	_home_global = global_position


func _is_at_home() -> bool:
	return global_position.distance_to(_home_global) <= dock_pos_epsilon \
			and absf(angle_difference(rotation, _home_rotation)) <= dock_rot_epsilon


func reset_to_dock() -> void:
	if not _home_cached:
		_cache_home()
	_dock()

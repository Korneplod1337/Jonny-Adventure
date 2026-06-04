class_name CardShot
extends BaseShot

const RETURN_ARRIVE_DISTANCE := 10.0
const MIN_CURVE_T_RATE := 0.06

@export var spin_speed: float = 10.0

@onready var _anim_sprite: AnimatedSprite2D = $shot_Animated
@onready var _speed_curve_line: Line2D = $CurveLine2D

var _spawn_origin: Vector2
var _max_outbound_distance := 0.0
var _curve_trip_duration := 1.0
var _curve_t := 0.0
var _spin_angle := 0.0


func _ready() -> void:
	super()
	penetration = 1
	extra_reload = 1.2
	self_damage_multiplier = 0.75
	self_range_multiplier = 0.75
	animaited_speed = GameState.animated_world_speed
	_spawn_origin = global_position
	_max_outbound_distance = atk_range * self_range_multiplier
	_curve_trip_duration = _max_outbound_distance * 2.0 / maxf(speed * self_speed_multiplier, 1.0)
	_speed_curve_line.visible = false
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	if exploded:
		return

	_spin_angle += spin_speed * delta
	_anim_sprite.rotation = _spin_angle

	if _curve_t >= 1.0:
		_finish_miss()
		return

	var mult := _sample_speed_curve(_curve_t)
	var move_dir: Vector2

	if mult >= 0.0:
		move_dir = direction.normalized()
	else:
		var to_home := _spawn_origin - global_position
		if to_home.length() <= RETURN_ARRIVE_DISTANCE:
			_finish_miss()
			return
		move_dir = to_home.normalized()

	var step := move_dir * speed * absf(mult) * delta * self_speed_multiplier
	global_position += step
	rotation = move_dir.angle()

	var t_rate := maxf(absf(mult), MIN_CURVE_T_RATE)
	_curve_t += (t_rate * delta) / _curve_trip_duration
	_curve_t = minf(_curve_t, 1.0)


func _sample_speed_curve(t: float) -> float:
	var curve := _speed_curve_line.width_curve
	if curve == null or curve.point_count == 0:
		return 1.0
	return curve.sample(clampf(t, 0.0, 1.0))


func _on_body_entered(body: Node) -> void:
	if exploded:
		return
	if body.is_in_group("player"):
		return

	if body.has_method("hit"):
		_handle_enemy_contact(body)
	else:
		_break_shot()


func _handle_enemy_contact(enemy: Node) -> void:
	if _register_pierce_hit(enemy, _get_final_damage()):
		_break_shot()


func _break_shot() -> void:
	if exploded:
		return
	exploded = true
	explosion(0)


func _finish_miss() -> void:
	if exploded:
		return
	exploded = true
	explosion(1)

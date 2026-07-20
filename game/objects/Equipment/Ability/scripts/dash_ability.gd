class_name DashAbility
extends BaseAbility

const DASH_DISTANCE := 180.0
const SPEED_MULT := 4.0

var _dashing: bool = false
var _dash_dir: Vector2 = Vector2.ZERO
var _dash_travelled: float = 0.0


func _init() -> void:
	ability_id = "Dash"
	cooldown_type = CooldownType.TIME
	cooldown_time = 20.0


func activate() -> bool:
	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()
	if dir == Vector2.ZERO and player.now_move_direction.length() > 1.0:
		dir = player.now_move_direction.normalized()
	if dir == Vector2.ZERO:
		return false

	_dash_dir = dir
	_dash_travelled = 0.0
	_dashing = true
	player.is_dashing = true
	player._update_enemy_collision()
	return true


func process_movement(delta: float) -> bool:
	if not _dashing:
		return false

	var speed: float = player.move_speed * SPEED_MULT
	var remaining: float = DASH_DISTANCE - _dash_travelled
	var step: float = minf(speed * delta, remaining)
	player.velocity = _dash_dir * speed
	_dash_travelled += step

	if _dash_travelled >= DASH_DISTANCE - 0.01:
		_end_dash()
	return true


func _end_dash() -> void:
	_dashing = false
	player.is_dashing = false
	player._update_enemy_collision()


func _exit_tree() -> void:
	if _dashing and player:
		_end_dash()
		player.velocity = Vector2.ZERO
	super._exit_tree()

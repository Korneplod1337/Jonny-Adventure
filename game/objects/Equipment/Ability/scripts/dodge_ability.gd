## Dodge — рывок назад (против направления движения), дистанция 200. CD: время или 1 зачищенная комната.
class_name DodgeAbility
extends BaseAbility

const DODGE_DISTANCE := 200.0
const SPEED_MULT := 4.0

var _dodging: bool = false
var _dodge_dir: Vector2 = Vector2.ZERO
var _dodge_travelled: float = 0.0


func _init() -> void:
	ability_id = "Dodge"
	cooldown_type = CooldownType.TIME
	cooldown_time = 10.0
	cooldown_room_recharge = 1


func activate() -> bool:
	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	).normalized()
	if dir == Vector2.ZERO and player.now_move_direction.length() > 1.0:
		dir = player.now_move_direction.normalized()
	if dir == Vector2.ZERO:
		return false

	_dodge_dir = -dir
	_dodge_travelled = 0.0
	_dodging = true
	player.is_dashing = true
	player._update_enemy_collision()
	return true


func process_movement(delta: float) -> bool:
	if not _dodging:
		return false

	var speed: float = player.move_speed * SPEED_MULT
	var remaining: float = DODGE_DISTANCE - _dodge_travelled
	var step: float = minf(speed * delta, remaining)
	player.velocity = _dodge_dir * speed
	_dodge_travelled += step

	if _dodge_travelled >= DODGE_DISTANCE - 0.01:
		_end_dodge()
	return true


func _end_dodge() -> void:
	_dodging = false
	player.is_dashing = false
	player._update_enemy_collision()


func _exit_tree() -> void:
	if _dodging and player:
		_end_dodge()
		player.velocity = Vector2.ZERO
	super._exit_tree()

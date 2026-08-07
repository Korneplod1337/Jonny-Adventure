extends EnemyBugGunslinger
class_name EnemyBugSniper

## Снайпер: дальше держит дистанцию, медленнее стреляет, сильнее пуля, отдача назад.

@export var recoil_distance: float = 30.0
@export var recoil_duration: float = 0.12

var _recoil_dir := Vector2.ZERO
var _recoil_left := 0.0
var _recoil_speed := 0.0


func _ready() -> void:
	# Относительно текущего Gunslinger (speed 400, range 600, interval 0.5, move 170).
	range_min = 300.0
	range_max = 600.0
	shot_interval = 1.0
	hard_move_speed = 170.0 * 0.8
	hard_projectile_speed = 400.0 * 1.5
	hard_projectile_range = 1000
	hard_projectile_damage = 2
	super._ready()


func _get_shot_count() -> int:
	return 2


func _rotates_during_pre_fire() -> bool:
	return true


func _on_shot_fired(facing_dir: Vector2) -> void:
	# Откид фиксируется по направлению выстрела; доворот на него не влияет.
	_recoil_dir = -facing_dir.normalized()
	if _recoil_dir == Vector2.ZERO:
		_recoil_dir = Vector2.DOWN
	_recoil_left = recoil_distance
	_recoil_speed = recoil_distance / maxf(recoil_duration, 0.01)


func _apply_firing_velocity(_delta: float) -> void:
	if _recoil_left <= 0.0:
		velocity = Vector2.ZERO
		return
	velocity = _recoil_dir * _recoil_speed


func _after_firing_move(prev_pos: Vector2) -> void:
	if _recoil_left <= 0.0:
		return
	var moved := global_position.distance_to(prev_pos)
	_recoil_left = maxf(0.0, _recoil_left - moved)
	if _recoil_left <= 0.0:
		velocity = Vector2.ZERO


func _abort_to_idle() -> void:
	_recoil_left = 0.0
	super._abort_to_idle()


func _start_after_fire() -> void:
	# Не сбрасываем отдачу мгновенно в момент выстрела — она уже отыграла за interval.
	_recoil_left = 0.0
	velocity = Vector2.ZERO
	super._start_after_fire()

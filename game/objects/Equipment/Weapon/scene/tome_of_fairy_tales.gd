extends BaseShot
class_name tome_of_fairy_tales

const ENEMY_GROUP := "Enemy"
const DETECTION_RANGE_MULTIPLIER := 1.25

## Максимальная скорость поворота (рад/с). Меньше — более плавная дуга.
@export var turn_speed: float = 2.5

## После первого захвата цели — только самонаведение (без Satellite / Math Circle).
var _homing_locked: bool = false
var _homing_speed: float = 0.0


func _ready() -> void:
	self_damage_multiplier = 0.6
	self_speed_multiplier = 0.8
	self_range_multiplier = 0.8
	extra_reload = 1.3
	super()
	$shot_Animated.play("fly")
	_homing_speed = maxf(speed * self_speed_multiplier, 1.0)


func _physics_process(delta: float) -> void:
	if exploded:
		return

	var target := _find_nearest_enemy()
	if target != null:
		_homing_locked = true

	if _homing_locked:
		_physics_process_homing_only(delta, target)
		return

	# Пока цели нет — обычные эффекты (sine / satellite / boomerang).
	super._physics_process(delta)


func _physics_process_homing_only(delta: float, target: CharacterBody2D) -> void:
	_detach_movement_modifiers()
	if target == null or not is_instance_valid(target):
		# Цель потеряна — летим по текущему direction без sine/satellite.
		target = _find_nearest_enemy()
	if target != null and is_instance_valid(target):
		_turn_towards(target.global_position, delta)

	var step := direction.normalized() * _homing_speed * delta
	if direction.length_squared() < 0.0001:
		step = Vector2.RIGHT * _homing_speed * delta
	global_position += step
	distance_travelled += step.length()
	rotation = direction.angle()
	_align_shadow_to_world()
	_align_crit_to_world()

	if distance_travelled >= atk_range * self_range_multiplier:
		exploded = true
		explosion(1)
		return
	_try_spread_shot_split()


func _detach_movement_modifiers() -> void:
	# Игнор Math Circle.
	sine_amplitude = 0.0
	_sine_initialized = false
	# Игнор Satellite — снимаем со слота один раз.
	if satellite_orbit or satellite_armed:
		if _satellite_ctrl and _satellite_ctrl.has_method("unregister_shot"):
			_satellite_ctrl.unregister_shot(self)
		_satellite_ctrl = null
		satellite_orbit = false
		satellite_armed = false
		satellite_phase = "free"
		satellite_slot_index = -1
		_boomerang_active = false
		_boomerang_segment_count = 0
		collision_mask = collision_mask | SATELLITE_WALL_MASK_BITS
	if _homing_speed < 1.0:
		_homing_speed = maxf(speed * self_speed_multiplier, 120.0)


func _turn_towards(target_pos: Vector2, delta: float) -> void:
	var to_target := target_pos - global_position
	if to_target.length_squared() <= 0.0:
		return

	var current_dir := direction.normalized()
	if current_dir == Vector2.ZERO:
		current_dir = Vector2.RIGHT
	var desired_dir := to_target.normalized()
	var angle_diff := current_dir.angle_to(desired_dir)
	var max_turn := turn_speed * delta
	direction = current_dir.rotated(clampf(angle_diff, -max_turn, max_turn))


func _get_detection_range() -> float:
	return maxf(atk_range * self_range_multiplier * DETECTION_RANGE_MULTIPLIER, 0.0)


func _find_nearest_enemy() -> CharacterBody2D:
	var nearest: CharacterBody2D = null
	var detection := _get_detection_range()
	var nearest_dist_sq := detection * detection

	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if not is_instance_valid(enemy) or not enemy is CharacterBody2D:
			continue
		if enemy.get("is_dead") == true:
			continue

		var dist_sq := global_position.distance_squared_to(enemy.global_position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = enemy

	return nearest

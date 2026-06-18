extends BaseShot
class_name tome_of_fairy_tales

const ENEMY_GROUP := "Enemy"
const DETECTION_RANGE_MULTIPLIER := 1.25

## Максимальная скорость поворота (рад/с). Меньше — более плавная дуга.
@export var turn_speed: float = 2.5

var _max_range: float
var _detection_range: float


func _ready() -> void:
	self_damage_multiplier = 0.5
	self_speed_multiplier = 0.8
	self_range_multiplier = 0.8
	extra_reload = 1.3
	_max_range = atk_range * self_range_multiplier
	_detection_range = _max_range * DETECTION_RANGE_MULTIPLIER
	super()
	$shot_Animated.play("fly")


func _physics_process(delta: float) -> void:
	if exploded:
		return

	var target := _find_nearest_enemy()
	if target:
		_turn_towards(target.global_position, delta)
	rotation = direction.angle()

	super._physics_process(delta)


func _turn_towards(target_pos: Vector2, delta: float) -> void:
	var to_target := target_pos - global_position
	if to_target.length_squared() <= 0.0:
		return

	var current_dir := direction.normalized()
	var desired_dir := to_target.normalized()
	var angle_diff := current_dir.angle_to(desired_dir)
	var max_turn := turn_speed * delta
	direction = current_dir.rotated(clampf(angle_diff, -max_turn, max_turn))


func _find_nearest_enemy() -> CharacterBody2D:
	var nearest: CharacterBody2D = null
	var nearest_dist_sq := _detection_range * _detection_range

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

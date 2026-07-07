extends BaseEnemy
class_name EnemySpiderSmall

@export_group("Hard Stats")
@export var hard_move_speed_min: float = 140.0
@export var hard_move_speed_max: float = 200.0
@export var hard_base_hp: int = 65
@export var hard_damage: int = 1
@export var hard_direction_change_min: float = 0.2
@export var hard_direction_change_max: float = 0.8
@export var hard_angle_deviation: float = 60.0

const MOVE_SPEED_MIN_MED_OFFSET := -20.0
const MOVE_SPEED_MIN_EASY_OFFSET := -40.0
const MOVE_SPEED_MAX_MED_OFFSET := -20.0
const MOVE_SPEED_MAX_EASY_OFFSET := -40.0
const HP_MED_OFFSET := -20
const HP_EASY_OFFSET := -40
const DIRECTION_CHANGE_MIN_MED_OFFSET := 0.0
const DIRECTION_CHANGE_MIN_EASY_OFFSET := 0.3
const DIRECTION_CHANGE_MAX_MED_OFFSET := 0.2
const DIRECTION_CHANGE_MAX_EASY_OFFSET := 0.2
const ANGLE_DEVIATION_MED_OFFSET := 0.0
const ANGLE_DEVIATION_EASY_OFFSET := -10.0

var move_speed_min: float
var move_speed_max: float
var direction_change_min: float
var direction_change_max: float
var angle_deviation: float
var _speed_range_min_ratio: float = 1.0
var _speed_range_max_ratio: float = 1.0

var wander_direction := Vector2.RIGHT
var current_speed := 100.0
var direction_timer := 0.0


func _apply_difficulty_offset(hard_value: float, med_offset: float, easy_offset: float) -> float:
	match DungeonManager.difficulty:
		"hard":
			return hard_value
		"med":
			return hard_value + med_offset
		_:
			return hard_value + easy_offset


func _ready() -> void:
	super._ready()
	_update_locomotion_animation()


func _on_blind_timer_timeout() -> void:
	super._on_blind_timer_timeout()
	if active:
		_pick_new_wander_params()
	_update_locomotion_animation()


func _update_locomotion_animation() -> void:
	if active:
		sprite.play("default")
	elif sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func _on_field_view_area_body_exited(body: Node2D) -> void:
	super._on_field_view_area_body_exited(body)
	_update_locomotion_animation()


func _setup_enemy_stats() -> void:
	move_speed_min = _apply_difficulty_offset(
		hard_move_speed_min, MOVE_SPEED_MIN_MED_OFFSET, MOVE_SPEED_MIN_EASY_OFFSET
	) * GameState.enemy_ms_multiplier
	move_speed_max = _apply_difficulty_offset(
		hard_move_speed_max, MOVE_SPEED_MAX_MED_OFFSET, MOVE_SPEED_MAX_EASY_OFFSET
	) * GameState.enemy_ms_multiplier
	base_move_speed = (move_speed_min + move_speed_max) * 0.5
	move_speed = base_move_speed
	_speed_range_min_ratio = move_speed_min / base_move_speed
	_speed_range_max_ratio = move_speed_max / base_move_speed
	base_hp = int(_apply_difficulty_offset(
		float(hard_base_hp), float(HP_MED_OFFSET), float(HP_EASY_OFFSET)
	) * GameState.enemy_hp_multiplier)
	damage = clampi(int(hard_damage * GameState.enemy_dmg_multiplier), 1, 4)
	direction_change_min = _apply_difficulty_offset(
		hard_direction_change_min,
		DIRECTION_CHANGE_MIN_MED_OFFSET,
		DIRECTION_CHANGE_MIN_EASY_OFFSET
	)
	direction_change_max = _apply_difficulty_offset(
		hard_direction_change_max,
		DIRECTION_CHANGE_MAX_MED_OFFSET,
		DIRECTION_CHANGE_MAX_EASY_OFFSET
	)
	angle_deviation = _apply_difficulty_offset(
		hard_angle_deviation, ANGLE_DEVIATION_MED_OFFSET, ANGLE_DEVIATION_EASY_OFFSET
	)

	super._setup_enemy_stats()


func _custom_physics(delta: float) -> void:
	if not player:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player := player.global_position - global_position
	if to_player.length() <= base_move_stop_distance:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	direction_timer -= delta
	if direction_timer <= 0.0:
		_pick_new_wander_params()

	velocity = wander_direction * current_speed
	sprite.flip_h = wander_direction.x < 0.0
	move_and_slide()


func _pick_new_wander_params() -> void:
	direction_timer = randf_range(direction_change_min, direction_change_max)
	current_speed = randf_range(
		move_speed * _speed_range_min_ratio,
		move_speed * _speed_range_max_ratio
	)

	if not player:
		wander_direction = Vector2.RIGHT.rotated(randf() * TAU)
		return

	var to_player := player.global_position - global_position
	if to_player.length_squared() < 0.01:
		wander_direction = Vector2.RIGHT.rotated(
			deg_to_rad(randf_range(-angle_deviation, angle_deviation))
		)
		return

	var base_angle := to_player.angle()
	var offset := deg_to_rad(randf_range(-angle_deviation, angle_deviation))
	wander_direction = Vector2.from_angle(base_angle + offset)

extends BaseEnemy

@export_group("Hard Stats")
@export var hard_move_step_distance: float = 250.0
@export var hard_move_speed: float = 200.0
@export var hard_base_hp: int = 100
@export var hard_damage: int = 1
@export var hard_cooldown_time: float = 0.8

const MOVE_STEP_MED_OFFSET := -50.0
const MOVE_STEP_EASY_OFFSET := -100.0
const MOVE_SPEED_MED_OFFSET := -25.0
const MOVE_SPEED_EASY_OFFSET := -50.0
const HP_MED_OFFSET := -20
const HP_EASY_OFFSET := -50
const COOLDOWN_MED_OFFSET := 0.1
const COOLDOWN_EASY_OFFSET := 0.2
const MS_MULT_HARD := 1.2
const MS_MULT_MED := 1.1
const MS_MULT_EASY := 1.0

@export var dash_curve: Curve

var move_step_distance: float = 100.0
var dash_distance_travelled: float = 0.0
var target_direction: Vector2 = Vector2.ZERO
var is_dashing: bool = false


func _apply_difficulty_offset(hard_value: float, med_offset: float, easy_offset: float) -> float:
	match DungeonManager.difficulty:
		"hard":
			return hard_value
		"med":
			return hard_value + med_offset
		_:
			return hard_value + easy_offset


func _get_ms_multiplier() -> float:
	match DungeonManager.difficulty:
		"hard":
			return MS_MULT_HARD
		"med":
			return MS_MULT_MED
		_:
			return MS_MULT_EASY


func _setup_enemy_stats() -> void:
	var ms_mult := _get_ms_multiplier() * GameState.enemy_ms_multiplier

	move_step_distance = _apply_difficulty_offset(
		hard_move_step_distance, MOVE_STEP_MED_OFFSET, MOVE_STEP_EASY_OFFSET
	) * ms_mult
	move_speed = _apply_difficulty_offset(
		hard_move_speed, MOVE_SPEED_MED_OFFSET, MOVE_SPEED_EASY_OFFSET
	) * ms_mult
	base_hp = int(_apply_difficulty_offset(
		float(hard_base_hp), float(HP_MED_OFFSET), float(HP_EASY_OFFSET)
	) * GameState.enemy_hp_multiplier)
	damage = clampi(int(hard_damage * GameState.enemy_dmg_multiplier), 1, 3)
	cooldown_time = _apply_difficulty_offset(
		hard_cooldown_time, COOLDOWN_MED_OFFSET, COOLDOWN_EASY_OFFSET
	) * GameState.enemy_cooldown_multiplier

	super._setup_enemy_stats()


func _custom_physics(delta: float) -> void:
	if is_dashing:
		var progress = dash_distance_travelled / move_step_distance
		if progress >= 1.0:
			is_dashing = false
			sprite.frame = 0
			dash_distance_travelled = 0.0
			velocity = Vector2.ZERO
			cooldown_timer.start()
			return

		var curve_multiplier = dash_curve.sample(progress)
		velocity = target_direction * move_speed * curve_multiplier
		dash_distance_travelled += velocity.length() * delta
		move_and_slide()
		return

	velocity = Vector2.ZERO


func enemy_action() -> void:
	choose_direction_and_dash()


func choose_direction_and_dash() -> void:
	var dir = (player.global_position - global_position).normalized()
	if dir.length() == 0:
		return

	target_direction = dir
	sprite.flip_h = target_direction.x < 0
	is_dashing = true
	dash_distance_travelled = 0.0
	sprite.frame = 1

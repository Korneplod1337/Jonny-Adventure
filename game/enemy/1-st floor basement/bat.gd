extends EnemyRanger
class_name EnemyBat

enum State { IDLE, FLYING, PREPARING, RECOVERING }

@export_group("Hard Stats")
@export var hard_move_speed: float = 150.0
@export var hard_base_hp: int = 80
@export var hard_damage: int = 2
@export var hard_cooldown_time: float = 0.8
@export var hard_projectile_speed: float = 300.0
@export var hard_projectile_range: float = 350.0
@export var hard_max_move_distance: float = 200.0
@export var hard_prepare_time: float = 0.4
@export var hard_post_shoot_pause: float = 0.8
@export var hard_fly_time_min: float = 1.5
@export var hard_fly_time_max: float = 2.5
@export var target_offset: float = 80.0
@export var near_player_range_mult: float = 1.2
@export var near_player_fly_distance_mult: float = 0.7

const MOVE_SPEED_MED_OFFSET := -30.0
const MOVE_SPEED_EASY_OFFSET := -50.0
const HP_MED_OFFSET := -30
const HP_EASY_OFFSET := -50
const DAMAGE_MED_OFFSET := -1
const DAMAGE_EASY_OFFSET := -1
const COOLDOWN_MED_OFFSET := 0.2
const COOLDOWN_EASY_OFFSET := 0.4
const PROJECTILE_SPEED_MED_OFFSET := -50.0
const PROJECTILE_SPEED_EASY_OFFSET := -100.0
const PROJECTILE_RANGE_MED_OFFSET := -50.0
const PROJECTILE_RANGE_EASY_OFFSET := -100.0
const MAX_MOVE_DISTANCE_MED_OFFSET := -25.0
const MAX_MOVE_DISTANCE_EASY_OFFSET := -50.0
const PREPARE_TIME_MED_OFFSET := 0.05
const PREPARE_TIME_EASY_OFFSET := 0.1
const POST_SHOOT_PAUSE_MED_OFFSET := 0.0
const POST_SHOOT_PAUSE_EASY_OFFSET := 0.2

var prepare_time: float
var post_shoot_pause: float
var fly_time_min: float
var fly_time_max: float

var state := State.IDLE
var fly_timer := 0.0
var prepare_timer := 0.0
var recover_timer := 0.0
var fly_target := Vector2.ZERO
var fly_distance_travelled := 0.0
var fly_distance_limit := 0.0


func _ready() -> void:
	super._ready()
	deals_melee_damage = false
	knockback_friction += 200
	$AnimatedSprite2D.play("default")


func _apply_level_buffs() -> void:
	move_speed = _scale_move_speed(
		hard_move_speed, MOVE_SPEED_MED_OFFSET, MOVE_SPEED_EASY_OFFSET
	)
	base_hp = _scale_hp(hard_base_hp, HP_MED_OFFSET, HP_EASY_OFFSET)
	damage = _scale_damage(hard_damage, DAMAGE_MED_OFFSET, DAMAGE_EASY_OFFSET)
	cooldown_time = _scale_cooldown(
		hard_cooldown_time, COOLDOWN_MED_OFFSET, COOLDOWN_EASY_OFFSET
	)
	projectile_speed = _apply_difficulty_offset(
		hard_projectile_speed, PROJECTILE_SPEED_MED_OFFSET, PROJECTILE_SPEED_EASY_OFFSET
	)
	projectile_range = _apply_difficulty_offset(
		hard_projectile_range, PROJECTILE_RANGE_MED_OFFSET, PROJECTILE_RANGE_EASY_OFFSET
	)
	max_move_distance = _apply_difficulty_offset(
		hard_max_move_distance, MAX_MOVE_DISTANCE_MED_OFFSET, MAX_MOVE_DISTANCE_EASY_OFFSET
	)
	prepare_time = _apply_difficulty_offset(
		hard_prepare_time, PREPARE_TIME_MED_OFFSET, PREPARE_TIME_EASY_OFFSET
	)
	post_shoot_pause = _apply_difficulty_offset(
		hard_post_shoot_pause, POST_SHOOT_PAUSE_MED_OFFSET, POST_SHOOT_PAUSE_EASY_OFFSET
	)
	fly_time_min = hard_fly_time_min
	fly_time_max = hard_fly_time_max

	super._apply_level_buffs()


func enemy_action() -> void:
	_start_fly_phase()


func _custom_physics(delta: float) -> void:
	if not active:
		state = State.IDLE
		velocity = Vector2.ZERO
		return

	if state == State.IDLE:
		if cooldown_timer.is_stopped():
			_start_fly_phase()
		else:
			velocity = Vector2.ZERO
		return

	match state:
		State.FLYING:
			_process_flying(delta)
		State.PREPARING:
			_process_preparing(delta)
		State.RECOVERING:
			_process_recovering(delta)


func _start_fly_phase() -> void:
	if not player or not active:
		state = State.IDLE
		return

	state = State.FLYING
	fly_timer = randf_range(fly_time_min, fly_time_max)
	fly_distance_travelled = 0.0
	fly_distance_limit = _get_fly_distance_limit()
	fly_target = player.global_position + Vector2(
		randf_range(-target_offset, target_offset),
		randf_range(-target_offset, target_offset)
	)


func _get_fly_distance_limit() -> float:
	if not player:
		return max_move_distance

	var near_threshold := projectile_range * near_player_range_mult
	if global_position.distance_to(player.global_position) <= near_threshold:
		return max_move_distance * near_player_fly_distance_mult

	return max_move_distance


func _process_flying(delta: float) -> void:
	fly_timer -= delta

	if fly_timer <= 0.0 or fly_distance_travelled >= fly_distance_limit:
		_start_prepare_phase()
		return

	var dir := fly_target - global_position
	if dir.length_squared() < 1.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	dir = dir.normalized()
	velocity = dir * move_speed
	sprite.flip_h = dir.x < 0
	var prev_position := global_position
	move_and_slide()
	fly_distance_travelled += global_position.distance_to(prev_position)


func _start_prepare_phase() -> void:
	state = State.PREPARING
	prepare_timer = prepare_time
	velocity = Vector2.ZERO


func _process_preparing(delta: float) -> void:
	velocity = Vector2.ZERO
	prepare_timer -= delta

	if prepare_timer <= 0.0:
		_shoot_at_player()


func _shoot_at_player() -> void:
	if not player or not active:
		_start_recover_phase()
		return

	var dir := player.global_position - global_position
	if dir.length_squared() < 1.0:
		_start_recover_phase()
		return

	shoot_projectile(dir)
	_start_recover_phase()


func _start_recover_phase() -> void:
	state = State.RECOVERING
	recover_timer = post_shoot_pause
	velocity = Vector2.ZERO


func _process_recovering(delta: float) -> void:
	velocity = Vector2.ZERO
	recover_timer -= delta

	if recover_timer <= 0.0:
		_start_fly_phase()

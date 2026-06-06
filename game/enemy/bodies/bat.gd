extends EnemyRanger
class_name EnemyBat

enum State { IDLE, FLYING, PREPARING, RECOVERING }

const NEAR_PLAYER_RANGE_MULT := 1.2
const NEAR_PLAYER_FLY_DISTANCE_MULT := 0.7

# ===== Характеристики по сложности =====
const STATS := {
	"easy": {
		"move_speed": 100.0,
		"base_hp": 35,
		"damage": 1,
		"cooldown_time": 1.5,
		"projectile_speed": 150.0,
		"projectile_range": 250.0,
		"max_move_distance": 150.0,
		"prepare_time": 0.5,
		"post_shoot_pause": 1.0,
		"fly_time_min": 2.0,
		"fly_time_max": 3.0,
	},
	"med": {
		"move_speed": 120.0,
		"base_hp": 50,
		"damage": 1,
		"cooldown_time": 1.2,
		"projectile_speed": 175.0,
		"projectile_range": 275.0,
		"max_move_distance": 165.0,
		"prepare_time": 0.45,
		"post_shoot_pause": 0.8,
		"fly_time_min": 1.8,
		"fly_time_max": 2.8,
	},
	"hard": {
		"move_speed": 150.0,
		"base_hp": 80,
		"damage": 2,
		"cooldown_time": 1.0,
		"projectile_speed": 200.0,
		"projectile_range": 300.0,
		"max_move_distance": 180.0,
		"prepare_time": 0.4,
		"post_shoot_pause": 0.8,
		"fly_time_min": 1.5,
		"fly_time_max": 2.5,
	},
}

var target_offset: float = 80
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


func _setup_enemy_stats() -> void:
	var key: String = DungeonManager.difficulty
	if key not in STATS:
		key = "easy"

	var s: Dictionary = STATS[key]
	move_speed = s.move_speed * GameState.enemy_ms_multiplier
	base_hp = int(s.base_hp * GameState.enemy_hp_multiplier)
	damage = clampi(int(s.damage * GameState.enemy_dmg_multiplier), 1, 4)
	cooldown_time = s.cooldown_time * GameState.enemy_cooldown_multiplier
	projectile_speed = s.projectile_speed
	projectile_range = s.projectile_range
	max_move_distance = s.max_move_distance
	prepare_time = s.prepare_time
	post_shoot_pause = s.post_shoot_pause
	fly_time_min = s.fly_time_min
	fly_time_max = s.fly_time_max

	super._setup_enemy_stats()


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

	var near_threshold := projectile_range * NEAR_PLAYER_RANGE_MULT
	if global_position.distance_to(player.global_position) <= near_threshold:
		return max_move_distance * NEAR_PLAYER_FLY_DISTANCE_MULT

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

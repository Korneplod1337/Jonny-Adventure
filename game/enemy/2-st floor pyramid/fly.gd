extends EnemyRanger
class_name EnemyFly

## Улучшенная муха на базе Bat: подлёт → 5 выстрелов (shot) → wait/fly в случайном порядке.

enum State { IDLE, FLYING, SHOOTING, WAITING, SCATTER }
enum AfterFly { SHOOT, WAIT }
enum AfterWait { SHOOT, FLY }

@export_group("Hard Stats")
@export var hard_move_speed: float = 185.0
@export var hard_base_hp: int = 120
@export var hard_damage: int = 2
@export var hard_cooldown_time: float = 0.6
@export var hard_projectile_speed: float = 380.0
@export var hard_projectile_range: float = 420.0
@export var hard_max_move_distance: float = 260.0
@export var hard_fly_time_min: float = 1.2
@export var hard_fly_time_max: float = 2.2
@export var hard_stand_time: float = 1.0
@export var shots_per_volley: int = 5
@export var approach_stop_distance: float = 140.0
@export var target_offset: float = 60.0
## Минимальная длительность фазы полёта — нельзя скипнуть в 0 кадров.
@export var hard_min_fly_time: float = 0.55
@export var hover_speed_mult: float = 0.4

const MOVE_SPEED_MED_OFFSET := -30.0
const MOVE_SPEED_EASY_OFFSET := -50.0
const HP_MED_OFFSET := -30
const HP_EASY_OFFSET := -50
const DAMAGE_MED_OFFSET := -0
const DAMAGE_EASY_OFFSET := -1
const COOLDOWN_MED_OFFSET := 0.15
const COOLDOWN_EASY_OFFSET := 0.3
const PROJECTILE_SPEED_MED_OFFSET := -40.0
const PROJECTILE_SPEED_EASY_OFFSET := -80.0
const PROJECTILE_RANGE_MED_OFFSET := -40.0
const PROJECTILE_RANGE_EASY_OFFSET := -80.0
const MAX_MOVE_DISTANCE_MED_OFFSET := -30.0
const MAX_MOVE_DISTANCE_EASY_OFFSET := -60.0

var stand_time: float = 1.5
var fly_time_min: float = 1.2
var fly_time_max: float = 2.2
var max_move_distance: float = 260.0
var min_fly_time: float = 1.2

var state := State.IDLE
var fly_timer := 0.0
var fly_elapsed := 0.0
var wait_timer := 0.0
var hover_t := 0.0
var fly_target := Vector2.ZERO
var fly_distance_travelled := 0.0
var fly_distance_limit := 0.0
var shots_left := 0
var after_fly := AfterFly.SHOOT
var after_wait := AfterWait.SHOOT
var scatter_timer := 0.0
var scatter_dir := Vector2.RIGHT
## Множители для ослабленных мух (червь и т.п.).
var projectile_speed_factor := 1.0
var projectile_visual_scale := 1.0


func _ready() -> void:
	super._ready()
	deals_melee_damage = false
	knockback_friction += 200.0
	sprite.play("default")


func _apply_level_buffs() -> void:
	move_speed = _scale_move_speed(
		hard_move_speed, MOVE_SPEED_MED_OFFSET, MOVE_SPEED_EASY_OFFSET
	)
	base_hp = _scale_hp(hard_base_hp, HP_MED_OFFSET, HP_EASY_OFFSET)
	damage = _scale_damage(hard_damage, DAMAGE_MED_OFFSET, DAMAGE_EASY_OFFSET)
	projectile_damage = _scale_damage(hard_projectile_damage, DAMAGE_MED_OFFSET, DAMAGE_EASY_OFFSET)
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
	stand_time = hard_stand_time
	fly_time_min = hard_fly_time_min
	fly_time_max = hard_fly_time_max
	min_fly_time = hard_min_fly_time
	super._apply_level_buffs()
	if GameState.level_bufs[2][1]:
		projectile_damage *= 2


func enemy_action() -> void:
	_start_approach_to_shoot()


## Разлёт после спавна: 1с в случайную сторону, потом обычный AI.
func begin_spawn_scatter(duration: float = 1.0, dir: Vector2 = Vector2.ZERO) -> void:
	if dir.length_squared() < 0.01:
		dir = Vector2.RIGHT.rotated(randf() * TAU)
	scatter_dir = dir.normalized()
	scatter_timer = duration
	state = State.SCATTER
	velocity = Vector2.ZERO
	sprite.play("default")


func _custom_physics(delta: float) -> void:
	if scatter_timer > 0.0 or state == State.SCATTER:
		_process_scatter(delta)
		return

	if not active:
		state = State.IDLE
		velocity = Vector2.ZERO
		return

	if state == State.IDLE:
		if cooldown_timer.is_stopped():
			_start_approach_to_shoot()
		else:
			velocity = Vector2.ZERO
		return

	match state:
		State.FLYING:
			_process_flying(delta)
		State.SHOOTING:
			velocity = Vector2.ZERO
			move_and_slide()
		State.WAITING:
			_process_waiting(delta)


func _process_scatter(delta: float) -> void:
	scatter_timer -= delta
	velocity = scatter_dir * move_speed
	sprite.flip_h = scatter_dir.x < 0.0
	move_and_slide()
	if scatter_timer > 0.0:
		return
	velocity = Vector2.ZERO
	state = State.IDLE
	# Если игрок уже в зоне — обычный старт через blind/cooldown.
	if player_in_vision and not active and blind_timer.is_stopped():
		blind_timer.start()


func _start_approach_to_shoot() -> void:
	after_fly = AfterFly.SHOOT
	_start_flying()


func _start_flying() -> void:
	if not player or not active:
		state = State.IDLE
		return
	state = State.FLYING
	fly_timer = randf_range(fly_time_min, fly_time_max)
	fly_elapsed = 0.0
	hover_t = randf() * TAU
	fly_distance_travelled = 0.0
	fly_distance_limit = max_move_distance
	fly_target = player.global_position + Vector2(
		randf_range(-target_offset, target_offset),
		randf_range(-target_offset, target_offset)
	)
	sprite.play("default")


func _process_flying(delta: float) -> void:
	fly_elapsed += delta
	fly_timer -= delta

	var in_range := false
	if player:
		in_range = global_position.distance_to(player.global_position) <= approach_stop_distance

	# Фазу полёта нельзя скипнуть: минимум min_fly_time, даже если уже рядом.
	var can_finish := fly_elapsed >= min_fly_time
	if can_finish and (fly_timer <= 0.0 or fly_distance_travelled >= fly_distance_limit or in_range):
		_on_fly_finished()
		return

	if in_range:
		_process_hover(delta)
		return

	var dir := fly_target - global_position
	if player and dir.length_squared() < 64.0:
		fly_target = player.global_position
		dir = fly_target - global_position

	if dir.length_squared() < 1.0:
		_process_hover(delta)
		return

	dir = dir.normalized()
	velocity = dir * move_speed
	sprite.flip_h = dir.x < 0.0
	var prev := global_position
	move_and_slide()
	fly_distance_travelled += global_position.distance_to(prev)


func _process_hover(delta: float) -> void:
	# Летает на месте / мелкий круг, пока не истечёт min/fly timer.
	hover_t += delta * 6.0
	var hover_dir := Vector2(cos(hover_t), sin(hover_t * 1.35))
	if hover_dir.length_squared() < 0.01:
		hover_dir = Vector2.RIGHT
	velocity = hover_dir.normalized() * move_speed * hover_speed_mult
	if player:
		sprite.flip_h = (player.global_position.x - global_position.x) < 0.0
	move_and_slide()


func _on_fly_finished() -> void:
	velocity = Vector2.ZERO
	match after_fly:
		AfterFly.SHOOT:
			_start_shooting()
		AfterFly.WAIT:
			after_wait = AfterWait.SHOOT
			_start_waiting()


func _start_shooting() -> void:
	if not player or not active:
		state = State.IDLE
		return
	state = State.SHOOTING
	shots_left = shots_per_volley
	velocity = Vector2.ZERO
	_face_player()
	# Только анимация; снаряд — строго по animation_finished.
	_play_shot_anim()


func _face_player() -> void:
	if not player:
		return
	sprite.flip_h = (player.global_position.x - global_position.x) < 0.0


func _play_shot_anim() -> void:
	# Не вызывать stop() — он может мгновенно кинуть animation_finished.
	sprite.animation = &"shot"
	sprite.frame = 0
	sprite.play(&"shot")


func _on_sprite_animation_finished() -> void:
	if sprite.animation == "die":
		super._on_sprite_animation_finished()
		return
	if sprite.animation != "shot" or state != State.SHOOTING or is_dead:
		return
	# Конец shot → выстрел, затем следующий shot или смена фазы.
	_shoot_at_player()
	shots_left -= 1
	if shots_left > 0 and active and not is_dead:
		_face_player()
		_play_shot_anim()
		return
	_begin_post_volley()


func _shoot_at_player() -> void:
	if not player or not active:
		return
	var dir := player.global_position - global_position
	if dir.length_squared() < 1.0:
		return
	_shoot_projectile_scaled(dir)


func _shoot_projectile_scaled(direction: Vector2) -> void:
	if not projectile_scene or direction == Vector2.ZERO:
		return
	var dir := direction.normalized()
	var shot: Node2D = projectile_scene.instantiate()
	shot.global_position = global_position + dir * 12.0
	shot.owner_enemy = self
	shot.setup(
		dir,
		get_projectile_damage(),
		projectile_speed * projectile_speed_factor,
		projectile_range
	)
	if projectile_visual_scale != 1.0:
		shot.scale *= projectile_visual_scale
	get_tree().current_scene.add_child(shot)
	sprite.flip_h = dir.x < 0.0


func _begin_post_volley() -> void:
	if not active or is_dead:
		state = State.IDLE
		return
	# 50%: wait → fly → shoot; 50%: fly → wait → shoot
	if randf() < 0.5:
		after_wait = AfterWait.FLY
		after_fly = AfterFly.SHOOT
		_start_waiting()
	else:
		after_fly = AfterFly.WAIT
		after_wait = AfterWait.SHOOT
		_start_flying()


func _start_waiting() -> void:
	state = State.WAITING
	wait_timer = stand_time
	velocity = Vector2.ZERO
	sprite.play("default")
	_on_stand_started()


## Хук для босса (призыв во время стояния).
func _on_stand_started() -> void:
	pass


func _process_waiting(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	wait_timer -= delta
	if wait_timer > 0.0:
		return
	match after_wait:
		AfterWait.SHOOT:
			_start_shooting()
		AfterWait.FLY:
			after_fly = AfterFly.SHOOT
			_start_flying()

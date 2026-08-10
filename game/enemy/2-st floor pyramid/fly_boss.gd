extends Boss
class_name EnemyFlyBoss

## Босс-муха: тот же паттерн, что у Fly, HP ×3, при стоянии 50% шанс призвать обычную муху.

enum State { IDLE, FLYING, SHOOTING, WAITING }
enum AfterFly { SHOOT, WAIT }
enum AfterWait { SHOOT, FLY }

@export_group("Boss Combat Stats")
@export var boss_projectile_damage: int = 2
@export var boss_projectile_speed: float = 380.0
@export var boss_projectile_range: float = 420.0
@export var projectile_scene: PackedScene = preload("res://game/enemy/projectiles/EnemyShot.tscn")

@export_group("Behavior")
@export var max_move_distance: float = 260.0
@export var fly_time_min: float = 1.2
@export var fly_time_max: float = 2.2
@export var stand_time: float = 1.0
@export var shots_per_volley: int = 5
@export var approach_stop_distance: float = 140.0
@export var target_offset: float = 60.0
@export var min_fly_time: float = 0.55
@export var hover_speed_mult: float = 0.4
@export var summon_chance: float = 0.5
@export var fly_scene: PackedScene = preload("uid://bg8l17bqn1vun")

const SUMMON_OFFSET := 48.0

var projectile_damage: int = 2
var projectile_speed: float = 380.0
var projectile_range: float = 420.0

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
var _spawned_minions: Array[CharacterBody2D] = []


func _ready() -> void:
	BossName = "Big Fly"
	deals_melee_damage = false
	knockback_friction += 200.0
	super._ready()
	sprite.play("default")


func _apply_level_buffs() -> void:
	super._apply_level_buffs()
	projectile_damage = maxi(1, int(round(float(boss_projectile_damage) * Boss_damage_buff)))
	projectile_speed = boss_projectile_speed
	projectile_range = boss_projectile_range
	if GameState.level_bufs[2][1]:
		projectile_damage = maxi(1, projectile_damage * 2)


func get_projectile_damage() -> Vector3i:
	return _build_damage_vector(projectile_damage)


func enemy_action() -> void:
	if not can_act_independently():
		return
	_start_approach_to_shoot()


func _schedule_next_decision() -> void:
	if not can_act_independently():
		return
	if not active or not player_in_vision or is_dead:
		return
	if state != State.IDLE:
		return
	enemy_action()


func _custom_physics(delta: float) -> void:
	if not can_act_independently():
		velocity = Vector2.ZERO
		move_and_slide()
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
	if not player or not active or projectile_scene == null:
		return
	var dir := player.global_position - global_position
	if dir.length_squared() < 1.0:
		return
	dir = dir.normalized()
	var shot: Node2D = projectile_scene.instantiate()
	shot.global_position = global_position + dir * 12.0
	shot.owner_enemy = self
	shot.setup(dir, get_projectile_damage(), projectile_speed, projectile_range)
	get_tree().current_scene.add_child(shot)
	sprite.flip_h = dir.x < 0.0


func _begin_post_volley() -> void:
	if not active or is_dead:
		state = State.IDLE
		return
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
	_try_summon_fly()


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


func _try_summon_fly() -> void:
	if fly_scene == null or randf() >= summon_chance:
		return
	var room := _get_room_node()
	if room and room.has_method("reserve_enemy_slot"):
		room.reserve_enemy_slot()

	var minion: CharacterBody2D = fly_scene.instantiate()
	minion.drop_coin_on_death = false
	if room:
		room.add_child(minion)
		if room.has_method("connect_single_enemy"):
			room.connect_single_enemy(minion, false)
	else:
		get_parent().add_child(minion)

	var side := 1.0 if randf() < 0.5 else -1.0
	minion.global_position = global_position + Vector2(side * SUMMON_OFFSET, randf_range(-24.0, 24.0))
	_register_minion(minion)


func _register_minion(minion: CharacterBody2D) -> void:
	if not is_instance_valid(minion):
		return
	_spawned_minions.append(minion)
	add_collision_exception_with(minion)
	minion.add_collision_exception_with(self)
	for other in _spawned_minions:
		if other != minion and is_instance_valid(other):
			minion.add_collision_exception_with(other)
			other.add_collision_exception_with(minion)


func _get_room_node() -> Node:
	var node: Node = self
	while node:
		if node.has_method("connect_single_enemy"):
			return node
		node = node.get_parent()
	return null

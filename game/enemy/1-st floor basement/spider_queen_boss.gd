extends Boss
class_name EnemySpiderQueenBoss

## Королева-босс не разворачивает спрайт по горизонтали.
const FLIPS_SPRITE_ON_DIRECTION := false

enum State { IDLE, WAIT_IDLE, STEP_MOVE, CHARGE_SHOT, SHOOT, SPAWN_EGG }

@export_group("Boss Combat Stats")
@export var boss_projectile_damage: int = 2
@export var boss_projectile_speed: float = 450.0
@export var boss_projectile_range: float = 850.0
@export var boss_angle_deviation: float = 40.0

@export_group("Behavior")
@export var short_move_time: float = 0.8
@export var wait_idle_time: float = 1.0
@export var shot_charge_time: float = 1.5
@export var spawn_distance_buffer: float = 30.0
@export var projectile_scene: PackedScene = preload("res://game/enemy/projectiles/EnemyShotAlt.tscn")
@export var spider_small_scene: PackedScene = preload("res://game/enemy/1-st floor basement/Spider_small.tscn")

var state: State = State.IDLE
var projectile_damage: int = 2
var projectile_speed: float = 450.0
var projectile_range: float = 850.0
var angle_deviation: float = 40.0
var _step_direction: Vector2 = Vector2.ZERO
var _step_time_elapsed: float = 0.0
var _phase_token: int = 0
var _spawned_minions: Array[CharacterBody2D] = []

@onready var shot_spawn_point: Marker2D = $ShotSpawnPoint
@onready var _minion_spawn_point: Marker2D = get_node_or_null("MinionSpawnPoint") as Marker2D


func _ready() -> void:
	super._ready()
	state = State.IDLE
	sprite.flip_h = FLIPS_SPRITE_ON_DIRECTION
	sprite.play("idle")



func _apply_level_buffs() -> void:
	super._apply_level_buffs()
	projectile_damage = maxi(1, int(round(float(boss_projectile_damage) * Boss_damage_buff)))
	projectile_speed = boss_projectile_speed
	projectile_range = boss_projectile_range
	angle_deviation = boss_angle_deviation
	if GameState.level_bufs[2][1]:
		projectile_damage = maxi(1, projectile_damage * 2)


func _on_field_view_area_body_entered(body: Node2D) -> void:
	super._on_field_view_area_body_entered(body)
	if not body.is_in_group("player"):
		return
	if not can_act_independently():
		return
	if active and state == State.IDLE and cooldown_timer.is_stopped():
		_schedule_next_decision()


func enemy_action() -> void:
	if not can_act_independently():
		return
	if is_dead or not active or not player:
		return
	if state != State.IDLE:
		return

	var roll := randi_range(1, 10)
	if roll <= 2:
		_start_wait_idle()
	elif roll <= 4:
		_start_short_move()
	elif randi() % 2 == 0:
		_start_spawn_egg()
	else:
		_start_shot_sequence()


func _custom_physics(delta: float) -> void:
	match state:
		State.STEP_MOVE:
			_process_step_move(delta)
		_:
			velocity = Vector2.ZERO
			move_and_slide()


func _begin_action(next_state: State) -> void:
	state = next_state
	velocity = Vector2.ZERO
	cooldown_timer.stop()


func _start_wait_idle() -> void:
	_begin_action(State.WAIT_IDLE)
	sprite.play("idle")
	_phase_token += 1
	_finish_wait_idle(_phase_token)


func _finish_wait_idle(token: int) -> void:
	await get_tree().create_timer(wait_idle_time).timeout
	if token != _phase_token or is_dead or not active:
		return
	if state != State.WAIT_IDLE:
		return
	_return_to_idle()


func _start_short_move() -> void:
	_begin_action(State.STEP_MOVE)
	_step_direction = Vector2.RIGHT.rotated(randf() * TAU)
	_step_time_elapsed = 0.0
	velocity = _step_direction * move_speed
	sprite.play("default")


func _process_step_move(delta: float) -> void:
	velocity = _step_direction * move_speed
	move_and_slide()
	_step_time_elapsed += delta

	if _step_time_elapsed >= short_move_time:
		_return_to_idle()


func _start_spawn_egg() -> void:
	_begin_action(State.SPAWN_EGG)
	sprite.play("spawn_egg")


func _start_shot_sequence() -> void:
	_begin_action(State.CHARGE_SHOT)
	sprite.play("shot_charge")
	_phase_token += 1
	_finish_charge_then_shoot(_phase_token)


func _finish_charge_then_shoot(token: int) -> void:
	await get_tree().create_timer(shot_charge_time).timeout
	if token != _phase_token or is_dead or not active:
		return
	if state != State.CHARGE_SHOT:
		return
	state = State.SHOOT
	sprite.play("shot")


func get_projectile_damage() -> Vector3i:
	return _build_damage_vector(projectile_damage)


func _spawn_projectile() -> void:
	var origin := global_position
	if is_instance_valid(shot_spawn_point):
		origin = shot_spawn_point.global_position

	var dir := player.global_position - origin
	if dir.length_squared() < 0.01:
		return
	dir = dir.normalized()

	var shot: Node2D = projectile_scene.instantiate()
	shot.global_position = origin
	shot.owner_enemy = self
	shot.setup(dir, get_projectile_damage(), projectile_speed, projectile_range)
	get_tree().current_scene.call_deferred("add_child", shot)


func _spawn_small_spider() -> void:
	var spawned_spider: CharacterBody2D = spider_small_scene.instantiate()
	spawned_spider.drop_coin_on_death = false

	var room := _get_room_node()
	if room:
		if room.has_method("reserve_enemy_slot"):
			room.reserve_enemy_slot()
		room.add_child(spawned_spider)
		if room.has_method("connect_single_enemy"):
			room.connect_single_enemy(spawned_spider, false)
	else:
		get_parent().add_child(spawned_spider)

	if is_instance_valid(_minion_spawn_point):
		spawned_spider.global_position = _minion_spawn_point.global_position
	else:
		spawned_spider.global_position = global_position
	_register_spawned_minion(spawned_spider)


func _register_spawned_minion(minion: CharacterBody2D) -> void:
	if not is_instance_valid(minion):
		return

	_spawned_minions.append(minion)
	_set_collision_ignored(minion, self)

	for other in _spawned_minions:
		if other != minion and is_instance_valid(other):
			_set_collision_ignored(minion, other)


func _set_collision_ignored(a: CharacterBody2D, b: CharacterBody2D) -> void:
	a.add_collision_exception_with(b)
	b.add_collision_exception_with(a)


func _get_room_node() -> Node:
	var node: Node = self
	while node:
		if node.has_method("connect_single_enemy"):
			return node
		node = node.get_parent()
	return null


## Конец фазы → поза ожидания (idle) → пауза между фазами → ролл следующего шага.
func _return_to_idle() -> void:
	if is_dead:
		return
	state = State.IDLE
	velocity = Vector2.ZERO
	sprite.play("idle")
	_schedule_next_decision()


func _on_sprite_animation_finished() -> void:
	if not can_act_independently():
		if sprite.animation == "die":
			super._on_sprite_animation_finished()
		elif sprite.animation == "spawn_egg":
			_spawn_small_spider()
		elif sprite.animation == "shot":
			_spawn_projectile()
		return

	if sprite.animation == "spawn_egg" and state == State.SPAWN_EGG:
		_spawn_small_spider()
		_return_to_idle()
		return

	if sprite.animation == "shot" and state == State.SHOOT:
		_spawn_projectile()
		_return_to_idle()
		return

	super._on_sprite_animation_finished()

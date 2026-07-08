extends BaseEnemy
class_name EnemySpiderQueen

## Королева не разворачивает спрайт по горизонтали при движении и атаках.
const FLIPS_SPRITE_ON_DIRECTION := false

enum State { IDLE, WAIT_IDLE, STEP_MOVE, CHARGE_SHOT, SHOOT, SPAWN_EGG }

@export_group("Stats")
## Скорость короткого отхода от игрока (с учётом сложности).
@export var hard_move_speed: float = 90.0
@export var hard_base_hp: int = 280
@export var hard_damage: int = 2
@export var hard_cooldown_time: float = 0.8
@export var hard_projectile_speed: float = 340.0
@export var hard_projectile_range: float = 320.0

@export_group("Behavior")
## Длительность короткого отхода от игрока.
@export var short_move_time: float = 0.8
## Разброс направления отхода от линии «от игрока», в градусах.
@export var short_move_angle_spread: float = 30.0
@export var wait_idle_time: float = 1.0
@export var shot_charge_time: float = 1.5
@export var spawn_distance_buffer: float = 50.0
@export var spawn_below_offset: Vector2 = Vector2(0, 84)
@export var projectile_scene: PackedScene = preload("res://game/enemy/projectiles/EnemyShotAlt.tscn")
@export var spider_small_scene: PackedScene = preload("res://game/enemy/1-st floor basement/Spider_small.tscn")

const MOVE_SPEED_MED_OFFSET := -20.0
const MOVE_SPEED_EASY_OFFSET := -40.0
const HP_MED_OFFSET := -40
const HP_EASY_OFFSET := -100
const DAMAGE_MED_OFFSET := 0
const DAMAGE_EASY_OFFSET := -1
const COOLDOWN_MED_OFFSET := 0.25
const COOLDOWN_EASY_OFFSET := 0.45
const PROJECTILE_SPEED_MED_OFFSET := -35.0
const PROJECTILE_SPEED_EASY_OFFSET := -70.0
const PROJECTILE_RANGE_MED_OFFSET := -60.0
const PROJECTILE_RANGE_EASY_OFFSET := -120.0

var state: State = State.IDLE
var projectile_speed: float = 300.0
var projectile_range: float = 450.0
var _step_direction: Vector2 = Vector2.ZERO
var _step_time_elapsed: float = 0.0
var _phase_token: int = 0
var _spawned_minions: Array[CharacterBody2D] = []

@onready var shot_spawn_point: Marker2D = $ShotSpawnPoint


func _apply_difficulty_offset(hard_value: float, med_offset: float, easy_offset: float) -> float:
	match DungeonManager.difficulty:
		"hard":
			return hard_value
		"med":
			return hard_value + med_offset
		_:
			return hard_value + easy_offset


func _ready() -> void:
	deals_melee_damage = false
	super._ready()
	state = State.IDLE
	sprite.flip_h = FLIPS_SPRITE_ON_DIRECTION
	sprite.play("idle")


func _setup_enemy_stats() -> void:
	move_speed = _apply_difficulty_offset(
		hard_move_speed, MOVE_SPEED_MED_OFFSET, MOVE_SPEED_EASY_OFFSET
	) * GameState.enemy_ms_multiplier
	base_hp = int(_apply_difficulty_offset(
		float(hard_base_hp), float(HP_MED_OFFSET), float(HP_EASY_OFFSET)
	) * GameState.enemy_hp_multiplier)
	damage = clampi(int(_apply_difficulty_offset(
		float(hard_damage), float(DAMAGE_MED_OFFSET), float(DAMAGE_EASY_OFFSET)
	) * GameState.enemy_dmg_multiplier), 1, 5)
	cooldown_time = _apply_difficulty_offset(
		hard_cooldown_time, COOLDOWN_MED_OFFSET, COOLDOWN_EASY_OFFSET
	) * GameState.enemy_cooldown_multiplier
	projectile_speed = _apply_difficulty_offset(
		hard_projectile_speed, PROJECTILE_SPEED_MED_OFFSET, PROJECTILE_SPEED_EASY_OFFSET
	)
	projectile_range = _apply_difficulty_offset(
		hard_projectile_range, PROJECTILE_RANGE_MED_OFFSET, PROJECTILE_RANGE_EASY_OFFSET
	)
	super._setup_enemy_stats()


func _on_field_view_area_body_entered(body: Node2D) -> void:
	super._on_field_view_area_body_entered(body)
	if not body.is_in_group("player"):
		return
	if active and state == State.IDLE and cooldown_timer.is_stopped():
		_schedule_next_decision()


func enemy_action() -> void:
	if is_dead or not active or not player:
		return
	if state != State.IDLE:
		return

	var roll := randi_range(1, 10)
	if roll <= 2:
		_start_wait_idle()
	elif roll <= 4:
		_start_short_move()
	else:
		var player_distance := global_position.distance_to(player.global_position)
		if player_distance > projectile_range + spawn_distance_buffer:
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


func _schedule_next_decision() -> void:
	if active and player_in_vision and not is_dead:
		cooldown_timer.start()


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
	if not player:
		_return_to_idle()
		return

	var dir := global_position - player.global_position
	if dir.length_squared() < 0.01:
		_return_to_idle()
		return

	_begin_action(State.STEP_MOVE)
	var base_angle := dir.angle()
	var angle_offset := deg_to_rad(randf_range(-short_move_angle_spread, short_move_angle_spread))
	_step_direction = Vector2.from_angle(base_angle + angle_offset)
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

	_finish_charge_then_shoot()


func _finish_charge_then_shoot() -> void:
	await get_tree().create_timer(shot_charge_time).timeout
	if is_dead or not active:
		return
	if state != State.CHARGE_SHOT:
		return
	state = State.SHOOT
	sprite.play("shot")


func _spawn_projectile() -> void:
	if not projectile_scene or not player:
		return

	var origin := global_position
	if is_instance_valid(shot_spawn_point):
		origin = shot_spawn_point.global_position

	var dir := player.global_position - origin
	if dir.length_squared() < 0.01:
		return
	dir = dir.normalized()

	var shot: Node2D = projectile_scene.instantiate()
	shot.global_position = origin

	if shot is EnemyShot:
		shot.owner_enemy = self
		shot.setup(dir, get_attack_damage(), projectile_speed, projectile_range)
	elif shot.has_method("setup"):
		shot.setup(dir, get_attack_damage(), projectile_speed, projectile_range)
	else:
		var atk := get_attack_damage()
		shot.set("direction", dir)
		shot.set("damage", [atk.x, atk.y, atk.z])
		shot.set("speed", projectile_speed)
		shot.set("atk_range", projectile_range)

	get_tree().current_scene.call_deferred("add_child", shot)


func _spawn_small_spider() -> void:
	if not spider_small_scene:
		return

	var spawned_spider: CharacterBody2D = spider_small_scene.instantiate()
	spawned_spider.global_position = global_position + spawn_below_offset
	spawned_spider.scale = scale
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


func _return_to_idle() -> void:
	if is_dead:
		return
	state = State.IDLE
	velocity = Vector2.ZERO
	sprite.play("idle")
	_schedule_next_decision()


func _on_sprite_animation_finished() -> void:
	if sprite.animation == "spawn_egg" and state == State.SPAWN_EGG:
		_spawn_small_spider()
		_return_to_idle()
		return

	if sprite.animation == "shot" and state == State.SHOOT:
		_spawn_projectile()
		_return_to_idle()
		return

	super._on_sprite_animation_finished()

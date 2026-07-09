class_name BaseEnemy
extends CharacterBody2D

var coin_scene = preload("res://game/objects/coins/Coin.tscn")

@export var move_speed: float = 100.0
var base_move_speed := move_speed
var slow_token: int = 0
var poison: float = 0
var effect_protection: float = 1

@export var cooldown_time: float = 1.5
var base_hp: int = 50 
var damage: int = 1

@export var use_base_move_towards_player: bool = false
@export var use_pathfinding: bool = false
@export var drop_coin_on_death: bool = true
## Расстояние до следующей точки маршрута при непрерывном движении (паук и др.).
## Меньше — точнее на поворотах, больше — плавнее. На рывки червя не влияет.
@export var path_desired_distance: float = 8.0
@export var deals_melee_damage: bool = true
## Останавливать движение, пока враг наносит урон через HitArea (Hog и Aries отключают).
@export var stop_on_melee_hit: bool = true
var base_move_stop_distance: float = 8.0
const NAV_LOCAL_MAX_DISTANCE_SQ := 250.0 * 250.0
const PATHFIND_UPDATE_INTERVAL := 0.25

var _pathfind_cooldown: float = 0.0
var _cached_nav_path: PackedVector2Array = PackedVector2Array()

var player_in_hit_range: bool = false
var player_in_vision: bool = false
var active: bool = false

var current_hp: int
var is_dead: bool = false

@onready var player: Node2D = get_tree().get_first_node_in_group("player")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var animated_speed := GameState.animated_world_speed
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var blind_timer: Timer = $BlindTimer
@onready var poison_timer: Timer = $PoisonTimer

signal _enemy_die(int)

@onready var effect_icons = $EffectAnchor/EffectIcons
var knockback_velocity: Vector2 = Vector2.ZERO
var _navigation_agent: NavigationAgent2D
var damage_flash_token: int = 0
var hitstun: float = 0.0  # Время в секундах паузы движения (0.3-0.5 сек)
@export var knockback_friction: float = 400.0  # Скорость затухания толчка
@export var hitstun_duration: float = 0.2  # Длительность hitstun


func _ready() -> void:
	blind_timer.wait_time = 0.5
	
	_apply_level_buffs()
	
	base_move_speed = move_speed
	current_hp = base_hp
	cooldown_timer.wait_time = cooldown_time

	sprite.animation_finished.connect(_on_sprite_animation_finished)
	sprite.frame = 0
	sprite.speed_scale = animated_speed
	
	player = get_tree().get_first_node_in_group("player")

	if use_pathfinding:
		_setup_pathfinding()


func _physics_process(delta: float) -> void:
	if not active or is_dead:
		return
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	if use_pathfinding and _navigation_agent and player:
		_pathfind_cooldown -= delta
		if _pathfind_cooldown <= 0.0:
			_pathfind_cooldown = PATHFIND_UPDATE_INTERVAL
			_refresh_navigation_path()

	var dealing_melee := _deal_melee_damage_to_player()
	#Отталкивание
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	if hitstun > 0:
		hitstun -= delta
		move_and_slide()
	else:
		knockback_velocity = Vector2.ZERO  # Останавливаем остатки
	velocity += knockback_velocity  # Добавляем knockback к общему velocity
	if hitstun <= 0:
		if dealing_melee and stop_on_melee_hit:
			velocity = Vector2.ZERO
			move_and_slide()
			return

		if use_base_move_towards_player:
			_base_move_towards_player(delta)
			return

		_custom_physics(delta)


func _base_move_towards_player(_delta: float) -> void:
	if not player:
		velocity = Vector2.ZERO
		return

	var dir := get_direction_to_player()
	if dir == Vector2.ZERO:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	velocity = dir * move_speed
	sprite.flip_h = dir.x < 0
	move_and_slide()


func _setup_pathfinding() -> void:
	if _navigation_agent:
		return
	_navigation_agent = NavigationAgent2D.new()
	_navigation_agent.name = "NavigationAgent2D"
	_navigation_agent.path_desired_distance = path_desired_distance
	_navigation_agent.target_desired_distance = base_move_stop_distance
	_navigation_agent.radius = _navigation_agent_radius()
	_navigation_agent.path_max_distance = 4000.0
	_navigation_agent.avoidance_enabled = false
	add_child(_navigation_agent)
	_navigation_agent.target_position = global_position
	_pathfind_cooldown = 0.0

func _navigation_agent_radius() -> float:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision and collision.shape is RectangleShape2D:
		var rect := collision.shape as RectangleShape2D
		var half := rect.size * 0.5 * Vector2(scale.x, scale.y)
		return half.length() + 4.0
	if collision and collision.shape is CircleShape2D:
		var circle := collision.shape as CircleShape2D
		return circle.radius * maxf(scale.x, scale.y) + 4.0
	return 22.0
## path_lookahead > 0 — направление рывка на эту дистанцию вдоль пути (червь).
## path_lookahead == 0 — следующая точка маршрута (паук и др.).
func get_direction_to_player(path_lookahead: float = 0.0) -> Vector2:
	if not player:
		return Vector2.ZERO

	var to_player := player.global_position - global_position
	if to_player.length() <= base_move_stop_distance:
		return Vector2.ZERO

	if not use_pathfinding or not _navigation_agent:
		return to_player.normalized()

	var path := _get_navigation_path_to_player()
	if path.size() < 2:
		return Vector2.ZERO

	if path_lookahead > 0.0:
		var remaining := path_lookahead
		var cursor := global_position
		for i in range(1, path.size()):
			var segment_end: Vector2 = path[i]
			var segment_vec := segment_end - cursor
			var segment_len := segment_vec.length()
			if segment_len < 0.01:
				cursor = segment_end
				continue
			if remaining <= segment_len:
				var aim := cursor + segment_vec.normalized() * remaining
				var dash_dir := aim - global_position
				return dash_dir.normalized() if dash_dir.length_squared() > 0.01 else Vector2.ZERO
			remaining -= segment_len
			cursor = segment_end
		var final_dir := path[path.size() - 1] - global_position
		return final_dir.normalized() if final_dir.length_squared() > 0.01 else Vector2.ZERO

	var target_index := 1
	for i in range(1, path.size()):
		target_index = i
		if global_position.distance_to(path[i]) > path_desired_distance:
			break

	var dir := path[target_index] - global_position
	return dir.normalized() if dir.length_squared() >= 4.0 else Vector2.ZERO


func _get_navigation_path_to_player() -> PackedVector2Array:
	return _cached_nav_path


func _refresh_navigation_path() -> void:
	_cached_nav_path = PackedVector2Array()
	if not player or not _navigation_agent:
		return

	_navigation_agent.target_position = player.global_position

	var map_rid := _navigation_agent.get_navigation_map()
	if map_rid == RID() or NavigationServer2D.map_get_iteration_id(map_rid) == 0:
		return
	var from := NavigationServer2D.map_get_closest_point(map_rid, global_position)
	if from.distance_squared_to(global_position) > NAV_LOCAL_MAX_DISTANCE_SQ:
		return
	var to := NavigationServer2D.map_get_closest_point(map_rid, player.global_position)
	_cached_nav_path = NavigationServer2D.map_get_path(map_rid, from, to, true)


func _apply_difficulty_offset(hard_value: float, med_offset: float, easy_offset: float) -> float:
	match DungeonManager.difficulty:
		"hard":
			return hard_value
		"med":
			return hard_value + med_offset
		_:
			return hard_value + easy_offset


func _scale_hp(hard_hp: int, med_offset: int, easy_offset: int) -> int:
	return int(
		_apply_difficulty_offset(float(hard_hp), float(med_offset), float(easy_offset))
		* GameState.enemy_hp_multiplier
	)

func _scale_damage(
	hard_dmg: int,
	med_offset: int,
	easy_offset: int ) -> int:
	return int(
		_apply_difficulty_offset(float(hard_dmg), float(med_offset), float(easy_offset))
		* GameState.enemy_dmg_multiplier
	)

func _scale_move_speed(hard_speed: float, med_offset: float, easy_offset: float) -> float:
	return _apply_difficulty_offset(hard_speed, med_offset, easy_offset) * GameState.enemy_ms_multiplier

func _scale_cooldown(hard_cd: float, med_offset: float, easy_offset: float) -> float:
	return _apply_difficulty_offset(hard_cd, med_offset, easy_offset) * GameState.enemy_cooldown_multiplier


func _deal_melee_damage_to_player() -> bool:
	if not player_in_hit_range or not deals_melee_damage or not player:
		return false
	var atk := get_attack_damage()
	player.take_damage(atk.x, atk.y, atk.z, self)
	return true


func _apply_level_buffs() -> void: ## apply stats and level buffs
	if GameState.level_bufs[2][1]:  # Deathly
		damage *= 2


func get_attack_damage() -> Vector3i:
	var phy := 0
	var mag := 0
	if GameState.level_bufs[3][1]:
		mag = damage
	else:
		phy = damage
	return Vector3i(phy, mag, 0)


func _custom_physics(_delta: float) -> void:
	velocity = Vector2.ZERO


func enemy_action() -> void:
	pass


func apply_slow(mult: float, duration: float) -> void:
	slow_token += 1
	var my_token := slow_token
	mult = mult - StatManager.get_stat(player, "magic") / 4
	move_speed = base_move_speed * mult

	_add_effect("freeze")
	_reset_slow_later(my_token, duration)

func _reset_slow_later(token: int, duration: float) -> void:
	await get_tree().create_timer(duration).timeout
	if token != slow_token:
		return
	move_speed = base_move_speed
	_remove_effect("freeze")


func apply_poison(effect: float) -> void:
	print('add poison effect: ', poison,' ', effect)
	poison += effect * (1 + StatManager.get_stat(player, 'magic'))
	print(poison)
	
	_add_effect("poison")
	if poison_timer.is_stopped():
		poison_timer.start(2)

func _on_poison_timer_timeout() -> void:
	print('poison dmg ', poison)
	hit(poison, true)
	poison /= 2
	if poison <= 20:
		poison = 0
		_remove_effect("poison")
		poison_timer.stop()
		return
	poison_timer.start(2)
	print('poison now: ', poison, 'hp: ', current_hp)
	

func apply_fire(effect: float, duration: float) -> void:
	print('add fire effect: ', effect)
	if 'fire1' not in active_effects and 'fire0' not in active_effects:
		_add_effect('fire0')
	elif 'fire0' in active_effects:
		_remove_effect('fire0')
		_add_effect('fire1')
		_reset_fire_later(effect, duration)


func _reset_fire_later(effect: float, duration: float) -> void:
	await get_tree().create_timer(duration).timeout
	hit(effect * (StatManager.get_stat(player, 'damage')/20)
				* (1 + StatManager.get_stat(player, 'magic')) /2, true)
	_remove_effect('fire1')
	
func apply_knockback(direction: Vector2, force: float) -> void:
	knockback_velocity = direction.normalized() * force * (1 + StatManager.get_stat(player, 'magic')/4)
	hitstun = hitstun_duration


var active_effects: Array[StringName] = []
func _add_effect(effect: StringName) -> void:
	if not active_effects.has(effect):
		active_effects.append(effect)
	effect_icons.show_effects(active_effects)

func _remove_effect(effect: StringName) -> void:
	active_effects.erase(effect)
	effect_icons.show_effects(active_effects)




# СИГНАЛЫ
func _on_field_view_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_vision = true
		if use_pathfinding:
			_pathfind_cooldown = 0.0
		if blind_timer.is_stopped() and not active:
			blind_timer.start()

func _on_field_view_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_vision = false
		active = false  # не видит игрока и спит
		blind_timer.stop()
		cooldown_timer.stop()
		velocity = Vector2.ZERO

func _on_blind_timer_timeout() -> void:
	if player_in_vision:
		active = true
		if use_pathfinding:
			_pathfind_cooldown = 0.0
		cooldown_timer.start()

func _on_cooldown_timer_timeout() -> void:
	enemy_action()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_hit_range = true

func _on_hit_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_hit_range = false

func hit(amount: float, clear:= false) -> void:
	if is_dead:
		return
	if not clear:
		amount *= effect_protection
	_flash_damage()
	current_hp -= amount
	if current_hp <= 0:
		die()


func _flash_damage() -> void:
	damage_flash_token += 1
	var my_token := damage_flash_token
	sprite.modulate.a = 0.75
	await get_tree().create_timer(0.1).timeout
	if my_token != damage_flash_token or not is_instance_valid(self):
		return
	sprite.modulate.a = 1.0

func die() -> void:
	if is_dead:
		return
	is_dead = true
	active = false
	player_in_vision = false
	velocity = Vector2.ZERO

	$CollisionShape2D.call_deferred("set_disabled", true)
	$HitArea/CollisionShape2D.call_deferred("set_disabled", true)
	$FieldViewArea.hide()
	$HitArea.hide()
	cooldown_timer.stop()
	blind_timer.stop()
	poison_timer.stop()
	sprite.play("die")
	_enemy_die.emit(1)

func _on_sprite_animation_finished() -> void:
	if sprite.animation == "die":
		var luck := 0.0
		if player:
			luck = StatManager.get_stat(player, "luck")
			if drop_coin_on_death and randf() < luck:
				spawn_coin()
		queue_free()
		StatsManager.add_statistic_progress("kills", 1)

func spawn_coin() -> void:
	var coin := coin_scene.instantiate()
	coin.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", coin)

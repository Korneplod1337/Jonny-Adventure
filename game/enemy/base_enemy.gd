class_name BaseEnemy
extends CharacterBody2D

@export var coin_scene: PackedScene

@export var move_speed: float = 100.0
var base_move_speed := move_speed
var slow_token: int = 0
var poison: float = 0
var poison_protection: float = 1

@export var cooldown_time: float = 1.5
@export var base_hp: int = 50
@export var damage: int = 1

@export var use_base_move_towards_player: bool = false
var base_move_stop_distance: float = 8.0

var player_in_hit_range: bool = false
var player_in_vision: bool = false
var active: bool = false

var current_hp: int
var is_dead: bool = false

@onready var player: Node2D = get_tree().get_first_node_in_group("player")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var blind_timer: Timer = $BlindTimer
@onready var poison_timer: Timer = $PoisonTimer

signal _enemy_die(int)

@onready var effect_icons = $EffectAnchor/EffectIcons
var knockback_velocity: Vector2 = Vector2.ZERO
var hitstun: float = 0.0  # Время в секундах паузы движения (0.3-0.5 сек)
@export var knockback_friction: float = 400.0  # Скорость затухания толчка
@export var hitstun_duration: float = 0.2  # Длительность hitstun


func _ready() -> void:
	_setup_enemy_stats()

	base_move_speed = move_speed
	current_hp = base_hp
	cooldown_timer.wait_time = cooldown_time

	sprite.animation_finished.connect(_on_sprite_animation_finished)
	sprite.frame = 0


func _physics_process(delta: float) -> void:
	if not active or is_dead:
		return
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	if player_in_hit_range:
		if GameState.level_bufs[3][1]:
			player.take_damage(0, damage, 0)
		else:
			player.take_damage(damage, 0, 0)
	#Отталкивание
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)
	if hitstun > 0:
		hitstun -= delta
		move_and_slide()
	else:
		knockback_velocity = Vector2.ZERO  # Останавливаем остатки
	velocity += knockback_velocity  # Добавляем knockback к общему velocity
	if hitstun <= 0:
		
		if use_base_move_towards_player:
			_base_move_towards_player(delta)
			return

		_custom_physics(delta)


func _base_move_towards_player(_delta: float) -> void:
	if not player:
		velocity = Vector2.ZERO
		return

	var dir := player.global_position - global_position
	if dir.length() <= base_move_stop_distance:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	dir = dir.normalized()
	velocity = dir * move_speed
	sprite.flip_h = dir.x < 0
	move_and_slide()


func _setup_enemy_stats() -> void:
	if GameState.level_bufs[2][1]:  # Deathly
		damage *= 2


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


func apply_poison(effect: float, damage_low: float) -> void:
	print('add poison effect: ', poison,' ', effect)
	poison += effect * (1 + StatManager.get_stat(player, 'magic'))
	poison_protection = damage_low
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
		poison_protection = 1
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
	print("Knockback applied: ", knockback_velocity)
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
	if not clear:
		if poison > 0:
			amount *= poison_protection
	current_hp -= amount
	if current_hp <= 0:
		die()

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO

	$CollisionShape2D.call_deferred("set_disabled", true)
	$HitArea/CollisionShape2D.call_deferred("set_disabled", true)
	$FieldViewArea.hide()
	$HitArea.hide()
	cooldown_timer.stop()
	blind_timer.stop()
	sprite.play("die")
	_enemy_die.emit(1)

func _on_sprite_animation_finished() -> void:
	if sprite.animation == "die":
		var luck := 0.0
		if player:
			luck = StatManager.get_stat(player, "luck")
			if randf() < luck:
				spawn_coin()
		queue_free()
		StatsManager.add_statistic_progress("kills", 1)

func spawn_coin() -> void:
	var coin := coin_scene.instantiate()
	coin.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", coin)

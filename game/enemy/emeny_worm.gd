extends CharacterBody2D

@export var coin_scene: PackedScene
@export var move_step_distance: float = 100.0
@export var move_speed: float = 100.0
@export var cooldown_time: float = 1.0
@export var base_hp: int = 50
@export var damage: int = 1
@export var dash_curve: Curve

var player_in_hit_range: bool = false
var player_in_vision: bool = false
var active: bool = false

var current_hp: int
var is_dead: bool = false

var dash_distance_travelled: float = 0.0
var target_direction: Vector2 = Vector2.ZERO
var is_dashing: bool = false

@onready var player: Node2D = get_tree().get_first_node_in_group("player")
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var cooldown_timer: Timer = $CooldownTimer
@onready var blind_timer: Timer = $BlindTimer

signal _enemy_die(int)

func _ready() -> void:
	if DungeonManager.difficulty == 'hard':
		move_step_distance = 250  		* GameState.enemy_ms_multiplayer
		move_speed = 300 				* GameState.enemy_ms_multiplayer
		base_hp = 550 					* GameState.enemy_hp_multiplayer
		damage = clampi(4 				* GameState.enemy_dmg_multiplayer, 1, 3)
	elif DungeonManager.difficulty == 'med':
		move_step_distance = 150 		* GameState.enemy_ms_multiplayer
		move_speed = 150 				* GameState.enemy_ms_multiplayer
		base_hp = 50 					* GameState.enemy_hp_multiplayer
		damage = clampi(1 				* GameState.enemy_dmg_multiplayer, 1, 3)
	else:
		pass

	current_hp = base_hp
	cooldown_timer.wait_time = cooldown_time  # РЫВКИ
	
	sprite.animation_finished.connect(_on_sprite_animation_finished)
	sprite.frame = 0

func _physics_process(delta: float) -> void:
	if not active or is_dead:
		return
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return
	if player_in_hit_range:
		player.take_damage(damage, 0, 0)

	# РЫВОК с Curve
	if is_dashing:
		var progress = dash_distance_travelled / move_step_distance  # 0 to 1
		if progress >= 1.0:
			is_dashing = false
			sprite.frame = 0
			dash_distance_travelled = 0.0
			cooldown_timer.start()
			return
	
		var curve_multiplier = dash_curve.sample(progress)
		velocity = target_direction * move_speed * curve_multiplier
		dash_distance_travelled += velocity.length() * delta  # Точно накапливаем дистанцию
		move_and_slide()
		return


func choose_direction_and_dash() -> void:
	var dir = (player.global_position - global_position).normalized()
	if dir.length() == 0: return
	
	target_direction = dir
	sprite.flip_h = target_direction.x < 0
	is_dashing = true
	dash_distance_travelled = 0.0
	sprite.frame = 1
	

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

func _on_blind_timer_timeout() -> void:
	if player_in_vision:
		active = true
		cooldown_timer.start()

func _on_cooldown_timer_timeout() -> void:
	choose_direction_and_dash()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_hit_range = true

func _on_hit_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_hit_range = false

func hit(amount: int) -> void:
	current_hp -= amount
	if current_hp <= 0:
		die()

func die() -> void:
	is_dead = true
	
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
		var luck: float = 0.0
		#if player and player.has_method("get_luck"):
		#	luck = player.get_luck()
		#if randf() < luck:
		spawn_coin()
		queue_free()
		StatsManager.add_statistic_progress('kills', 1) #хуйня переделать


func spawn_coin() -> void:
	var coin := coin_scene.instantiate()
	coin.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", coin)

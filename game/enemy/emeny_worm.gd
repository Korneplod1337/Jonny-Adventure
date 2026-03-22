extends BaseEnemy

@export var move_step_distance: float = 100.0
@export var dash_curve: Curve

var dash_distance_travelled: float = 0.0
var target_direction: Vector2 = Vector2.ZERO
var is_dashing: bool = false


func _setup_enemy_stats() -> void:
	if DungeonManager.difficulty == "hard":
		move_step_distance = 	300 		* GameState.enemy_ms_multiplier
		move_speed = 			250 		* GameState.enemy_ms_multiplier
		base_hp = 				100 		* GameState.enemy_hp_multiplier
		damage = clampi(		1 			* GameState.enemy_dmg_multiplier, 1, 3)
		cooldown_time = 		1.0 			* GameState.enemy_cooldown_multiplier
	elif DungeonManager.difficulty == "med":
		move_step_distance = 	150 		* GameState.enemy_ms_multiplier
		move_speed = 			150 		* GameState.enemy_ms_multiplier
		base_hp = 				60 		* GameState.enemy_hp_multiplier
		damage = clampi(		1 			* GameState.enemy_dmg_multiplier, 1, 3)
		cooldown_time = 		1.0 			* GameState.enemy_cooldown_multiplier
	else:
		base_hp = 				base_hp	* GameState.enemy_hp_multiplier
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

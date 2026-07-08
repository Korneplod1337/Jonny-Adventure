extends EnemySpiderQueen
class_name EnemySpiderQueenBoss


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
	elif randi() % 2 == 0:
		_start_spawn_egg()
	else:
		_start_shot_sequence()


func _start_short_move() -> void:
	_begin_action(State.STEP_MOVE)
	_step_direction = Vector2.RIGHT.rotated(randf() * TAU)
	_step_time_elapsed = 0.0
	velocity = _step_direction * move_speed
	sprite.play("default")

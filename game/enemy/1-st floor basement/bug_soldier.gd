extends EnemyBugGunslinger
class_name EnemyBugSoldier

## Солдат: короткая дробь конусом, во время очереди медленно идёт к игроку.
## Репозишн: отходит и якорится; после якоря не отходит снова, но всегда может подойти.

@export var pellet_count: int = 3
@export var cone_degrees: float = 20.0
@export var pellet_range: float = 220.0
@export var pellet_scale: float = 0.5
@export var firing_move_speed_mult: float = 0.22
@export var pre_walk_afk: float = 1.0


func _ready() -> void:
	shot_interval = 0.75
	super._ready()


func _get_shot_count() -> int:
	return 2


func _get_idle_pause_time() -> float:
	return pre_walk_afk


func _should_refresh_pathfinding() -> bool:
	return state == State.REPOSITION or state == State.FIRING


func _start_hiding() -> void:
	super._start_hiding()
	_invulnerable = true


func _start_pre_fire() -> void:
	super._start_pre_fire()
	_invulnerable = true


func _start_aiming() -> void:
	super._start_aiming()
	_invulnerable = true


func _start_firing() -> void:
	super._start_firing()
	_invulnerable = true


func _start_after_fire() -> void:
	super._start_after_fire()
	# После очереди снова уязвим (showing тоже уязвим у GS).
	_invulnerable = false


func _process_reposition(delta: float) -> void:
	_walk_timer += delta
	if _walk_timer >= max_walk_time:
		_start_hiding()
		return

	var dist := global_position.distance_to(player.global_position)

	# После якоря: если игрок подошёл ближе — стоим, не отходим снова.
	# Если ушёл далеко — всегда можем подойти.
	if _holding_in_range:
		if dist > range_max:
			_holding_in_range = false
			_move_reposition(dist)
		else:
			velocity = Vector2.ZERO
			rotation = 0.0
			if sprite.animation != "idle":
				sprite.play("idle")
			move_and_slide()
		return

	if dist > range_max:
		_move_reposition(dist)
		return

	if dist < range_min:
		_move_reposition(dist)
		return

	# В диапазоне — якорь «отошёл и остановился».
	_holding_in_range = true
	velocity = Vector2.ZERO
	rotation = 0.0
	if sprite.animation != "idle":
		sprite.play("idle")
	move_and_slide()


func _refresh_navigation_path() -> void:
	if not _should_refresh_pathfinding() or not player or not _navigation_agent:
		_cached_nav_path = PackedVector2Array()
		return

	if state == State.FIRING:
		_refresh_path_to_player()
		return

	var dist := global_position.distance_to(player.global_position)
	# После якоря pathfinding только на сближение, не на отход.
	if _holding_in_range and dist <= range_max:
		_cached_nav_path = PackedVector2Array()
		return

	if dist < range_min and not _holding_in_range:
		var away := (global_position - player.global_position).normalized()
		if away == Vector2.ZERO:
			away = Vector2.RIGHT
		_set_nav_path_to(global_position + away * 280.0)
	else:
		_refresh_path_to_player()


func _shoot_volley(facing_dir: Vector2) -> void:
	var base := facing_dir.normalized()
	if base == Vector2.ZERO:
		base = Vector2.UP.rotated(rotation)
	var half := deg_to_rad(cone_degrees * 0.5)
	for i in pellet_count:
		var t := 0.0 if pellet_count <= 1 else float(i) / float(pellet_count - 1)
		var ang := lerpf(-half, half, t)
		var dir := base.rotated(ang)
		_shoot_without_flip(dir, projectile_speed, pellet_range, pellet_scale)


func _apply_firing_velocity(_delta: float) -> void:
	if not player:
		velocity = Vector2.ZERO
		return
	var dir := get_direction_to_player()
	if dir == Vector2.ZERO:
		dir = (player.global_position - global_position).normalized()
	velocity = dir * move_speed * firing_move_speed_mult

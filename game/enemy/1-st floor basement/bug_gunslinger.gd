extends EnemyRanger
class_name EnemyBugGunslinger

enum State {
	IDLE,
	REPOSITION,
	HIDING,
	PRE_FIRE,
	AIMING,
	FIRING,
	AFTER_FIRE,
	SHOWING,
}

@export_group("Hard Stats")
@export var hard_move_speed: float = 170.0
@export var hard_base_hp: int = 200
@export var hard_damage: int = 1
@export var hard_cooldown_time: float = 1.0
@export var hard_projectile_speed: float = 300.0
@export var hard_projectile_range: float = 600.0
@export var max_turn_speed: float = 3.0 ## рад/сек, калибровка

@export_group("Spacing")
@export var range_min: float = 220.0
@export var range_max: float = 340.0
@export var max_walk_time: float = 2.0
@export var aim_time: float = 0.5
@export var shot_interval: float = 0.5
@export var after_fire_rotate_time: float = 0.5
@export var hard_idle_after_showing: float = 1.5

const MOVE_SPEED_MED_OFFSET := -20.0
const MOVE_SPEED_EASY_OFFSET := -40.0
const HP_MED_OFFSET := -50
const HP_EASY_OFFSET := -100
const DAMAGE_MED_OFFSET := 0
const DAMAGE_EASY_OFFSET := 0
const COOLDOWN_MED_OFFSET := 0.0
const COOLDOWN_EASY_OFFSET := 0.0
const PROJECTILE_SPEED_MED_OFFSET := -50.0
const PROJECTILE_SPEED_EASY_OFFSET := -100.0
const PROJECTILE_RANGE_MED_OFFSET := -50.0
const PROJECTILE_RANGE_EASY_OFFSET := -100.0
const IDLE_MED_OFFSET := 0.5
const IDLE_EASY_OFFSET := 0.5

var state := State.IDLE
var _invulnerable := false
var _walk_timer := 0.0
var _holding_in_range := false
var _phase_timer := 0.0
var _shots_left := 0
var _shot_timer := 0.0
var _idle_after_showing := 1.0
var _max_shots := 5
var _hit_area: Area2D
var _rotate_tween: Tween


func _ready() -> void:
	use_pathfinding = true
	stop_on_melee_hit = false
	melee_hit_cooldown = 1.0
	super._ready()
	_hit_area = $HitArea as Area2D
	sprite.flip_h = false
	sprite.play("idle")
	state = State.IDLE


func _apply_level_buffs() -> void:
	move_speed = _scale_move_speed(
		hard_move_speed, MOVE_SPEED_MED_OFFSET, MOVE_SPEED_EASY_OFFSET
	)
	base_hp = _scale_hp(hard_base_hp, HP_MED_OFFSET, HP_EASY_OFFSET)
	damage = _scale_damage(hard_damage, DAMAGE_MED_OFFSET, DAMAGE_EASY_OFFSET)
	projectile_damage = _scale_damage(
		hard_projectile_damage, DAMAGE_MED_OFFSET, DAMAGE_EASY_OFFSET
	)
	cooldown_time = _scale_cooldown(
		hard_cooldown_time, COOLDOWN_MED_OFFSET, COOLDOWN_EASY_OFFSET
	)
	projectile_speed = _apply_difficulty_offset(
		hard_projectile_speed, PROJECTILE_SPEED_MED_OFFSET, PROJECTILE_SPEED_EASY_OFFSET
	)
	projectile_range = _apply_difficulty_offset(
		hard_projectile_range, PROJECTILE_RANGE_MED_OFFSET, PROJECTILE_RANGE_EASY_OFFSET
	)
	_idle_after_showing = _apply_difficulty_offset(
		hard_idle_after_showing, IDLE_MED_OFFSET, IDLE_EASY_OFFSET
	)
	match DungeonManager.difficulty:
		"hard":
			_max_shots = 5
		"med":
			_max_shots = 4
		_:
			_max_shots = 3

	super._apply_level_buffs()
	if GameState.level_bufs[2][1]:
		projectile_damage *= 2


func _on_blind_timer_timeout() -> void:
	super._on_blind_timer_timeout()
	if active and state == State.IDLE:
		_start_reposition()


func _on_field_view_area_body_exited(body: Node2D) -> void:
	super._on_field_view_area_body_exited(body)
	if body.is_in_group("player") and not player_in_vision:
		_abort_to_idle()


func _abort_to_idle() -> void:
	_kill_rotate_tween()
	rotation = 0.0
	_invulnerable = false
	_holding_in_range = false
	_set_hit_area_enabled(true)
	velocity = Vector2.ZERO
	state = State.IDLE
	_phase_timer = 0.0
	if not is_dead:
		sprite.play("idle")


func enemy_action() -> void:
	pass


func _custom_physics(delta: float) -> void:
	if not active or is_dead or not player:
		velocity = Vector2.ZERO
		return

	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_start_reposition()
		State.REPOSITION:
			_process_reposition(delta)
		State.HIDING, State.AFTER_FIRE, State.SHOWING:
			velocity = Vector2.ZERO
			move_and_slide()
		State.PRE_FIRE:
			velocity = Vector2.ZERO
			if _rotates_during_pre_fire():
				_rotate_toward_player(delta)
			move_and_slide()
		State.AIMING:
			velocity = Vector2.ZERO
			_rotate_toward_player(delta)
			_phase_timer -= delta
			if _phase_timer <= 0.0:
				_start_firing()
			move_and_slide()
		State.FIRING:
			_rotate_toward_player(delta)
			_process_firing(delta)
			_apply_firing_velocity(delta)
			var prev_pos := global_position
			move_and_slide()
			_after_firing_move(prev_pos)


func _process_reposition(delta: float) -> void:
	_walk_timer += delta
	if _walk_timer >= max_walk_time:
		_start_hiding()
		return

	var dist := global_position.distance_to(player.global_position)

	# Уже был в диапазоне: подойти ближе нельзя, но отбежать от наезда — можно.
	if _holding_in_range:
		if dist < range_min:
			_move_reposition(dist)
		else:
			velocity = Vector2.ZERO
			rotation = 0.0
			if sprite.animation != "idle":
				sprite.play("idle")
			move_and_slide()
		return

	if dist >= range_min and dist <= range_max:
		_holding_in_range = true
		velocity = Vector2.ZERO
		rotation = 0.0
		sprite.play("idle")
		move_and_slide()
		return

	_move_reposition(dist)


func _move_reposition(dist: float) -> void:
	var dir := get_direction_to_player()
	if dir == Vector2.ZERO:
		if dist < range_min:
			dir = (global_position - player.global_position).normalized()
		else:
			dir = (player.global_position - global_position).normalized()

	velocity = dir * move_speed
	rotation = 0.0
	sprite.flip_h = false
	if sprite.animation != "default":
		sprite.play("default")
	move_and_slide()


func _process_firing(delta: float) -> void:
	_shot_timer -= delta
	if _shot_timer > 0.0:
		return
	if _shots_left <= 0:
		_start_after_fire()
		return
	_fire_one_shot()
	_shots_left -= 1
	_shot_timer = shot_interval
	# after-fire только после паузы interval — иначе отдача последнего выстрела сразу сбрасывается


func _get_shot_count() -> int:
	return randi_range(2, _max_shots)


func _get_idle_pause_time() -> float:
	return _idle_after_showing


func _rotates_during_pre_fire() -> bool:
	return false


func _fire_one_shot() -> void:
	_restart_fire_animation()
	var dir := Vector2.UP.rotated(rotation)
	_shoot_volley(dir)
	_on_shot_fired(dir)


## Один снаряд в направлении взгляда. Наследники могут стрелять дробью.
func _shoot_volley(facing_dir: Vector2) -> void:
	_shoot_without_flip(facing_dir)


func _on_shot_fired(_facing_dir: Vector2) -> void:
	pass


func _apply_firing_velocity(_delta: float) -> void:
	velocity = Vector2.ZERO


func _after_firing_move(_prev_pos: Vector2) -> void:
	pass


func _should_refresh_pathfinding() -> bool:
	return state == State.REPOSITION


func _restart_fire_animation() -> void:
	sprite.stop()
	sprite.play("fire")
	sprite.frame = 0


func _shoot_without_flip(direction: Vector2, spd: float = -1.0, atk_rng: float = -1.0, shot_scale: float = 1.0) -> void:
	if not projectile_scene or direction == Vector2.ZERO:
		return
	var shot: Node2D = projectile_scene.instantiate()
	var dir := direction.normalized()
	shot.global_position = global_position + dir * 12.0
	shot.owner_enemy = self
	var use_speed := projectile_speed if spd < 0.0 else spd
	var use_range := projectile_range if atk_rng < 0.0 else atk_rng
	shot.setup(dir, get_projectile_damage(), use_speed, use_range)
	if shot_scale != 1.0:
		shot.scale = Vector2(shot_scale, shot_scale)
	get_tree().current_scene.add_child(shot)


func _rotate_toward_player(delta: float) -> void:
	if not player:
		return
	var dir := player.global_position - global_position
	if dir.length_squared() < 0.01:
		return
	# Local "up" (Vector2.UP) faces the player.
	var target_rot := dir.angle() + PI * 0.5
	rotation = rotate_toward(rotation, target_rot, max_turn_speed * delta)


func _refresh_navigation_path() -> void:
	if not _should_refresh_pathfinding() or not player or not _navigation_agent:
		_cached_nav_path = PackedVector2Array()
		return

	if state == State.FIRING:
		_refresh_path_to_player()
		return

	var dist := global_position.distance_to(player.global_position)
	# После якоря pathfinding только на отход, не на сближение.
	if _holding_in_range and dist >= range_min:
		_cached_nav_path = PackedVector2Array()
		return

	_cached_nav_path = PackedVector2Array()
	var target: Vector2
	if dist < range_min:
		var away := (global_position - player.global_position).normalized()
		if away == Vector2.ZERO:
			away = Vector2.RIGHT
		target = global_position + away * 280.0
	elif _holding_in_range:
		_cached_nav_path = PackedVector2Array()
		return
	else:
		target = player.global_position

	_set_nav_path_to(target)


func _refresh_path_to_player() -> void:
	_set_nav_path_to(player.global_position)


func _set_nav_path_to(target: Vector2) -> void:
	_cached_nav_path = PackedVector2Array()
	_navigation_agent.target_position = target
	var map_rid := _navigation_agent.get_navigation_map()
	if map_rid == RID() or NavigationServer2D.map_get_iteration_id(map_rid) == 0:
		return
	var from := NavigationServer2D.map_get_closest_point(map_rid, global_position)
	if from.distance_squared_to(global_position) > NAV_LOCAL_MAX_DISTANCE_SQ:
		return
	var to := NavigationServer2D.map_get_closest_point(map_rid, target)
	_cached_nav_path = NavigationServer2D.map_get_path(map_rid, from, to, true)


func _set_hit_area_enabled(enabled: bool) -> void:
	if _hit_area == null:
		return
	_hit_area.monitoring = enabled
	if not enabled:
		player_in_hit_range = false
	else:
		call_deferred("_sync_hit_range")


func _sync_hit_range() -> void:
	if _hit_area == null or not _hit_area.monitoring or is_dead:
		return
	player_in_hit_range = false
	for body in _hit_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			player_in_hit_range = true
			break


func _start_reposition() -> void:
	if is_dead:
		return
	_kill_rotate_tween()
	rotation = 0.0
	state = State.REPOSITION
	_invulnerable = false
	_walk_timer = 0.0
	_holding_in_range = false
	_pathfind_cooldown = 0.0
	_set_hit_area_enabled(true)
	sprite.flip_h = false
	sprite.play("default")


func _start_hiding() -> void:
	if is_dead:
		return
	state = State.HIDING
	velocity = Vector2.ZERO
	_set_hit_area_enabled(false)
	# Still vulnerable during hiding.
	_invulnerable = false
	rotation = 0.0
	sprite.play("hiding")


func _start_pre_fire() -> void:
	if is_dead:
		return
	state = State.PRE_FIRE
	_invulnerable = true
	sprite.play("pre-fire")


func _start_aiming() -> void:
	if is_dead:
		return
	state = State.AIMING
	_invulnerable = true
	_phase_timer = aim_time


func _start_firing() -> void:
	if is_dead:
		return
	state = State.FIRING
	_invulnerable = true
	_shots_left = _get_shot_count()
	_shot_timer = 0.0
	_pathfind_cooldown = 0.0
	_process_firing(0.0)


func _start_after_fire() -> void:
	if is_dead:
		return
	state = State.AFTER_FIRE
	_invulnerable = true
	sprite.play("after-fire")
	_kill_rotate_tween()
	_rotate_tween = create_tween()
	_rotate_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_rotate_tween.tween_property(self, "rotation", 0.0, after_fire_rotate_time)


func _start_showing() -> void:
	if is_dead:
		return
	_kill_rotate_tween()
	rotation = 0.0
	state = State.SHOWING
	# Vulnerable again during showing.
	_invulnerable = false
	sprite.play("showing")


func _start_idle_pause() -> void:
	if is_dead:
		return
	_kill_rotate_tween()
	rotation = 0.0
	state = State.IDLE
	_invulnerable = false
	_set_hit_area_enabled(true)
	_phase_timer = _get_idle_pause_time()
	sprite.play("idle")


func _kill_rotate_tween() -> void:
	if _rotate_tween and _rotate_tween.is_valid():
		_rotate_tween.kill()
	_rotate_tween = null


func hit(amount: float, clear := false) -> void:
	if is_dead:
		return
	if _invulnerable:
		return
	super.hit(amount, clear)


func die() -> void:
	_kill_rotate_tween()
	_invulnerable = false
	_set_hit_area_enabled(false)
	super.die()


func _on_sprite_animation_finished() -> void:
	if is_dead or sprite.animation == "die":
		super._on_sprite_animation_finished()
		return

	match sprite.animation:
		"hiding":
			_start_pre_fire()
		"pre-fire":
			_start_aiming()
		"after-fire":
			_start_showing()
		"showing":
			_start_idle_pause()
		"fire":
			pass

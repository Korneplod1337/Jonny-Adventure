extends Boss
class_name EnemyBugShifterBoss

## Bugshifter: 3 фазы (Sniper → Soldier → Gunslinger). Логика жуков продублирована в Boss.

enum Form { SNIPER, SOLDIER, GUNSLINGER }
enum State {
	IDLE,
	REPOSITION,
	HIDING,
	PRE_FIRE,
	AIMING,
	FIRING,
	AFTER_FIRE,
	SHOWING,
	TRANSFORMING,
}

const SCN_SNIPER := preload("res://game/enemy/1-st floor basement/Bug_sniper.tscn")
const SCN_SOLDIER := preload("res://game/enemy/1-st floor basement/Bug_soldier.tscn")
const SCN_GUNSLINGER := preload("res://game/enemy/1-st floor basement/Bug_gunslinger.tscn")
const PROJECTILE_SCENE := preload("res://game/enemy/projectiles/EnemyShot.tscn")

const PHASE1_HP := 150
const PHASE2_HP := 300
const PHASE3_HP := 300
const PHASE1_MOVE_SPEED := 200.0
const PHASE23_SPEED_MULT := 1.25
const BASE_BUG_MOVE_SPEED := 170.0
const RETREAT_RANGE_DIV := 3.0
const TRANSFORM_TIME := 2.0
const TRANSFORM_SPINS := 3.0
const SWAP_CHANCE := 0.25
const SWAP_IFRAME := 0.2
const WALL_MASK := 16 | 32
const NUDGE_MARGIN := 48.0

@export var max_turn_speed: float = 3.0
@export var max_walk_time: float = 2.0
@export var aim_time: float = 0.5
@export var after_fire_rotate_time: float = 0.5
@export var recoil_distance: float = 30.0
@export var recoil_duration: float = 0.12
@export var pellet_count: int = 3
@export var cone_degrees: float = 20.0
@export var pellet_range: float = 220.0
@export var pellet_scale: float = 0.5
@export var firing_move_speed_mult: float = 0.22
@export var pre_walk_afk: float = 1.0

var form := Form.SNIPER
var state := State.IDLE
var projectile_scene: PackedScene = PROJECTILE_SCENE
var projectile_damage: int = 1
var projectile_speed: float = 400.0
var projectile_range: float = 600.0
var range_min: float = 220.0
var range_max: float = 340.0
var shot_interval: float = 0.5
var hard_idle_after_showing: float = 1.5

var _frames_sniper: SpriteFrames
var _frames_soldier: SpriteFrames
var _frames_gunslinger: SpriteFrames
var _combat_invulnerable := false
var _swap_invulnerable := false
var _phase_transforming := false
var _walk_timer := 0.0
var _holding_in_range := false
var _phase_timer := 0.0
var _shots_left := 0
var _shot_timer := 0.0
var _idle_after_showing := 1.0
var _max_shots := 5
var _recoil_dir := Vector2.ZERO
var _recoil_left := 0.0
var _recoil_speed := 0.0
var _rotate_tween: Tween
var _spin_tween: Tween
var _hit_area: Area2D


func _ready() -> void:
	BossName = "Bugshifter"
	use_pathfinding = true
	stop_on_melee_hit = false
	melee_hit_cooldown = 1.0
	deals_melee_damage = true
	_frames_sniper = _extract_frames(SCN_SNIPER)
	_frames_soldier = _extract_frames(SCN_SOLDIER)
	_frames_gunslinger = _extract_frames(SCN_GUNSLINGER)
	super._ready()
	_hit_area = $HitArea as Area2D
	_apply_form(Form.SNIPER, true)
	sprite.flip_h = false
	sprite.play("idle")
	state = State.IDLE


func _extract_frames(scn: PackedScene) -> SpriteFrames:
	var node := scn.instantiate()
	var spr := node.get_node("AnimatedSprite2D") as AnimatedSprite2D
	var frames: SpriteFrames = spr.sprite_frames.duplicate(true)
	node.free()
	return frames


func _apply_level_buffs() -> void:
	# Статы фаз задаёт _apply_form; здесь только базовый урон снаряда.
	super._apply_level_buffs()
	_refresh_projectile_damage()


func _refresh_projectile_damage() -> void:
	var base_dmg := 2 if form == Form.SNIPER else 1
	projectile_damage = maxi(1, int(round(float(base_dmg) * Boss_damage_buff)))
	if GameState.level_bufs[2][1]:
		projectile_damage = maxi(1, projectile_damage * 2)


func get_projectile_damage() -> Vector3i:
	return _build_damage_vector(projectile_damage)


func _schedule_next_decision() -> void:
	pass


func _on_cooldown_timer_timeout() -> void:
	pass


func enemy_action() -> void:
	pass


func _apply_form(next: Form, initial: bool = false) -> void:
	form = next
	var phase_hp := PHASE1_HP
	match form:
		Form.SNIPER:
			phase_hp = PHASE1_HP
			move_speed = PHASE1_MOVE_SPEED * Boss_move_speed_buff
			range_min = 300.0 / RETREAT_RANGE_DIV
			range_max = 600.0 / RETREAT_RANGE_DIV
			shot_interval = 1.0
			projectile_speed = 600.0
			projectile_range = 1000.0
			hard_idle_after_showing = 1.5
			_max_shots = 3
			pellet_count = 3
			cone_degrees = 30.0
			if _frames_sniper:
				sprite.sprite_frames = _frames_sniper
		Form.SOLDIER:
			phase_hp = PHASE2_HP
			move_speed = BASE_BUG_MOVE_SPEED * PHASE23_SPEED_MULT * Boss_move_speed_buff
			# Почти вплотную к игроку.
			range_min = 24.0
			range_max = 72.0
			shot_interval = 0.75
			projectile_speed = 400.0
			projectile_range = 600.0
			hard_idle_after_showing = pre_walk_afk
			_max_shots = 3
			pellet_count = 3
			cone_degrees = 20.0
			if _frames_soldier:
				sprite.sprite_frames = _frames_soldier
		Form.GUNSLINGER:
			phase_hp = PHASE3_HP
			move_speed = BASE_BUG_MOVE_SPEED * PHASE23_SPEED_MULT * Boss_move_speed_buff
			range_min = 220.0 / RETREAT_RANGE_DIV
			range_max = 340.0 / RETREAT_RANGE_DIV
			shot_interval = 0.5
			projectile_speed = 400.0
			projectile_range = 600.0
			hard_idle_after_showing = 1.5
			_max_shots = 6
			pellet_count = 3
			cone_degrees = 45.0
			if _frames_gunslinger:
				sprite.sprite_frames = _frames_gunslinger

	boss_base_hp = phase_hp
	base_hp = int(round(float(phase_hp) * Boss_HP_buff * GameState.boss_hp_multiplier))
	current_hp = base_hp
	damage = maxi(1, int(round(1.0 * Boss_damage_buff)))
	base_move_speed = move_speed
	_idle_after_showing = hard_idle_after_showing
	_refresh_projectile_damage()
	if not initial:
		sprite.play("idle")


func _on_blind_timer_timeout() -> void:
	if not can_act_independently():
		if player_in_vision:
			active = true
		return
	if player_in_vision:
		active = true
		if state == State.IDLE and not _phase_transforming:
			_start_reposition()


func _on_field_view_area_body_exited(body: Node2D) -> void:
	super._on_field_view_area_body_exited(body)
	if body.is_in_group("player") and not player_in_vision:
		_abort_to_idle()


func _abort_to_idle() -> void:
	if _phase_transforming:
		return
	_kill_rotate_tween()
	rotation = 0.0
	_combat_invulnerable = false
	_holding_in_range = false
	_recoil_left = 0.0
	_set_hit_area_enabled(true)
	velocity = Vector2.ZERO
	state = State.IDLE
	_phase_timer = 0.0
	if not is_dead:
		sprite.play("idle")


func _custom_physics(delta: float) -> void:
	if not can_act_independently() or not active or is_dead or not player:
		velocity = Vector2.ZERO
		if state == State.TRANSFORMING:
			move_and_slide()
		return

	match state:
		State.TRANSFORMING:
			velocity = Vector2.ZERO
			move_and_slide()
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
			if form == Form.SNIPER:
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
			var prev := global_position
			move_and_slide()
			_after_firing_move(prev)


func _process_reposition(delta: float) -> void:
	_walk_timer += delta
	if _walk_timer >= max_walk_time:
		_start_hiding()
		return

	var dist := global_position.distance_to(player.global_position)
	if form == Form.SOLDIER:
		_process_reposition_soldier(dist)
	else:
		_process_reposition_default(dist)


func _process_reposition_default(dist: float) -> void:
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


func _process_reposition_soldier(dist: float) -> void:
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
	if dist > range_max or dist < range_min:
		_move_reposition(dist)
		return
	_holding_in_range = true
	velocity = Vector2.ZERO
	rotation = 0.0
	if sprite.animation != "idle":
		sprite.play("idle")
	move_and_slide()


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


func _fire_one_shot() -> void:
	_restart_fire_animation()
	var dir := Vector2.UP.rotated(rotation)
	_shoot_volley(dir)
	if form == Form.SNIPER:
		_recoil_dir = -dir.normalized()
		if _recoil_dir == Vector2.ZERO:
			_recoil_dir = Vector2.DOWN
		_recoil_left = recoil_distance
		_recoil_speed = recoil_distance / maxf(recoil_duration, 0.01)


func _shoot_volley(facing_dir: Vector2) -> void:
	var base := facing_dir.normalized()
	if base == Vector2.ZERO:
		base = Vector2.UP.rotated(rotation)

	# Все фазы босса: конус из pellet_count пуль.
	var half := deg_to_rad(cone_degrees * 0.5)
	var shot_range := pellet_range if form == Form.SOLDIER else projectile_range
	var shot_scale := pellet_scale if form == Form.SOLDIER else 1.0
	for i in pellet_count:
		var t := 0.0 if pellet_count <= 1 else float(i) / float(pellet_count - 1)
		var ang := lerpf(-half, half, t)
		_shoot_without_flip(base.rotated(ang), projectile_speed, shot_range, shot_scale)


func _shoot_without_flip(
	direction: Vector2, spd: float = -1.0, atk_rng: float = -1.0, shot_scale: float = 1.0
) -> void:
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


func _apply_firing_velocity(_delta: float) -> void:
	match form:
		Form.SNIPER:
			if _recoil_left <= 0.0:
				velocity = Vector2.ZERO
			else:
				velocity = _recoil_dir * _recoil_speed
		Form.SOLDIER:
			if not player:
				velocity = Vector2.ZERO
				return
			var dir := get_direction_to_player()
			if dir == Vector2.ZERO:
				dir = (player.global_position - global_position).normalized()
			velocity = dir * move_speed * firing_move_speed_mult
		_:
			velocity = Vector2.ZERO


func _after_firing_move(prev_pos: Vector2) -> void:
	if form != Form.SNIPER or _recoil_left <= 0.0:
		return
	var moved := global_position.distance_to(prev_pos)
	_recoil_left = maxf(0.0, _recoil_left - moved)
	if _recoil_left <= 0.0:
		velocity = Vector2.ZERO


func _rotate_toward_player(delta: float) -> void:
	if not player:
		return
	var dir := player.global_position - global_position
	if dir.length_squared() < 0.01:
		return
	var target_rot := dir.angle() + PI * 0.5
	rotation = rotate_toward(rotation, target_rot, max_turn_speed * delta)


func _should_refresh_pathfinding() -> bool:
	if form == Form.SOLDIER:
		return state == State.REPOSITION or state == State.FIRING
	return state == State.REPOSITION


func _refresh_navigation_path() -> void:
	if not _should_refresh_pathfinding() or not player or not _navigation_agent:
		_cached_nav_path = PackedVector2Array()
		return
	if state == State.FIRING:
		_set_nav_path_to(player.global_position)
		return
	var dist := global_position.distance_to(player.global_position)
	if form == Form.SOLDIER:
		if _holding_in_range and dist <= range_max:
			_cached_nav_path = PackedVector2Array()
			return
		if dist < range_min and not _holding_in_range:
			var away := (global_position - player.global_position).normalized()
			if away == Vector2.ZERO:
				away = Vector2.RIGHT
			_set_nav_path_to(global_position + away * 280.0)
		else:
			_set_nav_path_to(player.global_position)
		return
	if _holding_in_range and dist >= range_min:
		_cached_nav_path = PackedVector2Array()
		return
	if dist < range_min:
		var away2 := (global_position - player.global_position).normalized()
		if away2 == Vector2.ZERO:
			away2 = Vector2.RIGHT
		_set_nav_path_to(global_position + away2 * 280.0)
	elif _holding_in_range:
		_cached_nav_path = PackedVector2Array()
	else:
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
	if is_dead or _phase_transforming:
		return
	_kill_rotate_tween()
	rotation = 0.0
	state = State.REPOSITION
	_combat_invulnerable = false
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
	_combat_invulnerable = form == Form.SOLDIER
	rotation = 0.0
	sprite.play("hiding")


func _start_pre_fire() -> void:
	if is_dead:
		return
	_try_swap_with_player()
	state = State.PRE_FIRE
	_combat_invulnerable = true
	sprite.play("pre-fire")


func _start_aiming() -> void:
	if is_dead:
		return
	state = State.AIMING
	_combat_invulnerable = true
	_phase_timer = aim_time


func _start_firing() -> void:
	if is_dead:
		return
	state = State.FIRING
	_combat_invulnerable = true
	if form == Form.GUNSLINGER:
		_shots_left = randi_range(3, _max_shots)
	else:
		_shots_left = _max_shots
	_shot_timer = 0.0
	_pathfind_cooldown = 0.0
	_process_firing(0.0)


func _start_after_fire() -> void:
	if is_dead:
		return
	_recoil_left = 0.0
	velocity = Vector2.ZERO
	state = State.AFTER_FIRE
	# Soldier уязвим после очереди; sniper/gunslinger — до showing.
	_combat_invulnerable = form != Form.SOLDIER
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
	_combat_invulnerable = false
	sprite.play("showing")


func _start_idle_pause() -> void:
	if is_dead:
		return
	_kill_rotate_tween()
	rotation = 0.0
	state = State.IDLE
	_combat_invulnerable = false
	_set_hit_area_enabled(true)
	_phase_timer = _idle_after_showing
	sprite.play("idle")


func _restart_fire_animation() -> void:
	sprite.stop()
	sprite.play("fire")
	sprite.frame = 0


func _kill_rotate_tween() -> void:
	if _rotate_tween and _rotate_tween.is_valid():
		_rotate_tween.kill()
	_rotate_tween = null


func _try_swap_with_player() -> void:
	if randf() >= SWAP_CHANCE or not is_instance_valid(player):
		return
	var boss_pos := global_position
	var player_pos := player.global_position
	global_position = _nudge_toward_room_center(player_pos)
	player.global_position = _nudge_toward_room_center(boss_pos)
	_grant_swap_iframes()


func _grant_swap_iframes() -> void:
	_swap_invulnerable = true
	if is_instance_valid(player):
		player.invulnerable = true
	await get_tree().create_timer(SWAP_IFRAME).timeout
	_swap_invulnerable = false
	if is_instance_valid(player) and player.imuneTimer.is_stopped():
		player.invulnerable = false


func _get_room_center() -> Vector2:
	var room: Node = self
	while room:
		var bounds := room.get_node_or_null("CameraBounds") as Area2D
		if bounds:
			return bounds.global_position
		room = room.get_parent()
	return global_position


func _nudge_toward_room_center(pos: Vector2) -> Vector2:
	var center := _get_room_center()
	var result := pos
	if not _position_blocked(result):
		return result
	for _i in 16:
		result = result.lerp(center, 0.18)
		if not _position_blocked(result):
			return result
	return center + (pos - center).normalized() * NUDGE_MARGIN


func _position_blocked(pos: Vector2) -> bool:
	var world := get_world_2d()
	if world == null:
		return false
	var space := world.direct_space_state
	var params := PhysicsPointQueryParameters2D.new()
	params.position = pos
	params.collision_mask = WALL_MASK
	params.collide_with_areas = false
	params.collide_with_bodies = true
	return not space.intersect_point(params, 1).is_empty()


func hit(amount: float, clear := false) -> void:
	if is_dead or _phase_transforming:
		return
	if _combat_invulnerable or _swap_invulnerable:
		return
	if not clear:
		amount *= effect_protection
	_flash_damage()
	current_hp -= amount
	if current_hp > 0:
		if vengeful_enabled:
			_fire_vengeful_shot()
		return
	current_hp = 0
	if form < Form.GUNSLINGER:
		_start_phase_transform()
	else:
		die()


func _start_phase_transform() -> void:
	if _phase_transforming or is_dead:
		return
	_phase_transforming = true
	_combat_invulnerable = true
	_swap_invulnerable = false
	_kill_rotate_tween()
	if _spin_tween and _spin_tween.is_valid():
		_spin_tween.kill()
	velocity = Vector2.ZERO
	state = State.TRANSFORMING
	_set_hit_area_enabled(false)
	_recoil_left = 0.0
	var next: Form = Form.SOLDIER if form == Form.SNIPER else Form.GUNSLINGER
	var start_rot := rotation
	_spin_tween = create_tween()
	_spin_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_spin_tween.tween_property(
		self, "rotation", start_rot + TAU * TRANSFORM_SPINS, TRANSFORM_TIME
	)
	# Смена текстуры в середине раскрутки.
	_swap_form_mid_spin(next)
	_spin_tween.finished.connect(_on_transform_spin_finished, CONNECT_ONE_SHOT)


func _swap_form_mid_spin(next: Form) -> void:
	await get_tree().create_timer(TRANSFORM_TIME * 0.5).timeout
	if is_dead or not _phase_transforming:
		return
	_apply_form(next)


func _on_transform_spin_finished() -> void:
	if is_dead:
		return
	rotation = 0.0
	_phase_transforming = false
	_combat_invulnerable = false
	_set_hit_area_enabled(true)
	_start_idle_pause()


func die() -> void:
	_kill_rotate_tween()
	if _spin_tween and _spin_tween.is_valid():
		_spin_tween.kill()
	_phase_transforming = false
	_combat_invulnerable = false
	_set_hit_area_enabled(false)
	rotation = 0.0
	super.die()


func _on_sprite_animation_finished() -> void:
	if is_dead or sprite.animation == "die":
		super._on_sprite_animation_finished()
		return
	if _phase_transforming:
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

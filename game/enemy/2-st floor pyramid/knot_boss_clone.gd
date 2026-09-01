extends BaseEnemy
class_name EnemyKnotBossClone

## Клон Knot-босса. Не босс и не EnemyKnot: своё качение, без способностей.

enum MoveState { EMERGING, WAIT_SYNC, IDLE, ROLL }

const DIRECTION_COUNT := 8
const ENEMY_LAYER := 4
const WALL_OBSTACLE_PIT_MASK := 176
const SOLID_COLLISION_MASK := 182
const GHOST_LIFETIME := 2.0

var roll_time: float = 2.0
var idle_time_min: float = 2.5
var idle_time_max: float = 2.5
var direction_step_degrees: float = 45.0

var _move_state := MoveState.IDLE
var _phase_timer := 0.0
var _roll_direction := Vector2.RIGHT
var _is_ghost := false
var is_temporary := false
var _lifetime := 0.0
var _emerge_tween: Tween

@onready var _hit_area: Area2D = $HitArea


func _ready() -> void:
	stop_on_melee_hit = false
	drop_coin_on_death = false
	super._ready()
	velocity = Vector2.ZERO
	_set_hit_area_enabled(false)


func _apply_level_buffs() -> void:
	base_hp = 1
	current_hp = 1
	damage = 1


func _on_cooldown_timer_timeout() -> void:
	pass


func _on_blind_timer_timeout() -> void:
	if player_in_vision:
		active = true
		if _move_state != MoveState.ROLL and _move_state != MoveState.EMERGING:
			if _move_state == MoveState.WAIT_SYNC:
				return
			_enter_idle()


func _on_field_view_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_in_vision = false
	if _move_state == MoveState.ROLL or _move_state == MoveState.EMERGING or _move_state == MoveState.WAIT_SYNC:
		return
	active = false
	blind_timer.stop()
	cooldown_timer.stop()
	velocity = Vector2.ZERO
	_enter_idle()


func _physics_process(delta: float) -> void:
	if _move_state == MoveState.ROLL and _hit_area != null and _hit_area.monitoring:
		_sync_hit_range()
	if _move_state == MoveState.EMERGING:
		return
	super._physics_process(delta)


func _custom_physics(delta: float) -> void:
	if _is_ghost:
		_lifetime -= delta
		if _lifetime <= 0.0:
			die()
			return

	_phase_timer -= delta

	match _move_state:
		MoveState.WAIT_SYNC:
			velocity = Vector2.ZERO
			move_and_slide()
		MoveState.IDLE:
			velocity = Vector2.ZERO
			if _phase_timer <= 0.0:
				_start_roll()
			move_and_slide()
		MoveState.ROLL:
			velocity = _roll_direction * move_speed
			move_and_slide()
			_handle_wall_collisions()
			if not _is_ghost and _phase_timer <= 0.0:
				_finish_roll_phase()
		_:
			velocity = Vector2.ZERO
			move_and_slide()


func configure_solid(source: EnemyKnotBoss, wait_for_leader: bool) -> void:
	_is_ghost = false
	is_temporary = false
	_copy_motion_from(source)
	deals_melee_damage = false
	_set_body_collision(ENEMY_LAYER, SOLID_COLLISION_MASK)
	_configure_hit_area(false)
	base_hp = 1
	current_hp = 1
	damage = 0
	scale = source.scale
	active = true
	player_in_vision = true
	_set_hit_area_enabled(false)
	if wait_for_leader:
		_move_state = MoveState.WAIT_SYNC
		_update_idle_animation()
	else:
		_enter_idle()


func configure_ghost(source: EnemyKnotBoss) -> void:
	_is_ghost = true
	is_temporary = true
	melee_hit_cooldown = source.melee_damage_cooldown
	_copy_motion_from(source)
	deals_melee_damage = true
	_set_body_collision(ENEMY_LAYER, WALL_OBSTACLE_PIT_MASK)
	_configure_hit_area(true)
	base_hp = 1
	current_hp = 1
	damage = 1
	scale = source.scale
	active = true
	player_in_vision = true
	_lifetime = GHOST_LIFETIME
	_start_roll()


func start_emerge(from: Vector2, to: Vector2, duration: float) -> void:
	_move_state = MoveState.EMERGING
	global_position = from
	modulate.a = 0.0
	_update_idle_animation()
	var start_scale := scale * 0.35
	var end_scale := scale
	scale = start_scale
	if _emerge_tween:
		_emerge_tween.kill()
	_emerge_tween = create_tween()
	_emerge_tween.set_parallel(true)
	_emerge_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_emerge_tween.tween_property(self, "global_position", to, duration)
	_emerge_tween.tween_property(self, "modulate:a", 1.0, duration)
	_emerge_tween.tween_property(self, "scale", end_scale, duration)
	_emerge_tween.finished.connect(_on_emerge_finished, CONNECT_ONE_SHOT)


func start_synced_roll() -> void:
	if is_dead:
		return
	if _move_state == MoveState.EMERGING:
		if _emerge_tween:
			_emerge_tween.kill()
		modulate.a = 1.0
		_on_emerge_finished()
	_start_roll()


func _on_emerge_finished() -> void:
	if is_dead:
		return
	_emerge_tween = null
	modulate.a = 1.0
	if _move_state == MoveState.EMERGING:
		_move_state = MoveState.WAIT_SYNC
		_update_idle_animation()


func _copy_motion_from(source: EnemyKnotBoss) -> void:
	move_speed = source.move_speed
	base_move_speed = source.move_speed
	roll_time = source.roll_time
	idle_time_min = source.idle_time_min
	idle_time_max = source.idle_time_max
	direction_step_degrees = source.direction_step_degrees


func _enter_idle() -> void:
	if _is_ghost:
		return
	_move_state = MoveState.IDLE
	_phase_timer = randf_range(idle_time_min, idle_time_max)
	velocity = Vector2.ZERO
	_set_hit_area_enabled(false)
	_update_idle_animation()


func _start_roll() -> void:
	_roll_direction = _pick_random_direction()
	_move_state = MoveState.ROLL
	_phase_timer = roll_time
	_set_hit_area_enabled(_is_ghost)
	_update_roll_animation()
	sprite.flip_h = _roll_direction.x < 0.0


func _finish_roll_phase() -> void:
	velocity = Vector2.ZERO
	if not player_in_vision:
		active = false
	_enter_idle()


func _pick_random_direction() -> Vector2:
	var index := randi() % DIRECTION_COUNT
	return Vector2.RIGHT.rotated(deg_to_rad(direction_step_degrees * float(index)))


func _handle_wall_collisions() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision == null:
			continue
		var collider = collision.get_collider()
		if collider == null or collider == self:
			continue
		if collider.is_in_group("player"):
			continue
		_roll_direction = _roll_direction.bounce(collision.get_normal()).normalized()
		if sprite:
			sprite.flip_h = _roll_direction.x < 0.0


func _set_body_collision(layer: int, mask: int) -> void:
	collision_layer = layer
	collision_mask = mask
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if body_shape:
		body_shape.disabled = false


func _configure_hit_area(enabled: bool) -> void:
	if _hit_area == null:
		return
	_hit_area.collision_layer = 0
	_hit_area.collision_mask = 1 if enabled else 0
	_hit_area.monitorable = false
	_set_hit_area_enabled(false)


func die() -> void:
	if _emerge_tween:
		_emerge_tween.kill()
		_emerge_tween = null
	super.die()


func _update_idle_animation() -> void:
	if not sprite or not sprite.sprite_frames:
		return
	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func _update_roll_animation() -> void:
	if not sprite or not sprite.sprite_frames:
		return
	if sprite.sprite_frames.has_animation("default"):
		sprite.play("default")


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

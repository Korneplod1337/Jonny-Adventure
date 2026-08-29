extends BaseEnemy
class_name EnemyRandomMover

## База для врагов со случайным перемещением: idle → roll по таймеру, без преследования игрока.

enum MoveState { IDLE, ROLL }

@export_group("Random Move")
@export var hard_roll_speed: float = 200.0
@export var hard_idle_time_min: float = 2.0
@export var hard_idle_time_max: float = 3.0
@export var hard_roll_time: float = 2.0
@export var roll_bounce_window: float = 1.0
@export var direction_step_degrees: float = 45.0

@export_group("Hard Stats")
@export var hard_base_hp: int = 100
@export var hard_damage: int = 1

const DIRECTION_COUNT := 8

var roll_speed: float
var idle_time_min: float
var idle_time_max: float
var roll_time: float

var _move_state := MoveState.IDLE
var _phase_timer := 0.0
var _roll_direction := Vector2.RIGHT
var _wall_frozen := false

@onready var _hit_area: Area2D = $HitArea


func _ready() -> void:
	stop_on_melee_hit = false
	deals_melee_damage = true
	super._ready()
	_set_hit_area_enabled(false)
	_enter_idle()


func _apply_level_buffs() -> void:
	roll_speed = _scale_move_speed(
		hard_roll_speed, _get_roll_speed_med_offset(), _get_roll_speed_easy_offset()
	)
	idle_time_min = hard_idle_time_min
	idle_time_max = hard_idle_time_max
	roll_time = hard_roll_time
	base_hp = _scale_hp(hard_base_hp, _get_hp_med_offset(), _get_hp_easy_offset())
	damage = _scale_damage(hard_damage, _get_damage_med_offset(), _get_damage_easy_offset())
	move_speed = roll_speed
	super._apply_level_buffs()


func _get_roll_speed_med_offset() -> float:
	return 0.0


func _get_roll_speed_easy_offset() -> float:
	return 0.0


func _get_hp_med_offset() -> int:
	return 0


func _get_hp_easy_offset() -> int:
	return 0


func _get_damage_med_offset() -> int:
	return 0


func _get_damage_easy_offset() -> int:
	return 0


func _physics_process(delta: float) -> void:
	if _move_state == MoveState.ROLL and _hit_area != null and _hit_area.monitoring:
		_sync_hit_range()
	super._physics_process(delta)


func _custom_physics(delta: float) -> void:
	_phase_timer -= delta

	match _move_state:
		MoveState.IDLE:
			velocity = Vector2.ZERO
			if _phase_timer <= 0.0:
				_start_roll()
			move_and_slide()
		MoveState.ROLL:
			if not _wall_frozen:
				velocity = _roll_direction * roll_speed
			else:
				velocity = Vector2.ZERO
			move_and_slide()
			_handle_wall_collisions()
			if _phase_timer <= 0.0:
				_finish_roll_phase()


func _on_blind_timer_timeout() -> void:
	if player_in_vision:
		active = true
		if _move_state != MoveState.ROLL:
			_enter_idle()


func _on_field_view_area_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	player_in_vision = false
	if _move_state == MoveState.ROLL:
		return
	active = false
	blind_timer.stop()
	cooldown_timer.stop()
	velocity = Vector2.ZERO
	_enter_idle()


func _enter_idle() -> void:
	_wall_frozen = false
	_move_state = MoveState.IDLE
	_phase_timer = randf_range(idle_time_min, idle_time_max)
	velocity = Vector2.ZERO
	_set_hit_area_enabled(false)
	_update_idle_animation()


func _start_roll() -> void:
	_wall_frozen = false
	_roll_direction = _pick_random_direction()
	_move_state = MoveState.ROLL
	_phase_timer = roll_time
	_set_hit_area_enabled(true)
	_update_roll_animation()
	sprite.flip_h = _roll_direction.x < 0.0


func _finish_roll_phase() -> void:
	_wall_frozen = false
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
		if collider.is_in_group("Enemy"):
			_roll_direction = _roll_direction.bounce(collision.get_normal()).normalized()
			sprite.flip_h = _roll_direction.x < 0.0
			continue

		if _phase_timer > roll_time - roll_bounce_window:
			_roll_direction = _roll_direction.bounce(collision.get_normal()).normalized()
			sprite.flip_h = _roll_direction.x < 0.0
		else:
			_wall_frozen = true


func _update_idle_animation() -> void:
	if not sprite or not sprite.sprite_frames:
		return
	if sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	else:
		sprite.stop()
		sprite.frame = 0


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

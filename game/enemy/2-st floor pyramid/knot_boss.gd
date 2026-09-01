extends Boss
class_name EnemyKnotBoss

## Босс-узел: качение как у Knot, но со своими статами и двумя типами клонов.
## Не наследует EnemyKnot / EnemyRandomMover.

enum MoveState { IDLE, ROLL }

const CLONE_SCENE := preload("res://game/enemy/2-st floor pyramid/Knot_boss_clone.tscn")
const DIRECTION_COUNT := 8

@export_group("Behavior")
@export var idle_time_min: float = 2.5
@export var idle_time_max: float = 2.5
@export var roll_time: float = 2.0
@export var direction_step_degrees: float = 45.0
@export var idle_clone_min: int = 1
@export var idle_clone_max: int = 4
@export var ghost_clone_min: int = 3
@export var ghost_clone_max: int = 6
@export var emerge_time: float = 1.0
@export var emerge_distance: float = 72.0
@export var room_spawn_margin: float = 48.0
@export var max_solid_clones: int = 7
@export var melee_damage_cooldown: float = 1.5

var _move_state := MoveState.IDLE
var _phase_timer := 0.0
var _roll_direction := Vector2.RIGHT
var _pending_ghost_wave := false
var _sync_clones: Array[EnemyKnotBossClone] = []
var _spawned_minions: Array[CharacterBody2D] = []

@onready var _hit_area: Area2D = $HitArea


func _ready() -> void:
	BossName = "Big Knot"
	stop_on_melee_hit = false
	deals_melee_damage = true
	melee_hit_cooldown = melee_damage_cooldown
	super._ready()
	_set_hit_area_enabled(false)
	_enter_idle()


func _apply_level_buffs() -> void:
	super._apply_level_buffs()
	base_move_speed = move_speed


func _schedule_next_decision() -> void:
	pass


func _on_cooldown_timer_timeout() -> void:
	pass


func _on_blind_timer_timeout() -> void:
	if not can_act_independently():
		if player_in_vision:
			active = true
		return
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


func _physics_process(delta: float) -> void:
	if _move_state == MoveState.ROLL and _hit_area != null and _hit_area.monitoring:
		_sync_hit_range()
	super._physics_process(delta)


func _custom_physics(delta: float) -> void:
	if not can_act_independently():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	_phase_timer -= delta

	match _move_state:
		MoveState.IDLE:
			velocity = Vector2.ZERO
			if _phase_timer <= 0.0:
				_start_roll()
			move_and_slide()
		MoveState.ROLL:
			velocity = _roll_direction * move_speed
			move_and_slide()
			_handle_wall_collisions()
			if _phase_timer <= 0.0:
				_finish_roll_phase()


func _enter_idle() -> void:
	_move_state = MoveState.IDLE
	_phase_timer = randf_range(idle_time_min, idle_time_max)
	velocity = Vector2.ZERO
	_set_hit_area_enabled(false)
	_update_idle_animation()
	if _can_use_abilities():
		_choose_ability()
	else:
		_pending_ghost_wave = false


func _can_use_abilities() -> bool:
	return can_act_independently() and active and player_in_vision and not is_dead


func _choose_ability() -> void:
	if randf() < 0.5:
		_pending_ghost_wave = false
		_spawn_idle_clones()
	else:
		_pending_ghost_wave = true


func _start_roll() -> void:
	_roll_direction = _pick_random_direction()
	_move_state = MoveState.ROLL
	_phase_timer = roll_time
	_set_hit_area_enabled(true)
	_update_roll_animation()
	sprite.flip_h = _roll_direction.x < 0.0
	_release_sync_clones()
	if _pending_ghost_wave and _can_use_abilities():
		_spawn_ghost_clones()
	_pending_ghost_wave = false


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


func _spawn_idle_clones() -> void:
	var slots_left := max_solid_clones - _count_solid_clones()
	if slots_left <= 0:
		return
	var count := mini(randi_range(idle_clone_min, idle_clone_max), slots_left)
	var origin := global_position
	for i in count:
		var clone := _make_clone()
		if clone == null:
			continue
		clone.configure_solid(self, true)
		clone.global_position = origin
		var angle := TAU * float(i) / float(count) + randf_range(-0.25, 0.25)
		var target := _clamp_spawn_point(origin + Vector2.RIGHT.rotated(angle) * emerge_distance)
		clone.start_emerge(origin, target, emerge_time)
		_sync_clones.append(clone)


func _spawn_ghost_clones() -> void:
	var count := randi_range(ghost_clone_min, ghost_clone_max)
	for _i in count:
		var clone := _make_clone()
		if clone == null:
			continue
		clone.global_position = _clamp_spawn_point(global_position)
		clone.configure_ghost(self)


func _count_solid_clones() -> int:
	var n := 0
	for minion in _spawned_minions:
		if not is_instance_valid(minion) or not (minion is EnemyKnotBossClone):
			continue
		var clone := minion as EnemyKnotBossClone
		if clone.is_dead or clone.is_temporary:
			continue
		n += 1
	return n


func _make_clone() -> EnemyKnotBossClone:
	var clone: EnemyKnotBossClone = CLONE_SCENE.instantiate()
	clone.drop_coin_on_death = false
	var room := _get_room_node()
	if room:
		room.add_child(clone)
	else:
		get_parent().add_child(clone)
	_register_minion(clone)
	return clone


func _release_sync_clones() -> void:
	for clone in _sync_clones:
		if is_instance_valid(clone) and not clone.is_dead:
			clone.start_synced_roll()
	_sync_clones.clear()


func _register_minion(minion: CharacterBody2D) -> void:
	if not is_instance_valid(minion):
		return
	_spawned_minions.append(minion)
	_set_collision_ignored(minion, self)
	for other in _spawned_minions:
		if other != minion and is_instance_valid(other):
			_set_collision_ignored(minion, other)
	call_deferred("_refresh_minion_collision_exceptions", minion)
	if minion.has_signal("_enemy_die"):
		minion._enemy_die.connect(func(_damage: int): _on_minion_died(minion), CONNECT_ONE_SHOT)


func _on_minion_died(minion: CharacterBody2D) -> void:
	_spawned_minions.erase(minion)
	if minion is EnemyKnotBossClone:
		_sync_clones.erase(minion)


func _set_collision_ignored(a: CharacterBody2D, b: CharacterBody2D) -> void:
	a.add_collision_exception_with(b)
	b.add_collision_exception_with(a)


func _refresh_minion_collision_exceptions(minion: CharacterBody2D) -> void:
	if not is_instance_valid(minion):
		return
	_set_collision_ignored(minion, self)
	for other in _spawned_minions:
		if other != minion and is_instance_valid(other):
			_set_collision_ignored(minion, other)


func _get_room_node() -> Node:
	var node: Node = self
	while node:
		if node.has_method("connect_single_enemy"):
			return node
		node = node.get_parent()
	return null


func _clamp_spawn_point(global_pos: Vector2) -> Vector2:
	var from := global_position
	var to := global_pos
	if from.distance_squared_to(to) < 1.0:
		return from

	var world := get_world_2d()
	if world == null:
		return to
	var space := world.direct_space_state
	if space == null:
		return to

	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = 16 | 32
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return to

	var normal: Vector2 = hit.normal
	if normal.length_squared() < 0.01:
		normal = (from - to).normalized()
	return hit.position + normal * room_spawn_margin


func die() -> void:
	if is_dead:
		return
	for minion in _spawned_minions:
		if is_instance_valid(minion) and minion is BaseEnemy and not minion.is_dead:
			minion.die()
	_spawned_minions.clear()
	_sync_clones.clear()
	super.die()


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

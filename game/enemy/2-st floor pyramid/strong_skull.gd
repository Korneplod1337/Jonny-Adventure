extends EnemyWeakSkull
class_name EnemyStrongSkull

## Как WeakSkull, но быстрее/танковее и периодически стреляет с упреждением.

enum Phase { CHASE, WINDUP }

@export_group("Projectile")
@export var projectile_scene: PackedScene
@export var hard_projectile_damage: int = 1
@export var hard_projectile_speed: float = 300.0
@export var hard_projectile_range: float = 450.0

@export_group("Ability")
@export var hard_ability_interval: float = 5.0
@export var hard_windup_time: float = 1.0
@export_range(0.0, 1.0) var shoot_chance: float = 0.5

const PROJECTILE_SPEED_MED_OFFSET := -25.0
const PROJECTILE_SPEED_EASY_OFFSET := -50.0
const PROJECTILE_RANGE_MED_OFFSET := -25.0
const PROJECTILE_RANGE_EASY_OFFSET := -50.0

var projectile_speed: float = 350.0
var projectile_range: float = 450.0
var projectile_damage: int = 1
var ability_interval: float = 5.0
var windup_time: float = 1.0

var phase := Phase.CHASE
var _ability_timer := 0.0
var _windup_timer := 0.0
var _will_shoot := false


func _ready() -> void:
	super._ready()
	# После WeakSkull._ready: движение сами (нужен windup без use_base_move).
	use_base_move_towards_player = false
	_ability_timer = ability_interval


func _apply_level_buffs() -> void:
	# WeakSkull: HP/speed; здесь поверх — projectile.
	super._apply_level_buffs()
	projectile_damage = _scale_damage(hard_projectile_damage, DAMAGE_MED_OFFSET, DAMAGE_EASY_OFFSET)
	projectile_speed = _apply_difficulty_offset(
		hard_projectile_speed, PROJECTILE_SPEED_MED_OFFSET, PROJECTILE_SPEED_EASY_OFFSET
	)
	projectile_range = _apply_difficulty_offset(
		hard_projectile_range, PROJECTILE_RANGE_MED_OFFSET, PROJECTILE_RANGE_EASY_OFFSET
	)
	ability_interval = hard_ability_interval
	windup_time = hard_windup_time
	if GameState.level_bufs[2][1]:
		projectile_damage *= 2


func get_projectile_damage() -> Vector3i:
	return _build_damage_vector(projectile_damage)


func _custom_physics(delta: float) -> void:
	if not player:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	match phase:
		Phase.WINDUP:
			_process_windup(delta)
		_:
			_process_chase(delta)


func _process_chase(delta: float) -> void:
	_ability_timer -= delta
	if _ability_timer <= 0.0:
		_start_windup()
		return

	var dir := get_direction_to_player()
	if dir == Vector2.ZERO:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	velocity = dir * move_speed
	move_and_slide()


func _start_windup() -> void:
	phase = Phase.WINDUP
	_windup_timer = windup_time
	_will_shoot = randf() < shoot_chance
	velocity = Vector2.ZERO
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func _process_windup(delta: float) -> void:
	velocity = Vector2.ZERO
	move_and_slide()
	_windup_timer -= delta
	if _windup_timer > 0.0:
		return

	if _will_shoot:
		_shoot_leading_shot()
	_finish_windup()


func _finish_windup() -> void:
	phase = Phase.CHASE
	_ability_timer = ability_interval
	_will_shoot = false
	_update_locomotion_animation()


func _shoot_leading_shot() -> void:
	if not projectile_scene or not player or not active:
		return
	var aim := _predict_intercept_point()
	var dir := aim - global_position
	if dir.length_squared() < 1.0:
		dir = player.global_position - global_position
	if dir.length_squared() < 1.0:
		return
	_spawn_projectile(dir.normalized())


func _predict_intercept_point() -> Vector2:
	var origin := global_position
	var target_pos := player.global_position
	var target_vel := _get_player_velocity()
	var speed := projectile_speed
	if speed <= 1.0:
		return target_pos

	var to_target := target_pos - origin
	var a := target_vel.length_squared() - speed * speed
	var b := 2.0 * to_target.dot(target_vel)
	var c := to_target.length_squared()

	var t := 0.0
	if absf(a) < 0.001:
		if absf(b) < 0.001:
			return target_pos
		t = -c / b
	else:
		var disc := b * b - 4.0 * a * c
		if disc < 0.0:
			return target_pos
		var sqrt_disc := sqrt(disc)
		var t1 := (-b - sqrt_disc) / (2.0 * a)
		var t2 := (-b + sqrt_disc) / (2.0 * a)
		if t1 > 0.0 and t2 > 0.0:
			t = minf(t1, t2)
		elif t1 > 0.0:
			t = t1
		elif t2 > 0.0:
			t = t2
		else:
			return target_pos

	if t <= 0.0:
		return target_pos
	# Не целимся бесконечно далеко.
	var max_t := projectile_range / speed if speed > 0.0 else 2.0
	t = minf(t, max_t)
	return target_pos + target_vel * t


func _get_player_velocity() -> Vector2:
	if not is_instance_valid(player):
		return Vector2.ZERO
	if player.has_method("get_real_velocity"):
		var rv: Vector2 = player.get_real_velocity()
		if rv.length_squared() > 1.0:
			return rv
	if "velocity" in player:
		return player.velocity
	return Vector2.ZERO


func _spawn_projectile(dir: Vector2) -> void:
	var shot: Node2D = projectile_scene.instantiate()
	shot.global_position = global_position + dir * 12.0
	shot.owner_enemy = self
	shot.setup(dir, get_projectile_damage(), projectile_speed, projectile_range)
	get_tree().current_scene.add_child(shot)
	if absf(dir.x) >= absf(dir.y) * 0.25:
		sprite.flip_h = dir.x < 0.0


func _update_active_walk_animation() -> void:
	if phase == Phase.WINDUP:
		if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
		return
	super._update_active_walk_animation()


func _on_field_view_area_body_exited(body: Node2D) -> void:
	super._on_field_view_area_body_exited(body)
	if body.is_in_group("player") and phase == Phase.WINDUP:
		_finish_windup()

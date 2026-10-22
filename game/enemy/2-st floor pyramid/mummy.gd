extends BaseEnemy
class_name EnemyMummy

## Мумия: идёт к игроку по пути, вблизи атакует с отложенным HitArea.

enum State { CHASE, ATTACK }

@export_group("Hard Stats")
@export var hard_base_hp: int = 100
@export var hard_damage: int = 1
@export var hard_move_speed: float = 80.0
@export var hard_attack_range: float = 48.0
@export var hard_attack_cooldown: float = 0.7

@export_group("Attack")
## Кадр атаки (0-based), на котором включается HitArea. 2 = 3-й спрайт.
@export var hitbox_frame: int = 2
## Запас к сумме радиусов коллизий, на котором мумия останавливается.
@export var body_stop_padding: float = 2.0

const MOVE_SPEED_MED_OFFSET := -15.0
const MOVE_SPEED_EASY_OFFSET := -30.0
const HP_MED_OFFSET := -20
const HP_EASY_OFFSET := -40
const DAMAGE_MED_OFFSET := 0
const DAMAGE_EASY_OFFSET := 0
const ATTACK_RANGE_MED_OFFSET := -4.0
const ATTACK_RANGE_EASY_OFFSET := -8.0
const ATTACK_COOLDOWN_MED_OFFSET := 0.1
const ATTACK_COOLDOWN_EASY_OFFSET := 0.2

var attack_range: float = 48.0
var attack_cooldown: float = 0.7
var state := State.CHASE
var _attack_hit_dealt := false
var _attack_cooldown_left := 0.0
var _hit_area_base_pos := Vector2.ZERO

@onready var _hit_area: Area2D = $HitArea


func _ready() -> void:
	use_pathfinding = true
	use_base_move_towards_player = false
	stop_on_melee_hit = false
	deals_melee_damage = true
	# Top-down: иначе CharacterBody2D плохо скользит вдоль стен.
	motion_mode = MOTION_MODE_FLOATING
	super._ready()
	# Полная коллизия с игроком — сквозь ноги не проходим.
	collision_mask |= 1
	if is_instance_valid(player):
		remove_collision_exception_with(player)
		player.remove_collision_exception_with(self)
	if _hit_area:
		_hit_area_base_pos = _hit_area.position
	_set_hit_area_enabled(false)
	_update_hit_area_side()
	if sprite:
		sprite.frame_changed.connect(_on_sprite_frame_changed)
		if sprite.sprite_frames and sprite.sprite_frames.has_animation("default"):
			sprite.play("default")


func _apply_level_buffs() -> void:
	move_speed = _scale_move_speed(
		hard_move_speed, MOVE_SPEED_MED_OFFSET, MOVE_SPEED_EASY_OFFSET
	)
	base_hp = _scale_hp(hard_base_hp, HP_MED_OFFSET, HP_EASY_OFFSET)
	damage = _scale_damage(hard_damage, DAMAGE_MED_OFFSET, DAMAGE_EASY_OFFSET)
	attack_range = _apply_difficulty_offset(
		hard_attack_range, ATTACK_RANGE_MED_OFFSET, ATTACK_RANGE_EASY_OFFSET
	)
	attack_cooldown = _scale_cooldown(
		hard_attack_cooldown, ATTACK_COOLDOWN_MED_OFFSET, ATTACK_COOLDOWN_EASY_OFFSET
	)
	super._apply_level_buffs()


## Радиус для nav: по ширине тела, не по диагонали высокого rect (иначе путь ломается).
func _navigation_agent_radius() -> float:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision and collision.shape is RectangleShape2D:
		var rect := collision.shape as RectangleShape2D
		return rect.size.x * 0.5 * absf(scale.x) + 6.0
	if collision and collision.shape is CircleShape2D:
		var circle := collision.shape as CircleShape2D
		return circle.radius * maxf(absf(scale.x), absf(scale.y)) + 4.0
	return 22.0


func _custom_physics(delta: float) -> void:
	if _attack_cooldown_left > 0.0:
		_attack_cooldown_left = maxf(0.0, _attack_cooldown_left - delta)

	if not player:
		velocity = Vector2.ZERO
		return

	match state:
		State.CHASE:
			_process_chase()
		State.ATTACK:
			_process_attack()


func _process_chase() -> void:
	# Дистанция стопа — между центрами CollisionShape2D (с учётом position offset), не origin нод.
	var my_col_center := _get_collision_center(self)
	var player_col_center := _get_collision_center(player)
	var to_col := player_col_center - my_col_center
	var col_dist := to_col.length()
	var stop_dir := to_col if col_dist > 0.01 else Vector2.DOWN
	var stop_dist := _get_body_stop_distance(stop_dir)
	var at_body_stop := col_dist <= stop_dist

	var to_player := player.global_position - global_position
	var in_attack_range := to_player.length() <= attack_range

	if (in_attack_range or at_body_stop) and _attack_cooldown_left <= 0.0:
		_start_attack()
		return

	if at_body_stop:
		velocity = Vector2.ZERO
		_apply_facing(to_player)
		_play_walk_anim()
		move_and_slide()
		return

	var dir := get_direction_to_player()
	if dir == Vector2.ZERO:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	velocity = dir * move_speed
	_apply_facing(to_player)
	_play_walk_anim()
	move_and_slide()


func _process_attack() -> void:
	velocity = Vector2.ZERO
	move_and_slide()


func _play_walk_anim() -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("default"):
		if sprite.animation != "default":
			sprite.play("default")


func _start_attack() -> void:
	if state == State.ATTACK:
		return
	_attack_hit_dealt = false
	_set_hit_area_enabled(false)
	# Поворот только в момент старта, дальше во время удара не крутимся.
	_apply_facing(_get_dir_to_player())
	_update_hit_area_side()
	state = State.ATTACK
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
		if sprite.frame >= hitbox_frame:
			_activate_attack_hitbox()
	else:
		_finish_attack()


func _finish_attack() -> void:
	_set_hit_area_enabled(false)
	_attack_hit_dealt = false
	state = State.CHASE
	_attack_cooldown_left = attack_cooldown
	if is_dead:
		return
	_play_walk_anim()


func _on_sprite_frame_changed() -> void:
	if is_dead or state != State.ATTACK:
		return
	if sprite == null or sprite.animation != "attack":
		return
	if sprite.frame >= hitbox_frame and (_hit_area == null or not _hit_area.monitoring):
		_activate_attack_hitbox()


func _activate_attack_hitbox() -> void:
	_update_hit_area_side()
	_set_hit_area_enabled(true)
	_sync_hit_range()
	_try_deal_attack_damage()


func _try_deal_attack_damage() -> void:
	if _attack_hit_dealt or state != State.ATTACK or not player:
		return
	if not player_in_hit_range:
		return
	var atk := get_attack_damage()
	player.take_damage(atk.x, atk.y, atk.z, self)
	_attack_hit_dealt = true


func _on_sprite_animation_finished() -> void:
	if sprite.animation == "attack":
		_finish_attack()
		return
	super._on_sprite_animation_finished()


func _deal_melee_damage_to_player() -> bool:
	if state != State.ATTACK or _attack_hit_dealt:
		return false
	if not super._deal_melee_damage_to_player():
		return false
	_attack_hit_dealt = true
	return true


func _get_dir_to_player() -> Vector2:
	if not player:
		return Vector2.RIGHT
	var to_player := player.global_position - global_position
	if to_player.length_squared() < 0.01:
		return Vector2.LEFT if sprite and sprite.flip_h else Vector2.RIGHT
	return to_player.normalized()


func _apply_facing(dir: Vector2) -> void:
	if state == State.ATTACK:
		return
	if dir.length_squared() < 0.01:
		return
	if absf(dir.x) >= absf(dir.y) * 0.25:
		sprite.flip_h = dir.x < 0.0
		_update_hit_area_side()


## HitArea только зеркалится с flip_h — позицию из сцены не телепортируем.
func _update_hit_area_side() -> void:
	if _hit_area == null:
		return
	var side := -1.0 if sprite.flip_h else 1.0
	_hit_area.position = Vector2(_hit_area_base_pos.x * side, _hit_area_base_pos.y)
	_hit_area.scale.x = side
	_hit_area.scale.y = 1.0
	_hit_area.rotation = 0.0


func _get_collision_center(body: Node2D) -> Vector2:
	if not is_instance_valid(body):
		return Vector2.ZERO
	var col := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		return col.global_position
	return body.global_position


func _get_body_stop_distance(approach_dir: Vector2) -> float:
	var dir := approach_dir.normalized() if approach_dir.length_squared() > 0.01 else Vector2.RIGHT
	return _extent_along(self, dir) + _extent_along(player, -dir) + body_stop_padding


func _extent_along(body: CharacterBody2D, dir: Vector2) -> float:
	if not is_instance_valid(body):
		return 16.0
	var col := body.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null or col.shape == null:
		return 16.0
	# half в мировых единицах; центр шейпа уже в global_position (offset учтён там).
	var half := _shape_half_extents(col.shape) * Vector2(
		absf(col.global_scale.x),
		absf(col.global_scale.y)
	)
	var d := dir.normalized()
	# AABB без учёта rotation шейпа (у мумии rotation = 0).
	return absf(d.x) * half.x + absf(d.y) * half.y


func _shape_half_extents(shape: Shape2D) -> Vector2:
	if shape is RectangleShape2D:
		return (shape as RectangleShape2D).size * 0.5
	if shape is CircleShape2D:
		var r := (shape as CircleShape2D).radius
		return Vector2(r, r)
	if shape is CapsuleShape2D:
		var cap := shape as CapsuleShape2D
		return Vector2(cap.radius, cap.height * 0.5 + cap.radius)
	return Vector2(16.0, 16.0)


func _set_hit_area_enabled(enabled: bool) -> void:
	if _hit_area == null:
		return
	_hit_area.monitoring = enabled
	_hit_area.monitorable = enabled
	if not enabled:
		player_in_hit_range = false


func _sync_hit_range() -> void:
	if _hit_area == null or not _hit_area.monitoring or is_dead:
		return
	player_in_hit_range = false
	for body in _hit_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			player_in_hit_range = true
			break


func _on_field_view_area_body_exited(body: Node2D) -> void:
	super._on_field_view_area_body_exited(body)
	if body.is_in_group("player") and state != State.ATTACK:
		_set_hit_area_enabled(false)
		_play_walk_anim()

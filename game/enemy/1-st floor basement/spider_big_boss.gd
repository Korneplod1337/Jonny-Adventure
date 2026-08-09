extends Boss
class_name EnemySpiderBigBoss

## Большой паук-босс: wander + pathfinding и фазы windup/ускоренной ходьбы.
## При смерти (если can_split_on_death) распадается на 4 уменьшенных босса-паука.

enum Phase { WANDER, WINDUP, DASH }

@export_group("Wander")
@export var boss_move_speed_min: float = 161.0
@export var boss_move_speed_max: float = 230.0
@export var direction_change_min: float = 0.4
@export var direction_change_max: float = 1.0
@export var angle_deviation: float = 40.0

@export_group("Phases")
@export var wander_phase_min: float = 4.0
@export var wander_phase_max: float = 8.0
@export var windup_duration: float = 1.0
@export var dash_duration: float = 1.0
@export var dash_speed_mult: float = 1.75
@export var dash_anim_speed_mult: float = 3.0

@export_group("Split")
@export var can_split_on_death: bool = true
@export var split_count: int = 4
@export var split_child_scale: float = 1.6
@export var split_spread: float = 88.0

const CHILD_HP := 100
const CHILD_DAMAGE := 1
## Быстрее обычного Spider_big (140–200).
const CHILD_SPEED_MIN := 200.0
const CHILD_SPEED_MAX := 350.0
## Layer игрока — чтобы дети не проходили сквозь него.
const PLAYER_COLLISION_LAYER := 1

var phase: Phase = Phase.WANDER
var wander_direction := Vector2.RIGHT
var current_speed := 100.0
var direction_timer := 0.0
var _phase_timer := 0.0
var _speed_range_min_ratio := 1.0
var _speed_range_max_ratio := 1.0
var _base_anim_speed := 1.0
var _spawned_minions: Array[CharacterBody2D] = []

var _self_scene: PackedScene


func _ready() -> void:
	use_pathfinding = true
	BossName = "Big Spider"
	if scene_file_path != "":
		_self_scene = load(scene_file_path) as PackedScene
	super._ready()
	_base_anim_speed = sprite.speed_scale
	phase = Phase.WANDER
	_update_locomotion_animation()
	_reset_wander_phase_timer()


func _apply_level_buffs() -> void:
	boss_move_speed = (boss_move_speed_min + boss_move_speed_max) * 0.5
	super._apply_level_buffs()
	var avg := maxf(0.01, move_speed)
	_speed_range_min_ratio = (boss_move_speed_min * Boss_move_speed_buff) / avg
	_speed_range_max_ratio = (boss_move_speed_max * Boss_move_speed_buff) / avg
	base_move_speed = move_speed


func _schedule_next_decision() -> void:
	# Фазы управляются своим таймером, не Boss phase-switch.
	pass


func _on_blind_timer_timeout() -> void:
	super._on_blind_timer_timeout()
	if active and not is_dead:
		_pick_new_wander_params()
		_reset_wander_phase_timer()
		_update_locomotion_animation()


func _on_field_view_area_body_entered(body: Node2D) -> void:
	super._on_field_view_area_body_entered(body)
	if body.is_in_group("player") and active and not is_dead:
		_pick_new_wander_params()
		_reset_wander_phase_timer()
		_update_locomotion_animation()


func _on_field_view_area_body_exited(body: Node2D) -> void:
	super._on_field_view_area_body_exited(body)
	_update_locomotion_animation()


func _custom_physics(delta: float) -> void:
	if not player:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if phase == Phase.WINDUP:
		velocity = Vector2.ZERO
		move_and_slide()
		_phase_timer -= delta
		if _phase_timer <= 0.0:
			_start_dash()
		return

	_process_wander(delta)


func _process_wander(delta: float) -> void:
	var to_player := player.global_position - global_position
	if to_player.length() <= base_move_stop_distance:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	direction_timer -= delta
	if direction_timer <= 0.0:
		_pick_new_wander_params()

	_phase_timer -= delta
	if phase == Phase.WANDER and _phase_timer <= 0.0:
		_start_windup()
		return
	if phase == Phase.DASH and _phase_timer <= 0.0:
		_end_dash()
		return

	# Та же ходьба, в DASH — просто быстрее (current_speed уже с множителем).
	velocity = wander_direction * current_speed
	sprite.flip_h = wander_direction.x < 0.0
	move_and_slide()


func _pick_new_wander_params() -> void:
	direction_timer = randf_range(direction_change_min, direction_change_max)
	var speed_mult := dash_speed_mult if phase == Phase.DASH else 1.0
	current_speed = randf_range(
		move_speed * _speed_range_min_ratio,
		move_speed * _speed_range_max_ratio
	) * speed_mult

	if not player:
		wander_direction = Vector2.RIGHT.rotated(randf() * TAU)
		return

	var to_player := get_direction_to_player()
	if to_player.length_squared() < 0.01:
		wander_direction = Vector2.RIGHT.rotated(
			deg_to_rad(randf_range(-angle_deviation, angle_deviation))
		)
		return

	var base_angle := to_player.angle()
	var offset := deg_to_rad(randf_range(-angle_deviation, angle_deviation))
	wander_direction = Vector2.from_angle(base_angle + offset)


func _reset_wander_phase_timer() -> void:
	_phase_timer = randf_range(wander_phase_min, wander_phase_max)


func _start_windup() -> void:
	phase = Phase.WINDUP
	_phase_timer = windup_duration
	velocity = Vector2.ZERO
	sprite.pause()


func _start_dash() -> void:
	phase = Phase.DASH
	_phase_timer = dash_duration
	# То же самое блуждание (со сменой направления), только быстрее.
	_pick_new_wander_params()
	sprite.play("default")
	sprite.speed_scale = _base_anim_speed * dash_anim_speed_mult


func _end_dash() -> void:
	phase = Phase.WANDER
	sprite.speed_scale = _base_anim_speed
	_pick_new_wander_params()
	_reset_wander_phase_timer()
	_update_locomotion_animation()


func _update_locomotion_animation() -> void:
	if is_dead:
		return
	if phase == Phase.WINDUP:
		sprite.pause()
		return
	if phase == Phase.DASH:
		sprite.speed_scale = _base_anim_speed * dash_anim_speed_mult
		sprite.play("default")
		return
	sprite.speed_scale = _base_anim_speed
	if active:
		sprite.play("default")
	elif sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func die() -> void:
	if is_dead:
		return
	# Слоты детей ДО emit смерти, иначе enemy_count=0 и комната откроется рано.
	if can_split_on_death:
		_reserve_split_slots()
		call_deferred("_spawn_split_children")
	super.die()


func _reserve_split_slots() -> void:
	var room := _get_room_node()
	if room == null or not room.has_method("reserve_enemy_slot"):
		return
	for i in split_count:
		room.reserve_enemy_slot()


func _spawn_split_children() -> void:
	if not is_instance_valid(self):
		return
	if _self_scene == null and scene_file_path != "":
		_self_scene = load(scene_file_path) as PackedScene
	if _self_scene == null:
		return

	var room := _get_room_node()
	var origin := global_position
	var angles := TAU / float(split_count)
	for i in split_count:
		var child: EnemySpiderBigBoss = _self_scene.instantiate()
		_configure_split_child(child)
		var ang := angles * float(i) + randf_range(-0.2, 0.2)
		var spawn_pos := origin + Vector2.from_angle(ang) * split_spread
		_add_split_child(child, room, spawn_pos)


func _add_split_child(child: EnemySpiderBigBoss, room: Node, spawn_pos: Vector2) -> void:
	if room:
		room.add_child(child)
		if room.has_method("connect_single_enemy"):
			room.connect_single_enemy(child, false)
	else:
		var parent := get_parent()
		if parent:
			parent.add_child(child)
		else:
			child.queue_free()
			return

	child.global_position = spawn_pos
	_register_spawned_minion(child)

	if room and room.has_method("on_boss_minion_spawned"):
		room.on_boss_minion_spawned(child)


func _configure_split_child(child: EnemySpiderBigBoss) -> void:
	child.can_split_on_death = false
	child.BossName = BossName
	child.boss_base_hp = CHILD_HP
	child.boss_damage = CHILD_DAMAGE
	child.boss_move_speed_min = CHILD_SPEED_MIN
	child.boss_move_speed_max = CHILD_SPEED_MAX
	child.boss_model_scale = split_child_scale
	child.Boss_HP_buff = 1.0
	child.Boss_damage_buff = 1.0
	child.Boss_move_speed_buff = 1.0
	child.Boss_model_size_buff = 1.0
	child.Boss_phase_switch_buff = 0.0
	child.drop_coin_on_death = false
	child.direction_change_min = direction_change_min
	child.direction_change_max = direction_change_max
	child.angle_deviation = angle_deviation
	# Коллизии с другими пауками и с игроком (не проходить насквозь).
	child.collision_mask = child.collision_mask | PLAYER_COLLISION_LAYER


func _register_spawned_minion(minion: CharacterBody2D) -> void:
	if not is_instance_valid(minion):
		return
	_spawned_minions.append(minion)
	# Игнор только с умирающим родителем; между детьми — обычные коллизии.
	if is_instance_valid(self):
		_set_collision_ignored(minion, self)


func _set_collision_ignored(a: CharacterBody2D, b: CharacterBody2D) -> void:
	a.add_collision_exception_with(b)
	b.add_collision_exception_with(a)


func _get_room_node() -> Node:
	var node: Node = self
	while node:
		if node.has_method("connect_single_enemy"):
			return node
		node = node.get_parent()
	return null

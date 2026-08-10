extends Worm
class_name WormInsectedFly

## Пирамидный червь: при смерти выпускает трёх ослабленных мух.

const FLY_SCENE := preload("uid://bg8l17bqn1vun")
const FLY_COUNT := 3
const FLY_SCALE_MULT := 0.75
const FLY_STAND_TIME_MULT := 1.5
const FLY_HP_MULT := 0.5
const FLY_SHOTS := 3
const FLY_PROJECTILE_DAMAGE := 1
const FLY_PROJECTILE_MULT := 0.75
const SPAWN_INTERVAL := 0.5
const SCATTER_DURATION := 1.0

@export var spawn_below_offset: Vector2 = Vector2(0, 42)

var _spawned_minions: Array[CharacterBody2D] = []

@onready var _minion_spawn_point: Marker2D = get_node_or_null("MinionSpawnPoint") as Marker2D
@onready var _minion_spawn_point_2: Marker2D = get_node_or_null("MinionSpawnPoint2") as Marker2D
@onready var _minion_spawn_point_3: Marker2D = get_node_or_null("MinionSpawnPoint3") as Marker2D


func die() -> void:
	if is_dead:
		return
	_reserve_fly_slots(FLY_COUNT)
	call_deferred("_spawn_death_flies")
	super.die()


func _reserve_fly_slots(count: int) -> void:
	var room := _get_room_node()
	if room == null or not room.has_method("reserve_enemy_slot"):
		return
	for i in count:
		room.reserve_enemy_slot()


func _spawn_death_flies() -> void:
	var room := _get_room_node()
	var positions := _get_spawn_positions()
	var base_angle := randf() * TAU
	for i in positions.size():
		if i > 0:
			await get_tree().create_timer(SPAWN_INTERVAL).timeout
		var dir := Vector2.from_angle(
			base_angle + TAU * float(i) / float(FLY_COUNT) + randf_range(-0.35, 0.35)
		)
		_spawn_one_fly(room, positions[i], dir)


func _get_spawn_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if is_instance_valid(_minion_spawn_point):
		positions.append(_minion_spawn_point.global_position)
	if is_instance_valid(_minion_spawn_point_2):
		positions.append(_minion_spawn_point_2.global_position)
	if is_instance_valid(_minion_spawn_point_3):
		positions.append(_minion_spawn_point_3.global_position)
	var origin := global_position
	var fallback_offsets := [
		Vector2(-24.0, 0.0),
		Vector2(24.0, 0.0),
		Vector2(0.0, 18.0),
	]
	while positions.size() < FLY_COUNT:
		var offset: Vector2 = fallback_offsets[positions.size() % fallback_offsets.size()]
		positions.append(origin + offset + spawn_below_offset)
	return positions


func _spawn_one_fly(room: Node, at_global: Vector2, scatter_dir: Vector2) -> void:
	var fly: EnemyFly = FLY_SCENE.instantiate()
	_configure_spawned_fly(fly)

	if room:
		room.add_child(fly)
		if room.has_method("connect_single_enemy"):
			room.connect_single_enemy(fly, false)
	else:
		var parent := get_parent() if is_instance_valid(self) else null
		if parent == null:
			fly.queue_free()
			return
		parent.add_child(fly)

	fly.global_position = at_global
	fly.scale *= FLY_SCALE_MULT
	fly.begin_spawn_scatter(SCATTER_DURATION, scatter_dir)
	_register_spawned_minion(fly)


func _configure_spawned_fly(fly: EnemyFly) -> void:
	fly.drop_coin_on_death = false
	fly.hard_projectile_damage = FLY_PROJECTILE_DAMAGE
	fly.hard_damage = FLY_PROJECTILE_DAMAGE
	fly.shots_per_volley = FLY_SHOTS
	fly.hard_stand_time *= FLY_STAND_TIME_MULT
	fly.hard_base_hp = maxi(1, int(round(float(fly.hard_base_hp) * FLY_HP_MULT)))
	fly.projectile_speed_factor = FLY_PROJECTILE_MULT
	fly.projectile_visual_scale = FLY_PROJECTILE_MULT


func _register_spawned_minion(minion: CharacterBody2D) -> void:
	if not is_instance_valid(minion):
		return
	_spawned_minions.append(minion)
	if is_instance_valid(self):
		_set_collision_ignored(minion, self)
	for other in _spawned_minions:
		if other != minion and is_instance_valid(other):
			_set_collision_ignored(minion, other)


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

extends Worm
class_name WormInsected

const SPIDER_SMALL_SCENE := preload("res://game/enemy/1-st floor basement/Spider_small.tscn")
const MINION_COUNT := 2

@export var spawn_below_offset: Vector2 = Vector2(0, 42)

var _spawned_minions: Array[CharacterBody2D] = []

@onready var _minion_spawn_point: Marker2D = get_node_or_null("MinionSpawnPoint") as Marker2D
@onready var _minion_spawn_point_2: Marker2D = get_node_or_null("MinionSpawnPoint2") as Marker2D


func die() -> void:
	if is_dead:
		return
	_reserve_minion_slots(MINION_COUNT)
	call_deferred("_spawn_death_minions")
	super.die()


func _reserve_minion_slots(count: int) -> void:
	var room := _get_room_node()
	if room == null or not room.has_method("reserve_enemy_slot"):
		return
	for i in count:
		room.reserve_enemy_slot()


func _spawn_death_minions() -> void:
	if not is_instance_valid(self):
		return
	var room := _get_room_node()
	var positions := _get_spawn_positions()
	for at_global in positions:
		_spawn_one_minion(room, at_global)


func _get_spawn_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	if is_instance_valid(_minion_spawn_point):
		positions.append(_minion_spawn_point.global_position)
	if is_instance_valid(_minion_spawn_point_2):
		positions.append(_minion_spawn_point_2.global_position)
	var origin := global_position
	var fallback_offsets := [
		Vector2(-16.0, spawn_below_offset.y),
		Vector2(16.0, spawn_below_offset.y),
	]
	while positions.size() < MINION_COUNT:
		var offset: Vector2 = fallback_offsets[positions.size() % fallback_offsets.size()]
		positions.append(origin + offset)
	return positions


func _spawn_one_minion(room: Node, at_global: Vector2) -> void:
	var spawned_spider: CharacterBody2D = SPIDER_SMALL_SCENE.instantiate()
	spawned_spider.drop_coin_on_death = false

	if room:
		room.add_child(spawned_spider)
		if room.has_method("connect_single_enemy"):
			room.connect_single_enemy(spawned_spider, false)
	else:
		var parent := get_parent() if is_instance_valid(self) else null
		if parent == null:
			spawned_spider.queue_free()
			return
		parent.add_child(spawned_spider)

	spawned_spider.global_position = at_global
	_register_spawned_minion(spawned_spider)


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

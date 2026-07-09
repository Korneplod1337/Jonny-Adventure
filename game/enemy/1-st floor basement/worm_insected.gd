extends Worm
class_name WormInsected

var spider_small_scene: PackedScene = preload("res://game/enemy/1-st floor basement/Spider_small.tscn")
@export var spawn_below_offset: Vector2 = Vector2(0, 42)
var _spawned_minions: Array[CharacterBody2D] = []

@onready var _minion_spawn_point: Marker2D = get_node_or_null("MinionSpawnPoint") as Marker2D


func die() -> void:
	super()
	var spawned_spider: CharacterBody2D = spider_small_scene.instantiate()
	
	var room := _get_room_node()
	if room:
		if room.has_method("reserve_enemy_slot"):
			room.reserve_enemy_slot()
		room.add_child(spawned_spider)
		if room.has_method("connect_single_enemy"):
			room.connect_single_enemy(spawned_spider, false)
	else:
		get_parent().call_deferred('add_child', spawned_spider)

	spawned_spider.global_position = _minion_spawn_point.global_position
	
	#register spawned minion
	_spawned_minions.append(spawned_spider)
	_set_collision_ignored(spawned_spider, self)
	for other in _spawned_minions:
		if other != spawned_spider and is_instance_valid(other):
			_set_collision_ignored(spawned_spider, other)


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

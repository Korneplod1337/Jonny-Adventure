extends Node

const PIECE_SCENE := preload("res://game/objects/Equipment/_enchantments/lightning_bolt_piece.tscn")
const SEGMENT_LENGTH := 32.0
const ROTATION_SCATTER := deg_to_rad(30.0)
const ENEMY_GROUP := "Enemy"

var _damage: float = 0.0
var _bounce_range: float = 0.0
var _bounce_chance: float = 0.0
var _max_bounces: int = 0
var _bounce_delay: float = 0.0
var _piece_scale: float = 2.0
var _scatter_sign: float = 1.0


func start(
	first_target: Node,
	damage: float,
	bounce_range: float,
	bounce_chance: float,
	max_bounces: int,
	bounce_delay: float,
	piece_scale: float = 2.0
) -> void:
	_damage = damage
	_bounce_range = bounce_range
	_bounce_chance = bounce_chance
	_max_bounces = max_bounces
	_bounce_delay = bounce_delay
	_piece_scale = piece_scale
	_scatter_sign = 1.0 if randf() < 0.5 else -1.0
	_run_chain(first_target)


func _run_chain(first_target: Node) -> void:
	if not is_instance_valid(first_target):
		queue_free()
		return

	var from_pos: Vector2 = first_target.global_position
	_deal_damage(first_target)

	var previous: Node = first_target
	var bounces_left := _max_bounces

	while bounces_left > 0:
		await get_tree().create_timer(_bounce_delay).timeout
		if not is_inside_tree():
			return

		if randf() >= _bounce_chance:
			break

		var next := _find_random_target(from_pos, previous)
		if next == null:
			break

		var to_pos: Vector2 = next.global_position
		_spawn_line(from_pos, to_pos)
		_deal_damage(next)

		from_pos = to_pos
		previous = next
		bounces_left -= 1

	queue_free()


func _deal_damage(target: Node) -> void:
	if not is_instance_valid(target):
		return
	if target.get("is_dead") == true:
		return
	SoundManager.play_lightning()
	if target.has_method("hit"):
		target.hit(_damage, true)
	if target.has_method("apply_lightning"):
		target.apply_lightning()


func _spawn_line(from_pos: Vector2, to_pos: Vector2) -> void:
	var delta := to_pos - from_pos
	var dist := delta.length()
	if dist <= 0.001:
		return
	var dir := delta / dist
	var base_rot := dir.angle()
	var step := SEGMENT_LENGTH * _piece_scale * 0.8
	var travelled := 0.0
	while travelled < dist:
		var pos := from_pos + dir * travelled
		var scatter := randf() * ROTATION_SCATTER * _scatter_sign
		_scatter_sign *= -1.0
		_spawn_piece(pos, base_rot + scatter)
		travelled += step


func _spawn_piece(world_pos: Vector2, rot_rad: float) -> void:
	var parent: Node = get_parent()
	if parent == null:
		parent = get_tree().current_scene
	if parent == null:
		return
	var piece := PIECE_SCENE.instantiate()
	parent.add_child(piece)
	piece.setup(world_pos, rot_rad, _piece_scale)


func _find_random_target(from_pos: Vector2, exclude: Node) -> Node:
	var candidates: Array[Node] = []
	var range_sq := _bounce_range * _bounce_range
	for enemy in get_tree().get_nodes_in_group(ENEMY_GROUP):
		if not is_instance_valid(enemy):
			continue
		if enemy == exclude:
			continue
		if enemy.get("is_dead") == true:
			continue
		if not enemy is Node2D:
			continue
		if from_pos.distance_squared_to(enemy.global_position) > range_sq:
			continue
		candidates.append(enemy)
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]

extends Node
var _modifiers: Array[HitModifier] = []
var _modifier_ids: Dictionary = {}

const EXPLOSION_SCENE := preload("uid://b2iw2atdj0500")


func get_hit_contact_point(from_node: Node, target: Node, weapon_point: Vector2) -> Vector2:
	if not target is Node2D or not from_node is Node2D:
		return weapon_point

	var target_2d := target as Node2D
	var from_2d := from_node as Node2D
	var space_state := from_2d.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(target_2d.global_position, weapon_point)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 4

	var result := space_state.intersect_ray(query)
	if not result.is_empty():
		return result.position

	return _closest_point_on_body(target_2d, weapon_point)


func apply_hit_modifiers(info: DamageInfo) -> void:
	for modifier in _modifiers:
		modifier.apply(info)


func deal_damage(from_node: Node, primary_target: Node, info: DamageInfo) -> void:
	apply_hit_modifiers(info)

	if info.explosive and info.explosive_radius > 0.0:
		_deal_single(primary_target, info)
		_spawn_explosion(from_node, info)
	elif info.aoe_radius > 0.0:
		_deal_area(from_node, info, info.aoe_radius, primary_target)
	else:
		_deal_single(primary_target, info)


func _spawn_explosion(from_node: Node, info: DamageInfo) -> void:
	var explosion: CombatExplosion = EXPLOSION_SCENE.instantiate()
	explosion.global_position = info.hit_position
	explosion.setup(info.explosive_radius)
	from_node.get_tree().current_scene.call_deferred('add_child', explosion)




func add_modifier(modifier: HitModifier, id: String = "") -> void:
	if id != "":
		remove_modifier_by_id(id)
		_modifier_ids[id] = modifier
	_modifiers.append(modifier)

func remove_modifier(modifier: HitModifier) -> void:
	_modifiers.erase(modifier)
	for key in _modifier_ids.keys():
		if _modifier_ids[key] == modifier:
			_modifier_ids.erase(key)
			break

func remove_modifier_by_id(id: String) -> void:
	if not _modifier_ids.has(id):
		return
	var modifier: HitModifier = _modifier_ids[id]
	_modifiers.erase(modifier)
	_modifier_ids.erase(id)

func clear_modifiers() -> void:
	_modifiers.clear()
	_modifier_ids.clear()



func _deal_single(target: Node, info: DamageInfo) -> void:
	if not _can_be_damaged(target):
		return
	if info.enchantment:
		info.enchantment.apply_on_hit(target, info.direction)
	target.hit(info.damage, info.is_clear)

func _deal_area(from_node: Node, info: DamageInfo, radius: float, primary_target: Node) -> void:
	var targets := _find_targets_in_radius(from_node, info.hit_position, radius)
	if _can_be_damaged(primary_target) and primary_target not in targets:
		targets.append(primary_target)

	for target in targets:
		var target_info := info.duplicate_info()
		if target is Node2D:
			target_info.direction = (target.global_position - info.hit_position).normalized()
		_deal_single(target, target_info)

func _find_targets_in_radius(from_node: Node, center: Vector2, radius: float) -> Array[Node]:
	var targets: Array[Node] = []
	var space_state = from_node.get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, center)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 4

	for collision in space_state.intersect_shape(query):
		var body: Node = collision.collider
		if _can_be_damaged(body):
			targets.append(body)
	return targets

func _can_be_damaged(body: Node) -> bool:
	return body != null and body.has_method("hit") and body.name != "Player"


func _closest_point_on_body(body: Node2D, from_point: Vector2) -> Vector2:
	var best_point := from_point
	var best_dist_sq := INF

	for child in body.get_children():
		if child is CollisionShape2D and child.shape != null:
			var point := _closest_point_on_collision_shape(child, from_point)
			var dist_sq := from_point.distance_squared_to(point)
			if dist_sq < best_dist_sq:
				best_dist_sq = dist_sq
				best_point = point

	return best_point


func _closest_point_on_collision_shape(col: CollisionShape2D, global_point: Vector2) -> Vector2:
	var shape := col.shape
	var local_point := col.global_transform.affine_inverse() * global_point

	if shape is CircleShape2D:
		var circle: CircleShape2D = shape
		var dir := local_point
		if dir.length_squared() < 0.001:
			dir = Vector2.RIGHT
		else:
			dir = dir.normalized()
		return col.global_transform * (dir * circle.radius)

	if shape is RectangleShape2D:
		var rect_shape: RectangleShape2D = shape
		var half := rect_shape.size / 2.0
		var rect := Rect2(-half, rect_shape.size)
		return col.global_transform * _closest_point_on_rect_boundary(rect, local_point)

	return col.global_position


func _closest_point_on_rect_boundary(rect: Rect2, point: Vector2) -> Vector2:
	if rect.has_point(point):
		var dist_left := point.x - rect.position.x
		var dist_right := rect.end.x - point.x
		var dist_top := point.y - rect.position.y
		var dist_bottom := rect.end.y - point.y
		var min_dist := minf(dist_left, minf(dist_right, minf(dist_top, dist_bottom)))
		if is_equal_approx(min_dist, dist_left):
			return Vector2(rect.position.x, point.y)
		if is_equal_approx(min_dist, dist_right):
			return Vector2(rect.end.x, point.y)
		if is_equal_approx(min_dist, dist_top):
			return Vector2(point.x, rect.position.y)
		return Vector2(point.x, rect.end.y)

	return Vector2(
		clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y)
	)

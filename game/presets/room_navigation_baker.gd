class_name RoomNavigationBaker

const WALL_LAYER_MASK := 16
const OBSTACLE_LAYER_MASK := 32
const GAP_LAYER_MASK := 128
const AGENT_RADIUS := 48.0
const WALKABLE_INSET := 32.0


static func setup_for_room(room: Node2D) -> void:
	if room.get_node_or_null("NavigationRegion"):
		return

	var outer_outline := _get_walkable_outline(room)
	if outer_outline.is_empty():
		push_warning("RoomNavigationBaker: no walkable outline in %s" % room.name)
		return

	outer_outline = _inset_rect_outline(outer_outline, WALKABLE_INSET)
	if outer_outline.is_empty():
		return

	var nav_poly := NavigationPolygon.new()
	nav_poly.agent_radius = AGENT_RADIUS

	var source_data := NavigationMeshSourceGeometryData2D.new()
	source_data.add_traversable_outline(_ensure_ccw(outer_outline))

	for obstruction in _collect_collision_outlines(room, WALL_LAYER_MASK | OBSTACLE_LAYER_MASK | GAP_LAYER_MASK):
		source_data.add_obstruction_outline(_ensure_cw(obstruction))

	NavigationServer2D.bake_from_source_geometry_data(nav_poly, source_data)

	if nav_poly.get_polygon_count() == 0:
		push_warning("RoomNavigationBaker: bake failed in %s" % room.name)
		return

	var nav_region := NavigationRegion2D.new()
	nav_region.name = "NavigationRegion"
	nav_region.navigation_polygon = nav_poly
	room.add_child(nav_region)


static func _get_walkable_outline(room: Node2D) -> PackedVector2Array:
	var camera_bounds := room.get_node_or_null("CameraBounds")
	if not camera_bounds:
		return PackedVector2Array()

	for child in camera_bounds.get_children():
		if child is CollisionShape2D:
			var outline := _outline_from_collision_shape(room, child as CollisionShape2D)
			if not outline.is_empty():
				return outline

	return PackedVector2Array()


static func _collect_collision_outlines(room: Node2D, layer_mask: int) -> Array[PackedVector2Array]:
	var outlines: Array[PackedVector2Array] = []
	_collect_collision_outlines_recursive(room, outlines, layer_mask)
	return outlines


static func _collect_collision_outlines_recursive(
	node: Node,
	outlines: Array[PackedVector2Array],
	layer_mask: int
) -> void:
	if node is CollisionShape2D:
		var collision := node as CollisionShape2D
		var body := collision.get_parent()
		if body is CollisionObject2D:
			var collision_object := body as CollisionObject2D
			if collision_object.collision_layer & layer_mask:
				var room := _find_room_root(node)
				if room:
					var outline := _outline_from_collision_shape(room, collision)
					if not outline.is_empty():
						outlines.append(outline)
	elif node is CollisionPolygon2D:
		var collision := node as CollisionPolygon2D
		var body := collision.get_parent()
		if body is CollisionObject2D:
			var collision_object := body as CollisionObject2D
			if collision_object.collision_layer & layer_mask:
				var room := _find_room_root(node)
				if room:
					var outline := PackedVector2Array()
					for point in collision.polygon:
						outline.append(room.to_local(collision.global_transform * point))
					if outline.size() >= 3:
						outlines.append(outline)

	for child in node.get_children():
		_collect_collision_outlines_recursive(child, outlines, layer_mask)


static func _find_room_root(node: Node) -> Node2D:
	var current := node
	while current:
		if current is Node2D and current.get_node_or_null("CameraBounds"):
			return current as Node2D
		current = current.get_parent()
	return null


static func _outline_from_collision_shape(
	room: Node2D,
	collision: CollisionShape2D
) -> PackedVector2Array:
	if collision.shape is RectangleShape2D:
		var rect := collision.shape as RectangleShape2D
		var half := rect.size * 0.5
		var local_corners := [
			Vector2(-half.x, -half.y),
			Vector2(half.x, -half.y),
			Vector2(half.x, half.y),
			Vector2(-half.x, half.y),
		]
		var outline := PackedVector2Array()
		for corner in local_corners:
			outline.append(room.to_local(collision.global_transform * corner))
		return outline

	if collision.shape is CircleShape2D:
		var circle := collision.shape as CircleShape2D
		var outline := PackedVector2Array()
		for i in 12:
			var angle := TAU * float(i) / 12.0
			var local_point := Vector2.RIGHT.rotated(angle) * circle.radius
			outline.append(room.to_local(collision.global_transform * local_point))
		return outline

	if collision.shape is CapsuleShape2D:
		var capsule := collision.shape as CapsuleShape2D
		var outline := PackedVector2Array()
		var radius := capsule.radius
		var half_height := maxf(capsule.height * 0.5, 0.0)
		var top := Vector2(0.0, -half_height)
		var bottom := Vector2(0.0, half_height)
		for i in 6:
			var angle := PI + TAU * float(i) / 12.0
			outline.append(
				room.to_local(collision.global_transform * (top + Vector2.RIGHT.rotated(angle) * radius))
			)
		for i in 6:
			var angle := TAU * float(i) / 12.0
			outline.append(
				room.to_local(collision.global_transform * (bottom + Vector2.RIGHT.rotated(angle) * radius))
			)
		return outline

	return PackedVector2Array()


static func _inset_rect_outline(outline: PackedVector2Array, inset: float) -> PackedVector2Array:
	if outline.size() != 4:
		return outline

	var center := Vector2.ZERO
	for point in outline:
		center += point
	center /= 4.0

	var inset_outline := PackedVector2Array()
	for point in outline:
		var dir := point - center
		if dir.length_squared() < 0.01:
			inset_outline.append(point)
			continue
		inset_outline.append(point - dir.normalized() * inset)
	return inset_outline


static func _ensure_ccw(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if _polygon_area(result) < 0.0:
		result.reverse()
	return result


static func _ensure_cw(points: PackedVector2Array) -> PackedVector2Array:
	var result := points.duplicate()
	if _polygon_area(result) > 0.0:
		result.reverse()
	return result


static func _polygon_area(points: PackedVector2Array) -> float:
	if points.size() < 3:
		return 0.0

	var area := 0.0
	for i in points.size():
		var j := (i + 1) % points.size()
		area += points[i].x * points[j].y - points[j].x * points[i].y
	return area * 0.5

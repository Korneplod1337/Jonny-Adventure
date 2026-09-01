extends BaseShot
class_name SwordShot

const MELEE_COPY_DECAY := 0.85
const MELEE_TIP_OFFSET_MULT := 100.0

@onready var anim_sprite: AnimatedSprite2D = $shot_Animated
@onready var col_shape: CollisionShape2D = $CollisionShape2D

var _melee_size_scale: float = 1.0
var _fire_direction := Vector2.RIGHT
var _melee_boomerang_legs: Array = []
var _melee_boomerang_leg_index := 0
var _melee_boomerang_copy := false
var _melee_spin_duration := 0.0


func _ready() -> void:
	speed = 0
	extra_reload = 1
	self_damage_multiplier = 0.8
	rotation = direction.angle()
	_fire_direction = direction.normalized()
	_melee_size_scale = clampf(0.4 + atk_range / 300.0, 0.6, 4.0)
	scale = Vector2(_melee_size_scale, _melee_size_scale)

	if GameState.SpreadShot and not _melee_boomerang_copy:
		_play_attack_sfx()
		call_deferred("_try_spread_shot_melee")
		return

	if not _melee_boomerang_copy:
		_play_attack_sfx()
		if boomerang_power > 0:
			_melee_boomerang_legs = BoomerangPath.build_legs(boomerang_power)

	if not anim_sprite.is_connected("frame_changed", Callable(self, "_on_frame_changed")):
		anim_sprite.frame_changed.connect(_on_frame_changed)
	if not anim_sprite.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		anim_sprite.animation_finished.connect(_on_animation_finished)
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited_ricochet):
		body_exited.connect(_on_body_exited_ricochet)
	anim_sprite.play("default")
	_on_frame_changed()
	


func _physics_process(_delta: float) -> void:
	pass


func _uses_melee_ricochet() -> bool:
	return true


func _get_flight_direction() -> Vector2:
	var dir := direction.normalized()
	if dir != Vector2.ZERO:
		return dir
	dir = _fire_direction.normalized()
	if dir != Vector2.ZERO:
		return dir
	return Vector2.RIGHT


func _on_body_entered(body: Node) -> void:
	if exploded:
		return
	if body.name == "Player" or body.is_in_group("player"):
		return
	if _ricochet_overlap_id != 0 and body.get_instance_id() == _ricochet_overlap_id:
		return

	if body.has_method("hit"):
		if not _is_ricochet_ignored(body):
			_deal_hit(body, _get_final_damage())
		_try_ricochet(body)
	else:
		_try_ricochet(body)


func _perform_melee_ricochet(body: Node) -> bool:
	var bounce := _compute_bounce_info(body)
	var normal: Vector2 = bounce.normal
	var hit_point: Vector2 = bounce.point
	var in_dir := _get_flight_direction()
	var out_dir := _apply_ricochet_spread(in_dir.bounce(normal))
	if out_dir.length_squared() < 0.0001:
		out_dir = _apply_ricochet_spread(-in_dir)

	ricochet -= 1

	var bounce_id := body.get_instance_id() if is_instance_valid(body) else 0
	if bounce_id != 0:
		_ricochet_overlap_id = bounce_id

	# Tip of current swing sits on impact; slash continues along bounce direction.
	var tip_local := col_shape.position if col_shape else Vector2.ZERO
	var tip_world_offset := tip_local.rotated(out_dir.angle()) * scale
	var spawn_pos := hit_point - tip_world_offset + normal * 4.0

	var parent_node := get_parent()
	if parent_node == null:
		return false

	var copy: SwordShot = duplicate()
	_configure_melee_copy(copy, out_dir, bounce_id)
	copy.monitoring = false
	copy.global_position = spawn_pos
	copy.rotation = out_dir.angle()
	parent_node.add_child.call_deferred(copy)
	copy.set_deferred("monitoring", true)
	return true


func _configure_melee_copy(copy: SwordShot, out_dir: Vector2, bounce_body_id: int) -> void:
	copy._melee_boomerang_copy = true
	copy._melee_boomerang_legs = _melee_boomerang_legs
	copy._melee_boomerang_leg_index = _melee_boomerang_leg_index
	copy._fire_direction = out_dir
	copy.direction = out_dir
	copy.boomerang_power = boomerang_power
	copy.damage = damage
	copy.enchantment = enchantment
	copy.self_damage_multiplier = self_damage_multiplier
	copy.self_range_multiplier = self_range_multiplier
	copy.spawned_spread = true
	copy.atk_range = atk_range
	copy.ricochet = ricochet
	copy.penetration = penetration
	copy.hack = hack
	copy._ricochet_ignore_ids = _ricochet_ignore_ids.duplicate()
	if bounce_body_id != 0:
		copy._ricochet_ignore_ids.append(bounce_body_id)
	if _melee_spin_duration > 0.0:
		copy._melee_spin_duration = _melee_spin_duration


func _on_frame_changed() -> void:
	var frame = anim_sprite.frame

	match frame:
		0:
			col_shape.position = Vector2(50, -34)
			col_shape.rotation = 0.45
		1:
			col_shape.position = Vector2(55.25, -25.5)
			col_shape.rotation = 0.82
		2:
			col_shape.position = Vector2(58.5, -17)
			col_shape.rotation = 1.09
		3:
			col_shape.position = Vector2(62.75, -8.5)
			col_shape.rotation = 1.36
		4:
			col_shape.position = Vector2(67, 0)
			col_shape.rotation = 1.65
		5:
			col_shape.position = Vector2(62, 11)
			col_shape.rotation = 2
		6:
			col_shape.position = Vector2(55, 22)
			col_shape.rotation = 2.37
		7:
			col_shape.position = Vector2(48, 32)
			col_shape.rotation = 2.74


func _on_animation_finished() -> void:
	_try_spawn_melee_boomerang_copy()
	queue_free()


func _try_spawn_melee_boomerang_copy() -> bool:
	var next_index := _melee_boomerang_leg_index + 1
	if next_index >= _melee_boomerang_legs.size():
		return false

	var leg: Dictionary = _melee_boomerang_legs[next_index]
	var copy: SwordShot = duplicate()
	copy._melee_boomerang_copy = true
	copy._melee_boomerang_legs = _melee_boomerang_legs
	copy._melee_boomerang_leg_index = next_index
	copy._fire_direction = _fire_direction
	copy.boomerang_power = boomerang_power
	copy.damage = damage
	copy.enchantment = enchantment
	copy.self_damage_multiplier = self_damage_multiplier
	copy.self_range_multiplier = self_range_multiplier
	copy.spawned_spread = true
	copy.atk_range = atk_range * MELEE_COPY_DECAY
	copy.ricochet = ricochet
	copy.penetration = penetration
	copy.hack = hack
	copy._ricochet_ignore_ids = _ricochet_ignore_ids.duplicate()
	if _melee_spin_duration > 0.0:
		copy._melee_spin_duration = _melee_spin_duration * MELEE_COPY_DECAY
	copy.direction = _fire_direction if leg.forward else -_fire_direction

	var tip_offset := direction.normalized() * (_melee_size_scale * MELEE_TIP_OFFSET_MULT)
	get_parent().add_child(copy)
	copy.global_position = global_position + tip_offset
	copy.rotation = copy.direction.angle()
	return true


func explosion(_animation_index) -> void:
	pass


func _on_explosion_finished() -> void:
	pass

extends SwordShot
class_name SolarisShot

const AURA_GROUP := "solaris_aura"
const PLAYER_OFFSET := Vector2(0, -10)
const AURA_META := "solaris_aura"

var _cooldown := 0.0


func _ready() -> void:
	visible = false
	set_physics_process(false)
	speed = 0
	extra_reload = 1
	use_spread = false
	pellet_count = 1
	rotation = 0.0

	# Инстанс от fire() — только для extra_reload у игрока, урон делает постоянная аура
	var existing := _get_existing_aura()
	if existing != null and existing != self:
		queue_free()
		return

	visible = true
	add_to_group(AURA_GROUP)
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_meta(AURA_META, self)
	_update_aura_scale()
	_cooldown = 0.0
	set_physics_process(true)


func _exit_tree() -> void:
	if player and player.get_meta(AURA_META, null) == self:
		player.remove_meta(AURA_META)


func _physics_process(delta: float) -> void:
	player = get_tree().get_first_node_in_group("player")
	if player == null or player.shot_id != "Solaris":
		queue_free()
		return

	global_position = player.global_position + PLAYER_OFFSET
	rotation = 0.0

	var new_range: float = player.atk_range
	if not is_equal_approx(new_range, atk_range):
		atk_range = new_range
		_update_aura_scale()

	player.extra_fire_rate = extra_reload

	_cooldown -= delta
	if _cooldown > 0.0:
		return
	# Всегда активно, пока экипировано (фишка Solaris). Пауза только при локах.
	if player.movement_locked or player.attack_locked:
		return

	damage = player.damage
	atk_range = player.atk_range
	enchantment = player.shot_enchantment
	_deal_aura_damage()

	_cooldown = StatManager.get_stat(player, "fire_rate")
	player.fire_rate = _cooldown


func _update_aura_scale() -> void:
	_melee_size_scale = clampf(0.8 + atk_range / 300.0, 0.8, 8.0)
	scale = Vector2(_melee_size_scale, _melee_size_scale)


func _deal_aura_damage() -> void:
	_update_aura_scale()
	var amount := _get_final_damage()
	_show_crit_effect()

	var radius := _get_aura_radius()
	if radius <= 0.0:
		return

	var space := get_world_2d().direct_space_state
	var circle := CircleShape2D.new()
	circle.radius = radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, global_position)
	query.collision_mask = collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true

	for result in space.intersect_shape(query, 64):
		var body: Node = result.get("collider")
		if body == null:
			continue
		if body.is_in_group("player") or body.name == "Player":
			continue
		if body.has_method("hit"):
			DamageDealer.deal_damage(self, body, _build_damage_info(body, amount))


func _get_aura_radius() -> float:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null or col.shape == null:
		return 0.0
	var shape_scale := absf(col.scale.x) * absf(scale.x)
	if col.shape is CircleShape2D:
		return (col.shape as CircleShape2D).radius * shape_scale
	return 47.0 * shape_scale


func _show_crit_effect() -> void:
	if crit_sprite < 0:
		return
	var crit_node := get_node_or_null("Crit")
	if crit_node is AnimatedSprite2D:
		crit_node.position = CRIT_WORLD_OFFSET
		crit_node.rotation = 0.0
		crit_node.frame = crit_sprite
		crit_node.show()


func _on_body_entered(_body: Node) -> void:
	pass


func _on_frame_changed() -> void:
	pass


func _on_animation_finished() -> void:
	pass


func _get_existing_aura() -> SolarisShot:
	var p := get_tree().get_first_node_in_group("player")
	if p and p.has_meta(AURA_META):
		var meta_aura = p.get_meta(AURA_META)
		if meta_aura is SolarisShot and is_instance_valid(meta_aura) and not meta_aura.is_queued_for_deletion():
			return meta_aura

	for node in get_tree().get_nodes_in_group(AURA_GROUP):
		if node is SolarisShot and is_instance_valid(node) and not node.is_queued_for_deletion():
			return node
	return null

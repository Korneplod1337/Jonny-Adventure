extends SwordShot
class_name SolarisShot

const AURA_GROUP := "solaris_aura"
const PLAYER_OFFSET := Vector2(0, -10)
const AURA_META := "solaris_aura"

var _cooldown := 0.0
## Мини-ауры на креплениях Satellite (пусто если режим обычный).
var _orbit_auras: Array = []
var _satellite_mode := false


func _ready() -> void:
	visible = false
	set_physics_process(false)
	extra_reload = 1
	self_damage_multiplier = 1
	speed = 0
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
	_clear_orbit_auras()
	if player and player.get_meta(AURA_META, null) == self:
		player.remove_meta(AURA_META)


func _physics_process(delta: float) -> void:
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		# Переход уровня — ждём игрока, не самоуничтожаемся.
		return
	if player.shot_id != "Solaris":
		queue_free()
		return

	# Держим ауру в том же мире/сцене, что и игрок.
	_ensure_same_scene_as_player()

	var want_sat := GameState.SatelliteOrbit
	if want_sat != _satellite_mode:
		_satellite_mode = want_sat
		if _satellite_mode:
			_enter_satellite_mode()
		else:
			_exit_satellite_mode()
	elif _satellite_mode:
		# SatelliteBuff и т.п. меняют число слотов без смены режима.
		_sync_orbit_aura_count()

	var new_range: float = player.atk_range
	if not is_equal_approx(new_range, atk_range):
		atk_range = new_range
		_update_aura_scale()
		_refresh_orbit_aura_scales()

	player.extra_fire_rate = extra_reload

	if _satellite_mode:
		_update_orbit_aura_positions()
		visible = false
	else:
		visible = true
		global_position = player.global_position + PLAYER_OFFSET
		rotation = 0.0

	_cooldown -= delta
	if _cooldown > 0.0:
		return
	if player.movement_locked or player.attack_locked:
		return

	damage = player.damage
	atk_range = player.atk_range
	enchantment = player.shot_enchantment
	extra_enchantment = null
	if GameState.WildBoots:
		var magic := StatManager.get_stat(player, "magic")
		var chance := lerpf(0.2, 0.4, clampf(magic / 4.0, 0.0, 1.0))
		if randf() < chance:
			extra_enchantment = EquipManager.roll_guaranteed_enchantment()

	if _satellite_mode:
		_deal_orbit_auras_damage()
	else:
		_deal_aura_damage()

	_cooldown = StatManager.get_stat(player, "fire_rate")
	player.fire_rate = _cooldown


func _ensure_same_scene_as_player() -> void:
	if player == null or not is_inside_tree():
		return
	var dest := get_tree().current_scene
	if dest == null:
		dest = player.get_parent()
	if dest == null:
		return
	if get_parent() != dest:
		reparent(dest)


func _enter_satellite_mode() -> void:
	var ctrl := _get_or_create_orbit_ctrl()
	if ctrl and ctrl.has_method("snap_even_layout"):
		ctrl.snap_even_layout()
	_rebuild_orbit_auras()
	visible = false


func _exit_satellite_mode() -> void:
	_clear_orbit_auras()
	visible = true
	_update_aura_scale()


func _sync_orbit_aura_count() -> void:
	var ctrl := _get_or_create_orbit_ctrl()
	if ctrl == null:
		return
	var need := ctrl.get_max_slots()
	if _orbit_auras.size() == need:
		return
	if ctrl.has_method("snap_even_layout"):
		ctrl.snap_even_layout()
	_rebuild_orbit_auras()


func _rebuild_orbit_auras() -> void:
	_clear_orbit_auras()
	var ctrl := _get_or_create_orbit_ctrl()
	if ctrl == null:
		return
	var n := ctrl.get_max_slots()
	var base_sc := _base_aura_scale()
	var sc := base_sc / float(maxi(n, 1))
	for i in n:
		var aura := _make_orbit_visual(sc)
		_orbit_auras.append({"node": aura, "slot": i})


func _get_or_create_orbit_ctrl() -> SatelliteOrbitController:
	if player == null:
		return null
	var ctrl := player.get_node_or_null("SatelliteOrbit") as SatelliteOrbitController
	if ctrl == null:
		ctrl = SatelliteOrbitController.new()
		ctrl.name = "SatelliteOrbit"
		player.add_child(ctrl)
	return ctrl


func _make_orbit_visual(sc: float) -> Node2D:
	var holder := Node2D.new()
	holder.z_index = z_index
	var spr := get_node_or_null("shot_Animated") as AnimatedSprite2D
	if spr:
		var copy: AnimatedSprite2D = spr.duplicate() as AnimatedSprite2D
		copy.visible = true
		holder.add_child(copy)
	holder.scale = Vector2(sc, sc)
	var parent_n := get_parent()
	if parent_n:
		parent_n.add_child(holder)
	else:
		add_child(holder)
	return holder


func _clear_orbit_auras() -> void:
	for entry in _orbit_auras:
		var n = entry.get("node")
		if n != null and is_instance_valid(n):
			n.queue_free()
	_orbit_auras.clear()


func _update_orbit_aura_positions() -> void:
	var ctrl := _get_or_create_orbit_ctrl()
	if ctrl == null:
		return
	for entry in _orbit_auras:
		var n: Node2D = entry.get("node") as Node2D
		var slot: int = int(entry.get("slot", 0))
		if n == null or not is_instance_valid(n):
			continue
		n.global_position = ctrl.get_anchor_world_pos(slot)
		n.global_rotation = 0.0


func _refresh_orbit_aura_scales() -> void:
	if not _satellite_mode:
		return
	var ctrl := _get_or_create_orbit_ctrl()
	var nslot := ctrl.get_max_slots() if ctrl else 1
	var sc := _base_aura_scale() / float(maxi(nslot, 1))
	for entry in _orbit_auras:
		var n: Node2D = entry.get("node") as Node2D
		if n:
			n.scale = Vector2(sc, sc)


func _deal_orbit_auras_damage() -> void:
	_refresh_orbit_aura_scales()
	var ctrl := _get_or_create_orbit_ctrl()
	if ctrl == null:
		return
	var base_r := _get_aura_radius_unscaled()
	var nslot := maxi(ctrl.get_max_slots(), 1)
	var radius := base_r * (_base_aura_scale() / float(nslot))
	if radius <= 0.0:
		return
	for entry in _orbit_auras:
		var slot: int = int(entry.get("slot", 0))
		var pos := ctrl.get_anchor_world_pos(slot)
		_deal_aura_at(pos, radius)


func _base_aura_scale() -> float:
	return clampf(0.8 + atk_range / 300.0, 0.8, 8.0)


func _update_aura_scale() -> void:
	_melee_size_scale = _base_aura_scale()
	if _satellite_mode:
		var ctrl := _get_or_create_orbit_ctrl()
		var n := ctrl.get_max_slots() if ctrl else 1
		scale = Vector2.ONE * (_melee_size_scale / float(maxi(n, 1)))
	else:
		scale = Vector2(_melee_size_scale, _melee_size_scale)


func _deal_aura_damage() -> void:
	_update_aura_scale()
	var radius := _get_aura_radius()
	if radius <= 0.0:
		return
	_deal_aura_at(global_position, radius)
	_show_crit_effect()


func _deal_aura_at(pos: Vector2, radius: float) -> void:
	var space := get_world_2d().direct_space_state
	var circle := CircleShape2D.new()
	circle.radius = radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.transform = Transform2D(0.0, pos)
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
			var amount := _get_final_damage(body)
			DamageDealer.deal_damage(self, body, _build_damage_info(body, amount))


func _get_aura_radius_unscaled() -> float:
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null or col.shape == null:
		return 47.0
	var shape_scale := absf(col.scale.x)
	if col.shape is CircleShape2D:
		return (col.shape as CircleShape2D).radius * shape_scale
	return 47.0 * shape_scale


func _get_aura_radius() -> float:
	return _get_aura_radius_unscaled() * absf(scale.x)


func _show_crit_effect() -> void:
	if crit_sprite < 0:
		return
	var crit_node := get_node_or_null("Crit")
	if crit_node is AnimatedSprite2D:
		crit_node.frame = crit_sprite
		crit_node.show()
		crit_node.global_rotation = 0.0
		crit_node.global_position = global_position + CRIT_WORLD_OFFSET


func _on_body_entered(_body: Node) -> void:
	pass


func _allows_ricochet() -> bool:
	return false


func _uses_melee_ricochet() -> bool:
	return false


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


## Вызвать после смены этажа / сцены — пересоздать ауру если Solaris экипирован.
static func ensure_for_player(p: Node) -> void:
	if p == null or not is_instance_valid(p):
		return
	if str(p.get("shot_id")) != "Solaris":
		return
	var existing = p.get_meta(AURA_META, null) if p.has_meta(AURA_META) else null
	if existing is SolarisShot and is_instance_valid(existing) and not existing.is_queued_for_deletion():
		if existing.get_tree() == p.get_tree():
			existing._ensure_same_scene_as_player()
			return
	# Старая аура умерла со сценой — спавним заново.
	var scene: PackedScene = p.get("shot_scene") as PackedScene
	if scene == null:
		return
	var aura: SolarisShot = scene.instantiate() as SolarisShot
	if aura == null:
		return
	aura.damage = p.damage
	aura.atk_range = p.atk_range
	var dest := p.get_tree().current_scene
	if dest == null:
		dest = p.get_parent()
	if dest == null:
		aura.queue_free()
		return
	dest.add_child(aura)
	aura.global_position = p.global_position + PLAYER_OFFSET

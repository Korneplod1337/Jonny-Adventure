extends BaseShot_equip


func apply_equip(player) -> void:
	super.apply_equip(player)
	_spawn_persistent_aura(player)


func _spawn_persistent_aura(player) -> void:
	if projectile == null or player == null:
		return

	for node in get_tree().get_nodes_in_group(SolarisShot.AURA_GROUP):
		if is_instance_valid(node):
			node.queue_free()

	var aura: SolarisShot = projectile.instantiate()
	aura.damage = player.damage
	aura.atk_range = player.atk_range
	if enchantment:
		aura.enchantment = enchantment.duplicate(true)
	get_tree().current_scene.add_child(aura)
	aura.global_position = player.global_position + SolarisShot.PLAYER_OFFSET

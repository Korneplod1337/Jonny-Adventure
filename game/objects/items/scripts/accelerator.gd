extends Item

func apply_item_effect() -> void:
	player.accelerator_power += effect_power #2
	player.speed_bonus += 2
	player.move_speed = StatManager.get_stat(player, "move_speed")
	player.damage = StatManager.get_stat(player, "damage")
	player._emit_stats_changed()

extends Item

func apply_item_effect() -> void:
	player.sacrosanct_power += effect_power #0.2
	player.damage = StatManager.get_stat(player, "damage")
	player._emit_stats_changed()

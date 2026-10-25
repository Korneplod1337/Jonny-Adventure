extends Item

func apply_item_effect() -> void:
	player.critical_flower_power += effect_power #1
	player.luck_bonus += 1
	player.accuracy_bonus += 1
	player.luck = StatManager.get_stat(player, "luck")
	player.spread = StatManager.get_stat(player, "spread")
	player._emit_stats_changed()

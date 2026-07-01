extends Item


func apply_item_effect() -> void:
	player.crit_chance_bonus += effect_power
	player.accuracy_bonus += 2
	player.spread = StatManager.get_stat(player, "spread")
	player._emit_stats_changed()

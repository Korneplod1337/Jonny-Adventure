extends Item

func apply_item_effect() -> void:
	player.siege_hammer_power += effect_power #25
	player.accuracy_bonus += 2
	player.spread = StatManager.get_stat(player, "spread")
	player._emit_stats_changed()

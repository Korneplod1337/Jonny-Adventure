extends Item

func apply_item_effect() -> void:
	player.range_bonus += 1
	player.accuracy_bonus += 1
	player.atk_range = StatManager.get_stat(player, "range")
	player.spread = StatManager.get_stat(player, "spread")
	player._emit_stats_changed()

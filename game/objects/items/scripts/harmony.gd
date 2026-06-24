extends Item

func apply_item_effect() -> void:
	player.accuracy_bonus += 2
	player.range_bonus += 1
	player.spread = StatManager.get_stat(player, "spread")
	player.atk_range = StatManager.get_stat(player, "range")
	player._emit_stats_changed()

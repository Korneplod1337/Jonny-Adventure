extends Item

func apply_item_effect() -> void:
	player.accuracy_bonus += 4
	player.spread = StatManager.get_stat(player, "spread")
	player._emit_stats_changed()

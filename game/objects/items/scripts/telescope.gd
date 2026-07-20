extends Item

func apply_item_effect() -> void:
	player.range_bonus += 3
	player.atk_range = StatManager.get_stat(player, "range")
	player._emit_stats_changed()

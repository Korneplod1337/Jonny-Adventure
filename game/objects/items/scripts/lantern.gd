extends Item

func apply_item_effect() -> void:
	player.range_bonus += 2
	player.luck_bonus += 3
	player.atk_range = StatManager.get_stat(player, "range")
	player.luck = StatManager.get_stat(player, "luck")
	player._emit_stats_changed()

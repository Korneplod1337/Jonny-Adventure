extends Item

func apply_item_effect() -> void:
	player.luck_bonus += 1
	player.range_bonus += 1
	player.luck = StatManager.get_stat(player, "luck")
	player.atk_range = StatManager.get_stat(player, "range")
	player._emit_stats_changed()

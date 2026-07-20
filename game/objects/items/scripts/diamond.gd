extends Item

func apply_item_effect() -> void:
	player.luck_bonus += 3
	player.range_bonus += 3
	player.fire_rate_bonus += 3
	player.luck = StatManager.get_stat(player, "luck")
	player.atk_range = StatManager.get_stat(player, "range")
	player.fire_rate = StatManager.get_stat(player, "fire_rate")
	player._emit_stats_changed()

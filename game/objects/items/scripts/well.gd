extends Item

func apply_item_effect() -> void:
	player.fire_rate_bonus += 3
	player.luck_bonus += 1
	player.fire_rate = StatManager.get_stat(player, "fire_rate")
	player.luck = StatManager.get_stat(player, "luck")
	player._emit_stats_changed()

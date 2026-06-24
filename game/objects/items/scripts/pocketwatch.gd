extends Item

func apply_item_effect() -> void:
	player.fire_rate_bonus += 1
	player.fire_rate = StatManager.get_stat(player, "fire_rate")
	player._emit_stats_changed()

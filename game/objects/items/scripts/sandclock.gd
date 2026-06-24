extends Item

func apply_item_effect() -> void:
	player.speed_bonus += 1
	player.fire_rate_bonus += 1
	player.move_speed = StatManager.get_stat(player, "move_speed")
	player.fire_rate = StatManager.get_stat(player, "fire_rate")
	player._emit_stats_changed()

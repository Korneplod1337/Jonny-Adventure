extends Item

func apply_item_effect() -> void:
	player.speed_bonus += 2
	player.accuracy_bonus += 2
	player.move_speed = StatManager.get_stat(player, "move_speed")
	player.spread = StatManager.get_stat(player, "spread")
	player._emit_stats_changed()

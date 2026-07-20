extends Item

func apply_item_effect() -> void:
	player.accuracy_bonus += 2
	player.speed_bonus += 2
	player.spread = StatManager.get_stat(player, "spread")
	player.move_speed = StatManager.get_stat(player, "move_speed")
	player._emit_stats_changed()

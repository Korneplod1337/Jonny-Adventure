extends Item

func apply_item_effect() -> void:
	player.luck_bonus += 1
	player.luck = StatManager.get_stat(player, "luck")
	player._emit_stats_changed()

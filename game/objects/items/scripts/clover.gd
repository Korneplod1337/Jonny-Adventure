extends Item

func apply_item_effect() -> void:
	player.luck_bonus += 4
	player.luck = StatManager.get_stat(player, "luck")
	player._emit_stats_changed()

extends Item

func apply_item_effect() -> void:
	player.luck_bonus += 1
	player.magic_bonus += 1
	player.luck = StatManager.get_stat(player, "luck")
	player.magic = StatManager.get_stat(player, "magic")
	player._emit_stats_changed()

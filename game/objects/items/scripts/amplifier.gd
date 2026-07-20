extends Item

func apply_item_effect() -> void:
	player.magic_bonus += 4
	player.magic = StatManager.get_stat(player, "magic")
	player._emit_stats_changed()

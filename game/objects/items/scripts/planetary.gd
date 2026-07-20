extends Item

func apply_item_effect() -> void:
	player.range_bonus += 2
	player.hp_bonus += 1
	player.atk_range = StatManager.get_stat(player, "range")
	player.max_hp = int(StatManager.get_stat(player, "hp"))
	player._emit_stats_changed()

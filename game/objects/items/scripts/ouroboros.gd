extends Item

func apply_item_effect() -> void:
	player.hp_bonus += 2
	player.magic_bonus += 2
	player.max_hp = int(StatManager.get_stat(player, "hp"))
	player.magic = StatManager.get_stat(player, "magic")
	player._emit_stats_changed()

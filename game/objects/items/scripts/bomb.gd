extends Item

func apply_item_effect() -> void:
	player.damage_bonus += 1
	player.magic_bonus += 2
	player.damage = StatManager.get_stat(player, "damage")
	player.magic = StatManager.get_stat(player, "magic")
	player._emit_stats_changed()

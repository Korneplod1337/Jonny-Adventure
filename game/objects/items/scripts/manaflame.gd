extends Item

func apply_item_effect() -> void:
	player.magic_bonus += 3
	player.damage_bonus += 1
	player.magic = StatManager.get_stat(player, "magic")
	player.damage = StatManager.get_stat(player, "damage")
	player._emit_stats_changed()

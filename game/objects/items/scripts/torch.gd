extends Item

func apply_item_effect() -> void:
	player.damage_bonus += 1
	player.damage = StatManager.get_stat(player, "damage")
	player._emit_stats_changed()

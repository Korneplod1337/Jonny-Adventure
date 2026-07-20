extends Item

func apply_item_effect() -> void:
	player.damage_bonus += 2
	player.hp_bonus += 2
	player.damage = StatManager.get_stat(player, "damage")
	player.max_hp = int(StatManager.get_stat(player, "hp"))
	player._emit_stats_changed()

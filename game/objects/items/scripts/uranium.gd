extends Item

func apply_item_effect() -> void:
	player.damage_bonus += 4
	player.magic_bonus += 2
	player.hp_bonus -= 3
	player.range_bonus -= 1
	player.damage = StatManager.get_stat(player, "damage")
	player.magic = StatManager.get_stat(player, "magic")
	player.max_hp = int(StatManager.get_stat(player, "hp"))
	player.atk_range = StatManager.get_stat(player, "range")
	player._emit_stats_changed()

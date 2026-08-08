extends Item

func apply_item_effect() -> void:
	var live_hp: int = int(player.hp_list["red"]) + int(player.hp_list["green"])
	player.base_damage += effect_power * live_hp
	player.damage = StatManager.get_stat(player, "damage")
	player.hp_bonus += 2
	player.max_hp = int(StatManager.get_stat(player, "hp"))
	player._emit_stats_changed()

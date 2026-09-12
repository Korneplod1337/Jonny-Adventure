extends Item

func apply_item_effect() -> void:
	player.crown_damage_per_item += effect_power #2
	# Уже подобранные предметы (корона сама добавится в Item._on_interact после mark_picked)
	player.base_damage += effect_power * ItemManager.run_picked_items.size()
	player.magic_bonus += 1
	player.magic = StatManager.get_stat(player, "magic")
	player.damage = StatManager.get_stat(player, "damage")
	player._emit_stats_changed()

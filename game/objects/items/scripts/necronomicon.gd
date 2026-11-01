extends Item


func apply_item_effect() -> void:
	# Каждый стак: красные ≤ max_hp / 2^stacks; враги ×0.7. max_hp<=0 — кап no-op.
	player.necronomicon_stacks += 1
	GameState.enemy_hp_multiplier *= effect_power # 0.7
	player.max_hp = int(StatManager.get_stat(player, "hp"))
	if player.has_method("clamp_necronomicon_red"):
		player.clamp_necronomicon_red()
	player._emit_stats_changed()

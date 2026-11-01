extends Item

## Revive 4с invuln+phase, max HP ×0.75. Без +hp_bonus.
const MAX_HP_MULT := 0.75
const REVIVE_IMMUNE := 4.0


func apply_item_effect() -> void:
	player.add_revival(true, REVIVE_IMMUNE, 0)
	player.max_hp_mult *= MAX_HP_MULT
	player.max_hp = int(StatManager.get_stat(player, "hp"))
	if player.has_method("trim_live_hp_to_max"):
		player.trim_live_hp_to_max()
	player._emit_stats_changed()

extends Item

## Возрождение: 2с неуязвимость, без phase. +4 hp_bonus (снимается при revive).
const REVIVE_IMMUNE := 2.0
const HP_BONUS := 4


func apply_item_effect() -> void:
	player.add_revival(false, REVIVE_IMMUNE, HP_BONUS)
	player.hp_bonus += HP_BONUS
	player.max_hp = int(StatManager.get_stat(player, "hp"))
	player._emit_stats_changed()

extends Item

## Общий first-strike бонус с Ballista.
const MODIFIER_ID := "first_strike"
const BONUS := 0.15


func apply_item_effect() -> void:
	var existing: HitModifier = DamageDealer.get_modifier_by_id(MODIFIER_ID)
	if existing is FirstStrikeHitModifier:
		(existing as FirstStrikeHitModifier).bonus += BONUS
	else:
		var modifier := FirstStrikeHitModifier.new()
		modifier.bonus = BONUS
		DamageDealer.add_modifier(modifier, MODIFIER_ID)
	player.damage_bonus += 1
	player.damage = StatManager.get_stat(player, "damage")
	player._emit_stats_changed()

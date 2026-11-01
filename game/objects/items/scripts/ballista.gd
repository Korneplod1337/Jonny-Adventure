extends Item

## Общий first-strike бонус с Guillotine.
const MODIFIER_ID := "first_strike"
var BONUS := effect_power


func apply_item_effect() -> void:
	var existing: HitModifier = DamageDealer.get_modifier_by_id(MODIFIER_ID)
	if existing is FirstStrikeHitModifier:
		(existing as FirstStrikeHitModifier).bonus += BONUS
		return
	var modifier := FirstStrikeHitModifier.new()
	modifier.bonus = BONUS
	DamageDealer.add_modifier(modifier, MODIFIER_ID)

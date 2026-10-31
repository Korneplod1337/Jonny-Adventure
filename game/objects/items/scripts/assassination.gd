extends Item

const MODIFIER_ID := "assassination"


func apply_item_effect() -> void:
	var existing: HitModifier = DamageDealer.get_modifier_by_id(MODIFIER_ID)
	if existing is AssassinationHitModifier:
		(existing as AssassinationHitModifier).stacks += 1
		return
	var modifier := AssassinationHitModifier.new()
	modifier.stacks = 1
	DamageDealer.add_modifier(modifier, MODIFIER_ID)

extends Item

const MODIFIER_ID := "ballista"


func apply_item_effect() -> void:
	var modifier := FullHealthHitModifier.new()
	modifier.multiplier = 1.30
	DamageDealer.add_modifier(modifier, MODIFIER_ID)

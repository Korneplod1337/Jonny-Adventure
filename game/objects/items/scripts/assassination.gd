extends Item

const MODIFIER_ID := "assassination"


func apply_item_effect() -> void:
	DamageDealer.add_modifier(AssassinationHitModifier.new(), MODIFIER_ID)

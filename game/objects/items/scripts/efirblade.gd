extends Item

const MODIFIER_ID := "efirblade"


func apply_item_effect() -> void:
	var modifier := ExecuteLowHpHitModifier.new()
	modifier.hp_threshold = 0.12
	DamageDealer.add_modifier(modifier, MODIFIER_ID)

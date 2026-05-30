extends Base_equip

const MODIFIER_ID := "death_shield"


func effect_on() -> void:
	var modifier := DamageMultiplierHitModifier.new()
	modifier.multiplier = 2.0
	DamageDealer.add_modifier(modifier, MODIFIER_ID)

func effect_off() -> void:
	DamageDealer.remove_modifier_by_id(MODIFIER_ID)

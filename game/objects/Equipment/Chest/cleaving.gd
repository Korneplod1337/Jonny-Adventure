extends Base_equip

const MODIFIER_ID := "Cleaving"


func effect_on() -> void:
	DamageDealer.add_modifier(CleavingAoeHitModifier.new(), MODIFIER_ID)


func effect_off() -> void:
	DamageDealer.remove_modifier_by_id(MODIFIER_ID)

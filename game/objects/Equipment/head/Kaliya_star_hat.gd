extends Base_equip

const MODIFIER_ID := "Kaliya_star_hat"


func effect_on() -> void:
	var modifier := ExplosiveHitModifier.new()
	modifier.radius = 30.0
	DamageDealer.add_modifier(modifier, MODIFIER_ID)

func effect_off() -> void:
	DamageDealer.remove_modifier_by_id(MODIFIER_ID)

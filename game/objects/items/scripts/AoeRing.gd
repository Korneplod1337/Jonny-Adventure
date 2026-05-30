'''
Применение модификаторов стрельбы с предметов
						должно выглядеть так:
'''

extends Item
const MODIFIER_ID := "aoe_ring"

func apply_item_effect() -> void:
	var modifier := AoeHitModifier.new()
	modifier.radius = effect_power if effect_power > 0.0 else 120.0
	DamageDealer.add_modifier(modifier, MODIFIER_ID)

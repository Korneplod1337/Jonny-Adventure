class_name PoisonEnchantment
extends EnchantmentResource

'''
Яд - накладывает складывающийся эффект (25) * магия 
и уменьшает кол-во эффектов в 2 раза, пока не станет меньше 20 (enemy)
уменьшает урон обычной атаки (x0.5)
'''
func _init() -> void:
	enchant_name = "Poison"

func get_effect() -> float:
	match level:
		1: return 15
		2: return 25
		3: return 40
		_: return 15

func get_damage_low() -> float:
	match level:
		1: return 0.8
		2: return 0.5
		3: return 0.1
		_: return 0.8

func apply_on_hit(target: Node, _projectile_direction: Vector2 = Vector2(0, 0)) -> void:
	if target.has_method("apply_poison"):
		target.apply_poison(get_effect(), get_damage_low())

func get_tooltip_text() -> String:
	match level:
		1: return ' with a layer of some kind of venom'
		2: return ' with a tightly applied poison'
		3: return ' with concentrated magic toxin'
		_: return ' -- !WRONG! --'
		
func get_name_text() -> String:
	return 'poisoned '

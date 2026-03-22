class_name KnockbackEnchantment
extends EnchantmentResource

'''
Отталкивание - толкает врага от снаряда с силой (100) * магия.
Сила зависит от уровня.
'''

func _init() -> void:
	enchant_name = "Knockback"

func get_force() -> float:
	match level:
		1: return 40.0
		2: return 80.0
		3: return 120.0
		_: return 40.0

func apply_on_hit(target: Node, projectile_direction: Vector2 = Vector2(0, 0)) -> void:
	if target.has_method("apply_knockback"):
		target.apply_knockback(projectile_direction, get_force())

func get_tooltip_text() -> String:
	match level:
		1: return ' with light push'
		2: return ' with strong knockback'
		3: return ' with massive repulsion'
		_: return ' -- !WRONG! --'

func get_name_text() -> String:
	return 'knockback '

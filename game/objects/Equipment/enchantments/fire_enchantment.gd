class_name FireEnchantment
extends EnchantmentResource

'''
Огонь - с первой тычки накладывает эффект, второй активирует его, последующие обновляют?
наносит урон (25) * (магия/2 + урон/2) действует 2 тика (раз в 1,5 секунды)
'''

func _init() -> void:
	enchant_name = "Fire"

func get_effect() -> float:
	match level:
		1: return 10
		2: return 25
		3: return 60
		_: return 10

func get_duration() -> float:
	match level:
		1: return 0.75
		2: return 1.5
		3: return 2.25
		_: return 2

func apply_on_hit(target: Node, _projectile_direction: Vector2 = Vector2(0, 0)) -> void:
	if target.has_method("apply_fire"):
		target.apply_fire(get_effect(), get_duration())

func get_tooltip_text() -> String:
	match level:
		1: return ' with a pleasant feeling of cold'
		2: return ' with an angry ice crust'
		3: return ' with a bone-chilling frost'
		_: return ' -- !WRONG! --'

func get_name_text() -> String:
	return 'fiery '

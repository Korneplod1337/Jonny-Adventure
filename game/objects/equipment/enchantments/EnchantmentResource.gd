class_name EnchantmentResource
extends Resource

var enchant_name: String = "Enchantment"
@export_range(1, 3, 1) var level: int = 1

func apply_on_hit(_target: Node) -> void:
	pass

func get_title() -> String:
	return "%s %d" % [enchant_name, level]

func get_tooltip_text() -> String:
	return get_title()

func get_name_text() -> String:
	return ''

'''
Лёд - замедляет на мультиплеер (0.8) * магия на кол-во секунд (2)
Яд - накладывает складывающийся эффект (25) * магия 
и уменьшает кол-во эффектов в 2 раза, пока не станет меньше 20 
уменьшает урон обычной атаки (x0.5)
Огонь - с первой тычки накладывает эффект, второй активирует его, последующие обновляют
наносит урон (25) * (магия/2 + урон/2) действует 2 тика (раз в 1,5 секунды)
Отталкивание - отталкивает врага на дистанцию * %магия
'''

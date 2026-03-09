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

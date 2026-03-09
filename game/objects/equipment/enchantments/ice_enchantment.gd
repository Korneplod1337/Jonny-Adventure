class_name IceEnchantment
extends EnchantmentResource

@export var duration: float = 2.0

func _init() -> void:
	enchant_name = "Ice"

func get_slow_multiplier() -> float:
	match level:
		1: return 0.9
		2: return 0.8
		3: return 0.65
		_: return 0.9

func apply_on_hit(target: Node) -> void:
	if target.has_method("apply_slow"):
		target.apply_slow(get_slow_multiplier(), duration)

func get_tooltip_text() -> String:
	match level:
		1: return ' with a pleasant feeling of cold'
		2: return ' with an angry ice crust'
		3: return ' with a bone-chilling frost'
		_: return ' -- !WRONG! --'

func get_name_text() -> String:
	return 'icy '

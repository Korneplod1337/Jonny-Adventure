class_name DamageInfo
extends RefCounted

var damage: float = 0.0
var is_clear: bool = false

var source: Node = null
var hit_position: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT

var enchantment: EnchantmentResource = null

var aoe_radius: float = 0.0
var explosive: bool = false
var explosive_radius: float = 0.0
var lightning: bool = false


func duplicate_info() -> DamageInfo:
	var copy := DamageInfo.new()
	copy.damage = damage
	copy.is_clear = is_clear
	copy.source = source
	copy.hit_position = hit_position
	copy.direction = direction
	copy.enchantment = enchantment
	copy.aoe_radius = aoe_radius
	copy.explosive = explosive
	copy.explosive_radius = explosive_radius
	copy.lightning = lightning
	return copy

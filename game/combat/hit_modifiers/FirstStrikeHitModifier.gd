class_name FirstStrikeHitModifier
extends HitModifier

@export var multiplier: float = 1.15

var _struck: Dictionary = {}


func is_per_target() -> bool:
	return true


func apply(info: DamageInfo) -> void:
	if info.target == null:
		return
	var id := info.target.get_instance_id()
	if _struck.has(id):
		return
	_struck[id] = true
	info.damage *= multiplier

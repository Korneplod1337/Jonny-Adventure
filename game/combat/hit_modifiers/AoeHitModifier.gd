class_name AoeHitModifier
extends HitModifier

@export var radius: float = 120.0


func apply(info: DamageInfo) -> void:
	info.aoe_radius = maxf(info.aoe_radius, radius)

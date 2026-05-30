class_name ExplosiveHitModifier
extends HitModifier

@export var radius: float = 70.0


func apply(info: DamageInfo) -> void:
	info.explosive = true
	info.explosive_radius += radius
	#info.explosive_radius = maxf(info.explosive_radius, radius)

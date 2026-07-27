extends SwordShot
class_name AxeShot


func _ready() -> void:
	super()
	extra_reload = 1
	self_damage_multiplier = 1.15
	_melee_size_scale = clampf(0.6 + atk_range / 300.0, 0.8, 4.0)
	scale = Vector2(_melee_size_scale, _melee_size_scale)


func _on_frame_changed() -> void:
	var frame = anim_sprite.frame

	match frame:
		0:
			col_shape.position = Vector2(45, -38)
			col_shape.rotation = 0.52
		1:
			col_shape.position = Vector2(50.25, -28.5)
			col_shape.rotation = 0.85
		2:
			col_shape.position = Vector2(53.5, -18.5)
			col_shape.rotation = 1.12
		3:
			col_shape.position = Vector2(57.5, -8.5)
			col_shape.rotation = 1.4
		4:
			col_shape.position = Vector2(61, 0)
			col_shape.rotation = 1.68
		5:
			col_shape.position = Vector2(56, 12)
			col_shape.rotation = 2.05
		6:
			col_shape.position = Vector2(49, 24)
			col_shape.rotation = 2.4
		7:
			col_shape.position = Vector2(42, 34)
			col_shape.rotation = 2.75

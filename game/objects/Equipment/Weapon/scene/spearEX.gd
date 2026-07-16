extends SwordShot
class_name EXSpearShot

func _ready() -> void:
	super()
	extra_reload = 1
	self_damage_multiplier = 1.25

func _on_frame_changed() -> void:
	var frame = anim_sprite.frame
	
	match frame:
		0:
			col_shape.position = Vector2(72, -22)
			col_shape.rotation_degrees = -30
		1: 
			col_shape.position = Vector2(78, -18)
			col_shape.rotation_degrees = -25
		2: 
			col_shape.position = Vector2(90, -8)
			col_shape.rotation_degrees = -10
		3: 
			col_shape.position = Vector2(95, 0)
			col_shape.rotation_degrees = 0
		4: 
			col_shape.position = Vector2(87, 9)
			col_shape.rotation_degrees = 10
		5: 
			col_shape.position = Vector2(80, 20)
			col_shape.rotation_degrees = 20
		6: 
			col_shape.position = Vector2(72, 22)
			col_shape.rotation_degrees = 30

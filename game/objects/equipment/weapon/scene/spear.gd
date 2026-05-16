extends SwordShot
class_name SpearShot

func _ready() -> void:
	super()
	self_damage_multiplier = 0.8
	extra_reload = 0.8

func _on_frame_changed() -> void:
	var frame = anim_sprite.frame
	match frame:
		0:
			col_shape.position = Vector2(42+42, 0)
		1: 
			col_shape.position = Vector2(46+42, 0)
		2: 
			col_shape.position = Vector2(50+42, 0)
		3: 
			col_shape.position = Vector2(52+42, 0)
		4: 
			col_shape.position = Vector2(54+42, 0)
		5: 
			col_shape.position = Vector2(48+42, 0)
		6: 
			col_shape.position = Vector2(42+42, 0)

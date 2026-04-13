extends BaseShot
class_name SwordShot

@onready var anim_sprite: AnimatedSprite2D = $shot_Animated
@onready var col_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	type = 'melee'
	speed = 0
	self.scale = Vector2(clampi(0.4 + atk_range/300, 0.6, 4), clampi(0.4 +atk_range/300, 0.6, 4))
	# Rotate the entire sword node based on direction from player
	# This makes the swing follow the aim direction
	rotation = direction.angle()
	
	# Connect signals for animation and collision
	if not anim_sprite.is_connected("frame_changed", Callable(self, "_on_frame_changed")):
		anim_sprite.frame_changed.connect(_on_frame_changed)
	if not anim_sprite.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		anim_sprite.animation_finished.connect(_on_animation_finished)
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		body_entered.connect(_on_body_entered)
	
	# Start the swing
	anim_sprite.play("default")
	
	# Initial collision update
	_on_frame_changed()

func _physics_process(_delta: float) -> void:
	# We override this to stop the moving logic from BaseShot
	# But we keep it empty to prevent inherited movement
	pass

func _on_body_entered(body: Node) -> void:
	# Standard checks from BaseShot but without destroying the sword
	if exploded:
		return
	if body.name == "Player":
		return
		
	if body.has_method("hit"):
		body.hit(damage * self_damage_multiplier)
		
		# Apply enchantment if present
		if enchantment:
			enchantment.apply_on_hit(body, (body.global_position - global_position).normalized())
	

func _on_frame_changed() -> void:
	# Manually update the CollisionShape2D to follow the sword in the animation
	# Adjust these offsets and rotations based on your specific sword sprites
	var frame = anim_sprite.frame
	
	match frame:
		0:
			col_shape.position = Vector2(50, -34)
			col_shape.rotation = 0.45
		1: 
			col_shape.position = Vector2(55.25, -25.5)
			col_shape.rotation = 0.82
		2: 
			col_shape.position = Vector2(58.5, -17)
			col_shape.rotation = 1.09
		3: 
			col_shape.position = Vector2(62.75, -8.5)
			col_shape.rotation = 1.36
		4: 
			col_shape.position = Vector2(67, 0)
			col_shape.rotation = 1.65
		5: 
			col_shape.position = Vector2(62, 11)
			col_shape.rotation = 2
		6: 
			col_shape.position = Vector2(55, 22)
			col_shape.rotation = 2.37
		7:
			col_shape.position = Vector2(48, 32)
			col_shape.rotation = 2.74

func _on_animation_finished() -> void:
	queue_free()

func explosion() -> void:
	pass

func _on_explosion_finished():
	pass

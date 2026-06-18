extends BaseShot
class_name SwordShot

const MELEE_COPY_DECAY := 0.85
const MELEE_TIP_OFFSET_MULT := 100.0

@onready var anim_sprite: AnimatedSprite2D = $shot_Animated
@onready var col_shape: CollisionShape2D = $CollisionShape2D

var _melee_size_scale: float = 1.0
var _fire_direction := Vector2.RIGHT
var _melee_boomerang_legs: Array = []
var _melee_boomerang_leg_index := 0
var _melee_boomerang_copy := false
var _melee_spin_duration := 0.0


func _ready() -> void:
	speed = 0
	extra_reload = 0.8
	rotation = direction.angle()

	if not _melee_boomerang_copy:
		_fire_direction = direction.normalized()
		if boomerang_power > 0:
			_melee_boomerang_legs = BoomerangPath.build_legs(boomerang_power)

	_melee_size_scale = clampf(0.4 + atk_range / 300.0, 0.6, 4.0)
	scale = Vector2(_melee_size_scale, _melee_size_scale)

	if not anim_sprite.is_connected("frame_changed", Callable(self, "_on_frame_changed")):
		anim_sprite.frame_changed.connect(_on_frame_changed)
	if not anim_sprite.is_connected("animation_finished", Callable(self, "_on_animation_finished")):
		anim_sprite.animation_finished.connect(_on_animation_finished)
	if not is_connected("body_entered", Callable(self, "_on_body_entered")):
		body_entered.connect(_on_body_entered)

	anim_sprite.play("default")
	_on_frame_changed()


func _physics_process(_delta: float) -> void:
	pass


func _on_body_entered(body: Node) -> void:
	if exploded:
		return
	if body.name == "Player":
		return

	if body.has_method("hit"):
		_deal_hit(body, _get_final_damage())


func _on_frame_changed() -> void:
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
	_try_spawn_melee_boomerang_copy()
	queue_free()


func _try_spawn_melee_boomerang_copy() -> bool:
	var next_index := _melee_boomerang_leg_index + 1
	if next_index >= _melee_boomerang_legs.size():
		return false

	var leg: Dictionary = _melee_boomerang_legs[next_index]
	var copy: SwordShot = duplicate()
	copy._melee_boomerang_copy = true
	copy._melee_boomerang_legs = _melee_boomerang_legs
	copy._melee_boomerang_leg_index = next_index
	copy._fire_direction = _fire_direction
	copy.boomerang_power = boomerang_power
	copy.damage = damage
	copy.enchantment = enchantment
	copy.self_damage_multiplier = self_damage_multiplier
	copy.self_range_multiplier = self_range_multiplier
	copy.spawned_spread = true
	copy.atk_range = atk_range * MELEE_COPY_DECAY
	if _melee_spin_duration > 0.0:
		copy._melee_spin_duration = _melee_spin_duration * MELEE_COPY_DECAY
	copy.direction = _fire_direction if leg.forward else -_fire_direction

	var tip_offset := direction.normalized() * (_melee_size_scale * MELEE_TIP_OFFSET_MULT)
	get_parent().add_child(copy)
	copy.global_position = global_position + tip_offset
	copy.rotation = copy.direction.angle()
	return true


func explosion(_animation_index) -> void:
	pass


func _on_explosion_finished() -> void:
	pass

extends Node2D

## Препятствие как камень, но с HP. Попадание трясёт спрайт; уничтожение — анимация и queue_free.

const SHAKE_DURATION := 0.5
const SHAKE_AMPLITUDE := 2.0

@export var max_hp: float = 30.0

@onready var body: RigidBody2D = $RigidBody2D
@onready var collision_shape: CollisionShape2D = $RigidBody2D/CollisionShape2D
@onready var sprite: AnimatedSprite2D = $RigidBody2D/AnimatedSprite2D

var current_hp: float = 30.0
var _destroyed: bool = false
var _shake_time_left: float = 0.0
var _sprite_base_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	current_hp = max_hp
	_sprite_base_pos = sprite.position
	if not sprite.animation_finished.is_connected(_on_animation_finished):
		sprite.animation_finished.connect(_on_animation_finished)
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"idle"):
		sprite.play(&"idle")


func _process(delta: float) -> void:
	if _shake_time_left <= 0.0:
		return
	_shake_time_left -= delta
	if _shake_time_left <= 0.0 or _destroyed:
		_shake_time_left = 0.0
		sprite.position = _sprite_base_pos
		return
	sprite.position = _sprite_base_pos + Vector2(
		randf_range(-SHAKE_AMPLITUDE, SHAKE_AMPLITUDE),
		randf_range(-SHAKE_AMPLITUDE, SHAKE_AMPLITUDE)
	)


func hit(amount: float, _clear := false) -> void:
	if _destroyed:
		return
	current_hp -= amount
	_start_shake()
	if current_hp <= 0.0:
		_begin_destroy()


func _start_shake() -> void:
	if _destroyed:
		return
	_shake_time_left = SHAKE_DURATION


func _begin_destroy() -> void:
	if _destroyed:
		return
	_destroyed = true
	_shake_time_left = 0.0
	sprite.position = _sprite_base_pos

	if body:
		body.set_deferred("collision_layer", 0)
		body.set_deferred("collision_mask", 0)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)

	if sprite.sprite_frames and sprite.sprite_frames.has_animation(&"die"):
		sprite.play(&"die")
	else:
		queue_free()


func _on_animation_finished() -> void:
	if not _destroyed:
		return
	if sprite.animation == &"die":
		queue_free()

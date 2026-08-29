extends BaseEnemy
class_name EnemyShortVision

## База для врагов с маленьким радиусом обзора: idle вне зоны, активность вблизи.

@export var hard_vision_radius: float = -1.0

@onready var _field_view_shape: CollisionShape2D = get_node_or_null(
	"FieldViewArea/Field_of_View"
) as CollisionShape2D


func _ready() -> void:
	super._ready()
	_apply_vision_radius()
	_update_locomotion_animation()


func _apply_vision_radius() -> void:
	if hard_vision_radius <= 0.0 or _field_view_shape == null:
		return
	if not (_field_view_shape.shape is CircleShape2D):
		return
	var circle := (_field_view_shape.shape as CircleShape2D).duplicate()
	circle.radius = hard_vision_radius
	_field_view_shape.shape = circle


func _on_blind_timer_timeout() -> void:
	super._on_blind_timer_timeout()
	_update_locomotion_animation()


func _on_field_view_area_body_exited(body: Node2D) -> void:
	super._on_field_view_area_body_exited(body)
	_update_locomotion_animation()


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if active and not is_dead:
		_update_active_walk_animation()


func _update_locomotion_animation() -> void:
	if is_dead or sprite == null or sprite.sprite_frames == null:
		return
	if active:
		_update_active_walk_animation()
	elif sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func _update_active_walk_animation() -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if not player:
		_play_walk_side()
		return

	var to_player := player.global_position - global_position
	if to_player.length_squared() < 1.0:
		if sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")
		return

	if absf(to_player.y) > absf(to_player.x):
		var anim := "up" if to_player.y < 0.0 else "down"
		if sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)
		sprite.flip_h = false
		return

	_play_walk_side(to_player.x < 0.0)


func _play_walk_side(flip_left: bool = false) -> void:
	if sprite.sprite_frames.has_animation("default"):
		sprite.play("default")
	sprite.flip_h = flip_left

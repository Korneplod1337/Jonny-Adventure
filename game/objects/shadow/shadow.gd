@tool
extends Node2D

const ANIM_OVAL := &"oval"
const ANIM_ROUND := &"round"

## Смещение тени вниз в МИРОВЫХ координатах (не зависит от rotation снаряда).
@export var world_down_offset := Vector2(0, 20)

var _sprite_type := 0

@export_enum("Oval", "Round")
var sprite_type: int:
	get:
		return _sprite_type
	set(value):
		_sprite_type = clampi(value, 0, 1)
		_apply_sprite_type()


func _enter_tree() -> void:
	_apply_sprite_type()


func _apply_sprite_type() -> void:
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		return
	var anim := ANIM_ROUND if _sprite_type == 1 else ANIM_OVAL
	if not sprite.sprite_frames.has_animation(anim):
		return
	sprite.animation = anim
	sprite.frame = 0
	sprite.stop()


## Плавно сжимает тень до нуля за `duration` секунд (анимация разрушения снаряда).
func shrink_to_zero(duration: float) -> void:
	if duration <= 0.0:
		scale = Vector2.ZERO
		return
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "scale", Vector2.ZERO, duration)

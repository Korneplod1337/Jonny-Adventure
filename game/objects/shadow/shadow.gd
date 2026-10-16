@tool
extends Node2D

const ANIM_OVAL := &"oval"
const ANIM_ROUND := &"round"

## Смещение тени вниз в МИРОВЫХ координатах (не зависит от rotation снаряда).
@export var world_down_offset := Vector2(0, 20)

var _sprite_type := 0
var _anchor_offset := Vector2.ZERO
var _anchored_to_body := false

@export_enum("Oval", "Round")
var sprite_type: int:
	get:
		return _sprite_type
	set(value):
		_sprite_type = clampi(value, 0, 1)
		_apply_sprite_type()


func _enter_tree() -> void:
	_apply_sprite_type()


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_follow_character_body_unrotated()


## Для CharacterBody2D (жуки/боссы): тень на фиксированном смещении под ногами,
## без вращения вместе с телом.
func _follow_character_body_unrotated() -> void:
	var parent_body := get_parent() as CharacterBody2D
	if parent_body == null or not parent_body.is_inside_tree():
		return

	if not _anchored_to_body:
		_anchor_offset = position
		top_level = true
		# Иначе top_level рисует тень поверх спрайта врага.
		show_behind_parent = true
		z_as_relative = true
		z_index = -1
		_anchored_to_body = true

	var sx := absf(parent_body.global_scale.x)
	var sy := absf(parent_body.global_scale.y)
	global_position = parent_body.global_position + Vector2(_anchor_offset.x * sx, _anchor_offset.y * sy)
	global_rotation = 0.0
	global_scale = Vector2(sx, sy)


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

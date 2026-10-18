@tool
class_name BossHpBarStyle
extends Resource

## Общий стиль HP-бара всех боссов.
## Править удобнее всего в BossHpBarPreview → Shared Style.

@export_group("Textures")
@export var bg_texture: Texture2D:
	set(value):
		bg_texture = value
		emit_changed()

@export var fill_texture: Texture2D:
	set(value):
		fill_texture = value
		emit_changed()

@export var trail_texture: Texture2D:
	set(value):
		trail_texture = value
		emit_changed()

@export var frame_texture: Texture2D:
	set(value):
		frame_texture = value
		emit_changed()

@export_group("Fallback Colors")
@export var fill_color: Color = Color(0.78, 0.32, 0.36, 0.95):
	set(value):
		fill_color = value
		emit_changed()

@export var trail_color: Color = Color(1.0, 0.72, 0.72, 0.85):
	set(value):
		trail_color = value
		emit_changed()

@export var bg_color: Color = Color(0.12, 0.1, 0.1, 0.65):
	set(value):
		bg_color = value
		emit_changed()

@export var border_color: Color = Color(0.05, 0.04, 0.04, 0.9):
	set(value):
		border_color = value
		emit_changed()

@export_group("Size")
@export var preferred_height: float = 0.0:
	set(value):
		preferred_height = value
		emit_changed()

# EffectIcons.gd
extends Node2D

@export var spacing: float = 18.0
@export var freeze_icon: Texture2D
@export var poison_icon: Texture2D
@export var fire_icon0: Texture2D
@export var fire_icon1: Texture2D

func show_effects(active_effects: Array) -> void:
	for child in get_children():
		child.queue_free()

	var textures: Array[Texture2D] = []

	for effect in active_effects:
		match effect:
			"freeze":
				if freeze_icon:
					textures.append(freeze_icon)
			"poison":
				if poison_icon:
					textures.append(poison_icon)
			"fire0":
				if fire_icon0:
					textures.append(fire_icon0)
			"fire1":
				if fire_icon1:
					textures.append(fire_icon1)

	if textures.is_empty():
		return

	var total_width := (textures.size() - 1) * spacing
	var start_x := -total_width / 2.0

	for i in range(textures.size()):
		var icon := Sprite2D.new()
		icon.texture = textures[i]
		icon.scale = Vector2(1, 1)
		icon.centered = true
		icon.position = Vector2(start_x + i * spacing, 0)
		add_child(icon)

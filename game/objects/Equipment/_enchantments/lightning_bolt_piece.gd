extends Node2D

const VISIBLE_TIME := 0.75
const TEXTURES: Array[Texture2D] = [
	preload("res://image/enchants/lightning enchant_effect1.png"),
	preload("res://image/enchants/lightning enchant_effect2.png"),
	preload("res://image/enchants/lightning enchant_effect3.png"),
	preload("res://image/enchants/lightning enchant_effect4.png"),
]

@onready var _sprite: Sprite2D = $Sprite2D


func setup(world_pos: Vector2, rot_rad: float, piece_scale: float = 1.0) -> void:
	global_position = world_pos
	rotation = rot_rad
	scale = Vector2(piece_scale, piece_scale)
	if _sprite:
		_sprite.texture = TEXTURES[randi() % TEXTURES.size()]


func _ready() -> void:
	if _sprite and _sprite.texture == null:
		_sprite.texture = TEXTURES[randi() % TEXTURES.size()]
	await get_tree().create_timer(VISIBLE_TIME).timeout
	if is_instance_valid(self):
		queue_free()

@tool
extends Node2D

const TEXTURES: Array[Texture2D] = [
	preload("res://image/objects/obstacles/Gap1.png"),
	preload("res://image/objects/obstacles/Gap2.png"),
	preload("res://image/objects/obstacles/Gap3.png"),
	preload("res://image/objects/obstacles/Gap4.png"),
	preload("res://image/objects/obstacles/Gap5.png"),
	preload("res://image/objects/obstacles/Gap6.png"),
	preload("res://image/objects/obstacles/Gap7.png"),
	preload("res://image/objects/obstacles/Gap8.png"),
	preload("res://image/objects/obstacles/Gap9.png"),
	preload("res://image/objects/obstacles/Gap10.png"),
	preload("res://image/objects/obstacles/Gap11.png"),
	preload("res://image/objects/obstacles/Gap12.png"),
	preload("res://image/objects/obstacles/Gap13.png"),
	preload("res://image/objects/obstacles/Gap14.png"),
]

var _variant := 0

@export_enum(
	"Gap 1",
	"Gap 2",
	"Gap 3",
	"Gap 4",
	"Gap 5",
	"Gap 6",
	"Gap 7",
	"Gap 8",
	"Gap 9",
	"Gap 10",
	"Gap 11",
	"Gap 12",
	"Gap 13",
	"Gap 14"
)
var variant: int:
	get:
		return _variant
	set(value):
		_variant = clampi(value, 0, TEXTURES.size() - 1)
		_apply_variant()


func _enter_tree() -> void:
	_apply_variant()


func _apply_variant() -> void:
	var sprite := get_node_or_null("RigidBody2D/Sprite2D") as Sprite2D
	if sprite == null:
		return
	sprite.texture = TEXTURES[_variant]

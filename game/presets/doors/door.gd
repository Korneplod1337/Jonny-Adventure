extends Node2D

const DEFAULT_ANIM := "default"

const ROOM_TYPE_TO_ANIM := {
	0: "start",      # START
	1: "standart",   # STANDARD
	2: "shop",       # SHOP
	3: "armory",     # ARMORY
	4: "default",    # BLOOD_TRIBUTE
	5: "treasure",   # TREASURE
	6: "default",    # BANK
	7: "default",    # GAMBLING
	8: "boss",       # BOSS
	9: "default",    # SECRET
}

@export var dir: Vector2        # направление выхода: (1,0), (-1,0), (0,1), (0,-1)
@export var target_room_pos: Vector2  # логическая позиция соседней комнаты
@export var entrance_offset: Vector2  # локальный оффсет точки появления внутри целевой комнаты

var active := true
var just_teleported := false

@onready var _room_type_sprites: AnimatedSprite2D = $Room_type_sprites


func configure(direction: Vector2, target_pos: Vector2, target_room_type: int, offset: Vector2) -> void:
	dir = direction
	target_room_pos = target_pos
	entrance_offset = offset
	_apply_sprite_for_room_type(target_room_type)


func _apply_sprite_for_room_type(room_type: int) -> void:
	var sprites := _get_room_type_sprites()
	if sprites == null or sprites.sprite_frames == null:
		return

	var anim_name: String = ROOM_TYPE_TO_ANIM.get(room_type, DEFAULT_ANIM)
	if not sprites.sprite_frames.has_animation(anim_name):
		anim_name = DEFAULT_ANIM

	sprites.play(anim_name)


func _get_room_type_sprites() -> AnimatedSprite2D:
	if _room_type_sprites == null:
		_room_type_sprites = get_node_or_null("Room_type_sprites")
	return _room_type_sprites


func _on_body_entered(body: Node2D) -> void:
	if not active:
		return
	if not body.is_in_group("player"):
		return

	active = false

	var dungeon := get_tree().current_scene
	dungeon.teleport_player(self, body)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	if just_teleported:
		just_teleported = false
		active = true
		return
	active = true


func set_temporarily_inactive() -> void:
	active = false
	just_teleported = true


func reactivate_after_room_clear() -> void:
	active = true
	just_teleported = false

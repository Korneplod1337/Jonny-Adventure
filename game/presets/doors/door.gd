extends Node2D

@export var dir: Vector2        # направление выхода: (1,0), (-1,0), (0,1), (0,-1)
@export var target_room_pos: Vector2  # логическая позиция соседней комнаты
@export var entrance_offset: Vector2  # локальный оффсет точки появления внутри целевой комнаты

var active := true
var just_teleported := false

func _ready() -> void:
	pass
	



func _on_body_entered(body: Node2D) -> void:
	if not active:
		return
	if not body.is_in_group("player"):
		return
	
	active = false
	
	# просим root (dungeon) перенести игрока
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

func set_temporarily_inactive() -> void: # вызывается из dungeon сразу после телепорта
	active = false
	just_teleported = true

func reactivate_after_room_clear() -> void:
	active = true
	just_teleported = false

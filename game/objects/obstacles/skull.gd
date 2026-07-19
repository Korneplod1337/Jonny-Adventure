extends Area2D

const EXPLOSION_SCENE := preload("res://game/combat/combat_effects/explosion.tscn")

@export var explosion_radius: float = 50.0
@export var explosion_damage: float = 	50.0

var _triggered: bool = false
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_pick_random_sprite()

func _pick_random_sprite() -> void:
	var frames := _sprite.sprite_frames
	_sprite.frame = randi() % frames.get_frame_count("default")


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_trigger()
	return

func _trigger() -> void:
	_triggered = true
	set_deferred("monitoring", false)

	var explosion: CombatExplosion = EXPLOSION_SCENE.instantiate()
	explosion.global_position = global_position
	explosion.setup(explosion_radius, explosion_damage)
	get_tree().current_scene.call_deferred("add_child", explosion)
	queue_free()

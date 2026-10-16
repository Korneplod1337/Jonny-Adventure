extends Area2D

## Сколько этажей вперёд при касании.
@export var value: int = 1

var _picked := false


func _ready() -> void:
	var anim := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if anim:
		anim.play()
	PickupIdleFloat.begin(self)


func _on_body_entered(body: Node) -> void:
	if _picked or not body.is_in_group("player"):
		return
	_picked = true

	var dungeon := get_tree().current_scene
	if dungeon == null or not dungeon.has_method("regenerate_floor"):
		queue_free()
		return

	var steps := maxi(1, value)
	var max_floor: int = dungeon.floors_config.size() - 1
	var new_floor := mini(max_floor, int(dungeon.current_floor) + steps)
	if new_floor == dungeon.current_floor:
		queue_free()
		return

	var skipped := new_floor - int(dungeon.current_floor)
	for _i in skipped:
		GameState.enemy_hp_multiplier *= 1.1
		if GameState.LuckyHead:
			GameState.enemy_hp_multiplier *= 0.97
			StatManager.upgrade_stat(body, "luck", 1)

	dungeon.call_deferred("regenerate_floor", new_floor)
	queue_free()

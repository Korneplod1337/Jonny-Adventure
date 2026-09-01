## Ember — выпускает fireball по направлению выстрела/движения. Урон: 40 + 2 за каждые 0.2 magic. Дальность: 200 + 12 за каждые 0.1 magic.
class_name EmberAbility
extends BaseAbility

const PROJECTILE_SCENE := preload("res://game/objects/Equipment/Ability/effects/Fireball.tscn")
const SPAWN_OFFSET := Vector2(0, -10)


func _init() -> void:
	ability_id = "Ember"
	cooldown_type = CooldownType.TIME
	cooldown_time = 5.0


func activate() -> bool:
	var dir := Input.get_vector("fire_left", "fire_right", "fire_up", "fire_down")
	if dir == Vector2.ZERO:
		dir = Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)
	dir = dir.normalized()
	if dir == Vector2.ZERO:
		return false

	var shot_speed: float = 300.0 * (
		1.0 + (player.move_speed_level + player.fire_rate_level - 8.0) * 0.05
	)
	var parent: Node = player.get_tree().current_scene
	if parent == null:
		parent = player.get_parent()

	var proj := PROJECTILE_SCENE.instantiate()
	proj.setup(dir, shot_speed, get_magic())
	proj.position = player.global_position + SPAWN_OFFSET
	parent.add_child(proj)
	return true

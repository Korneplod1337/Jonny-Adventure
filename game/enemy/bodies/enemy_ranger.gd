extends BaseEnemy
class_name EnemyRanger

@export var projectile_scene: PackedScene

var projectile_speed: float
var projectile_range: float
var max_move_distance: float


func _ready() -> void:
	super._ready()


func shoot_projectile(direction: Vector2) -> void:
	if not projectile_scene or direction == Vector2.ZERO:
		return

	var shot: Node2D = projectile_scene.instantiate()
	var dir := direction.normalized()
	shot.global_position = global_position + dir * 12.0

	if shot is EnemyShot:
		shot.setup(dir, get_attack_damage(), projectile_speed, projectile_range)
	elif shot.has_method("setup"):
		shot.setup(dir, get_attack_damage(), projectile_speed, projectile_range)
	else:
		shot.set("direction", dir)
		var atk := get_attack_damage()
		shot.set("damage", [atk.x, atk.y, atk.z])
		shot.set("speed", projectile_speed)
		shot.set("atk_range", projectile_range)

	get_tree().current_scene.add_child(shot)
	sprite.flip_h = dir.x < 0

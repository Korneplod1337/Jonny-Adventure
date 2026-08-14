## Cracked Eruption — веер осколков по направлению выстрела/движения; число от magic. CD: время.
class_name CrackedEruptionAbility
extends BaseAbility

const PROJECTILE_SCENE := preload("res://game/objects/Equipment/Ability/effects/CrackedEruption.tscn")
const CONE_DEG := 45.0
const RANGE_MULT := 0.25
const MAGIC_PER_SHOT := 0.15
const SPAWN_OFFSET := Vector2(0, -10)
const SPAWN_JITTER := 15.0


func _init() -> void:
	ability_id = "CrackedEruption"
	cooldown_type = CooldownType.TIME
	cooldown_time = 2.0


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

	var magic := get_magic()
	var count := int(floor(magic / MAGIC_PER_SHOT))
	if count <= 0:
		return true

	var shot_speed: float = 300.0 * (
		1.0 + (player.move_speed_level + player.fire_rate_level - 8.0) * 0.05
	)
	var shot_range: float = StatManager.get_stat(player, "range") * RANGE_MULT + 100
	var half_cone := deg_to_rad(CONE_DEG * 0.5)
	var parent: Node = player.get_tree().current_scene
	if parent == null:
		parent = player.get_parent()

	for _i in count:
		var angle := randf_range(-half_cone, half_cone)
		var shot_dir := dir.rotated(angle)
		var jitter := Vector2(
			randf_range(-SPAWN_JITTER, SPAWN_JITTER),
			randf_range(-SPAWN_JITTER, SPAWN_JITTER)
		)
		var proj := PROJECTILE_SCENE.instantiate()
		proj.setup(shot_dir, shot_speed, shot_range)
		proj.position = player.global_position + SPAWN_OFFSET + jitter
		parent.add_child(proj)

	return true

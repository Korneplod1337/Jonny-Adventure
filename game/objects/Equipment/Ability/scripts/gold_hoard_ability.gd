## Gold Hoard — спавнит 2–3 монеты перед игроком (шанс 3-й от luck: 5%…100%). CD: 2 комнаты (старт 0/2).
class_name GoldHoardAbility
extends BaseAbility

const COIN_SCENE := preload("res://game/objects/coins/Coin.tscn")
const SPAWN_FORWARD := 40.0
const SPAWN_JITTER := 12.0


func _init() -> void:
	ability_id = "GoldHoard"
	cooldown_type = CooldownType.ROOMS
	cooldown_rooms = 2
	start_rooms_progress = 0


func activate() -> bool:
	var luck := StatManager.get_stat(player, "luck")
	var t := clampf((luck - 0.1) / 1.9, 0.0, 1.0)
	var chance_three := lerpf(0.05, 1.0, t)
	var count := 3 if randf() < chance_three else 2

	var forward := Input.get_vector("fire_left", "fire_right", "fire_up", "fire_down")
	if forward == Vector2.ZERO:
		forward = Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)
	if forward == Vector2.ZERO:
		forward = Vector2.DOWN
	forward = forward.normalized()

	var parent: Node = player.get_tree().current_scene
	if parent == null:
		parent = player.get_parent()
	for _i in count:
		var jitter := Vector2(
			randf_range(-SPAWN_JITTER, SPAWN_JITTER),
			randf_range(-SPAWN_JITTER, SPAWN_JITTER)
		)
		var coin := COIN_SCENE.instantiate()
		coin.position = player.global_position + forward * SPAWN_FORWARD + jitter
		parent.call_deferred("add_child", coin)
	return true

extends StaticBody2D

const STATS: Array[String] = [
	"hp", "move_speed", "luck", "magic",
	"damage", "spread", "range", "fire_rate"
]

const SUCCESS_CHANCE_AT_ZERO_LUCK := 0.50
const SUCCESS_CHANCE_AT_MAX_LUCK := 0.90

@onready var interactable: Area2D = $Interactable
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	interactable.interact = _on_interact
	interactable.interact_name = "Use by 1 coin"
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play(&"default")


func _on_interact() -> void:
	if not interactable.is_interactable:
		return
	if GameState.coins < 1:
		return
	if not get_tree().get_first_node_in_group("player"):
		return

	GameState.add_coins(-1)
	interactable.is_interactable = false
	sprite.play(&"use")


func _on_animation_finished() -> void:
	match sprite.animation:
		&"use":
			_resolve_outcome()
		&"active", &"fire":
			_reset_for_reuse()


func _resolve_outcome() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and _roll_success(player):
		_grant_random_stat(player)
		sprite.play(&"active")
	else:
		sprite.play(&"fire")


func _roll_success(player: Node) -> bool:
	var luck: float = StatManager.get_stat(player, "luck")
	# luck clamped 0.1–2.0 in StatManager → 0 at min, 1 at max
	var t := clampf((luck - 0.1) / 1.9, 0.0, 1.0)
	var chance := lerpf(SUCCESS_CHANCE_AT_ZERO_LUCK, SUCCESS_CHANCE_AT_MAX_LUCK, t)
	return randf() < chance


func _grant_random_stat(player: Node) -> void:
	var stat_name: String = STATS[randi() % STATS.size()]
	StatManager.upgrade_stat(player, stat_name, 1)


func _reset_for_reuse() -> void:
	sprite.play(&"default")
	interactable.is_interactable = true

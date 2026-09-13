extends BaseShot
class_name SpecialShot

const PUDDLE_SCENE := preload("res://game/combat/combat_effects/special_flask_puddle.tscn")
const FLASK_DAMAGE_MULT := 0.25

@onready var crit: AnimatedSprite2D = $Crit


func _ready() -> void:
	self_damage_multiplier = FLASK_DAMAGE_MULT
	extra_reload = 1.2
	super()
	if crit:
		crit.position = CRIT_WORLD_OFFSET.rotated(-rotation)
		crit.rotation = -rotation


func _get_crit_chance() -> float:
	var chance := 0.1
	var shooter := _get_player()
	if shooter:
		chance += StatManager.get_stat(shooter, "luck") / 2.0
		chance += shooter.crit_chance_bonus
	return chance


func _register_pierce_hit(target: Node, amount: float) -> bool:
	var should_stop := super._register_pierce_hit(target, amount)
	# Лужа на каждом pierce, если снаряд продолжает полёт (не бумеранг).
	if not should_stop and not _boomerang_active:
		_spawn_puddle(global_position)
	return should_stop


func _perform_projectile_ricochet(body: Node) -> bool:
	var ok := super._perform_projectile_ricochet(body)
	# Лужа на каждом рикошете (не бумеранг — только финал).
	if ok and not _boomerang_active:
		_spawn_puddle(global_position)
	return ok


func explosion(_animation_index) -> void:
	speed = 0
	set_deferred("monitoring", false)
	_spawn_puddle(global_position)
	$shot_Animated.speed_scale = animaited_speed
	# Всегда разбитие, miss нет.
	$shot_Animated.play("default")
	if not $shot_Animated.is_connected("animation_finished", Callable(self, "_on_explosion_finished")):
		$shot_Animated.connect("animation_finished", Callable(self, "_on_explosion_finished"))


func _spawn_puddle(at_position: Vector2) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null:
		return
	var puddle: SpecialFlaskPuddle = PUDDLE_SCENE.instantiate()
	puddle.setup_from_shot(self, at_position)
	parent.call_deferred("add_child", puddle)

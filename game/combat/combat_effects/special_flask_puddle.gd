extends Area2D
class_name SpecialFlaskPuddle

const BASE_COLLISION_RADIUS := 15.0
const PUDDLE_DAMAGE_MULT := 0.5
const CRIT_WORLD_OFFSET := Vector2(0, -60)

@export var lifetime: float = 2.0
@export var tick_interval: float = 1
@export var radius: float = 40.0

var enchantment: EnchantmentResource
var extra_enchantment: EnchantmentResource
var hack: int = 0
var aoe_radius: float = 0.0
var _player: Node = null
var _active: bool = false
var _crit_sprite: int = -1

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _damage_timer: Timer = $Timer
@onready var _crit: AnimatedSprite2D = $Crit


static func get_player_level_sum(p: Node) -> float:
	if p == null:
		return 8.0
	return (
		float(p.hit_points_level)
		+ float(p.move_speed_level)
		+ float(p.luck_level)
		+ float(p.magic_level)
		+ float(p.damage_level)
		+ float(p.spread_level)
		+ float(p.fire_rate_level)
		+ float(p.range_level)
	)


static func scale_from_player(p: Node) -> Dictionary:
	var sum := get_player_level_sum(p)
	var t := clampf((sum - 8.0) / 72.0, 0.0, 1.0)
	return {
		"lifetime": lerpf(2.0, 4.0, t),
		"radius": lerpf(60.0, 180.0, t),
		"tick_interval": lerpf(1, 0.5, t),
	}


func setup_from_shot(shot: BaseShot, at_position: Vector2) -> void:
	global_position = at_position
	_player = shot._get_player()
	enchantment = shot.enchantment
	extra_enchantment = shot.extra_enchantment
	hack = shot.hack
	aoe_radius = shot.aoe_radius
	var scaled := scale_from_player(_player)
	lifetime = scaled.lifetime
	radius = scaled.radius
	tick_interval = scaled.tick_interval


func _ready() -> void:
	monitoring = false
	var scale_factor := radius / BASE_COLLISION_RADIUS
	scale = Vector2.ONE * scale_factor
	_sprite.speed_scale = GameState.animated_world_speed
	_sprite.play("spawn")
	_damage_timer.wait_time = maxf(tick_interval, 0.05)
	_damage_timer.one_shot = false
	if _crit:
		_crit.visible = false
		_crit.top_level = true


func _on_body_entered(body: Node2D) -> void:
	if _active and _can_damage(body):
		_damage_body(body)


func _on_damage_timer_timeout() -> void:
	_tick_damage()


func _tick_damage() -> void:
	if not _active:
		return
	for body in get_overlapping_bodies():
		if _can_damage(body):
			_damage_body(body)


func _damage_body(body: Node) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		return

	var amount := _roll_player_damage()
	if amount <= 0.0:
		return

	var info := DamageInfo.new()
	info.damage = amount
	info.source = _player
	info.hit_position = global_position
	info.enchantment = enchantment
	info.extra_enchantment = extra_enchantment
	info.hack = hack
	info.aoe_radius = aoe_radius
	var to_target := Vector2.RIGHT
	if body is Node2D:
		to_target = ((body as Node2D).global_position - global_position)
		if to_target.length_squared() < 0.0001:
			to_target = Vector2.RIGHT
		else:
			to_target = to_target.normalized()
	info.direction = to_target
	info.hack_direction = to_target

	DamageDealer.deal_damage(_player, body, info)
	_show_crit_effect()
	_spawn_hack(body, amount)


func _roll_player_damage() -> float:
	_crit_sprite = -1
	var base := StatManager.get_stat(_player, "damage") * PUDDLE_DAMAGE_MULT
	if enchantment and enchantment.has_method("get_damage_low"):
		base *= enchantment.get_damage_low()
	if extra_enchantment and extra_enchantment.has_method("get_damage_low"):
		base *= extra_enchantment.get_damage_low()

	var chance := 0.1
	chance += StatManager.get_stat(_player, "luck") / 2.0
	chance += _player.crit_chance_bonus

	var spread_val := StatManager.get_stat(_player, "spread")
	var crit_bonus := 60.0 / (spread_val + 20.0)
	var total_crit := 1.0
	while true:
		if randf() < chance:
			_crit_sprite += 1
			total_crit += crit_bonus
			chance -= 0.2
			if _crit_sprite == 4:
				StatsManager.add_statistic_progress("Mega_crit", 1)
				SoundManager.play_megacrit()
				break
		else:
			break
	return base * total_crit


func _show_crit_effect() -> void:
	if _crit_sprite < 0 or _crit == null:
		return
	_crit.global_position = global_position + CRIT_WORLD_OFFSET
	_crit.global_rotation = 0.0
	_crit.scale = Vector2(2, 2)
	_crit.frame = _crit_sprite
	_crit.show()


func _spawn_hack(target: Node, dealt_damage: float) -> void:
	if hack <= 0 or dealt_damage <= 0.0:
		return
	if not target is Node2D or not is_instance_valid(target):
		return
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	var dir := ((target as Node2D).global_position - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	HackCleave.spawn_batch(parent, target as Node2D, dir, dealt_damage * 0.5, hack)


func _can_damage(body: Node) -> bool:
	return body != null and body.has_method("hit") and not body.is_in_group("player")


func _activate() -> void:
	_active = true
	monitoring = true
	_sprite.play("default")
	_damage_timer.start()
	get_tree().create_timer(lifetime).timeout.connect(_start_end)
	call_deferred("_tick_damage")


func _start_end() -> void:
	if not _active:
		return
	_active = false
	_damage_timer.stop()
	set_deferred("monitoring", false)
	_sprite.play("end")


func _on_animation_finished() -> void:
	match _sprite.animation:
		&"spawn":
			_activate()
		&"end":
			queue_free()

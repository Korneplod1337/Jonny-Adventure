class_name arid_membrane
extends BaseShot

const TICK_MULTS: Array[float] = [0.2, 0.3, 0.5]

var _stuck := false
var _stick_target: Node2D = null
var _stick_offset := Vector2.ZERO
var _next_tick_index := 1
var _tick_cd := 0.0
var _finishing := false


func _ready() -> void:
	extra_reload = 1.2
	fire_sfx_kind = FireSfxKind.TEAR
	super()


func _physics_process(delta: float) -> void:
	if _stuck:
		_process_stuck(delta)
		return
	super._physics_process(delta)


func _on_body_entered(body) -> void:
	if exploded or _stuck:
		return
	if body.name == "Player" or body.is_in_group("player"):
		return

	if body.has_method("hit"):
		_stick_to(body)
		return

	exploded = true
	explosion(0)


func _stick_to(body: Node) -> void:
	if not body is Node2D:
		return

	_stuck = true
	exploded = true
	speed = 0
	set_deferred("monitoring", false)
	_stick_target = body as Node2D
	_stick_offset = _stick_target.to_local(global_position)

	# Первый удар: 20%, без зачарования
	_deal_membrane_hit(_stick_target, TICK_MULTS[0], false)

	var anim: AnimatedSprite2D = $shot_Animated
	anim.speed_scale = GameState.animated_world_speed
	anim.play("sticking")

	_next_tick_index = 1
	_tick_cd = _get_tick_interval()


func _process_stuck(delta: float) -> void:
	if _finishing:
		return
	if not is_instance_valid(_stick_target) or _stick_target.get("is_dead") == true:
		queue_free()
		return

	global_position = _stick_target.to_global(_stick_offset)

	_tick_cd -= delta
	if _tick_cd > 0.0:
		return

	# 2-й и 3-й тик: с зачарованием
	_deal_membrane_hit(_stick_target, TICK_MULTS[_next_tick_index], true)
	_next_tick_index += 1

	if _next_tick_index >= TICK_MULTS.size():
		_finish_stuck()
		return

	_tick_cd = _get_tick_interval()


func _finish_stuck() -> void:
	_finishing = true
	explosion(0)


func _get_tick_interval() -> float:
	var shooter := _get_player()
	if shooter == null:
		return 0.5
	shooter.extra_fire_rate = extra_reload
	return StatManager.get_stat(shooter, "fire_rate")


func _deal_membrane_hit(target: Node, damage_mult: float, apply_enchant: bool) -> void:
	if not is_instance_valid(target) or not target.has_method("hit"):
		return

	var amount := _get_membrane_damage(damage_mult, apply_enchant)
	var info := _build_damage_info(target, amount)
	if not apply_enchant:
		info.enchantment = null
	DamageDealer.deal_damage(self, target, info)
	_show_crit_effect()


func _get_membrane_damage(damage_mult: float, apply_enchant_mult: bool) -> float:
	crit_sprite = -1
	var final_damage := float(damage * self_damage_multiplier) * damage_mult
	if apply_enchant_mult and enchantment and enchantment.has_method("get_damage_low"):
		final_damage *= enchantment.get_damage_low()

	var chance := _get_crit_chance()
	var spread_val := 20.0
	var shooter := _get_player()
	if shooter:
		spread_val = StatManager.get_stat(shooter, "spread")
	var crit_bonus := base_crit_bonus / (spread_val + 20)
	var total_crit := 1.0
	while true:
		if randf() < chance:
			crit_sprite += 1
			total_crit += crit_bonus
			chance -= 0.2
			if crit_sprite == 4:
				StatsManager.add_statistic_progress("Mega_crit", 1)
				SoundManager.play_megacrit()
				break
		else:
			break
	return final_damage * total_crit

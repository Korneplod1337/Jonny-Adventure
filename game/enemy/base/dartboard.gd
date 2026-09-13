extends BaseEnemy
@onready var label: Label = $Label

var damage_last_hit: float = 0.0
var dps: float = 0.0
var total_damage_recent: float = 0.0  # Сумма урона за последние 2 сек
var no_damage_timer: float = 0.0      # Счетчик без хита
var hit_time: float = 0.0
var hit_count: int = 0
var time_since_last_hit: float = 0.0
var show_dps: bool = false

func _physics_process(delta: float) -> void:
	super(delta)
	player = get_tree().get_first_node_in_group("player")
	no_damage_timer += delta
	if hit_count > 0:
		hit_time += delta
		time_since_last_hit += delta
	if no_damage_timer >= 2.0:
		total_damage_recent = 0.0
		dps = 0.0
		hit_time = 0.0
		hit_count = 0
		time_since_last_hit = 0.0
		show_dps = false
		label.hide()
	update_label()

func _ready() -> void:
	super()
	update_label()
	await get_tree().process_frame
	_apply_player_sprite()


func _apply_player_sprite() -> void:
	player = get_tree().get_first_node_in_group("player")
	var anim_sprite: AnimatedSprite2D = $AnimatedSprite2D
	if player.player_name in ["JonnyAlt", "JonnyttaAlt"]:
		anim_sprite.animation = &"alt"
	else:
		anim_sprite.animation = &"default"

func hit(damage: float, clear:= false) -> void:
	if not clear:
		if poison > 0:
			damage *= effect_protection
	_flash_damage()
	label.show()
	damage_last_hit = damage
	total_damage_recent += damage
	no_damage_timer = 0.0
	hit_count += 1

	if hit_count == 1:
		# Интервал ещё неизвестен — DPS не показываем
		hit_time = 0.0
		time_since_last_hit = 0.0
		dps = 0.0
		show_dps = false
	elif hit_count == 2:
		# Интервал 1→2 × 2 ≈ окно включая задержку до первого выстрела
		hit_time = time_since_last_hit * 2.0
		dps = total_damage_recent / hit_time
		show_dps = true
		time_since_last_hit = 0.0
	else:
		dps = total_damage_recent / hit_time
		time_since_last_hit = 0.0


func update_label() -> void:
	if show_dps:
		label.text = "Total: %.1f\nLast hit = %.1f\nDPS: %.1f" % [
			total_damage_recent, damage_last_hit, dps
		]
	else:
		label.text = "Total: %.1f\nLast hit = %.1f" % [
			total_damage_recent, damage_last_hit
		]

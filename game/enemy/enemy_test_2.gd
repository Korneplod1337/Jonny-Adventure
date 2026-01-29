extends CharacterBody2D
@onready var label: Label = $Label

var damage_last_hit: float = 0.0
var dps: float = 0.0
var total_damage_recent: float = 0.0  # Сумма урона за последние 2 сек
var no_damage_timer: float = 0.0      # Счетчик без хита
var hit_time: float = 0.0

func _process(delta: float) -> void:
	no_damage_timer += delta
	hit_time += delta
	if no_damage_timer >= 2.0:
		total_damage_recent = 0.0
		dps = 0.0
		hit_time = 0.5
		label.hide()
	update_label()

func _ready() -> void:
	update_label()

func hit(damage: float) -> void:
	label.show()
	damage_last_hit = damage
	total_damage_recent += damage
	no_damage_timer = 0.0
	dps = total_damage_recent / hit_time
	print(total_damage_recent, hit_time)


func update_label() -> void:
	label.text = "Last hit = %.1f\nDPS: %.1f" % [damage_last_hit, dps]

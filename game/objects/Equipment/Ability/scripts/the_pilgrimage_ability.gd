## The Pilgrimage — +1 ко всем 8 уровням статов. CD: 15 зачищенных комнат (старт 0/15).
class_name ThePilgrimageAbility
extends BaseAbility

const STATS: Array[String] = [
	"hp", "move_speed", "luck", "magic", "damage", "spread", "range", "fire_rate"
]


func _init() -> void:
	ability_id = "ThePilgrimage"
	cooldown_type = CooldownType.ROOMS
	cooldown_rooms = 15
	start_rooms_progress = 0


func activate() -> bool:
	for stat_name in STATS:
		StatManager.upgrade_stat(player, stat_name, 1)
	player._emit_stats_changed()
	return true

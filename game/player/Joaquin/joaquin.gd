extends Jonny
class_name Joaquin

const START_BASE_GUN_EQUIP := preload("res://game/objects/Equipment/Weapon/equip/Pistol_equip.tscn")
const REDIRECT_STATS: Array[String] = [
	"move_speed", "luck", "magic", "damage", "spread", "range", "fire_rate",
]
const CHEST_ITEM_TIERS_ALL: Array = [0, 1, 2, 3, 4]
const CHEST_EQUIP_TIERS_ALL: Array = [0, 1, 2, 3]


func _init() -> void:
	player_name = "Joaquin"
	base_max_hp = 0
	base_move_speed = 253.0
	base_luck = 0.3
	base_magic = 0.3
	base_damage = 33.0
	base_spread = 13.0
	base_range = 153.0
	base_fire_rate = 0.53
	hit_points_level = 1.0
	move_speed_level = 1.0
	luck_level = 1.0
	magic_level = 1.0
	damage_level = 1.0
	spread_level = 1.0
	range_level = 1.0
	fire_rate_level = 1.0


func _ready() -> void:
	hp_list = {
		"red": 0,
		"green": 0,
		"blue": 0,
		"black": 0,
	}
	super()


func _process(delta: float) -> void:
	_flush_hp_bonus_redirect()
	super._process(delta)


func _equip_start_weapon() -> void:
	var equip: BaseShot_equip = START_BASE_GUN_EQUIP.instantiate()
	equip.apply_equip(self)


func heal(_red: int = 0, _green: int = 0, _blue: int = 0, _black: int = 0) -> void:
	# Не может получать HP или армор.
	return


func _emit_stats_changed() -> void:
	_flush_hp_bonus_redirect()
	# Не даём накапливать пустые слоты / live HP.
	max_hp = 0
	hit_points_level = 1.0
	hp_bonus = 0
	hp_list["red"] = 0
	hp_list["green"] = 0
	hp_list["blue"] = 0
	hp_list["black"] = 0
	super._emit_stats_changed()


## Апгрейд стата hp → редирект; вызывается из StatManager через has_method.
func try_redirect_hp_upgrade(lvl: int) -> bool:
	if lvl > 0:
		for _i in lvl:
			_redirect_one_stat_level()
	return true


## Сундуки вызывают через has_method — на Jonny этих методов нет.
func get_chest_item_tiers(_default_tiers: Array) -> Array:
	return CHEST_ITEM_TIERS_ALL.duplicate()


func get_chest_equip_tiers(_default_tiers: Array) -> Array:
	return CHEST_EQUIP_TIERS_ALL.duplicate()


## Ловим прямые `hp_bonus += N` без сеттера на Jonny.
func _flush_hp_bonus_redirect() -> void:
	if hp_bonus == 0:
		return
	var gained := hp_bonus
	hp_bonus = 0
	if gained > 0:
		for _i in gained:
			_redirect_one_stat_level()


func _redirect_one_stat_level() -> void:
	var candidates: Array[String] = []
	for stat_name in REDIRECT_STATS:
		if _get_stat_level(stat_name) < 10.0:
			candidates.append(stat_name)
	if candidates.is_empty():
		return
	var pick: String = candidates[randi() % candidates.size()]
	match pick:
		"move_speed":
			move_speed_level = clampf(move_speed_level + 1.0, 1.0, 10.0)
			move_speed = ST.get_stat(self, "move_speed")
		"luck":
			luck_level = clampf(luck_level + 1.0, 1.0, 10.0)
			luck = ST.get_stat(self, "luck")
		"magic":
			magic_level = clampf(magic_level + 1.0, 1.0, 10.0)
			magic = ST.get_stat(self, "magic")
		"damage":
			damage_level = clampf(damage_level + 1.0, 1.0, 10.0)
			damage = ST.get_stat(self, "damage")
		"spread":
			spread_level = clampf(spread_level + 1.0, 1.0, 10.0)
			spread = ST.get_stat(self, "spread")
		"range":
			range_level = clampf(range_level + 1.0, 1.0, 10.0)
			atk_range = ST.get_stat(self, "range")
		"fire_rate":
			fire_rate_level = clampf(fire_rate_level + 1.0, 1.0, 10.0)
			fire_rate = ST.get_stat(self, "fire_rate")


func _get_stat_level(stat_name: String) -> float:
	match stat_name:
		"move_speed":
			return move_speed_level
		"luck":
			return luck_level
		"magic":
			return magic_level
		"damage":
			return damage_level
		"spread":
			return spread_level
		"range":
			return range_level
		"fire_rate":
			return fire_rate_level
		_:
			return 10.0

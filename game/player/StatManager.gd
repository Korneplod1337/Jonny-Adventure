extends Node


func get_stat(p: Node, stat: String) -> float :
	match stat:
		"hp": 
			var hp = int(p.base_max_hp + lerp(0.0, 9.0, (p.hit_points_level - 1.0) / 9.0))
			hp += int(p.hp_bonus * 0.5)
			hp = clamp(hp, -10.0, 10.0)
			return hp
		"move_speed":
			var speed = p.base_move_speed + lerp(0.0, 270.0, (p.move_speed_level - 1.0) / 9.0)
			speed *= clamp((1 + p.speed_bonus * 0.05), 0.4, 1.6)
			return speed
		"luck":
			var luck = p.base_luck + lerp(0.0, 0.63, (p.luck_level - 1.0) / 9.0)
			luck *= (1 + p.luck_bonus * 0.05)
			luck = clamp(luck, 0.1, 4.0)
			return luck
		"magic":
			var magic = p.base_magic + lerp(0.0, 0.9, (p.magic_level - 1.0) / 9.0)
			magic *= (1 + p.magic_bonus * 0.05)
			magic = clamp(magic, 0.0, 4.0)
			return magic
		"damage":
			var damage = p.base_damage + lerp(0.0, 27.0, (p.damage_level - 1.0) / 9.0)
			damage *= (1 + p.damage_bonus * 0.1)
			damage = clamp(damage, 0.1, 1000.0)
			return damage
		"spread":
			var spread_deg: float = p.base_spread + lerp(36.0, 0.0, (p.spread_level - 1.0) / 9.0)
			spread_deg *= (1 - p.accuracy_bonus * 0.05)
			spread_deg = clamp(spread_deg, 0.01, 180.0)
			return spread_deg
		"range":
			var range_val = p.base_range + lerp(0.0, 360.0, (p.range_level - 1.0) / 9.0)
			range_val *= clamp((1 + p.range_bonus * 0.05), 0.2, 4.0)
			return range_val
		"fire_rate":
			var fire_rate = p.base_fire_rate + lerp(1.0, 0.1, (p.fire_rate_level - 1.0) / 9.0)
			print(fire_rate, ' ', (1 - clamp(p.fire_rate_bonus, -20, 20) * 0.04 * p.extra_fire_rate))
			fire_rate *= (1 - clamp(p.fire_rate_bonus, -20, 20) * 0.03 * p.extra_fire_rate)
			#print(fire_rate, '- Итого')
			return fire_rate
		_:
			push_warning("Unknown stat in getter: %s" % stat)
			return 1


func upgrade_stat(p: Node, stat:String, lvl: int) -> void:
	match stat:
		'hp':
			var hp_list = p.hp_list
			p.hit_points_level = clamp(p.hit_points_level + lvl, 1.0, 10.0)
			p.max_hp = get_stat(p, 'hp')
			if lvl < 0:
				var live_total :int = hp_list["red"] + hp_list["green"]
				if live_total > p.max_hp:
					if hp_list["red"] > 0:
						hp_list["red"] -= 1
					elif hp_list["green"] > 0:
						hp_list["green"] -= 1
		'move_speed':
			p.move_speed_level = clamp(p.move_speed_level + lvl, 1.0, 10.0)
			p.move_speed = get_stat(p, "move_speed")
		'luck':
			p.luck_level = clamp(p.luck_level + lvl, 1.0, 10.0)
			p.luck = get_stat(p, "luck")
		'magic':
			# 
			p.magic_level = clamp(p.magic_level + lvl, 1.0, 10.0)
			p.magic = get_stat(p, "magic")
		'damage':
			p.damage_level = clamp(p.damage_level + lvl, 1.0, 10.0)
			p.damage = get_stat(p, "damage")
		'spread':
			p.spread_level = clamp(p.spread_level + lvl, 1.0, 10.0)
			p.spread = get_stat(p, "spread")
		'range':
			p.range_level = clamp(p.range_level + lvl, 1.0, 10.0)
			p.atk_range =get_stat(p, "range")
		'fire_rate': 
			p.fire_rate_level = clamp(p.fire_rate_level + lvl, 1.0, 10.0)
			p.fire_rate = get_stat(p, "fire_rate")
		_:
			push_warning("Unknown stat in upgrade: %s" %stat)
	p._emit_stats_changed()

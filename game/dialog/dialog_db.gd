extends Node
## Авторский скрипт диалогов: ивенты, триггеры, деревья реплик, idle-пулы.
## Править контент здесь. Торговцы: sherochka | pepyaka | erik

var is_dialog_open: bool = false

## event_id → { trader, priority, dialog, trigger }
## trigger — имя метода в этом скрипте, возвращающего bool
const EVENTS := {
	"sherochka_first_talk": {
		"trader": "sherochka",
		"priority": 100,
		"dialog": "sherochka_first_talk",
		"trigger": "trig_sherochka_first_talk",
	},
	"pepyaka_first_talk": {
		"trader": "pepyaka",
		"priority": 100,
		"dialog": "pepyaka_first_talk",
		"trigger": "trig_pepyaka_first_talk",
	},
	"pepyaka_loyal_friend": {
		"trader": "pepyaka",
		"priority": 80,
		"dialog": "pepyaka_loyal_friend",
		"trigger": "trig_pepyaka_loyal_friend",
	},
	"erik_first_talk": {
		"trader": "erik",
		"priority": 100,
		"dialog": "erik_first_talk",
		"trigger": "trig_erik_first_talk",
	},
	"erik_rich_customer": {
		"trader": "erik",
		"priority": 70,
		"dialog": "erik_rich_customer",
		"trigger": "trig_erik_rich_customer",
	},
	"sherochka_coin_favor": {
		"trader": "sherochka",
		"priority": 60,
		"dialog": "sherochka_coin_favor",
		"trigger": "trig_sherochka_coin_favor",
	},
	"erik_secret_doors": {
		"trader": "erik",
		"priority": 60,
		"dialog": "erik_secret_doors",
		"trigger": "trig_erik_secret_doors",
	},
}

const DIALOGS := {
	"sherochka_first_talk": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "Oh! A new face. I'm Sherochka. Welcome to my shop!",
				"choices": [
					{"text": "Nice to meet you!", "next": "n1", "actions": [{"type": "loyalty", "stat": "shop_loyalty", "delta": 1}]},
					{"text": "Just browsing.", "next": "n2", "actions": []},
				],
			},
			"n1": {
				"text": "Hehe, come back often - I save the good stuff for friends.",
				"choices": [
					{"text": "I will!", "next": "", "actions": [{"type": "complete_event", "event": "sherochka_first_talk"}, {"type": "end"}]},
				],
			},
			"n2": {
				"text": "The wares aren't going anywhere... probably.",
				"choices": [
					{"text": "Leave", "next": "", "actions": [{"type": "complete_event", "event": "sherochka_first_talk"}, {"type": "end"}]},
				],
			},
		},
	},
	"sherochka_idle_0": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "Need anything shiny today?",
				"choices": [
					{"text": "Leave", "next": "", "actions": [{"type": "end"}]},
				],
			},
		},
	},
	"sherochka_idle_1": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "The best way to spend money is with me",
				"choices": [
					{"text": "Leave", "next": "", "actions": [{"type": "end"}]},
				],
			},
		},
	},
	"sherochka_idle_2": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "Hey, I have items for every taste",
				"choices": [
					{"text": "Leave", "next": "", "actions": [{"type": "end"}]},
				],
			},
		},
	},
	"sherochka_idle_3": {
		"start": "n0",
		"nodes": {
			"n0": {
# "text": "There's nothing I don't have, [shake rate=28 level=10]{player_name}[/shake] — [wave amp=20 freq=8] abc wave[/wave] — [tornado radius=6 freq=8] abc tornado[/tornado]
				"text": "There's nothing I don't have, [shake rate=25 level=8	]{player_name}[/shake]",
				"choices": [
					{"text": "Leave", "next": "", "actions": [{"type": "end"}]},
				],
			},
		},
	},
	"sherochka_coin_favor": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "Hey {player_name}... lend me some coins? I'll make it worth your while.",
				"choices": [
					{
						"text": "Give 3 coins",
						"next": "n1",
						"require": [{"type": "coins", "amount": 3}],
						"actions": [{"type": "spend_coins", "amount": 3}],
					},
					{
						"text": "Give 5 coins",
						"next": "n2",
						"require": [{"type": "coins", "amount": 5}],
						"actions": [{"type": "spend_coins", "amount": 5}],
					},
					{"text": "Not now", "next": "", "actions": [{"type": "end"}]},
				],
			},
			"n1": {
				"text": "Really thanks. I have a little something back.",
				"enter_actions": [{"type": "throw_random_item", "pool": "shop", "tiers": [1]}],
				"choices": [
					{"text": "Thanks", "next": "", "actions": [
						{"type": "complete_event", "event": "sherochka_coin_favor"},
						{"type": "end"},
					]},
				],
			},
			"n2": {
				"text": "You're a gem :D\nHere — a little something back!",
				"enter_actions": [{"type": "throw_random_item", "pool": "shop", "tiers": [2]}],
				"choices": [
					{"text": "Thanks", "next": "", "actions": [
						{"type": "complete_event", "event": "sherochka_coin_favor"},
						{"type": "loyalty", "stat": "shop_loyalty", "delta": 2},
						{"type": "end"},
					]},
				],
			},
		},
	},
	"pepyaka_first_talk": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "YO! Pepyaka's armory. You look like you need powerfully bullets",
				"choices": [
					{"text": "What do you have?", "next": "n1"},
					{"text": "Maybe later.", "next": "n1"},
				],
			},
			"n1": {
				"text": "Stick around, man. Loyalty gets you better deal",
				"choices": [
					{"text": "Got it", "next": "", "actions": [{"type": "complete_event", "event": "pepyaka_first_talk"}, {"type": "end"}]},
				],
			},
		},
	},
	"pepyaka_loyal_friend": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "You've been a good guy. Here - a little discount, on the house",
				"choices": [
					{"text": "Thanks!", "next": "", "actions": [
						{"type": "discount", "mult": 0.6},
						{"type": "complete_event", "event": "pepyaka_loyal_friend"},
						{"type": "end"},
					]},
					{"text": "Leave", "next": "", "actions": [{"type": "end"}]},
				],
			},
		},
	},
	"pepyaka_idle_0": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "Sharpen your resolve before your blade",
				"choices": [
					{"text": "Leave", "next": "", "actions": [{"type": "end"}]},
				],
			},
		},
	},
	"pepyaka_idle_1": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "What? I make perfect waves with my hands",
				"choices": [
					{"text": "Leave", "next": "", "actions": [{"type": "end"}]},
				],
			},
		},
	},
	"pepyaka_idle_2": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "I am a multiple champion of the dance cup!",
				"choices": [
					{"text": "Wow!", "next": "", "actions": [{"type": "end"}]},
				],
			},
		},
	},
	"pepyaka_idle_3": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "You'll never beat me in a dance battle",
				"choices": [
					{"text": "Leave", "next": "", "actions": [{"type": "end"}]},
				],
			},
		},
	},
	"pepyaka_idle_4": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "I once won the cup as The World's Best Weapon Maker. However, I need to work hard to show everything I have.",
				"choices": [
					{"text": "Leave", "next": "", "actions": [{"type": "end"}]},
				],
			},
		},
	},
	"erik_first_talk": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "[shake rate=28 level=10]Yo...[/shake] name's Erik, I keep the coins safe, y'know, just drop 'em on the table, dude, and like... withdraw whenever, whenever you feel it, y'know?",
				"choices": [
					{"text": "Good to know.", "next": "n1", "actions": []},
					{"text": "Leave", "next": "", "actions": [{"type": "complete_event", "event": "erik_first_talk"}, {"type": "end"}]},
				],
			},
			"n1": {
				"text": "Hey, don't lose your head out there, bro... like... the vault? It stays put, man. i-it's not goin' anywhere it's a vault, dude",
				"choices": [
					{"text": "Bye", "next": "", "actions": [{"type": "complete_event", "event": "erik_first_talk"}, {"type": "end"}]},
				],
			},
		},
	},
	"erik_rich_customer": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "Loyalty's a big deal, dude. The more you pay up or help folks out, the more doors open for ya. Just play nice and the traders'll hook you up big time. Maybe I'll even lend a hand or somethin', man.",
				"choices": [
					{"text": "----", "next": "", "actions": [
						{"type": "give_item", "id": "heal"},
						{"type": "complete_event", "event": "erik_rich_customer"},
						{"type": "end"},
					]},
					{"text": "Maybe later", "next": "", "actions": [{"type": "end"}]},
				],
			},
		},
	},
	"erik_secret_doors": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "Yo {player_name}... you've been droppin' serious coin with me, dude. Like... a lot. So uh... tip from your banker, man?\nKeep an eye out for secret doors - the barricaded ones, y'know? They ain't just walls. Shoot 'em to open",
				"choices": [
					{"text": "Got it", "next": "", "actions": [
						{"type": "complete_event", "event": "erik_secret_doors"},
						{"type": "end"},
					]},
				],
			},
		},
	},
	"erik_idle_0": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "The vault's secure, man, solid. but your pockets? Ehh... not so much, [wave amp=20 freq=8]hehehe... bummer[/wave], dude...",
				"choices": [
					{"text": "Leave", "next": "", "actions": [{"type": "end"}]},
				],
			},
		},
	},
	"erik_idle_1": {
		"start": "n0",
		"nodes": {
			"n0": {
				"text": "Interest? Pfft haha.., na-ah... like money? That's interest enough, dude",
				"choices": [
					{"text": "Leave", "next": "", "actions": [{"type": "end"}]},
				],
			},
		},
	},
}

const IDLE := {
	"sherochka": ["sherochka_idle_0", "sherochka_idle_1", "sherochka_idle_2", "sherochka_idle_3"],
	"pepyaka": ["pepyaka_idle_0", "pepyaka_idle_1", "pepyaka_idle_2", "pepyaka_idle_3", "pepyaka_idle_4"],
	"erik": ["erik_idle_0", "erik_idle_1"],
}


func refresh() -> void:
	evaluate_triggers()


func evaluate_triggers() -> void:
	for event_id in EVENTS.keys():
		if GameState.is_dialog_event_completed(event_id):
			continue
		var data: Dictionary = EVENTS[event_id]
		var trigger_name: String = str(data.get("trigger", ""))
		if trigger_name.is_empty():
			continue
		if not has_method(trigger_name):
			push_warning("DialogDB: missing trigger method '%s'" % trigger_name)
			continue
		if call(trigger_name):
			GameState.activate_dialog_event(event_id)


func has_pending_event_for(trader_id: String) -> bool:
	for event_id in GameState.active_dialog_events:
		var data: Dictionary = EVENTS.get(event_id, {})
		if str(data.get("trader", "")) == trader_id:
			return true
	return false


## Returns { "dialog_id": String, "event_id": String } — event_id empty for idle.
func pick_dialog_for(trader_id: String) -> Dictionary:
	var best_id := ""
	var best_priority := -999999
	for event_id in GameState.active_dialog_events:
		var data: Dictionary = EVENTS.get(event_id, {})
		if str(data.get("trader", "")) != trader_id:
			continue
		var priority: int = int(data.get("priority", 0))
		if priority > best_priority:
			best_priority = priority
			best_id = event_id
	if not best_id.is_empty():
		var ev: Dictionary = EVENTS[best_id]
		return {"dialog_id": str(ev.get("dialog", "")), "event_id": best_id}

	var idle_pool: Array = IDLE.get(trader_id, [])
	if idle_pool.is_empty():
		return {"dialog_id": "", "event_id": ""}
	var pick: String = str(idle_pool[randi() % idle_pool.size()])
	return {"dialog_id": pick, "event_id": ""}


func get_dialog(dialog_id: String) -> Dictionary:
	return DIALOGS.get(dialog_id, {})


func get_player_display_name() -> String:
	var player = get_tree().get_first_node_in_group("player")
	if player and "player_name" in player:
		return str(player.player_name)
	return "Jonny"


## Плейсхолдеры: {player_name}, {PLAYER_NAME} (UPPERCASE).
## BBCode эффекты RichTextLabel: [shake rate=20 level=5]...[/shake], [wave], [tornado] и т.д.
func format_dialog_text(raw: String) -> String:
	var pname := get_player_display_name()
	var out := raw.replace("{player_name}", pname)
	out = out.replace("{PLAYER_NAME}", pname.to_upper())
	return out


## require: [{"type": "coins", "amount": 5}, ...]
func check_requirements(requirements: Array) -> bool:
	for req in requirements:
		if typeof(req) != TYPE_DICTIONARY:
			continue
		var t: String = str(req.get("type", ""))
		match t:
			"coins":
				if GameState.coins < int(req.get("amount", 0)):
					return false
			"bank_coins":
				if GameState.bank_coins < int(req.get("amount", 0)):
					return false
			"stat_gte":
				var key: String = str(req.get("stat", ""))
				var data: Dictionary = StatsManager.get_stat_display(key)
				if float(data.get("value", 0)) < float(req.get("amount", 0)):
					return false
			_:
				push_warning("DialogDB: unknown require type '%s'" % t)
				return false
	return true


func start_dialog(trader_id: String, focus_node: Node2D) -> void:
	if is_dialog_open:
		return
	evaluate_triggers()
	var pick := pick_dialog_for(trader_id)
	var dialog_id: String = str(pick.get("dialog_id", ""))
	if dialog_id.is_empty() or not DIALOGS.has(dialog_id):
		return
	is_dialog_open = true
	var ui_scene: PackedScene = load("res://game/dialog/dialog_ui.tscn")
	var ui = ui_scene.instantiate()
	get_tree().root.add_child(ui)
	ui.begin(trader_id, dialog_id, str(pick.get("event_id", "")), focus_node)


func apply_actions(actions: Array, focus_node: Node2D = null) -> bool:
	## Returns true if dialog should end.
	var should_end := false
	for action in actions:
		if typeof(action) != TYPE_DICTIONARY:
			continue
		var t: String = str(action.get("type", ""))
		match t:
			"end":
				should_end = true
			"complete_event":
				GameState.complete_dialog_event(str(action.get("event", "")))
			"loyalty":
				var stat: String = str(action.get("stat", ""))
				var delta: float = float(action.get("delta", 0))
				if not stat.is_empty() and delta != 0.0:
					StatsManager.add_statistic_progress(stat, delta)
			"spend_coins":
				var amount: int = int(action.get("amount", 0))
				if amount > 0 and GameState.coins >= amount:
					GameState.add_coins(-amount)
					SoundManager.play_coins(mini(amount, 5))
			"give_item":
				var item_id: String = str(action.get("id", ""))
				if item_id.is_empty():
					continue
				var pos := Vector2.ZERO
				if focus_node and is_instance_valid(focus_node):
					pos = focus_node.global_position + Vector2(0, 80)
				else:
					var player = get_tree().get_first_node_in_group("player")
					if player:
						pos = player.global_position
				ItemManager.certain_spawn(item_id, pos)
			"throw_random_item":
				var pool: String = str(action.get("pool", "shop"))
				var tiers: Array = action.get("tiers", [1])
				_throw_random_item(pool, tiers, focus_node)
			"discount":
				var mult: float = float(action.get("mult", 0.9))
				GameState.cost_multiplier *= mult
				GameState.dialog_shop_discount *= mult
				GameState.notify_prices_changed()
			_:
				print("DialogDB: unknown action type '%s'" % t)
	return should_end


func _throw_random_item(pool: String, tiers: Array, focus_node: Node2D = null) -> void:
	var item_data: Dictionary = ItemManager.random_pick(pool, tiers)
	if item_data.is_empty():
		print("DialogDB: no item for pool=", pool, " tiers=", tiers)
		return
	var scene: PackedScene = item_data.get("scene")
	if scene == null:
		return
	var inst = scene.instantiate()
	var from_pos := Vector2.ZERO
	if focus_node and is_instance_valid(focus_node):
		from_pos = focus_node.global_position
	var player = get_tree().get_first_node_in_group("player")
	var to_pos := from_pos + Vector2(0, 100)
	if player:
		to_pos = player.global_position
	inst.cost = 0
	if "where" in inst:
		inst.where = "gift"
	var parent := get_tree().current_scene
	parent.add_child(inst)
	inst.global_position = from_pos
	var tween := parent.create_tween()
	tween.tween_property(inst, "global_position", to_pos, 0.45)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# --- Triggers (edit these) ---

func trig_sherochka_first_talk() -> bool:
	return not GameState.is_dialog_event_completed("sherochka_first_talk")


func trig_sherochka_coin_favor() -> bool:
	if GameState.is_dialog_event_completed("sherochka_coin_favor"):
		return false
	var data: Dictionary = StatsManager.get_stat_display("shop_loyalty")
	return float(data.get("value", 0)) >= 5.0


func trig_pepyaka_first_talk() -> bool:
	return not GameState.is_dialog_event_completed("pepyaka_first_talk")


func trig_pepyaka_loyal_friend() -> bool:
	if GameState.is_dialog_event_completed("pepyaka_loyal_friend"):
		return false
	var data: Dictionary = StatsManager.get_stat_display("armory_loyalty")
	return float(data.get("value", 0)) >= 10.0


func trig_erik_first_talk() -> bool:
	return not GameState.is_dialog_event_completed("erik_first_talk")


func trig_erik_rich_customer() -> bool:
	if GameState.is_dialog_event_completed("erik_rich_customer"):
		return false
	var data: Dictionary = StatsManager.get_stat_display("bank_loyalty")
	return float(data.get("value", 0)) >= 15.0


func trig_erik_secret_doors() -> bool:
	if GameState.is_dialog_event_completed("erik_secret_doors"):
		return false
	var data: Dictionary = StatsManager.get_stat_display("bank_loyalty")
	return float(data.get("value", 0)) >= 30.0

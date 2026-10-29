extends Node

const SAVE_PATH := "user://progress.cfg"
var state: Dictionary = {}
var last_error := OK


func _ready() -> void:
	_reset_memory()
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	var stored: Variant = cfg.get_value("campaign", "state", {})
	if stored is Dictionary and stored.has("stars"):
		for key: String in state:
			if stored.has(key) and typeof(stored[key]) == typeof(state[key]):
				state[key] = stored[key]
	else:
		state.stars[0] = clampi(int(cfg.get_value("level_01", "stars", 0)), 0, 3)
		state.coins = maxi(0, int(cfg.get_value("player", "coins", 0)))
	if state.stars.size() != 3:
		state.stars = [0, 0, 0]
	for index in range(3):
		state.stars[index] = clampi(int(state.stars[index]), 0, 3)
	state.coins = clampi(int(state.coins), 0, 1000000)
	state.coupons = clampi(int(state.coupons), 0, 99)
	state.trends = clampi(int(state.trends), 0, 99)
	state.last_level = clampi(int(state.last_level), 0, 2)
	state.story_complete = completed(0) and completed(1) and completed(2)


func _reset_memory() -> void:
	state = {"stars": [0, 0, 0], "coins": 0, "badges": [], "coupons": 0,
		"trends": 0, "uniform_alt": false, "story_complete": false,
		"last_level": 0, "attempt": {}, "started": false}


func save() -> Error:
	var cfg := ConfigFile.new()
	cfg.set_value("campaign", "version", 2)
	cfg.set_value("campaign", "state", state)
	last_error = cfg.save(SAVE_PATH)
	return last_error


func new_game() -> bool:
	var old := state.duplicate(true)
	_reset_memory()
	state.started = true
	if save() != OK:
		state = old
		return false
	return true


func has_progress() -> bool:
	return state.started or state.stars.any(func(value: Variant) -> bool: return int(value) > 0) or not state.attempt.is_empty()


func completed(index: int) -> bool:
	return index >= 0 and index < 3 and int(state.stars[index]) >= 2


func unlocked(index: int) -> bool:
	return index == 0 or (index > 0 and index < 3 and completed(index - 1))


func next_level() -> int:
	for index in range(3):
		if not completed(index):
			return index
	return 2


func save_attempt(attempt: Dictionary) -> bool:
	state.attempt = attempt.duplicate(true)
	state.started = true
	if not attempt.is_empty():
		state.last_level = clampi(int(attempt.get("level", 0)), 0, 2)
	return save() == OK


func record_result(index: int, stars: int, thrift: bool, fast: bool) -> Dictionary:
	var old := state.duplicate(true)
	var first_clear := not completed(index)
	var reward := maxi(0, stars - int(state.stars[index])) * 50
	state.coins += reward
	state.stars[index] = maxi(int(state.stars[index]), stars)
	state.last_level = mini(index + 1, 2)
	state.attempt = {}
	if stars == 3:
		_badge("Estrella dorada")
	if thrift:
		_badge("Buen presupuesto")
	if fast:
		_badge("Contra reloj")
	if first_clear and index == 0:
		_badge("Primer cambio")
	if first_clear and index == 1:
		state.coupons += 1
		state.trends += 1
		_badge("Diseñador de eventos")
	state.story_complete = completed(0) and completed(1) and completed(2)
	if state.story_complete:
		_badge("Hair Designer")
	if save() != OK:
		state = old
		return {"saved": false, "reward": 0, "first_clear": false}
	return {"saved": true, "reward": reward, "first_clear": first_clear}


func _badge(name: String) -> void:
	if not state.badges.has(name):
		state.badges.append(name)


func purchase(item: String) -> bool:
	var price := 60 if item == "coupons" else 80
	if item not in ["coupons", "trends"] or state.coins < price or (item == "trends" and not completed(1)):
		return false
	var old := state.duplicate(true)
	state.coins -= price
	state[item] += 1
	if save() != OK:
		state = old
		return false
	return true


func consume(item: String) -> bool:
	if item not in ["coupons", "trends"] or state[item] <= 0:
		return false
	state[item] -= 1
	if save() != OK:
		state[item] += 1
		return false
	return true


func consume_service_items(coupon: bool, trend: bool) -> bool:
	if (coupon and state.coupons <= 0) or (trend and state.trends <= 0):
		return false
	if not coupon and not trend:
		return true
	var old := state.duplicate(true)
	state.coupons -= 1 if coupon else 0
	state.trends -= 1 if trend else 0
	if save() != OK:
		state = old
		return false
	return true

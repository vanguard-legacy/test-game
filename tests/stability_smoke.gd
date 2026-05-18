extends SceneTree

const GameBalance := preload("res://scripts/game_balance.gd")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const MAX_STEPS_PER_WAVE: int = 2200
const SIMULATION_STEP: float = 0.1


func _initialize() -> void:
	_run_smoke.call_deferred()


func _run_smoke() -> void:
	print("STABILITY_SMOKE_START")
	_verify_reward_choices()

	var main := MAIN_SCENE.instantiate()
	root.add_child(main)
	await process_frame

	print("STABILITY_SMOKE_NEW_GAME")
	main._on_new_game_requested()
	main.run_state.gold = 10000
	main.run_state.owned_tower_ids.clear()
	main.run_state.owned_tower_ids.append(GameBalance.TOWER_GWIZARD)
	main.run_state.owned_tower_ids.append(GameBalance.TOWER_LONGBOW)
	main.run_state.owned_tower_ids.append(GameBalance.TOWER_FROST)
	main._update_ui()
	await process_frame

	_place_test_towers(main)
	_verify_sell_tower(main)

	for _wave_index in range(2):
		print("STABILITY_SMOKE_WAVE_START %d" % (_wave_index + 1))
		main._on_start_wave_requested()
		_run_wave_until_complete(main)
		if main.active_reward_choices.size() > 0:
			print("STABILITY_SMOKE_REWARD %d" % (_wave_index + 1))
			main._on_reward_choice_selected(0)

		if main.run_state.game_over:
			print("STABILITY_SMOKE_GAME_OVER %d" % main.run_state.wave)
			break

		print("STABILITY_SMOKE_WAVE_DONE %d enemies=%d" % [main.run_state.wave, main.enemies.size()])

	await process_frame
	print("STABILITY_SMOKE_OK wave=%d score=%d gold=%d" % [main.run_state.wave, main.run_state.score, main.run_state.gold])
	quit(0)


func _verify_reward_choices() -> void:
	print("STABILITY_SMOKE_REWARD_CHOICES")
	var owned_tower_ids: Array[String] = [
		GameBalance.TOWER_GWIZARD,
		GameBalance.TOWER_LONGBOW,
		GameBalance.TOWER_FROST,
	]
	var chosen_reward_ids: Array[String] = [
		"sharper_runes",
		"focus_lenses",
		"quick_chanting",
		"battle_scribes",
		"haste_runes",
	]

	for reward_level in range(24):
		var choices := GameBalance.get_reward_choices(owned_tower_ids, chosen_reward_ids, reward_level)
		if choices.size() != 3:
			push_error("Reward choice count was %d at level %d." % [choices.size(), reward_level])
			quit(1)
			return

		for reward in choices:
			if reward.id.is_empty():
				push_error("Reward choice had an empty id at level %d." % reward_level)
				quit(1)
				return


func _place_test_towers(main: Node) -> void:
	print("STABILITY_SMOKE_PLACE_TOWERS")
	var tower_ids: Array[String] = [
		GameBalance.TOWER_GWIZARD,
		GameBalance.TOWER_GWIZARD,
		GameBalance.TOWER_LONGBOW,
		GameBalance.TOWER_FROST,
		GameBalance.TOWER_LONGBOW,
		GameBalance.TOWER_FROST,
	]
	var ground_points: Array[Vector2] = [
		Vector2(-7.0, -3.9),
		Vector2(-6.2, 0.4),
		Vector2(-2.5, 0.8),
		Vector2(1.3, -0.8),
		Vector2(3.0, 4.2),
		Vector2(7.5, 4.7),
	]

	for index in range(tower_ids.size()):
		var ground_point := ground_points[index]
		var tower_position: Vector3 = main.level_map._world_from_ground(ground_point, 0.62)
		main.selected_tower_id = tower_ids[index]
		main._on_tower_placement_confirmed(tower_position)
		var tower = main.towers[-1]
		if tower.terrain_bonus == null:
			push_error("Tower terrain bonus was not applied.")
			quit(1)
			return


func _verify_sell_tower(main: Node) -> void:
	print("STABILITY_SMOKE_SELL_TOWER")
	var gold_before: int = main.run_state.gold
	var tower_count_before: int = main.towers.size()
	var tower_to_sell: PrototypeTower = main.towers[0]
	main._select_tower(tower_to_sell)
	if not tower_to_sell.is_selected:
		push_error("Selecting a tower did not enable its selection highlight.")
		quit(1)
		return

	var refund: int = tower_to_sell.get_sell_value()
	main._on_sell_tower_requested()
	if main.towers.size() != tower_count_before - 1:
		push_error("Selling a tower did not remove it from the tower list.")
		quit(1)
		return

	if main.towers.has(tower_to_sell):
		push_error("Selling a selected tower left that tower in the tower list.")
		quit(1)
		return

	if main.run_state.gold != gold_before + refund:
		push_error("Selling a tower refunded %d gold; expected %d." % [main.run_state.gold - gold_before, refund])
		quit(1)
		return


func _run_wave_until_complete(main: Node) -> void:
	for _step_index in range(MAX_STEPS_PER_WAVE):
		main._process(SIMULATION_STEP)
		for tower in main.towers.duplicate():
			if is_instance_valid(tower):
				tower._process(SIMULATION_STEP)

		for enemy in main.enemies.duplicate():
			if is_instance_valid(enemy):
				enemy._process(SIMULATION_STEP)

		if main.active_reward_choices.size() > 0:
			return

		if not main.run_state.wave_active and main.enemies.is_empty():
			return

		if main.run_state.game_over:
			return

	push_error("Stability smoke wave timed out.")
	quit(1)

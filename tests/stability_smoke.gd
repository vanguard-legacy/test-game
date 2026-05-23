extends SceneTree

const GameBalance := preload("res://scripts/game_balance.gd")
const Tower := preload("res://scripts/tower.gd")
const TowerProjectile := preload("res://scripts/tower_projectile.gd")
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
	await main._on_new_game_requested("20260522")
	main.run_state.gold = 10000
	main.run_state.owned_tower_ids.clear()
	main.run_state.owned_tower_ids.append(GameBalance.TOWER_GWIZARD)
	main.run_state.owned_tower_ids.append(GameBalance.TOWER_LONGBOW)
	main.run_state.owned_tower_ids.append(GameBalance.TOWER_FROST)
	main._update_ui()
	await process_frame

	_verify_game_speed(main)
	_verify_auto_start_toggle(main)
	_verify_spawn_tooltip(main)
	_verify_reward_overlay_non_modal(main)
	_place_test_towers(main)
	_verify_sell_tower(main)

	for _wave_index in range(2):
		print("STABILITY_SMOKE_WAVE_START %d" % (_wave_index + 1))
		main._on_start_wave_requested()
		while main.run_state.wave_active or not main.enemies.is_empty() or main.active_reward_choices.size() > 0:
			_run_wave_until_complete(main)
			if main.active_reward_choices.size() > 0:
				print("STABILITY_SMOKE_REWARD %d" % (_wave_index + 1))
				main._on_reward_choice_selected(0)

			if main.run_state.game_over:
				print("STABILITY_SMOKE_GAME_OVER %d" % main.run_state.wave)
				break

		if main.run_state.game_over:
			break

		print("STABILITY_SMOKE_WAVE_DONE %d enemies=%d" % [main.run_state.wave, main.enemies.size()])

	await process_frame
	if main.run_state.wave != 2:
		push_error("Smoke expected to complete wave 2, but ended on wave %d." % main.run_state.wave)
		quit(1)
		return

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

	var exhausted_choices := GameBalance.get_reward_choices(owned_tower_ids, chosen_reward_ids, 24)
	if not exhausted_choices.is_empty():
		push_error("Exhausted rewards should return no stipend fallback choices.")
		quit(1)
		return

	owned_tower_ids = [GameBalance.TOWER_GWIZARD]
	chosen_reward_ids.clear()
	var choices := GameBalance.get_reward_choices(owned_tower_ids, chosen_reward_ids, 0)
	if choices.size() != 3:
		push_error("Fresh reward draft returned %d choices; expected 3." % choices.size())
		quit(1)
		return

	for reward in choices:
		if reward.id.is_empty():
			push_error("Reward choice had an empty id.")
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


func _verify_game_speed(main: Node) -> void:
	print("STABILITY_SMOKE_GAME_SPEED")
	main._on_game_speed_requested(32.0)
	if not is_equal_approx(Engine.time_scale, 32.0):
		push_error("Game speed control did not set Engine.time_scale to 32x.")
		quit(1)
		return

	main._on_game_speed_requested(1.0)
	if not is_equal_approx(Engine.time_scale, 1.0):
		push_error("Game speed control did not return Engine.time_scale to 1x.")
		quit(1)
		return


func _verify_spawn_tooltip(main: Node) -> void:
	print("STABILITY_SMOKE_SPAWN_TOOLTIP")
	var next_wave_body: String = main._get_spawn_tooltip_body()
	if not next_wave_body.contains("Gobbelin"):
		push_error("Next-wave spawn tooltip did not include incoming Gobbelins.")
		quit(1)
		return

	var wave_before: int = main.run_state.wave
	main.run_state.start_wave(GameBalance.get_wave_definition(wave_before + 1))
	var current_wave_body: String = main._get_spawn_tooltip_body()
	if not current_wave_body.contains("Still coming"):
		push_error("Active-wave spawn tooltip did not switch to remaining enemies.")
		quit(1)
		return

	main.run_state.wave = wave_before
	main.run_state.wave_active = false
	main.run_state.wave_queue.clear()
	main.run_state.next_spawn_index = 0


func _verify_auto_start_toggle(main: Node) -> void:
	print("STABILITY_SMOKE_AUTO_START")
	main._on_auto_start_toggled(true)
	if not main.auto_start_next_wave:
		push_error("Auto wave toggle did not enable auto-start.")
		quit(1)
		return

	main._on_auto_start_toggled(false)
	if main.auto_start_next_wave:
		push_error("Auto wave toggle did not disable auto-start.")
		quit(1)
		return


func _verify_reward_overlay_non_modal(main: Node) -> void:
	print("STABILITY_SMOKE_REWARD_OVERLAY")
	main._open_reward_choices()
	if main.get_tree().paused:
		push_error("Reward choices paused gameplay.")
		quit(1)
		return

	if main.active_reward_choices.is_empty():
		push_error("Reward choices did not open.")
		quit(1)
		return

	main._on_reward_choice_selected(0)


func _verify_sell_tower(main: Node) -> void:
	print("STABILITY_SMOKE_SELL_TOWER")
	var gold_before: int = main.run_state.gold
	var tower_count_before: int = main.towers.size()
	var tower_to_sell: Tower = main.towers[0]
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

		for projectile in main.tower_container.get_children():
			if projectile is TowerProjectile:
				projectile._process(SIMULATION_STEP)

		if main.active_reward_choices.size() > 0:
			return

		if not main.run_state.wave_active and main.enemies.is_empty():
			return

		if main.run_state.game_over:
			return

	push_error("Stability smoke wave timed out.")
	quit(1)

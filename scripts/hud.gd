extends CanvasLayer
class_name PrototypeHud

const GameBalance := preload("res://scripts/game_balance.gd")
const TOOLTIP_OFFSET: Vector2 = Vector2(18.0, 18.0)

signal build_tower_requested(tower_id: String)
signal cancel_build_requested
signal start_wave_requested
signal upgrade_tower_requested
signal reward_choice_selected(choice_index: int)
signal menu_requested
signal resume_requested
signal new_game_requested
signal restart_requested
signal quit_requested

@onready var top_bar: PanelContainer = $Root/Layout/TopBar
@onready var build_panel: PanelContainer = $Root/Layout/BottomRow/BuildPanel
@onready var upgrade_panel: PanelContainer = $Root/Layout/BottomRow/UpgradePanel
@onready var message_panel: PanelContainer = $Root/Layout/BottomRow/MessagePanel
@onready var title_label: Label = $Root/Layout/TopBar/Margin/StatsRow/Title
@onready var wave_value: Label = $Root/Layout/TopBar/Margin/StatsRow/WaveStat/Value
@onready var lives_value: Label = $Root/Layout/TopBar/Margin/StatsRow/LivesStat/Value
@onready var gold_value: Label = $Root/Layout/TopBar/Margin/StatsRow/GoldStat/Value
@onready var xp_value: Label = $Root/Layout/TopBar/Margin/StatsRow/XPStat/Value
@onready var score_value: Label = $Root/Layout/TopBar/Margin/StatsRow/ScoreStat/Value
@onready var towers_value: Label = $Root/Layout/TopBar/Margin/StatsRow/TowersStat/Value
@onready var incoming_value: Label = $Root/Layout/TopBar/Margin/StatsRow/IncomingStat/Value
@onready var menu_button: Button = $Root/Layout/TopBar/Margin/StatsRow/MenuButton
@onready var build_title: Label = $Root/Layout/BottomRow/BuildPanel/Margin/Stack/BuildTitle
@onready var upgrade_title: Label = $Root/Layout/BottomRow/UpgradePanel/Margin/Stack/UpgradeTitle
@onready var selected_tower_label: Label = $Root/Layout/BottomRow/UpgradePanel/Margin/Stack/SelectedTowerLabel
@onready var tower_stats_label: Label = $Root/Layout/BottomRow/UpgradePanel/Margin/Stack/TowerStatsLabel
@onready var message_title: Label = $Root/Layout/BottomRow/MessagePanel/Margin/Stack/MessageTitle
@onready var message_label: Label = $Root/Layout/BottomRow/MessagePanel/Margin/Stack/MessageLabel
@onready var build_tower_button: Button = $Root/Layout/BottomRow/BuildPanel/Margin/Stack/BuildTowerButton
@onready var build_tower_button_2: Button = $Root/Layout/BottomRow/BuildPanel/Margin/Stack/BuildTowerButton2
@onready var build_tower_button_3: Button = $Root/Layout/BottomRow/BuildPanel/Margin/Stack/BuildTowerButton3
@onready var cancel_build_button: Button = $Root/Layout/BottomRow/BuildPanel/Margin/Stack/CancelBuildButton
@onready var start_wave_button: Button = $Root/Layout/BottomRow/BuildPanel/Margin/Stack/StartWaveButton
@onready var upgrade_tower_button: Button = $Root/Layout/BottomRow/UpgradePanel/Margin/Stack/UpgradeTowerButton
@onready var menu_overlay: Control = $Root/MenuOverlay
@onready var menu_panel: PanelContainer = $Root/MenuOverlay/MenuPanel
@onready var menu_title: Label = $Root/MenuOverlay/MenuPanel/Margin/Stack/MenuTitle
@onready var resume_button: Button = $Root/MenuOverlay/MenuPanel/Margin/Stack/ResumeButton
@onready var new_game_button: Button = $Root/MenuOverlay/MenuPanel/Margin/Stack/NewGameButton
@onready var restart_button: Button = $Root/MenuOverlay/MenuPanel/Margin/Stack/RestartButton
@onready var quit_button: Button = $Root/MenuOverlay/MenuPanel/Margin/Stack/QuitButton
@onready var reward_overlay: Control = $Root/RewardOverlay
@onready var reward_panel: PanelContainer = $Root/RewardOverlay/RewardPanel
@onready var reward_title: Label = $Root/RewardOverlay/RewardPanel/Margin/Stack/RewardTitle
@onready var reward_choice_1_button: Button = $Root/RewardOverlay/RewardPanel/Margin/Stack/RewardChoices/RewardChoice1Button
@onready var reward_choice_2_button: Button = $Root/RewardOverlay/RewardPanel/Margin/Stack/RewardChoices/RewardChoice2Button
@onready var reward_choice_3_button: Button = $Root/RewardOverlay/RewardPanel/Margin/Stack/RewardChoices/RewardChoice3Button
@onready var tower_tooltip: PanelContainer = $Root/TowerTooltip
@onready var tower_tooltip_title: Label = $Root/TowerTooltip/Margin/Stack/TooltipTitle
@onready var tower_tooltip_body: Label = $Root/TowerTooltip/Margin/Stack/TooltipBody

var tower_slot_buttons: Array[Button] = []
var tower_slot_ids: Array[String] = []
var tower_slot_tooltips: Array[Dictionary] = []
var reward_choice_buttons: Array[Button] = []
var tower_tooltip_source: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	tower_slot_buttons = [build_tower_button, build_tower_button_2, build_tower_button_3]
	reward_choice_buttons = [reward_choice_1_button, reward_choice_2_button, reward_choice_3_button]
	_apply_styles()
	for index in range(tower_slot_buttons.size()):
		tower_slot_buttons[index].pressed.connect(_on_tower_slot_button_pressed.bind(index))
		tower_slot_buttons[index].mouse_entered.connect(_on_tower_slot_mouse_entered.bind(index))
		tower_slot_buttons[index].mouse_exited.connect(_on_tower_slot_mouse_exited)

	for index in range(reward_choice_buttons.size()):
		reward_choice_buttons[index].pressed.connect(_on_reward_choice_button_pressed.bind(index))

	cancel_build_button.pressed.connect(_on_cancel_build_button_pressed)
	start_wave_button.pressed.connect(_on_start_wave_button_pressed)
	upgrade_tower_button.pressed.connect(_on_upgrade_tower_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	resume_button.pressed.connect(_on_resume_button_pressed)
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	set_build_mode(false)
	update_selected_tower(null, 0)


func _process(_delta: float) -> void:
	if tower_tooltip.visible:
		_position_tower_tooltip()


func update_stats(wave: int, lives: int, score: int, gold: int, xp: int, xp_to_next: int, incoming: int, tower_count: int) -> void:
	wave_value.text = str(wave)
	lives_value.text = str(lives)
	gold_value.text = str(gold)
	xp_value.text = "%d/%d" % [xp, xp_to_next]
	score_value.text = str(score)
	towers_value.text = str(tower_count)
	incoming_value.text = str(incoming)


func set_message(message: String) -> void:
	message_label.text = message


func set_build_mode(is_building: bool) -> void:
	cancel_build_button.modulate.a = 1.0 if is_building else 0.0
	cancel_build_button.disabled = not is_building
	cancel_build_button.mouse_filter = Control.MOUSE_FILTER_STOP if is_building else Control.MOUSE_FILTER_IGNORE
	if is_building:
		for button in tower_slot_buttons:
			button.disabled = true


func update_build_options(owned_tower_ids: Array[String], active_tower_id: String, gold: int, can_build: bool, is_building: bool) -> void:
	tower_slot_ids.clear()
	tower_slot_tooltips.clear()
	for slot_index in range(tower_slot_buttons.size()):
		var button := tower_slot_buttons[slot_index]
		if slot_index >= owned_tower_ids.size():
			tower_slot_ids.append("")
			tower_slot_tooltips.append({
				"title": "Locked Tower Slot",
				"body": "Choose tower unlock rewards to add more build options.",
			})
			button.text = "Locked Tower Slot"
			button.tooltip_text = ""
			button.disabled = true
			continue

		var tower_id := owned_tower_ids[slot_index]
		var tower_config := GameBalance.get_tower_config(tower_id)
		var tower_cost := int(tower_config.get("cost", GameBalance.TOWER_COST))
		var tower_name := str(tower_config.get("short_name", tower_config.get("name", "Tower")))
		tower_slot_ids.append(tower_id)
		tower_slot_tooltips.append(_get_build_slot_tooltip(tower_config))
		button.text = "%s (%d)" % [tower_name, tower_cost]
		button.tooltip_text = ""
		button.disabled = is_building or not can_build or gold < tower_cost
		button.modulate.a = 1.0 if tower_id == active_tower_id else 0.88


func set_start_wave_enabled(is_enabled: bool) -> void:
	start_wave_button.disabled = not is_enabled


func update_selected_tower(tower: PrototypeTower, gold: int) -> void:
	if tower == null or not is_instance_valid(tower):
		selected_tower_label.text = "No tower selected"
		tower_stats_label.text = "Click a placed tower to inspect it."
		upgrade_tower_button.text = "Upgrade Tower"
		upgrade_tower_button.disabled = true
		return

	selected_tower_label.text = tower.get_display_name()
	tower_stats_label.text = "Damage %.1f  Range %.1f\n%s" % [tower.damage, tower.attack_range, tower.get_upgrade_summary()]
	upgrade_tower_button.text = tower.get_upgrade_summary()
	upgrade_tower_button.disabled = not tower.can_upgrade() or gold < tower.get_upgrade_cost()


func show_main_menu(title: String, can_resume: bool) -> void:
	menu_title.text = title
	menu_overlay.visible = true
	resume_button.disabled = not can_resume
	restart_button.disabled = not can_resume


func hide_menu() -> void:
	menu_overlay.visible = false


func show_reward_choices(choices: Array[Dictionary]) -> void:
	reward_overlay.visible = true
	reward_title.text = "Choose a Reward"
	for index in range(reward_choice_buttons.size()):
		var button := reward_choice_buttons[index]
		if index >= choices.size():
			button.text = "No Reward"
			button.disabled = true
			continue

		var reward := choices[index]
		button.text = "%s\n%s" % [str(reward.get("title", "Reward")), str(reward.get("description", ""))]
		button.disabled = false


func hide_reward_choices() -> void:
	reward_overlay.visible = false


func show_tower_tooltip(title: String, body: String, source: String = "world") -> void:
	tower_tooltip_source = source
	tower_tooltip_title.text = title
	tower_tooltip_body.text = body
	tower_tooltip.visible = true
	_position_tower_tooltip()


func hide_tower_tooltip() -> void:
	tower_tooltip.visible = false
	tower_tooltip_source = ""


func hide_world_tower_tooltip() -> void:
	if tower_tooltip_source == "world":
		hide_tower_tooltip()


func _on_tower_slot_button_pressed(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= tower_slot_ids.size():
		return

	var tower_id := tower_slot_ids[slot_index]
	if tower_id.is_empty():
		return

	build_tower_requested.emit(tower_id)


func _on_tower_slot_mouse_entered(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= tower_slot_tooltips.size():
		return

	var tooltip := tower_slot_tooltips[slot_index]
	show_tower_tooltip(str(tooltip.get("title", "")), str(tooltip.get("body", "")), "ui")


func _on_tower_slot_mouse_exited() -> void:
	if tower_tooltip_source == "ui":
		hide_tower_tooltip()


func _on_cancel_build_button_pressed() -> void:
	cancel_build_requested.emit()


func _on_start_wave_button_pressed() -> void:
	start_wave_requested.emit()


func _on_upgrade_tower_button_pressed() -> void:
	upgrade_tower_requested.emit()


func _on_reward_choice_button_pressed(choice_index: int) -> void:
	reward_choice_selected.emit(choice_index)


func _on_menu_button_pressed() -> void:
	menu_requested.emit()


func _on_resume_button_pressed() -> void:
	resume_requested.emit()


func _on_new_game_button_pressed() -> void:
	new_game_requested.emit()


func _on_restart_button_pressed() -> void:
	restart_requested.emit()


func _on_quit_button_pressed() -> void:
	quit_requested.emit()


func _apply_styles() -> void:
	for panel in [top_bar, build_panel, upgrade_panel, message_panel, menu_panel, reward_panel, tower_tooltip]:
		panel.add_theme_stylebox_override("panel", PrototypeUiTheme.panel_style())

	for button in [cancel_build_button, start_wave_button, upgrade_tower_button, menu_button, resume_button, new_game_button, restart_button, quit_button]:
		_style_button(button)

	for button in tower_slot_buttons:
		_style_button(button)

	for button in reward_choice_buttons:
		_style_button(button)

	title_label.add_theme_color_override("font_color", PrototypeUiTheme.TEXT_COLOR)
	title_label.add_theme_font_size_override("font_size", 20)
	build_title.add_theme_color_override("font_color", PrototypeUiTheme.TEXT_COLOR)
	build_title.add_theme_font_size_override("font_size", 18)
	upgrade_title.add_theme_color_override("font_color", PrototypeUiTheme.TEXT_COLOR)
	upgrade_title.add_theme_font_size_override("font_size", 18)
	selected_tower_label.add_theme_color_override("font_color", PrototypeUiTheme.TEXT_COLOR)
	tower_stats_label.add_theme_color_override("font_color", PrototypeUiTheme.MUTED_TEXT_COLOR)
	message_title.add_theme_color_override("font_color", PrototypeUiTheme.TEXT_COLOR)
	message_title.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", PrototypeUiTheme.TEXT_COLOR)
	message_label.add_theme_font_size_override("font_size", 15)
	menu_title.add_theme_color_override("font_color", PrototypeUiTheme.TEXT_COLOR)
	menu_title.add_theme_font_size_override("font_size", 24)
	reward_title.add_theme_color_override("font_color", PrototypeUiTheme.TEXT_COLOR)
	reward_title.add_theme_font_size_override("font_size", 24)
	tower_tooltip_title.add_theme_color_override("font_color", PrototypeUiTheme.VALUE_TEXT_COLOR)
	tower_tooltip_title.add_theme_font_size_override("font_size", 17)
	tower_tooltip_body.add_theme_color_override("font_color", PrototypeUiTheme.TEXT_COLOR)
	tower_tooltip_body.add_theme_font_size_override("font_size", 14)
	_style_stat_labels()


func _style_stat_labels() -> void:
	var stat_nodes: Array[Node] = [
		wave_value.get_parent(),
		lives_value.get_parent(),
		gold_value.get_parent(),
		xp_value.get_parent(),
		score_value.get_parent(),
		towers_value.get_parent(),
		incoming_value.get_parent(),
	]

	for stat_node in stat_nodes:
		for child in stat_node.get_children():
			var label := child as Label
			if label == null:
				continue

			if label.name == "Value":
				label.add_theme_color_override("font_color", PrototypeUiTheme.VALUE_TEXT_COLOR)
				label.add_theme_font_size_override("font_size", 20)
			else:
				label.add_theme_color_override("font_color", PrototypeUiTheme.MUTED_TEXT_COLOR)
				label.add_theme_font_size_override("font_size", 12)


func _style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", PrototypeUiTheme.button_style(PrototypeUiTheme.BUTTON_COLOR))
	button.add_theme_stylebox_override("hover", PrototypeUiTheme.button_style(PrototypeUiTheme.BUTTON_HOVER_COLOR))
	button.add_theme_stylebox_override("pressed", PrototypeUiTheme.button_style(PrototypeUiTheme.BUTTON_HOVER_COLOR.darkened(0.12)))
	button.add_theme_stylebox_override("disabled", PrototypeUiTheme.button_style(PrototypeUiTheme.BUTTON_DISABLED_COLOR))
	button.add_theme_color_override("font_color", PrototypeUiTheme.TEXT_COLOR)
	button.add_theme_color_override("font_disabled_color", PrototypeUiTheme.MUTED_TEXT_COLOR)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _get_build_slot_tooltip(tower_config: Dictionary) -> Dictionary:
	var tower_name := str(tower_config.get("name", "Tower"))
	var description := str(tower_config.get("description", ""))
	var body := "%s\nCost %d gold\nDamage %.1f  Range %.1f\nFires every %.2fs\n%s" % [
		description,
		int(tower_config.get("cost", GameBalance.TOWER_COST)),
		float(tower_config.get("damage", GameBalance.TOWER_BASE_DAMAGE)),
		float(tower_config.get("range", GameBalance.TOWER_BASE_RANGE)),
		float(tower_config.get("fire_rate", GameBalance.TOWER_BASE_FIRE_RATE)),
		_get_effect_summary(tower_config),
	]
	return {"title": tower_name, "body": body}


func _get_effect_summary(tower_config: Dictionary) -> String:
	match str(tower_config.get("effect", GameBalance.TOWER_EFFECT_BOLT)):
		GameBalance.TOWER_EFFECT_FROST:
			return "Applies a slowing chill on hit."
		GameBalance.TOWER_EFFECT_SPLASH:
			return "Splashes nearby enemies around the target."
		_:
			return "Reliable single-target damage."


func _position_tower_tooltip() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var tooltip_size := tower_tooltip.size
	if tooltip_size == Vector2.ZERO:
		tooltip_size = tower_tooltip.custom_minimum_size

	var target_position := get_viewport().get_mouse_position() + TOOLTIP_OFFSET
	target_position.x = minf(target_position.x, viewport_size.x - tooltip_size.x - 12.0)
	target_position.y = minf(target_position.y, viewport_size.y - tooltip_size.y - 12.0)
	tower_tooltip.position = target_position.max(Vector2(12.0, 12.0))

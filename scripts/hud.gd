extends CanvasLayer
class_name DefenseHud

const GameBalance := preload("res://scripts/game_balance.gd")
const HudViewModel := preload("res://scripts/hud_view_model.gd")
const RewardDefinition := preload("res://scripts/reward_definition.gd")
const TowerDefinition := preload("res://scripts/tower_definition.gd")
const TooltipData := preload("res://scripts/tooltip_data.gd")
const Tower := preload("res://scripts/tower.gd")
const UiTheme := preload("res://scripts/ui_theme.gd")
const TOOLTIP_OFFSET: Vector2 = Vector2(18.0, 18.0)

# Presentation-only HUD. Gameplay state arrives as typed view models and
# definitions; this script formats controls, emits user intent, and owns tooltip
# placement without changing run state directly.

signal build_tower_requested(tower_id: String)
signal cancel_build_requested
signal start_wave_requested
signal upgrade_tower_requested
signal sell_tower_requested
signal reward_choice_selected(choice_index: int)
signal menu_requested
signal resume_requested
signal new_game_requested
signal restart_requested
signal quit_requested
signal game_speed_requested(speed: float)

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
@onready var speed_1x_button: Button = $Root/Layout/TopBar/Margin/StatsRow/SpeedControls/Speed1xButton
@onready var speed_2x_button: Button = $Root/Layout/TopBar/Margin/StatsRow/SpeedControls/Speed2xButton
@onready var speed_4x_button: Button = $Root/Layout/TopBar/Margin/StatsRow/SpeedControls/Speed4xButton
@onready var menu_button: Button = $Root/Layout/TopBar/Margin/StatsRow/MenuButton
@onready var build_title: Label = $Root/Layout/BottomRow/BuildPanel/Margin/Stack/BuildTitle
@onready var upgrade_title: Label = $Root/Layout/BottomRow/UpgradePanel/Margin/Stack/UpgradeTitle
@onready var selected_tower_label: Label = $Root/Layout/BottomRow/UpgradePanel/Margin/Stack/SelectedTowerLabel
@onready var tower_stats_label: Label = $Root/Layout/BottomRow/UpgradePanel/Margin/Stack/TowerStatsLabel
@onready var message_title: Label = $Root/Layout/BottomRow/MessagePanel/Margin/Stack/MessageTitle
@onready var message_scroll: ScrollContainer = $Root/Layout/BottomRow/MessagePanel/Margin/Stack/MessageScroll
@onready var message_label: Label = $Root/Layout/BottomRow/MessagePanel/Margin/Stack/MessageScroll/MessageLabel
@onready var build_tower_button: Button = $Root/Layout/BottomRow/BuildPanel/Margin/Stack/BuildTowerButton
@onready var build_tower_button_2: Button = $Root/Layout/BottomRow/BuildPanel/Margin/Stack/BuildTowerButton2
@onready var build_tower_button_3: Button = $Root/Layout/BottomRow/BuildPanel/Margin/Stack/BuildTowerButton3
@onready var cancel_build_button: Button = $Root/Layout/BottomRow/BuildPanel/Margin/Stack/CancelBuildButton
@onready var start_wave_button: Button = $Root/Layout/BottomRow/BuildPanel/Margin/Stack/StartWaveButton
@onready var upgrade_tower_button: Button = $Root/Layout/BottomRow/UpgradePanel/Margin/Stack/UpgradeTowerButton
@onready var sell_tower_button: Button = $Root/Layout/BottomRow/UpgradePanel/Margin/Stack/SellTowerButton
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
var tower_slot_tooltips: Array[TooltipData] = []
var reward_choice_buttons: Array[Button] = []
var speed_buttons: Array[Button] = []
var tower_tooltip_source: String = ""
var command_log: Array[String] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cache_button_groups()
	_apply_styles()
	_connect_button_signals()
	set_build_mode(false)
	update_selected_tower(null, 0)


func _cache_button_groups() -> void:
	tower_slot_buttons = [build_tower_button, build_tower_button_2, build_tower_button_3]
	reward_choice_buttons = [reward_choice_1_button, reward_choice_2_button, reward_choice_3_button]
	speed_buttons = [speed_1x_button, speed_2x_button, speed_4x_button]


func _connect_button_signals() -> void:
	for index in range(tower_slot_buttons.size()):
		tower_slot_buttons[index].pressed.connect(_on_tower_slot_button_pressed.bind(index))
		tower_slot_buttons[index].mouse_entered.connect(_on_tower_slot_mouse_entered.bind(index))
		tower_slot_buttons[index].mouse_exited.connect(_on_tower_slot_mouse_exited)

	for index in range(reward_choice_buttons.size()):
		reward_choice_buttons[index].pressed.connect(_on_reward_choice_button_pressed.bind(index))

	speed_1x_button.pressed.connect(_on_speed_button_pressed.bind(1.0))
	speed_2x_button.pressed.connect(_on_speed_button_pressed.bind(2.0))
	speed_4x_button.pressed.connect(_on_speed_button_pressed.bind(4.0))
	cancel_build_button.pressed.connect(_on_cancel_build_button_pressed)
	start_wave_button.pressed.connect(_on_start_wave_button_pressed)
	upgrade_tower_button.pressed.connect(_on_upgrade_tower_button_pressed)
	sell_tower_button.pressed.connect(_on_sell_tower_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	resume_button.pressed.connect(_on_resume_button_pressed)
	new_game_button.pressed.connect(_on_new_game_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)


func _process(_delta: float) -> void:
	if tower_tooltip.visible:
		_position_tower_tooltip()


func update_from_view_model(view_model: HudViewModel) -> void:
	_update_stats(view_model)
	_update_build_options(view_model)
	_update_speed_controls(view_model.game_speed)
	start_wave_button.disabled = not view_model.can_start_wave


func set_message(message: String) -> void:
	if message.is_empty():
		return

	command_log.append(message)
	message_label.text = "\n".join(command_log)
	_scroll_command_log_to_bottom.call_deferred()


func clear_message_log() -> void:
	command_log.clear()
	message_label.text = ""
	message_scroll.scroll_vertical = 0


func set_build_mode(is_building: bool) -> void:
	cancel_build_button.modulate.a = 1.0 if is_building else 0.0
	cancel_build_button.disabled = not is_building
	cancel_build_button.mouse_filter = Control.MOUSE_FILTER_STOP if is_building else Control.MOUSE_FILTER_IGNORE
	if is_building:
		for button in tower_slot_buttons:
			button.disabled = true


func _update_stats(view_model: HudViewModel) -> void:
	wave_value.text = str(view_model.wave)
	lives_value.text = str(view_model.lives)
	gold_value.text = str(view_model.gold)
	xp_value.text = "%d/%d" % [view_model.xp, view_model.xp_to_next]
	score_value.text = str(view_model.score)
	towers_value.text = str(view_model.tower_count)
	incoming_value.text = str(view_model.incoming)


func _update_build_options(view_model: HudViewModel) -> void:
	tower_slot_ids.clear()
	tower_slot_tooltips.clear()
	for slot_index in range(tower_slot_buttons.size()):
		var button := tower_slot_buttons[slot_index]
		if slot_index >= view_model.owned_tower_ids.size():
			tower_slot_ids.append("")
			tower_slot_tooltips.append(TooltipData.new("Locked Tower Slot", "Choose tower unlock rewards to add more build options."))
			button.text = "Locked Tower Slot"
			button.tooltip_text = ""
			button.disabled = true
			continue

		var tower_id := view_model.owned_tower_ids[slot_index]
		var tower_definition := GameBalance.get_tower_definition(tower_id)
		tower_slot_ids.append(tower_id)
		tower_slot_tooltips.append(_get_build_slot_tooltip(tower_definition))
		button.text = "%s (%d)" % [tower_definition.short_name, tower_definition.cost]
		button.tooltip_text = ""
		button.disabled = view_model.is_building or not view_model.can_build or view_model.gold < tower_definition.cost
		button.modulate.a = 1.0 if tower_id == view_model.active_tower_id else 0.88


func _update_speed_controls(game_speed: float) -> void:
	for button in speed_buttons:
		var button_speed := float(button.get_meta("speed", 1.0))
		button.button_pressed = is_equal_approx(button_speed, game_speed)
		button.modulate.a = 1.0 if button.button_pressed else 0.72


func update_selected_tower(tower: Tower, gold: int) -> void:
	if tower == null or not is_instance_valid(tower):
		selected_tower_label.text = "No tower selected"
		tower_stats_label.text = "Click a placed tower to inspect it."
		upgrade_tower_button.text = "Upgrade Tower"
		upgrade_tower_button.disabled = true
		sell_tower_button.text = "Sell Tower"
		sell_tower_button.disabled = true
		return

	selected_tower_label.text = tower.get_display_name()
	tower_stats_label.text = "Damage %.1f  Range %.1f\n%s" % [tower.damage, tower.attack_range, tower.get_upgrade_summary()]
	upgrade_tower_button.text = tower.get_upgrade_summary()
	upgrade_tower_button.disabled = not tower.can_upgrade() or gold < tower.get_upgrade_cost()
	sell_tower_button.text = "Sell: %d gold" % tower.get_sell_value()
	sell_tower_button.disabled = false


func show_main_menu(title: String, can_resume: bool) -> void:
	menu_title.text = title
	menu_overlay.visible = true
	resume_button.disabled = not can_resume
	restart_button.disabled = not can_resume


func hide_menu() -> void:
	menu_overlay.visible = false


func show_reward_choices(choices: Array[RewardDefinition]) -> void:
	reward_overlay.visible = true
	reward_title.text = "Choose a Reward"
	for index in range(reward_choice_buttons.size()):
		var button := reward_choice_buttons[index]
		if index >= choices.size():
			button.text = "No Reward"
			button.disabled = true
			continue

		var reward := choices[index]
		button.text = "%s\n%s" % [reward.title, reward.description]
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
	if tower_tooltip_source == "world" or tower_tooltip_source == "placement":
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
	show_tower_tooltip(tooltip.title, tooltip.body, "ui")


func _on_tower_slot_mouse_exited() -> void:
	if tower_tooltip_source == "ui":
		hide_tower_tooltip()


func _on_cancel_build_button_pressed() -> void:
	cancel_build_requested.emit()


func _on_start_wave_button_pressed() -> void:
	start_wave_requested.emit()


func _on_upgrade_tower_button_pressed() -> void:
	upgrade_tower_requested.emit()


func _on_sell_tower_button_pressed() -> void:
	sell_tower_requested.emit()


func _on_reward_choice_button_pressed(choice_index: int) -> void:
	reward_choice_selected.emit(choice_index)


func _on_speed_button_pressed(speed: float) -> void:
	game_speed_requested.emit(speed)


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
		panel.add_theme_stylebox_override("panel", UiTheme.panel_style())

	for button in [cancel_build_button, start_wave_button, upgrade_tower_button, sell_tower_button, menu_button, resume_button, new_game_button, restart_button, quit_button]:
		_style_button(button)

	for button in tower_slot_buttons:
		_style_button(button)

	for button in reward_choice_buttons:
		_style_button(button)

	for index in range(speed_buttons.size()):
		var button := speed_buttons[index]
		button.toggle_mode = true
		button.set_meta("speed", [1.0, 2.0, 4.0][index])
		_style_button(button)

	title_label.add_theme_color_override("font_color", UiTheme.TEXT_COLOR)
	title_label.add_theme_font_size_override("font_size", 20)
	build_title.add_theme_color_override("font_color", UiTheme.TEXT_COLOR)
	build_title.add_theme_font_size_override("font_size", 18)
	upgrade_title.add_theme_color_override("font_color", UiTheme.TEXT_COLOR)
	upgrade_title.add_theme_font_size_override("font_size", 18)
	selected_tower_label.add_theme_color_override("font_color", UiTheme.TEXT_COLOR)
	tower_stats_label.add_theme_color_override("font_color", UiTheme.MUTED_TEXT_COLOR)
	message_title.add_theme_color_override("font_color", UiTheme.TEXT_COLOR)
	message_title.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", UiTheme.TEXT_COLOR)
	message_label.add_theme_font_size_override("font_size", 15)
	menu_title.add_theme_color_override("font_color", UiTheme.TEXT_COLOR)
	menu_title.add_theme_font_size_override("font_size", 24)
	reward_title.add_theme_color_override("font_color", UiTheme.TEXT_COLOR)
	reward_title.add_theme_font_size_override("font_size", 24)
	tower_tooltip_title.add_theme_color_override("font_color", UiTheme.VALUE_TEXT_COLOR)
	tower_tooltip_title.add_theme_font_size_override("font_size", 17)
	tower_tooltip_body.add_theme_color_override("font_color", UiTheme.TEXT_COLOR)
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
				label.add_theme_color_override("font_color", UiTheme.VALUE_TEXT_COLOR)
				label.add_theme_font_size_override("font_size", 20)
			else:
				label.add_theme_color_override("font_color", UiTheme.MUTED_TEXT_COLOR)
				label.add_theme_font_size_override("font_size", 12)


func _style_button(button: Button) -> void:
	button.add_theme_stylebox_override("normal", UiTheme.button_style(UiTheme.BUTTON_COLOR))
	button.add_theme_stylebox_override("hover", UiTheme.button_style(UiTheme.BUTTON_HOVER_COLOR))
	button.add_theme_stylebox_override("pressed", UiTheme.button_style(UiTheme.BUTTON_HOVER_COLOR.darkened(0.12)))
	button.add_theme_stylebox_override("disabled", UiTheme.button_style(UiTheme.BUTTON_DISABLED_COLOR))
	button.add_theme_color_override("font_color", UiTheme.TEXT_COLOR)
	button.add_theme_color_override("font_disabled_color", UiTheme.MUTED_TEXT_COLOR)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT


func _get_build_slot_tooltip(tower_definition: TowerDefinition) -> TooltipData:
	return TooltipData.new(tower_definition.display_name, tower_definition.get_build_tooltip_body())


func _position_tower_tooltip() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var tooltip_size := tower_tooltip.size
	if tooltip_size == Vector2.ZERO:
		tooltip_size = tower_tooltip.custom_minimum_size

	var target_position := get_viewport().get_mouse_position() + TOOLTIP_OFFSET
	target_position.x = minf(target_position.x, viewport_size.x - tooltip_size.x - 12.0)
	target_position.y = minf(target_position.y, viewport_size.y - tooltip_size.y - 12.0)
	tower_tooltip.position = target_position.max(Vector2(12.0, 12.0))


func _scroll_command_log_to_bottom() -> void:
	var vertical_bar := message_scroll.get_v_scroll_bar()
	if vertical_bar == null:
		return

	message_scroll.scroll_vertical = int(vertical_bar.max_value)

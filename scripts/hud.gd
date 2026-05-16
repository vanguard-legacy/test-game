extends CanvasLayer
class_name PrototypeHud

signal build_tower_requested
signal cancel_build_requested
signal start_wave_requested
signal upgrade_tower_requested
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


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_styles()
	build_tower_button.pressed.connect(_on_build_tower_button_pressed)
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


func update_stats(wave: int, lives: int, score: int, gold: int, incoming: int, tower_count: int) -> void:
	wave_value.text = str(wave)
	lives_value.text = str(lives)
	gold_value.text = str(gold)
	score_value.text = str(score)
	towers_value.text = str(tower_count)
	incoming_value.text = str(incoming)


func set_message(message: String) -> void:
	message_label.text = message


func set_build_mode(is_building: bool) -> void:
	cancel_build_button.modulate.a = 1.0 if is_building else 0.0
	cancel_build_button.disabled = not is_building
	cancel_build_button.mouse_filter = Control.MOUSE_FILTER_STOP if is_building else Control.MOUSE_FILTER_IGNORE
	build_tower_button.disabled = is_building


func set_build_enabled(is_enabled: bool) -> void:
	if build_tower_button.disabled and not cancel_build_button.disabled:
		return

	build_tower_button.disabled = not is_enabled


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
	tower_stats_label.text = "Damage %.1f  Range %.1f\n%s" % [tower.damage, tower.range, tower.get_upgrade_summary()]
	upgrade_tower_button.text = tower.get_upgrade_summary()
	upgrade_tower_button.disabled = not tower.can_upgrade() or gold < tower.get_upgrade_cost()


func show_main_menu(title: String, can_resume: bool) -> void:
	menu_title.text = title
	menu_overlay.visible = true
	resume_button.disabled = not can_resume
	restart_button.disabled = not can_resume


func hide_menu() -> void:
	menu_overlay.visible = false


func _on_build_tower_button_pressed() -> void:
	build_tower_requested.emit()


func _on_cancel_build_button_pressed() -> void:
	cancel_build_requested.emit()


func _on_start_wave_button_pressed() -> void:
	start_wave_requested.emit()


func _on_upgrade_tower_button_pressed() -> void:
	upgrade_tower_requested.emit()


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
	for panel in [top_bar, build_panel, upgrade_panel, message_panel, menu_panel]:
		panel.add_theme_stylebox_override("panel", PrototypeUiTheme.panel_style())

	for button in [build_tower_button, cancel_build_button, start_wave_button, upgrade_tower_button, menu_button, resume_button, new_game_button, restart_button, quit_button]:
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
	_style_stat_labels()


func _style_stat_labels() -> void:
	var stat_nodes: Array[Node] = [
		wave_value.get_parent(),
		lives_value.get_parent(),
		gold_value.get_parent(),
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

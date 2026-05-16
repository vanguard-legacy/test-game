extends CanvasLayer
class_name PrototypeHud

signal build_tower_requested
signal cancel_build_requested
signal start_wave_requested

@onready var top_bar: PanelContainer = $Root/Layout/TopBar
@onready var build_panel: PanelContainer = $Root/Layout/BottomRow/BuildPanel
@onready var message_panel: PanelContainer = $Root/Layout/BottomRow/MessagePanel
@onready var title_label: Label = $Root/Layout/TopBar/Margin/StatsRow/Title
@onready var wave_value: Label = $Root/Layout/TopBar/Margin/StatsRow/WaveStat/Value
@onready var lives_value: Label = $Root/Layout/TopBar/Margin/StatsRow/LivesStat/Value
@onready var gold_value: Label = $Root/Layout/TopBar/Margin/StatsRow/GoldStat/Value
@onready var score_value: Label = $Root/Layout/TopBar/Margin/StatsRow/ScoreStat/Value
@onready var towers_value: Label = $Root/Layout/TopBar/Margin/StatsRow/TowersStat/Value
@onready var incoming_value: Label = $Root/Layout/TopBar/Margin/StatsRow/IncomingStat/Value
@onready var build_title: Label = $Root/Layout/BottomRow/BuildPanel/Margin/Stack/BuildTitle
@onready var message_title: Label = $Root/Layout/BottomRow/MessagePanel/Margin/Stack/MessageTitle
@onready var message_label: Label = $Root/Layout/BottomRow/MessagePanel/Margin/Stack/MessageLabel
@onready var build_tower_button: Button = $Root/Layout/BottomRow/BuildPanel/Margin/Stack/BuildTowerButton
@onready var cancel_build_button: Button = $Root/Layout/BottomRow/BuildPanel/Margin/Stack/CancelBuildButton
@onready var start_wave_button: Button = $Root/Layout/BottomRow/BuildPanel/Margin/Stack/StartWaveButton


func _ready() -> void:
	_apply_styles()
	build_tower_button.pressed.connect(_on_build_tower_button_pressed)
	cancel_build_button.pressed.connect(_on_cancel_build_button_pressed)
	start_wave_button.pressed.connect(_on_start_wave_button_pressed)
	set_build_mode(false)


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
	cancel_build_button.visible = is_building
	build_tower_button.disabled = is_building


func set_build_enabled(is_enabled: bool) -> void:
	if build_tower_button.disabled and cancel_build_button.visible:
		return

	build_tower_button.disabled = not is_enabled


func set_start_wave_enabled(is_enabled: bool) -> void:
	start_wave_button.disabled = not is_enabled


func _on_build_tower_button_pressed() -> void:
	build_tower_requested.emit()


func _on_cancel_build_button_pressed() -> void:
	cancel_build_requested.emit()


func _on_start_wave_button_pressed() -> void:
	start_wave_requested.emit()


func _apply_styles() -> void:
	for panel in [top_bar, build_panel, message_panel]:
		panel.add_theme_stylebox_override("panel", PrototypeUiTheme.panel_style())

	for button in [build_tower_button, cancel_build_button, start_wave_button]:
		_style_button(button)

	title_label.add_theme_color_override("font_color", PrototypeUiTheme.TEXT_COLOR)
	title_label.add_theme_font_size_override("font_size", 20)
	build_title.add_theme_color_override("font_color", PrototypeUiTheme.TEXT_COLOR)
	build_title.add_theme_font_size_override("font_size", 18)
	message_title.add_theme_color_override("font_color", PrototypeUiTheme.TEXT_COLOR)
	message_title.add_theme_font_size_override("font_size", 18)
	message_label.add_theme_color_override("font_color", PrototypeUiTheme.TEXT_COLOR)
	message_label.add_theme_font_size_override("font_size", 15)
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

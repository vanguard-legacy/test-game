class_name PrototypeUiTheme
extends RefCounted

const PANEL_COLOR: Color = Color(0.09, 0.12, 0.11, 0.86)
const PANEL_BORDER: Color = Color(0.64, 0.56, 0.36, 0.65)
const BUTTON_COLOR: Color = Color(0.18, 0.25, 0.22, 0.95)
const BUTTON_HOVER_COLOR: Color = Color(0.24, 0.34, 0.29, 0.98)
const BUTTON_DISABLED_COLOR: Color = Color(0.13, 0.14, 0.13, 0.78)
const TEXT_COLOR: Color = Color(0.92, 0.88, 0.76)
const MUTED_TEXT_COLOR: Color = Color(0.66, 0.69, 0.62)
const VALUE_TEXT_COLOR: Color = Color(0.98, 0.92, 0.58)


static func panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = PANEL_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	return style


static func button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = PANEL_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

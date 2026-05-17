class_name PrototypeTooltipData
extends RefCounted

# Small UI text payload for cursor-following tooltips.

var title: String = ""
var body: String = ""


func _init(new_title: String = "", new_body: String = "") -> void:
	title = new_title
	body = new_body

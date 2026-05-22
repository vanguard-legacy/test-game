class_name DefenseHudViewModel
extends RefCounted

# One-frame snapshot for the HUD. Main builds this from gameplay state so HUD
# methods stay small and do not need long parameter lists.

var wave: int = 0
var lives: int = 0
var score: int = 0
var gold: int = 0
var xp: int = 0
var xp_to_next: int = 0
var incoming: int = 0
var tower_count: int = 0
var owned_tower_ids: Array[String] = []
var active_tower_id: String = ""
var can_build: bool = false
var is_building: bool = false
var can_start_wave: bool = false
var game_speed: float = 1.0

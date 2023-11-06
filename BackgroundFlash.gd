extends Node2D
class_name BackgroundFlash

onready var gamelogic = get_node("/root/LevelScene/GameLogic");
var last_delta = 0;

func _process(delta: float) -> void:
	last_delta = delta;
	update();

func _draw():
	if (gamelogic.undo_effect_strength > 0):
		var color = Color(gamelogic.undo_effect_color);
		color.a = gamelogic.undo_effect_strength;
		draw_rect(Rect2(0, 0, gamelogic.pixel_width, gamelogic.pixel_height), color, true);
	gamelogic.undo_effect_strength -= gamelogic.undo_effect_per_second*last_delta;

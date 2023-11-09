extends Sprite
class_name SparkleSprite

# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"
var target = null;
var offset_by = Vector2(0, 0);
var timer = 0.0;
var timer_max = 3.0;
var seconds_per_spiral = 1.0;
var max_radius = 512;
var going_in = true;
var frame_timer = 0.0;
var frame_timer_max = 0.08;

func _ready() -> void:
	position = Vector2(-999, -999);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	frame_timer += delta;
	if (frame_timer > frame_timer_max):
		frame_timer -= frame_timer_max;
		if (frame == hframes - 1):
			frame = 0;
		else:
			frame += 1;
	timer += delta;
	if (timer > timer_max):
		queue_free();
	else:
		var angle = 2*PI*fmod(timer, seconds_per_spiral);
		var magnitude = pow(timer/timer_max, 3);
		if (going_in):
			magnitude = pow((timer_max-timer)/timer_max, 3);
		position = target.position + offset_by + Vector2(max_radius*magnitude, 0).rotated(angle);

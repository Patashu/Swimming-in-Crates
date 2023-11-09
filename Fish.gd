extends Sprite


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"
var gamelogic = null
var timer = 0.0;
var speed_mult = 1.0;
var sin_mult = 1.0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if (gamelogic.rng.randi_range(0, 1) == 1):
		flip_h = true;
	position += Vector2(gamelogic.rng.randf_range(-4, 4), gamelogic.rng.randf_range(-4, 4));
	speed_mult = gamelogic.rng.randf_range(0.8, 1.6);
	sin_mult = gamelogic.rng.randf_range(0.8, 1.6);
	timer += gamelogic.rng.randf_range(0, 16*PI);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta;
	var velocity = Vector2(0, 0);
	if (flip_h):
		velocity = Vector2(speed_mult*(sin(sin_mult*timer)+1)*3*delta, 0);
	else:
		velocity = Vector2(speed_mult*(sin(sin_mult*timer)+1)*3*-delta, 0);
	position += velocity;
	var feeler = velocity;
	feeler.x = sign(feeler.x);
	feeler *= 4;
	var pos = gamelogic.terrainmap.world_to_map(position+feeler);
	if !gamelogic.terrain_in_tile(pos).has(LevelEditor.Tiles.Water):
		flip_h = !flip_h;
		velocity.x = -velocity.x;
		pos += velocity*2;
	offset.y = sin(timer);

extends ActorBase
class_name Actor

var gamelogic = null
var actorname = -1
var stored_position = Vector2.ZERO
var pos = Vector2.ZERO
var broken = false;
# -1 for grounded, 0 for falling, 1+ for turns of coyote time left
var airborne = -1
var strength = 0
var heaviness = 0
var durability = 0
var fall_speed = -1
var climbs = false
var is_character = false
# undo trails logic
var color = Color(1, 1, 1, 1);
# animation system logic
var animation_timer = 0;
var animation_timer_max = 0.05;
var animations = [];
var facing_left = false;
# animated sprites logic
var frame_timer = 0;
var frame_timer_max = 0.1;
var post_mortem = -1;
# ding
var ding = null;
# transient multi-push/multi-fall state:
# basically, things that move become non-colliding until the end of the multi-push/fall tick they're
# a part of, so other things that shared their tile can move with them
var just_moved = false;
# action lines!
var action_lines_timer = 0;
var action_lines_timer_max = 0.25;

# faster than string comparisons
enum Name {
	Dolphin,
	WoodenCrate,
	IronCrate,
	SteelCrate,
	Goal,
}

func update_graphics() -> void:
	var tex = get_next_texture();
	set_next_texture(tex, facing_left);

func get_next_texture() -> Texture:
	if actorname == Name.Dolphin:
		return preload("res://assets/dolphin_idle.png");
	elif actorname == Name.IronCrate:
		return preload("res://assets/iron_crate.png");
	elif actorname == Name.SteelCrate:
		return preload("res://assets/steel_crate.png");
	elif actorname == Name.WoodenCrate:
		return preload("res://assets/wooden_crate.png");
	return null;

func set_next_texture(tex: Texture, facing_left_at_the_time: bool) -> void:
	# facing updates here, even if the texture didn't change
	if facing_left_at_the_time:
		flip_h = true;
	else:
		flip_h = false;
	
	if (self.texture == tex):
		return;
		
	if tex == null:
		visible = false;
	elif self.texture == null:
		visible = true;
		
	self.texture = tex;
	
	frame_timer = 0;
	frame = 0;

# POST 'oh shit I have an infinite' gravity rules (AD07):
# (-1 fall speed is infinite. It's so infinite it breaks glass and keeps going!)
# If fall speed is 0, airborne rules are ignored (WIP).
# If fall speed is 1, state becomes airborne 2 when it jumps, 1 when it stops being airborne for any other reasn.
# If fall speed is 2 or higher, state becomes airborne 2 when it jumps, and airborne 0 when it stops being over ground
# for any other reason.
# If fall speed is 1, actor may move sideways at airborne 1 or 0 freely,
# but not upwards unless grounded.
# If fallspeed is 2 or higher, actor may move sideways at airborne 1 and in no direction at airborne 0.
# (A forbidden direction is a null move and passes time.)
func fall_speed() -> int:
	if broken:
		return 99;
	return fall_speed;
	
# because I want Light to float but not cuckoo clocks <w<
func floats() -> bool:
	return fall_speed() == 1 and is_character;
	
func climbs() -> bool:
	return climbs and !broken;

func pushable() -> bool:
	if (just_moved):
		return false;
	if (broken):
		return is_character;
	return true;
		
func phases_into_terrain() -> bool:
	return false;
	
func phases_into_actors() -> bool:
	return false;

func _process(delta: float) -> void:
	#action lines
	if (is_character and airborne != -1):
		action_lines_timer += delta;
		if (action_lines_timer > action_lines_timer_max):
			action_lines_timer -= action_lines_timer_max;
			var sprite = Sprite.new();
			sprite.set_script(preload("res://GoalParticle.gd"));
			sprite.texture = preload("res://assets/action_line.png");
			sprite.position = self.position;
			sprite.position.x += gamelogic.rng.randf_range(0, gamelogic.cell_size);
			sprite.position.y += gamelogic.rng.randf_range(0, gamelogic.cell_size/2);
			if (airborne == 0):
				sprite.velocity = Vector2(0, -16);
			else:
				sprite.velocity = Vector2(0, 16);
				sprite.position.y += gamelogic.cell_size/2;
			sprite.centered = true;
			sprite.rotate_magnitude = 0;
			sprite.alpha_max = 1;
			sprite.modulate = self.modulate;
			sprite.modulate.a = 0;
			sprite.fadeout_timer_max = 0.75;
			gamelogic.overactorsparticles.add_child(sprite);
	
	#animated sprites
	if hframes <= 1:
		pass
	else:
		frame_timer += delta;
		if (frame_timer > frame_timer_max):
			frame_timer -= frame_timer_max;
			if broken and frame >= 4 and post_mortem != 1:
				pass
			elif frame < (hframes * vframes) - 1:
				frame += 1;
	
	# animation system stuff
	if (animations.size() > 0):
		var current_animation = animations[0];
		var is_done = true;
		if (current_animation[0] == 0): #move
			animation_timer_max = 0.083;
			position -= current_animation[1]*(animation_timer/animation_timer_max)*16;
			animation_timer += delta;
			if (animation_timer > animation_timer_max):
				position += current_animation[1]*1*16;
				# no rounding errors here! get rounded sucker!
				position.x = round(position.x); position.y = round(position.y);
			else:
				is_done = false;
				position += current_animation[1]*(animation_timer/animation_timer_max)*16;
		elif (current_animation[0] == 1): #bump
			animation_timer_max = 0.1;
			var bump_amount = (animation_timer/animation_timer_max);
			if (bump_amount > 0.5):
				bump_amount = 1-bump_amount;
			bump_amount *= 0.2;
			position -= current_animation[1]*bump_amount*16;
			animation_timer += delta;
			if (animation_timer > animation_timer_max):
				position.x = round(position.x); position.y = round(position.y);
			else:
				is_done = false;
				bump_amount = (animation_timer/animation_timer_max);
				if (bump_amount > 0.5):
					bump_amount = 1-bump_amount;
				bump_amount *= 0.2;
				position += current_animation[1]*bump_amount*16;
		elif (current_animation[0] == 2): #set_next_texture
			set_next_texture(current_animation[1], current_animation[2]);
		elif (current_animation[0] == 3): #sfx
			gamelogic.play_sound(current_animation[1]);
		elif (current_animation[0] == 4): #fade
			animation_timer_max = 3;
			animation_timer += delta;
			if (animation_timer > animation_timer_max):
				self.modulate.a = 0;
			else:
				is_done = false;
				self.modulate.a = 1-(animation_timer/animation_timer_max);
		if (is_done):
			animations.pop_front();
			animation_timer = 0;
		

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
var buoyancy = 0
var can_swap = false
var climbs = false
var is_character = false
var has_gem = false
var gem = null;
var pressing = false;
var open = false;
var open_animate = false;
var dolphin_sprite = null;
# undo trails logic
var color = Color(1, 1, 1, 1);
# animation system logic
var animation_timer = 0;
var animation_timer_max = 0.05;
var animations = [];
# dolphin nonsense
var facing_left = false;
var facing_vertical = Vector2.ZERO;
var in_move = false;
var dolphin_flip_transition_table = [-1, -1, -1, -1];
var dolphin_flip_frame_max = -1;
var flip_h_will_be = false;
var rotation_degrees_will_be = 0;
var bob_timer = 0;
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
	Hatch,
	CrateFloat,
	CrateFloatNoPush,
	CrateFloatNoSwap,
	CrateFloatNothing,
	CrateNeutral,
	CrateNeutralNoPush,
	CrateNeutralNoSwap,
	CrateNeutralNothing,
	CrateSink,
	CrateSinkNoPush,
	CrateSinkNoSwap,
	CrateSinkNothing,
}

func update_graphics() -> void:
	var tex = get_next_texture();
	dolphin_flip_transition_table = [-1, -1, -1, -1];
	set_next_texture(tex, facing_left, facing_vertical, gem_status());
	open_animate = open;

func get_next_texture() -> Resource:
	if actorname == Name.Dolphin:
		frame_timer_max = 0.3;
		return null;
	elif actorname == Name.Hatch:
		hframes = 7;
		return preload("res://assets/hatch_spritesheet.png");
	elif texture != null:
		return texture;
	else:
		return load("res://assets/" + Name.keys()[actorname].to_lower() + ".png");
	return null;

func gem_status() -> Texture:
	if !is_instance_valid(gem):
		return null;
	elif pressing:
		return preload("res://assets/gem_active.png");
	else:
		return preload("res://assets/gem.png");

func set_next_texture(tex: Texture, facing_left_at_the_time: bool, facing_vertical_at_the_time: Vector2, gem_tex: Texture) -> void:
	if is_instance_valid(gem) and gem_tex != null:
		gem.texture = gem_tex;
	
	# facing updates here, even if the texture didn't change
	if (is_character):
#		var old_facing_left = dolphin_sprite.flip_h;
#		var old_facing_vertical = Vector2.ZERO;
#		if (dolphin_sprite.rotation_degrees == -90 and old_facing_left):
#			old_facing_vertical = Vector2.DOWN;
#		elif (dolphin_sprite.rotation_degrees == -90 and !old_facing_left):
#			old_facing_vertical = Vector2.UP;
#		if (dolphin_sprite.rotation_degrees == 90 and !old_facing_left):
#			old_facing_vertical = Vector2.DOWN;
#		elif (dolphin_sprite.rotation_degrees == 90 and old_facing_left):
#			old_facing_vertical = Vector2.UP;
		
		var dolphin_flip_frame_max_old = dolphin_flip_frame_max;
		
		if facing_left_at_the_time:
			flip_h_will_be = true;
		else:
			flip_h_will_be = false;

		if (facing_vertical_at_the_time.y == 0):
			rotation_degrees_will_be = 0;
			if (facing_left_at_the_time):
				#l, d, r, u
				dolphin_flip_frame_max = dolphin_flip_transition_table[0];
				dolphin_flip_transition_table = [0, 1, -1, 3];
			else:
				#l, d, r, u
				dolphin_flip_frame_max = dolphin_flip_transition_table[2];
				dolphin_flip_transition_table = [-1, 1, 0, 3];
		elif (facing_vertical_at_the_time.y > 0): #down
			if (facing_left_at_the_time):
				rotation_degrees_will_be = -90;
				#l, d, r, u
				dolphin_flip_frame_max = dolphin_flip_transition_table[1];
				dolphin_flip_transition_table = [3, 0, 2, 2];
			else:
				rotation_degrees_will_be = 90;
				#l, d, r, u
				dolphin_flip_frame_max = dolphin_flip_transition_table[1];
				dolphin_flip_transition_table = [2, 0, 3, 2];
		else: #(facing_vertical_at_the_time.y < 0): #up
			if (facing_left_at_the_time):
				rotation_degrees_will_be = 90;
				#l, d, r, u
				dolphin_flip_frame_max = dolphin_flip_transition_table[3];
				dolphin_flip_transition_table = [2, 2, 3, 0];
			else:
				rotation_degrees_will_be = -90;
				#l, d, r, u
				dolphin_flip_frame_max = dolphin_flip_transition_table[3];
				dolphin_flip_transition_table = [3, 2, 2, 0];
		
		if dolphin_flip_frame_max == -1:
			dolphin_sprite.texture = preload("res://assets/dolphin_animation.png");
			dolphin_sprite.hframes = 12;
			dolphin_sprite.flip_h = flip_h_will_be;
			dolphin_sprite.rotation_degrees = rotation_degrees_will_be;
		elif dolphin_flip_frame_max >= 1:
			dolphin_sprite.texture = preload("res://assets/dolphin_flip.png");
			dolphin_sprite.hframes = 3;
			dolphin_sprite.frame = 0;
			frame_timer = 0;
			frame_timer_max = 0.08;
		else:
			dolphin_flip_frame_max = dolphin_flip_frame_max_old;
	
	if (self.texture == tex):
		return;
		
	if tex == null:
		visible = false;
	elif self.texture == null:
		visible = true;
		
	self.texture = tex;
	
	frame_timer = 0;
	frame = 0;

func gain_gem() -> void:
	has_gem = true;
	gem = Sprite.new();
	gem.texture = preload("res://assets/gem.png");
	gem.centered = false;
	self.add_child(gem);

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
	
# no one floats atm
func floats() -> bool:
	return false;
	#return fall_speed() == 1 and is_character;
	
func climbs() -> bool:
	return climbs and !broken;

func pushable() -> bool:
	if (just_moved):
		return false;
	if (broken):
		return is_character;
	if (open):
		return false;
	return true;
		
func phases_into_terrain() -> bool:
	return false;
	
func phases_into_actors() -> bool:
	return false;

var delays = [0.2, 0.3, 0.4, 0.3, 0.2, 0.15, 0.2, 0.4, 0.3, 0.25, 0.2, 0.15]

func _process(delta: float) -> void:
	if (is_character):
		bob_timer += delta;
		dolphin_sprite.position.y = 8 + sin(bob_timer);
	
	#action lines
	if (airborne != -1):
		var fall = gamelogic.falling_direction(self);
		if (fall != Vector2.ZERO):
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
					sprite.velocity = Vector2(0, -16*fall.y);
				else:
					sprite.velocity = Vector2(0, 16*fall.y);
				if (sprite.velocity.y > 0):
					sprite.position.y += gamelogic.cell_size/2;
				sprite.centered = true;
				sprite.rotate_magnitude = 0;
				sprite.alpha_max = 1;
				sprite.modulate = self.modulate;
				sprite.modulate.a = 0;
				sprite.fadeout_timer_max = 0.75;
				gamelogic.overactorsparticles.add_child(sprite);
	
	#animated sprites
	if actorname == Name.Dolphin:
		if (dolphin_flip_frame_max > 0):
			frame_timer += delta;
			if (frame_timer > frame_timer_max):
				frame_timer -= frame_timer_max;
				if (dolphin_sprite.frame + 1 >= dolphin_flip_frame_max):
					dolphin_flip_frame_max = -1;
					dolphin_sprite.texture = preload("res://assets/dolphin_animation.png");
					dolphin_sprite.hframes = 12;
					dolphin_sprite.flip_h = flip_h_will_be;
					dolphin_sprite.rotation_degrees = rotation_degrees_will_be;
				else:
					dolphin_sprite.frame += 1;
		else:
			if (in_move):
				frame_timer_max = 0.05;
			else:
				frame_timer_max = delays[dolphin_sprite.frame];
	#		elif dolphin_sprite.frame == 2 or dolphin_sprite.frame == 7:
	#			frame_timer_max = 1.0;
	#		else:
	#			frame_timer_max = 0.3;
			frame_timer += delta;
			if (frame_timer > frame_timer_max):
				frame_timer -= frame_timer_max;
				if (dolphin_sprite.frame == dolphin_sprite.hframes -1):
					dolphin_sprite.frame = 0;
				else:
					if broken and dolphin_sprite.frame >= 4 and post_mortem != 1:
						pass
					elif dolphin_sprite.frame < (dolphin_sprite.hframes * dolphin_sprite.vframes) - 1:
						dolphin_sprite.frame += 1;
	elif hframes <= 1:
		pass
	elif actorname == Name.Hatch:
		frame_timer += delta;
		if (frame_timer > frame_timer_max):
			frame_timer -= frame_timer_max;
			var impulse = -1;
			if (open_animate):
				impulse = 1;
				
			if (impulse == 1 and frame < (hframes * vframes) - 1):
				frame += 1;
			elif (impulse == -1 and frame > 0):
				frame -= 1;
	else:
		frame_timer += delta;
		if (frame_timer > frame_timer_max):
			frame_timer -= frame_timer_max;
			if (frame == hframes - 1):
				frame = 0;
			else:
				if broken and frame >= 4 and post_mortem != 1:
					pass
				elif frame < (hframes * vframes) - 1:
					frame += 1;
	
	# animation system stuff
	in_move = false;
	if (animations.size() > 0 and gamelogic.player.dolphin_flip_frame_max == -1):
		var current_animation = animations[0];
		var is_done = true;
		if (current_animation[0] == 0): #move
			in_move = true;
			animation_timer_max = 0.13; #0.083;
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
			in_move = true;
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
			set_next_texture(current_animation[1], current_animation[2], current_animation[3], current_animation[4]);
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
		elif (current_animation[0] == 5): #open
			open_animate = current_animation[1];
		elif (current_animation[0] == 6): #swap
			var dir = current_animation[1];
			gamelogic.play_sound("swap");
			var overactorsparticles = self.get_parent().get_parent().get_node("OverActorsParticles");
			for i in range(2):
				var sprite = Sprite.new();
				sprite.set_script(preload("res://OneTimeSprite.gd"));
				sprite.texture = preload("res://assets/swap_overlay.png")
				sprite.position = self.position + current_animation[1]*i*gamelogic.cell_size;
				sprite.centered = false;
				sprite.hframes = 5;
				sprite.frame_max = 5;
				overactorsparticles.add_child(sprite);
		if (is_done):
			animations.pop_front();
			animation_timer = 0;
		

extends Node
class_name GameLogic

var debug_prints = false;

onready var levelscene : Node2D = get_node("/root/LevelScene");
onready var underterrainfolder : Node2D = levelscene.get_node("UnderTerrainFolder");
onready var actorsfolder : Node2D = levelscene.get_node("ActorsFolder");
onready var levelfolder : Node2D = levelscene.get_node("LevelFolder");
onready var terrainmap : TileMap = levelfolder.get_node("TerrainMap");
onready var overactorsparticles : Node2D = levelscene.get_node("OverActorsParticles");
onready var underactorsparticles : Node2D = levelscene.get_node("UnderActorsParticles");
onready var menubutton : Button = levelscene.get_node("MenuButton");
onready var levellabel : Label = levelscene.get_node("LevelLabel");
onready var levelstar : Sprite = levelscene.get_node("LevelStar");
onready var winlabel : Node2D = levelscene.get_node("WinLabel");
onready var metainfolabel : Label = levelscene.get_node("MetaInfoLabel");
onready var tutoriallabel : RichTextLabel = levelscene.get_node("TutorialLabel");
onready var targeter : Sprite = levelscene.get_node("Targeter")
onready var downarrow : Sprite = levelscene.get_node("DownArrow");
onready var leftarrow : Sprite = levelscene.get_node("LeftArrow");
onready var rightarrow : Sprite = levelscene.get_node("RightArrow");
onready var Shade : Node2D = levelscene.get_node("Shade");
onready var checkerboard : TextureRect = levelscene.get_node("Checkerboard");
onready var rng : RandomNumberGenerator = RandomNumberGenerator.new();
onready var virtualbuttons : Node2D = levelscene.get_node("VirtualButtons");
onready var replaybuttons : Node2D = levelscene.get_node("ReplayButtons");
onready var replayturnlabel : Label = levelscene.get_node("ReplayButtons/ReplayTurn/ReplayTurnLabel");
onready var replayturnslider : HSlider = levelscene.get_node("ReplayButtons/ReplayTurn/ReplayTurnSlider");
onready var replayspeedlabel : Label = levelscene.get_node("ReplayButtons/ReplaySpeed/ReplaySpeedLabel");
onready var replayspeedslider : HSlider = levelscene.get_node("ReplayButtons/ReplaySpeed/ReplaySpeedSlider");
var replayturnsliderset = false;
var replayspeedsliderset = false;

# distinguish between temporal layers when a move or state change happens
# ghosts is for undo trail ghosts
enum Chrono {
	MOVE
	UNDO
	TIMELESS
}

# distinguish between different strengths of movement. Gravity is also special in that it won't try to make
# 'voluntary' movements like going past thin platforms.
enum Strength {
	NONE
	CRYSTAL
	WOODEN
	LIGHT
	HEAVY
	GRAVITY
}

# distinguish between different heaviness. Light is IRON and Heavy is STEEL.
enum Heaviness {
	NONE
	CRYSTAL
	WOODEN
	IRON
	STEEL
	SUPERHEAVY
	INFINITE
}

# distinguish between levels of durability by listing the first thing that will destroy you.
enum Durability {
	SPIKES
	FIRE
	PITS
	NOTHING
}

# yes means 'do the thing you intended'. no means 'cancel it and this won't cause time to pass'.
# surprise means 'cancel it but there was a side effect so time passes'.
enum Success {
	Yes,
	No,
	Surprise,
}

# types of undo events

enum Undo {
	move, #0
	set_actor_var, #1
	animation_substep, #2
}

# and same for animations
enum Animation {
	move, #0
	bump, #1
	set_next_texture, #2
	sfx, #3
	fade, #4
	press, #5
	unpress, #6
}

# attempted performance optimization - have an enum of all tile ids and assert at startup that they're right
# order SEEMS to be the same as in DefaultTiles
# keep in sync with LevelEditor
enum Tiles {
	Wall,
	Dolphin,
	Goal,
	Gem,
	Switch,
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
	Water,
}

# information about the level
var is_custom = false;
var test_mode = false;
var custom_string = "";
var chapter = 0;
var level_in_chapter = 0;
var level_is_extra = false;
var in_insight_level = false;
var has_insight_level = false;
var insight_level_scene = null;
var level_number = 0
var level_name = "Blah Blah Blah";
var level_replay = "";
var level_author = "";
var heavy_max_moves = -1;
var light_max_moves = -1;
var clock_turns : String = "";
var map_x_max : int = 0;
var map_y_max : int = 0;
var map_x_max_max : int = 31; # can change these if I want to adjust hori/vertical scrolling
var map_y_max_max : int = 15;
var terrain_layers = []

# information about the actors and their state
var player : Actor = null
var actors = []
var goals = []
var turn = 0;
var undo_buffer = [];

# save file, ooo!
var save_file = {}
var puzzles_completed = 0;

# song-and-dance state
var sounds = {}
var music_tracks = [];
var music_info = [];
var now_playing = null;
var speakers = [];
var target_track = -1;
var current_track = -1;
var fadeout_timer = 0;
var fadeout_timer_max = 0;
var fanfare_duck_db = 0;
var music_discount = -10;
var music_speaker = null;
var lost_speaker = null;
var lost_speaker_volume_tween;
var won_speaker = null;
var sounds_played_this_frame = {};
var muted = false;
var won = false;
var won_cooldown = 0;
var lost = false;
var won_fade_started = false;
var cell_size = 16;
var undo_effect_strength = 0;
var undo_effect_per_second = 0;
var undo_effect_color = Color("#E6E6EC");
var arbitrary_color = Color("#E6E6EC");
var ui_stack = [];
var ready_done = false;
var using_controller = false;

#UI defaults
var win_label_default_y = 113;
var pixel_width = ProjectSettings.get("display/window/size/width"); #512
var pixel_height = ProjectSettings.get("display/window/size/height"); #300

# animation server
var animation_server = []
var animation_substep = 0;

#replay system
var replay_timer = 0;
var user_replay = "";
var user_replay_before_restarts = [];
var doing_replay = false;
var replay_paused = false;
var replay_turn = 0;
var replay_interval = 0.5;
var next_replay = -1;
var unit_test_mode = false;
var meta_undo_a_restart_mode = false;

# list of levels in the game
var level_list = [];
var level_filenames = [];
var level_names = [];
var has_remix = {};
var chapter_names = [];
var chapter_skies = [];
var chapter_tracks = [];
var chapter_replacements = {};
var level_replacements = {};
var target_sky = Color("#0E0E12");
var old_sky = Color("#0E0E12");
var current_sky = Color("#0E0E12");
var sky_timer = 0;
var sky_timer_max = 0;
var chapter_standard_starting_levels = [];
var chapter_advanced_starting_levels = [];
var chapter_standard_unlock_requirements = [];
var chapter_advanced_unlock_requirements = [];
var save_file_string = "user://swimmingincrates0.sav";

func save_game():
	var file = File.new()
	file.open(save_file_string, File.WRITE)
	file.store_line(to_json(save_file))
	file.close()

func default_save_file() -> void:
	if (save_file == null or typeof(save_file) != TYPE_DICTIONARY):
		save_file = {};
	if (!save_file.has("level_number")):
		save_file["level_number"] = 0
	if (!save_file.has("levels")):
		save_file["levels"] = {}
	if (!save_file.has("version")):
		save_file["version"] = 0
	if (!save_file.has("music_volume")):
		save_file["music_volume"] = 0.0
	if (!save_file.has("sfx_volume")):
		save_file["sfx_volume"] = 0.0
	if (!save_file.has("fanfare_volume")):
		save_file["fanfare_volume"] = 0.0

func load_game():
	var file = File.new()
	if not file.file_exists(save_file_string):
		return default_save_file();
		
	file.open(save_file_string, File.READ)
	var json_parse_result = JSON.parse(file.get_as_text())
	file.close();
	
	if json_parse_result.error == OK:
		var data = json_parse_result.result;
		if typeof(data) == TYPE_DICTIONARY:
			save_file = data;
		else:
			return default_save_file();
	else:
		return default_save_file();
	
	default_save_file();
	
	react_to_save_file_update();

func _ready() -> void:
	# Call once when the game is booted up.
	menubutton.connect("pressed", self, "escape");
	levelstar.scale = Vector2(1.0/6.0, 1.0/6.0);
	winlabel.call_deferred("change_text", "You have won!\n\n[Enter]: Watch Replay\nMade by Patashu (Everything but Art) and Teal Knight (Art)");
	connect_virtual_buttons();
	prepare_audio();
	call_deferred("adjust_winlabel");
	load_game();
	initialize_level_list();
	tile_changes();
	initialize_shaders();
	if (OS.is_debug_build()):
		assert_tile_enum();
	
	# Load the first map.
	load_level(0);
	ready_done = true;

func connect_virtual_buttons() -> void:
	virtualbuttons.get_node("Verbs/UndoButton").connect("button_down", self, "_undobutton_pressed");
	virtualbuttons.get_node("Verbs/UndoButton").connect("button_up", self, "_undobutton_released");
	virtualbuttons.get_node("Dirs/LeftButton").connect("button_down", self, "_leftbutton_pressed");
	virtualbuttons.get_node("Dirs/LeftButton").connect("button_up", self, "_leftbutton_released");
	virtualbuttons.get_node("Dirs/DownButton").connect("button_down", self, "_downbutton_pressed");
	virtualbuttons.get_node("Dirs/DownButton").connect("button_up", self, "_downbutton_released");
	virtualbuttons.get_node("Dirs/RightButton").connect("button_down", self, "_rightbutton_pressed");
	virtualbuttons.get_node("Dirs/RightButton").connect("button_up", self, "_rightbutton_released");
	virtualbuttons.get_node("Dirs/UpButton").connect("button_down", self, "_upbutton_pressed");
	virtualbuttons.get_node("Dirs/UpButton").connect("button_up", self, "_upbutton_released");
	virtualbuttons.get_node("Others/EnterButton").connect("button_down", self, "_enterbutton_pressed");
	virtualbuttons.get_node("Others/EnterButton").connect("button_up", self, "_enterbutton_released");
	replaybuttons.get_node("ReplaySpeed/F9Button").connect("button_down", self, "_f9button_pressed");
	replaybuttons.get_node("ReplaySpeed/F9Button").connect("button_up", self, "_f9button_released");
	replaybuttons.get_node("ReplaySpeed/F10Button").connect("button_down", self, "_f10button_pressed");
	replaybuttons.get_node("ReplaySpeed/F10Button").connect("button_up", self, "_f10button_released");
	replaybuttons.get_node("ReplayTurn/PrevTurnButton").connect("button_down", self, "_prevturnbutton_pressed");
	replaybuttons.get_node("ReplayTurn/PrevTurnButton").connect("button_up", self, "_prevturnbutton_released");
	replaybuttons.get_node("ReplayTurn/NextTurnButton").connect("button_down", self, "_nextturnbutton_pressed");
	replaybuttons.get_node("ReplayTurn/NextTurnButton").connect("button_up", self, "_nextturnbutton_released");
	replaybuttons.get_node("ReplayTurn/PauseButton").connect("button_down", self, "_pausebutton_pressed");
	replaybuttons.get_node("ReplayTurn/PauseButton").connect("button_up", self, "_pausebutton_released");
	replaybuttons.get_node("ReplayTurn/ReplayTurnSlider").connect("value_changed", self, "_replayturnslider_value_changed");
	replaybuttons.get_node("ReplaySpeed/ReplaySpeedSlider").connect("value_changed", self, "_replayspeedslider_value_changed");
	
func virtual_button_pressed(action: String) -> void:
	if (ui_stack.size() > 0 and ui_stack[ui_stack.size() - 1] != self):
		return;
	Input.action_press(action);
	menubutton.grab_focus();
	menubutton.release_focus();
	
func virtual_button_released(action: String) -> void:
	if (ui_stack.size() > 0 and ui_stack[ui_stack.size() - 1] != self):
		return;
	Input.action_release(action);
	menubutton.grab_focus();
	menubutton.release_focus();
	
func _undobutton_pressed() -> void:
	virtual_button_pressed("undo");
	
func _leftbutton_pressed() -> void:
	virtual_button_pressed("ui_left");
	
func _rightbutton_pressed() -> void:
	virtual_button_pressed("ui_right");
	
func _upbutton_pressed() -> void:
	virtual_button_pressed("ui_up");

func _downbutton_pressed() -> void:
	virtual_button_pressed("ui_down");
	
func _enterbutton_pressed() -> void:
	virtual_button_pressed("ui_accept");
	
func _f9button_pressed() -> void:
	virtual_button_pressed("slowdown_replay");
	
func _f10button_pressed() -> void:
	virtual_button_pressed("speedup_replay");
	
func _prevturnbutton_pressed() -> void:
	virtual_button_pressed("replay_back1");

func _nextturnbutton_pressed() -> void:
	virtual_button_pressed("replay_fwd1");
	
func _pausebutton_pressed() -> void:
	virtual_button_pressed("replay_pause");
	
func _undobutton_released() -> void:
	virtual_button_released("character_undo");
	
func _swapbutton_released() -> void:
	virtual_button_released("character_switch");
	
func _metaundobutton_released() -> void:
	virtual_button_released("meta_undo");
	
func _leftbutton_released() -> void:
	virtual_button_released("ui_left");
	
func _rightbutton_released() -> void:
	virtual_button_released("ui_right");
	
func _upbutton_released() -> void:
	virtual_button_released("ui_up");

func _downbutton_released() -> void:
	virtual_button_released("ui_down");
	
func _enterbutton_released() -> void:
	virtual_button_released("ui_accept");
	
func _f9button_released() -> void:
	virtual_button_released("slowdown_replay");
	
func _f10button_released() -> void:
	virtual_button_released("speedup_replay");
	
func _prevturnbutton_released() -> void:
	virtual_button_released("replay_back1");

func _nextturnbutton_released() -> void:
	virtual_button_released("replay_fwd1");
	
func _pausebutton_released() -> void:
	virtual_button_released("replay_pause");
	
func _replayturnslider_value_changed(value: int) -> void:
	if !doing_replay:
		return;
	if (replayturnsliderset):
		return;
	var differential = value - replay_turn;
	if (differential != 0):
		replay_advance_turn(differential);
	
func _replayspeedslider_value_changed(value: int) -> void:
	if !doing_replay:
		return;
	if (replayspeedsliderset):
		return;
	var old_replay_interval = replay_interval;
	replay_interval = (100-value) * 0.01;
	adjust_next_replay_time(old_replay_interval);
	update_info_labels();

func react_to_save_file_update() -> void:	
	level_number = save_file["level_number"];
	if (save_file.has("puzzle_checkerboard")):
		checkerboard.visible = true;
	setup_resolution();
	setup_volume();
	setup_animation_speed();
	setup_virtual_buttons();
	deserialize_bindings();
	setup_deadzone();
	refresh_puzzles_completed();
	
var actions = ["ui_accept", "ui_cancel", "escape", "ui_left", "ui_right", "ui_up", "ui_down",
"undo", "restart",
"mute", "start_replay", "speedup_replay",
"slowdown_replay", "start_saved_replay"];
	
func setup_deadzone() -> void:
	if (!save_file.has("deadzone")):
		save_file["deadzone"] = InputMap.action_get_deadzone("ui_up");
	else:
		InputMap.action_set_deadzone("ui_up", save_file["deadzone"]);
		InputMap.action_set_deadzone("ui_down", save_file["deadzone"]);
		InputMap.action_set_deadzone("ui_left", save_file["deadzone"]);
		InputMap.action_set_deadzone("ui_right", save_file["deadzone"]);
	
func deserialize_bindings() -> void:
	if save_file.has("keyboard_bindings"):
		for action in actions:
			var events = InputMap.get_action_list(action);
			for event in events:
				if (event is InputEventKey):
					InputMap.action_erase_event(action, event);
			for new_event_str in save_file["keyboard_bindings"][action]:
				var parts = new_event_str.split(",");
				var new_event = InputEventKey.new();
				new_event.scancode = int(parts[0]);
				new_event.physical_scancode = int(parts[1]);
				InputMap.action_add_event(action, new_event);
	if save_file.has("controller_bindings"):
		for action in actions:
			var events = InputMap.get_action_list(action);
			for event in events:
				if (event is InputEventJoypadButton):
					InputMap.action_erase_event(action, event);
			for new_event_int in save_file["controller_bindings"][action]:
				var new_event = InputEventJoypadButton.new();
				new_event.button_index = new_event_int;
				InputMap.action_add_event(action, new_event);

func serialize_bindings() -> void:
	if !save_file.has("keyboard_bindings"):
		save_file["keyboard_bindings"] = {};
	else:
		save_file["keyboard_bindings"].clear();
	if !save_file.has("controller_bindings"):
		save_file["controller_bindings"] = {};
	else:
		save_file["controller_bindings"].clear();
	
	for action in actions:
		var events = InputMap.get_action_list(action);
		save_file["keyboard_bindings"][action] = [];
		save_file["controller_bindings"][action] = [];
		for event in events:
			if (event is InputEventKey):
				save_file["keyboard_bindings"][action].append(str(event.scancode) + "," +str(event.physical_scancode));
			elif (event is InputEventJoypadButton):
				save_file["controller_bindings"][action].append(event.button_index);
	
func setup_virtual_buttons() -> void:
	var value = 1;
	if (save_file.has("virtual_buttons")):
		value = save_file["virtual_buttons"];
	if (value > 0):
		for folder in virtualbuttons.get_children():
			for button in folder.get_children():
				button.disabled = false;
		virtualbuttons.visible = true;
		if value == 1:
			virtualbuttons.get_node("Verbs").position = Vector2(0, 0);
			virtualbuttons.get_node("Dirs").position = Vector2(0, 0);
			replaybuttons.get_node("ReplayTurn").position = Vector2(0, 0);
			replaybuttons.get_node("ReplaySpeed").position = Vector2(0, 0);
		elif value == 2:
			virtualbuttons.get_node("Verbs").position = Vector2(0, 0);
			virtualbuttons.get_node("Dirs").position = Vector2(-108, 0);
			replaybuttons.get_node("ReplayTurn").position = Vector2(0, 0);
			replaybuttons.get_node("ReplaySpeed").position = Vector2(138, 0);
		elif value == 3:
			virtualbuttons.get_node("Verbs").position = Vector2(128, 0);
			virtualbuttons.get_node("Dirs").position = Vector2(0, 0);
			replaybuttons.get_node("ReplayTurn").position = Vector2(-128, 0);
			replaybuttons.get_node("ReplaySpeed").position = Vector2(0, 0);
		elif value == 4:
			virtualbuttons.get_node("Verbs").position = Vector2(128, 0);
			virtualbuttons.get_node("Dirs").position = Vector2(-108, 0);
			replaybuttons.get_node("ReplayTurn").position = Vector2(-128, 0);
			replaybuttons.get_node("ReplaySpeed").position = Vector2(138, 0);
		elif value == 5:
			virtualbuttons.get_node("Verbs").position = Vector2(0, 0);
			virtualbuttons.get_node("Dirs").position = Vector2(-300, 0);
			replaybuttons.get_node("ReplayTurn").position = Vector2(160, 0);
			replaybuttons.get_node("ReplaySpeed").position = Vector2(138, 0);
		elif value == 6:
			virtualbuttons.get_node("Verbs").position = Vector2(300, 0);
			virtualbuttons.get_node("Dirs").position = Vector2(0, 0);
			replaybuttons.get_node("ReplayTurn").position = Vector2(-128, 0);
			replaybuttons.get_node("ReplaySpeed").position = Vector2(-150, 0);
	else:
		replaybuttons.get_node("ReplayTurn").position = Vector2(0, 0);
		replaybuttons.get_node("ReplaySpeed").position = Vector2(0, 0);
		for folder in virtualbuttons.get_children():
			for button in folder.get_children():
				button.disabled = true;
		virtualbuttons.visible = false;
	
func setup_resolution() -> void:
	if (save_file.has("pixel_scale")):
		var value = save_file["pixel_scale"];
		var size = Vector2(pixel_width*value, pixel_height*value);
		OS.set_window_size(size);
		OS.center_window();
	if (save_file.has("vsync_enabled")):
		OS.vsync_enabled = save_file["vsync_enabled"];
		
func setup_volume() -> void:
	if (save_file.has("sfx_volume")):
		var value = save_file["sfx_volume"];
		for speaker in speakers:
			speaker.volume_db = value;
	if (save_file.has("music_volume")):
		var value = save_file["music_volume"];
		music_speaker.volume_db = value;
		music_speaker.volume_db = music_speaker.volume_db + music_discount;
	if (save_file.has("fanfare_volume")):
		var value = save_file["fanfare_volume"];
		won_speaker.volume_db = value;
	
func setup_animation_speed() -> void:
	if (save_file.has("animation_speed")):
		var value = save_file["animation_speed"];
		Engine.time_scale = value;
		
func initialize_shaders() -> void:
	pass
	#each thing that uses a shader has to compile the first time it's used, so... use it now!
	#var afterimage = preload("Afterimage.tscn").instance();
	#afterimage.initialize(targeter, arbitrary_color);
	#levelscene.call_deferred("add_child", afterimage);
	#afterimage.position = Vector2(-99, -99);
	# TODO: compile the Static shader by flicking it on for a single frame? same for ripple and grayscale
	
func tile_changes(level_editor: bool = false) -> void:
	# hide light and heavy goal sprites when in-game and not in-editor
	#if (!level_editor):
	#	terrainmap.tile_set.tile_set_texture(Tiles.LightGoal, null);
	#	terrainmap.tile_set.tile_set_texture(Tiles.HeavyGoal, null);
	#	terrainmap.tile_set.tile_set_texture(Tiles.LightGoalJoke, null);
	#	terrainmap.tile_set.tile_set_texture(Tiles.HeavyGoalJoke, null);
	#else:
	#	terrainmap.tile_set.tile_set_texture(Tiles.LightGoal, preload("res://assets/light_goal.png"));
	#	terrainmap.tile_set.tile_set_texture(Tiles.HeavyGoal, preload("res://assets/heavy_goal.png"));
	#	terrainmap.tile_set.tile_set_texture(Tiles.LightGoalJoke, preload("res://assets/light_goal_joke.png"));
	#	terrainmap.tile_set.tile_set_texture(Tiles.HeavyGoalJoke, preload("res://assets/heavy_goal_joke.png"));
	pass
	
func assert_tile_enum() -> void:
	for i in range (Tiles.size()):
		var expected_tile_name = Tiles.keys()[i];
		var expected_tile_id = Tiles.values()[i];
		var actual_tile_id = terrainmap.tile_set.find_tile_by_name(expected_tile_name);
		var actual_tile_name = terrainmap.tile_set.tile_get_name(expected_tile_id);
		if (actual_tile_name != expected_tile_name):
			print(expected_tile_name, ", ", expected_tile_id, ", ", actual_tile_name, ", ", actual_tile_id);
		elif (actual_tile_id != expected_tile_id):
			print(expected_tile_name, ", ", expected_tile_id, ", ", actual_tile_name, ", ", actual_tile_id);
	
func initialize_level_list() -> void:
	
	chapter_names.push_back("Swimming in Crates");
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_standard_unlock_requirements.push_back(0);
	chapter_skies.push_back(Color("#0E0E12"));
	chapter_tracks.push_back(-1);
	level_filenames.push_back("Level")
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	chapter_advanced_unlock_requirements.push_back(0);

	# sentinel to make overflow checks easy
	chapter_standard_starting_levels.push_back(level_filenames.size());
	chapter_advanced_starting_levels.push_back(level_filenames.size());
	
	for level_filename in level_filenames:
		level_list.push_back(load("res://levels/" + level_filename + ".tscn"));
	
	for level_prototype in level_list:
		var level = level_prototype.instance();
		var level_name = level.get_node("LevelInfo").level_name;
		level_names.push_back(level_name);
		level.queue_free();
		
	for i in range(level_list.size()):
		var level_name = level_names[i];
		var level_filename = level_filenames[i];
			
	refresh_puzzles_completed();
		
func refresh_puzzles_completed() -> void:
	puzzles_completed = 0;
	for level_name in level_names:
		if save_file["levels"].has(level_name) and save_file["levels"][level_name].has("won") and save_file["levels"][level_name]["won"]:
			puzzles_completed += 1;

func ready_map() -> void:
	won = false;
	end_lose();
	lost_speaker.stop();
	for actor in actors:
		actor.queue_free();
	actors.clear();
	for goal in goals:
		goal.queue_free();
	goals.clear();
	for whatever in underactorsparticles.get_children():
		whatever.queue_free();
	for whatever in overactorsparticles.get_children():
		whatever.queue_free();
	turn = 0;
	undo_buffer.clear();
	user_replay = "";
	
	var level_info = terrainmap.get_node_or_null("LevelInfo");
	if (level_info != null): # might be a custom puzzle
		level_name = level_info.level_name;
		level_author = level_info.level_author;
		level_replay = level_info.level_replay;
		if ("$" in level_replay):
			var level_replay_parts = level_replay.split("$");
			level_replay = level_replay_parts[level_replay_parts.size()-1];
	
	calculate_map_size();
	make_actors();
	
	finish_animations(Chrono.TIMELESS);
	update_info_labels();
	check_won();
	
	ready_tutorial();
	update_level_label();
	
func ready_tutorial() -> void:
	metainfolabel.visible = true;
	tutoriallabel.visible = false;
	downarrow.visible = false;
	leftarrow.visible = false;
	rightarrow.visible = false;
	return;
	
func get_used_cells_by_id_all_layers(id: int) -> Array:
	var results = []
	for layer in terrain_layers:
		results.append(layer.get_used_cells_by_id(id));
	return results;
	
func get_used_cells_by_id_one_array(id: int) -> Array:
	var results = []
	for layer in terrain_layers:
		results.append_array(layer.get_used_cells_by_id(id));
	return results;

func make_actors() -> void:	
	# find the player
	# as a you-fucked-up backup, put them in 0,0 if there seems to be none
	var layers_tiles = get_used_cells_by_id_all_layers(Tiles.Dolphin);
	var found_one = false;
	for i in range(layers_tiles.size()):
		var tiles = layers_tiles[i];
		if (tiles.size() > 0):
			found_one = true;
	if !found_one:
		layers_tiles = [[Vector2(0, 0)]];
	for i in range(layers_tiles.size()):
		var tiles = layers_tiles[i];
		for tile in tiles:
			terrain_layers[i].set_cellv(tile, -1);
			player = make_actor(Actor.Name.Dolphin, tile, true);
			player.heaviness = Heaviness.IRON;
			player.strength = Strength.LIGHT;
			player.durability = Durability.SPIKES;
			player.fall_speed = 1;
			player.climbs = true;
			player.color = arbitrary_color;
			if (player.pos.x > (map_x_max / 2)):
				player.facing_left = true;
			player.update_graphics();
	
	# crates
	extract_actors(Tiles.CrateFloat, Actor.Name.CrateFloat,
	Heaviness.IRON, Strength.WOODEN, Durability.FIRE, 1, false, Color(0.5, 0.5, 0.5, 1), -1, true);
	extract_actors(Tiles.CrateFloatNoPush, Actor.Name.CrateFloatNoPush,
	Heaviness.STEEL, Strength.WOODEN, Durability.FIRE, 1, false, Color(0.5, 0.5, 0.5, 1), -1, true);
	extract_actors(Tiles.CrateFloatNoSwap, Actor.Name.CrateFloatNoSwap,
	Heaviness.IRON, Strength.WOODEN, Durability.FIRE, 1, false, Color(0.5, 0.5, 0.5, 1), -1, false);
	extract_actors(Tiles.CrateFloatNothing, Actor.Name.CrateFloatNothing,
	Heaviness.STEEL, Strength.WOODEN, Durability.FIRE, 1, false, Color(0.5, 0.5, 0.5, 1), -1, false);
	
	extract_actors(Tiles.CrateNeutral, Actor.Name.CrateNeutral,
	Heaviness.IRON, Strength.WOODEN, Durability.FIRE, 1, false, Color(0.5, 0.5, 0.5, 1), 0, true);
	extract_actors(Tiles.CrateNeutralNoPush, Actor.Name.CrateNeutralNoPush,
	Heaviness.STEEL, Strength.WOODEN, Durability.FIRE, 1, false, Color(0.5, 0.5, 0.5, 1), 0, true);
	extract_actors(Tiles.CrateNeutralNoSwap, Actor.Name.CrateNeutralNoSwap,
	Heaviness.IRON, Strength.WOODEN, Durability.FIRE, 1, false, Color(0.5, 0.5, 0.5, 1), 0, false);
	extract_actors(Tiles.CrateNeutralNothing, Actor.Name.CrateNeutralNothing,
	Heaviness.STEEL, Strength.WOODEN, Durability.FIRE, 1, false, Color(0.5, 0.5, 0.5, 1), 0, false);
	
	extract_actors(Tiles.CrateSink, Actor.Name.CrateSink,
	Heaviness.IRON, Strength.WOODEN, Durability.FIRE, 1, false, Color(0.5, 0.5, 0.5, 1), 1, true);
	extract_actors(Tiles.CrateSinkNoPush, Actor.Name.CrateSinkNoPush,
	Heaviness.STEEL, Strength.WOODEN, Durability.FIRE, 1, false, Color(0.5, 0.5, 0.5, 1), 1, true);
	extract_actors(Tiles.CrateSinkNoSwap, Actor.Name.CrateSinkNoSwap,
	Heaviness.IRON, Strength.WOODEN, Durability.FIRE, 1, false, Color(0.5, 0.5, 0.5, 1), 1, false);
	extract_actors(Tiles.CrateSinkNothing, Actor.Name.CrateSinkNothing,
	Heaviness.STEEL, Strength.WOODEN, Durability.FIRE, 1, false, Color(0.5, 0.5, 0.5, 1), 1, false);
	
	find_gems();
	
func extract_actors(id: int, actorname: int, heaviness: int, strength: int, durability: int, fall_speed: int,
climbs: bool, color: Color, buoyancy: int, can_swap: bool) -> void:
	var layers_tiles = get_used_cells_by_id_all_layers(id);
	for i in range(layers_tiles.size()):
		var tiles = layers_tiles[i];
		for tile in tiles:
			terrain_layers[i].set_cellv(tile, -1);
			var actor = make_actor(actorname, tile, false);
			actor.heaviness = heaviness;
			actor.strength = strength;
			actor.durability = durability;
			actor.fall_speed = fall_speed;
			actor.climbs = climbs;
			actor.is_character = false;
			actor.color = color;
			actor.buoyancy = buoyancy;
			actor.can_swap = can_swap;
			actor.update_graphics();

func find_gems() -> void:
	var layers_tiles = get_used_cells_by_id_all_layers(Tiles.Gem);
	for i in range(layers_tiles.size()):
		var tiles = layers_tiles[i];
		for tile in tiles:
			terrain_layers[i].set_cellv(tile, -1);
			# get first actor with the same pos and gemless and gem it
			for actor in actors:
				if actor.pos == tile and !actor.has_gem:
					actor.gain_gem();
	
func calculate_map_size() -> void:
	map_x_max = 0;
	map_y_max = 0;
	for layer in terrain_layers:
		var tiles = layer.get_used_cells();
		for tile in tiles:
			if tile.x > map_x_max:
				map_x_max = tile.x;
			if tile.y > map_y_max:
				map_y_max = tile.y;
	terrainmap.position.x = (map_x_max_max-map_x_max)*(cell_size/2)-8;
	terrainmap.position.y = (map_y_max_max-map_y_max)*(cell_size/2)+12;
	underterrainfolder.position = terrainmap.position;
	actorsfolder.position = terrainmap.position;
	underactorsparticles.position = terrainmap.position;
	overactorsparticles.position = terrainmap.position;
	checkerboard.rect_position = terrainmap.position;
	checkerboard.rect_size = cell_size*Vector2(map_x_max+1, map_y_max+1);
	# hack for World's Smallest Puzzle!
	if (map_y_max == 0):
		checkerboard.rect_position.y -= cell_size;
		
func update_targeter() -> void:
	targeter.visible = false;
#	if (heavy_selected):
#		targeter.position = heavy_actor.position + terrainmap.position - Vector2(2, 2);
#	else:
#		targeter.position = light_actor.position + terrainmap.position - Vector2(2, 2);
#
#	if (!downarrow.visible):
#		return;
#
#	downarrow.position = targeter.position - Vector2(0, 24);
#
#	if (heavy_turn > 0 and heavy_selected):
#		rightarrow.position = heavytimeline.position - Vector2(24, 24) + Vector2(0, 24)*heavy_turn;
#	else:
#		rightarrow.position = Vector2(-48, -48);
#
#	if (light_turn > 0 and !heavy_selected):
#		leftarrow.position = lighttimeline.position + Vector2(24, -24) + Vector2(0, 24)*light_turn;
#	else:
#		leftarrow.position = Vector2(-48, -48);
		
func prepare_audio() -> void:
	# TODO: I could automate this if I can iterate the folder
	# TODO: replace this with an enum and assert on startup like tiles

	sounds["abysschime"] = preload("res://sfx/abysschime.ogg");
	sounds["bluefire"] = preload("res://sfx/bluefire.ogg");
	sounds["broken"] = preload("res://sfx/broken.ogg");
	sounds["bump"] = preload("res://sfx/bump.ogg");
	sounds["fall"] = preload("res://sfx/fall.ogg");
	sounds["fuzz"] = preload("res://sfx/fuzz.ogg");
	sounds["greenfire"] = preload("res://sfx/greenfire.ogg");
	sounds["greentimecrystal"] = preload("res://sfx/greentimecrystal.ogg");
	sounds["heavycoyote"] = preload("res://sfx/heavycoyote.ogg");
	sounds["heavyland"] = preload("res://sfx/heavyland.ogg");
	sounds["heavystep"] = preload("res://sfx/heavystep.ogg");
	sounds["heavyuncoyote"] = preload("res://sfx/heavyuncoyote.ogg");
	sounds["heavyunland"] = preload("res://sfx/heavyunland.ogg");
	sounds["involuntarybump"] = preload("res://sfx/involuntarybump.ogg");
	sounds["involuntarybumplight"] = preload("res://sfx/involuntarybumplight.ogg");
	sounds["involuntarybumpother"] = preload("res://sfx/involuntarybumpother.ogg");
	sounds["lightcoyote"] = preload("res://sfx/lightcoyote.ogg");
	sounds["lightland"] = preload("res://sfx/lightland.ogg");
	sounds["lightstep"] = preload("res://sfx/lightstep.ogg");
	sounds["lightuncoyote"] = preload("res://sfx/lightuncoyote.ogg");
	sounds["lightunland"] = preload("res://sfx/lightunland.ogg");
	sounds["lose"] = preload("res://sfx/lose.ogg");
	sounds["magentatimecrystal"] = preload("res://sfx/magentatimecrystal.ogg");
	sounds["metarestart"] = preload("res://sfx/metarestart.ogg");
	sounds["metaundo"] = preload("res://sfx/metaundo.ogg");
	sounds["push"] = preload("res://sfx/push.ogg");
	sounds["redfire"] = preload("res://sfx/redfire.ogg");
	sounds["remembertimecrystal"] = preload("res://sfx/remembertimecrystal.ogg");
	sounds["restart"] = preload("res://sfx/restart.ogg");	
	sounds["shatter"] = preload("res://sfx/shatter.ogg");
	sounds["shroud"] = preload("res://sfx/shroud.ogg");
	sounds["step"] = preload("res://sfx/step.ogg");
	sounds["switch"] = preload("res://sfx/switch.ogg");
	sounds["tick"] = preload("res://sfx/tick.ogg");
	sounds["timesup"] = preload("res://sfx/timesup.ogg");
	sounds["unbroken"] = preload("res://sfx/unbroken.ogg");
	sounds["undo"] = preload("res://sfx/undo.ogg");
	sounds["undostrong"] = preload("res://sfx/undostrong.ogg");
	sounds["unfall"] = preload("res://sfx/unfall.ogg");
	sounds["unpush"] = preload("res://sfx/unpush.ogg");
	sounds["unshatter"] = preload("res://sfx/unshatter.ogg");
	sounds["untick"] = preload("res://sfx/untick.ogg");
	sounds["usegreenality"] = preload("res://sfx/usegreenality.ogg");
	sounds["voidundo"] = preload("res://sfx/voidundo.ogg");
	sounds["winentwined"] = preload("res://sfx/winentwined.ogg");
	sounds["winbadtime"] = preload("res://sfx/winbadtime.ogg");

	for i in range (8):
		var speaker = AudioStreamPlayer.new();
		self.add_child(speaker);
		speakers.append(speaker);
	lost_speaker = AudioStreamPlayer.new();
	lost_speaker.stream = sounds["lose"];
	lost_speaker_volume_tween = Tween.new();
	self.add_child(lost_speaker_volume_tween);
	self.add_child(lost_speaker);
	won_speaker = AudioStreamPlayer.new();
	self.add_child(won_speaker);
	music_speaker = AudioStreamPlayer.new();
	self.add_child(music_speaker);

func fade_in_lost():
	winlabel.visible = true;
	call_deferred("adjust_winlabel");
	Shade.on = true;
	
	if muted or (doing_replay and meta_undo_a_restart_mode):
		return;
	var db = save_file["fanfare_volume"];
	if (db <= -30):
		return;
	lost_speaker.volume_db = -40 + db;
	lost_speaker_volume_tween.interpolate_property(lost_speaker, "volume_db", -40 + db, -10 + db, 3.00, 1, Tween.EASE_IN, 0)
	lost_speaker_volume_tween.start();
	lost_speaker.play();

func cut_sound() -> void:
	if (doing_replay and meta_undo_a_restart_mode):
		return;
	for speaker in speakers:
		speaker.stop();
	lost_speaker.stop();
	won_speaker.stop();

func play_sound(sound: String) -> void:
	if muted or (doing_replay and meta_undo_a_restart_mode):
		return;
	if (sounds_played_this_frame.has(sound)):
		return;
	for speaker in speakers:
		if speaker.volume_db <= -30:
			return;
		if !speaker.playing:
			speaker.stream = sounds[sound];
			sounds_played_this_frame[sound] = true;
			speaker.play();
			return;

func play_won(sound: String) -> void:
	if muted or (doing_replay and meta_undo_a_restart_mode):
		return;
	if (sounds_played_this_frame.has(sound)):
		return;
	var speaker = won_speaker;
	# might adjust to -40 db or whatever depending
	if speaker.volume_db <= -30:
		return;
	if speaker.playing:
		speaker.stop();
	speaker.stream = sounds[sound];
	sounds_played_this_frame[sound] = true;
	speaker.play();
	return;

func toggle_mute() -> void:
	if (!muted):
		floating_text("M: Muted");
	else:
		floating_text("M: Unmuted");
	muted = !muted;
	music_speaker.stream_paused = muted;
	cut_sound();

func make_actor(actorname: int, pos: Vector2, is_character: bool, chrono: int = Chrono.TIMELESS) -> Actor:
	var actor = Actor.new();
	actors.append(actor);
	actor.actorname = actorname;
	actor.is_character = is_character;
	actor.gamelogic = self;
	actor.offset = Vector2(cell_size/2, cell_size/2);
	actorsfolder.add_child(actor);
	move_actor_to(actor, pos, chrono, false, false);
	if (chrono < Chrono.UNDO):
		print("TODO")
	return actor;

func move_actor_relative(actor: Actor, dir: Vector2, chrono: int, hypothetical: bool, is_gravity: bool,
pushers_list: Array = [], is_move: bool = false, success: int = Success.No) -> int:
	return move_actor_to(actor, actor.pos + dir, chrono, hypothetical,
	is_gravity, pushers_list, is_move, success);
	
func move_actor_to(actor: Actor, pos: Vector2, chrono: int, hypothetical: bool, is_gravity: bool,
pushers_list: Array = [], is_move: bool = false, success: int = Success.No) -> int:
	var dir = pos - actor.pos;
	var old_pos = actor.pos;
	
	if (success == Success.No):
		success = try_enter(actor, dir, chrono, true, hypothetical, is_gravity, pushers_list);
	if (success == Success.Yes and !hypothetical):
		actor.pos = pos;
		# do facing change now before move happens
		if (is_move and actor.is_character):
			if (dir == Vector2.LEFT and !actor.facing_left):
				set_actor_var(actor, "facing_left", true, chrono);
			elif (dir == Vector2.RIGHT and actor.facing_left):
				set_actor_var(actor, "facing_left", false, chrono);
				
		if actor.has_gem:
			if actor.pressing:
				set_actor_var(actor, "pressing", false, chrono);
			if terrain_in_tile(actor.pos).has(Tiles.Switch):
				set_actor_var(actor, "pressing", true, chrono);
			
		add_undo_event([Undo.move, actor, dir], chrono);
		
		#do sound effects for special moves
		var was_push = pushers_list.size() > 0;
		var was_fall = is_gravity;
		if (was_push):
			add_to_animation_server(actor, [Animation.sfx, "push"]);
		if (was_fall):
			add_to_animation_server(actor, [Animation.sfx, "fall"]);

		add_to_animation_server(actor, [Animation.move, dir]);
		
		return success;
	elif (success != Success.Yes):
		if (!hypothetical):
			# involuntary bump sfx
			if (pushers_list.size() > 0):
				if (actor.actorname == Actor.Name.Dolphin):
					add_to_animation_server(actor, [Animation.sfx, "involuntarybumplight"]);
				else:
					add_to_animation_server(actor, [Animation.sfx, "involuntarybumpother"]);
		# bump animation always happens, I think?
		add_to_animation_server(actor, [Animation.bump, dir]);
	return success;
		
func adjust_turn(amount: int) -> void:
	turn += amount;
	check_won();
		
func actors_in_tile(pos: Vector2) -> Array:
	var result = [];
	for actor in actors:
		if actor.pos == pos:
			result.append(actor);
	return result;
	
func terrain_in_tile(pos: Vector2) -> Array:
	var result = [];
	for layer in terrain_layers:
		result.append(layer.get_cellv(pos));
	return result;
	
#func maybe_break_actor(actor: Actor, hazard: int, hypothetical: bool, green_terrain: int, chrono: int) -> int:
#	# AD04: being broken makes you immune to breaking :D
#	if (!actor.broken and actor.durability <= hazard):
#		if (!hypothetical):
#			actor.post_mortem = hazard;
#			if (green_terrain == Greenness.Green and chrono < Chrono.CHAR_UNDO):
#				chrono = Chrono.CHAR_UNDO;
#			if (green_terrain == Greenness.Void and chrono < Chrono.META_UNDO):
#				chrono = Chrono.META_UNDO;
#			set_actor_var(actor, "broken", true, chrono);
#		return Success.Surprise;
#	else:
#		return Success.No;

#func find_or_create_layer_having_this_tile(pos: Vector2, assumed_old_tile: int) -> int:
#	for layer in range(terrain_layers.size()):
#		var terrain_layer = terrain_layers[layer];
#		var old_tile = terrain_layer.get_cellv(pos);
#		if (old_tile == assumed_old_tile):
#			return layer;
#	# create a new one.
#	var new_layer = TileMap.new();
#	new_layer.tile_set = terrainmap.tile_set;
#	new_layer.cell_size = terrainmap.cell_size;
#	# new layer will have to be at the back (first cihld, last terrain_layer), so I don't desync existing memories of layers.
#	terrainmap.add_child(new_layer);
#	terrainmap.move_child(new_layer, 0);
#	terrain_layers.push_back(new_layer);
#	return terrain_layers.size() - 1;

#func maybe_change_terrain(actor: Actor, pos: Vector2, layer: int, hypothetical: bool, green_terrain: int,
#chrono: int, new_tile: int, assumed_old_tile: int = -2, animation_nonce: int = -1) -> int:
#	if (chrono == Chrono.GHOSTS):
#		# TODO: the ghost will technically be on the wrong layer but, whatever, too much of a pain in the ass to fix rn
#		# (I think the solution would be to programatically have one Node2D between each presentation TileMap and put it in the right folder)
#		if new_tile != -1:
#			var ghost = make_ghost_here_with_texture(pos, terrainmap.tile_set.tile_get_texture(new_tile));
#		else:
#			var ghost = make_ghost_here_with_texture(pos, preload("res://timeline/timeline-broken-12.png"));
#			ghost.scale = Vector2(2, 2);
#		return Success.Surprise;
#
#	if (!hypothetical):
#		var terrain_layer = terrain_layers[layer];
#		var old_tile = terrain_layer.get_cellv(pos);
#		if (assumed_old_tile != -2 and assumed_old_tile != old_tile):
#			# desync (probably due to fuzz doubled glass mechanic). find or create the first layer where assumed_old_tile is correct.
#			layer = find_or_create_layer_having_this_tile(pos, assumed_old_tile);
#			terrain_layer = terrain_layers[layer];
#		terrain_layer.set_cellv(pos, new_tile);
#		if (green_terrain == Greenness.Green and chrono < Chrono.CHAR_UNDO):
#			chrono = Chrono.CHAR_UNDO;
#		if (green_terrain == Greenness.Void and chrono < Chrono.META_UNDO):
#			chrono = Chrono.META_UNDO;
#
#		if (animation_nonce == -1):
#			animation_nonce = animation_nonce_fountain_dispense();
#
#		add_undo_event([Undo.change_terrain, actor, pos, layer, old_tile, new_tile, animation_nonce], chrono);
#		# TODO: presentation/data terrain layer update (see notes)
#		# ~encasement layering/unlayering~~ just kidding, chronofrag time (AD11)
#		if new_tile == Tiles.GlassBlock or new_tile == Tiles.GlassBlockCracked:
#			add_to_animation_server(actor, [Animation.unshatter, terrainmap.map_to_world(pos), old_tile, new_tile, animation_nonce]);
#			for actor in actors:
#				# time crystal/glass chronofrag interaction: it isn't. that's my decision for now.
#				if actor.pos == pos and !actor.broken and actor.durability <= Durability.PITS:
#					actor.post_mortem = Durability.PITS;
#					set_actor_var(actor, "broken", true, chrono);
#		else:
#			if (old_tile == Tiles.Fuzz):
#				play_sound("fuzz");
#			else:
#				add_to_animation_server(actor, [Animation.shatter, terrainmap.map_to_world(pos), old_tile, new_tile, animation_nonce]);
#	return Success.Surprise;

func current_tile_is_solid(actor: Actor, dir: Vector2, _is_gravity: bool) -> bool:
	var terrain = terrain_in_tile(actor.pos);
	var blocked = false;
	
	# when moving retrograde, it would have been valid to come out of a oneway, but not to have gone THROUGH one.
	# so check that.
	# besides that, glass blocks prevent exit.
#	for id in terrain:
#		match id:
#			Tiles.OnewayEast:
#				blocked = is_retro and dir == Vector2.RIGHT;
#				if (blocked):
#					flash_terrain = id;
#					flash_colour = oneway_flash;
#			Tiles.OnewayWest:
#				blocked = is_retro and dir == Vector2.LEFT;
#				if (blocked):
#					flash_terrain = id;
#					flash_colour = oneway_flash;
#			Tiles.OnewayNorth:
#				blocked = is_retro and dir == Vector2.UP;
#				if (blocked):
#					flash_terrain = id;
#					flash_colour = oneway_flash;
#			Tiles.OnewaySouth:
#				blocked = is_retro and dir == Vector2.DOWN;
#				if (blocked):
#					flash_terrain = id;
#					flash_colour = oneway_flash;
#			Tiles.GlassBlock:
#				blocked = true;
#				if (blocked):
#					flash_terrain = id;
#					flash_colour = no_foo_flash;
#			Tiles.GlassBlockCracked:
#				# it'd be cool to let actors break out of cracked glass blocks under their own power.
#				blocked = true;
#				if (blocked):
#					flash_terrain = id;
#					flash_colour = no_foo_flash;
#			Tiles.GreenGlassBlock:
#				blocked = true;
#				if (blocked):
#					flash_terrain = id;
#					flash_colour = no_foo_flash;
#			Tiles.VoidGlassBlock:
#				blocked = true;
#				if (blocked):
#					flash_terrain = id;
#					flash_colour = no_foo_flash;
#		if blocked:
#			return true;
	return false;

func no_if_true_yes_if_false(input: bool) -> int:
	if (input):
		return Success.No;
	return Success.Yes;

func try_enter_terrain(actor: Actor, pos: Vector2, dir: Vector2, hypothetical: bool, is_gravity: bool,
chrono: int) -> int:
	var result = Success.Yes;
	
	# check for bottomless pits
	#if (pos.y > map_y_max):
		#return maybe_break_actor(actor, Durability.PITS, hypothetical, Greenness.Mundane, chrono);

	var terrain = terrain_in_tile(pos);
	for i in range(terrain.size()):
		var id = terrain[i];
		match id:
			Tiles.Wall:
				result = Success.No;
		if result != Success.Yes:
			return result;
	return result;
	
func terrain_is_hazardous(actor: Actor, pos: Vector2) -> int:
#	if (pos.y > map_y_max and actor.durability <= Durability.PITS):
#		return Durability.PITS;
#	var terrain = terrain_in_tile(pos);
#	if (terrain.has(Tiles.Spikeball) and actor.durability <= Durability.SPIKES):
#		return Durability.SPIKES;
	return -1;
	
func strength_check(strength: int, heaviness: int) -> bool:
	if (heaviness == Heaviness.NONE):
		return strength >= Strength.NONE;
	if (heaviness == Heaviness.CRYSTAL):
		return strength >= Strength.CRYSTAL;
	if (heaviness == Heaviness.WOODEN):
		return strength >= Strength.WOODEN;
	if (heaviness == Heaviness.IRON):
		return strength >= Strength.LIGHT;
	if (heaviness == Heaviness.STEEL):
		return strength >= Strength.HEAVY;
	if (heaviness == Heaviness.SUPERHEAVY):
		return strength >= Strength.GRAVITY;
	return false;
	
func try_enter(actor: Actor, dir: Vector2, chrono: int, can_push: bool, hypothetical: bool, is_gravity: bool,
pushers_list: Array = []) -> int:
	var dest = actor.pos + dir;
	if (chrono >= Chrono.UNDO):
		return Success.Yes;
	
	# handle solidity in our tile, solidity in the tile over, hazards/surprises in the tile over
	if (!actor.phases_into_terrain()):
		if (current_tile_is_solid(actor, dir, is_gravity)):
			return Success.No;
		var solidity_check = try_enter_terrain(actor, dest, dir, hypothetical, is_gravity, chrono);
		if (solidity_check != Success.Yes):
			return solidity_check;
	
	# handle pushing
	var actors_there = actors_in_tile(dest);
	var pushables_there = [];
	for actor_there in actors_there:
		if actor_there.pushable():
			pushables_there.push_back(actor_there);
	
	if (pushables_there.size() > 0):
		if (!can_push):
			return Success.No;
		# check if the current actor COULD push the next actor, then give them a push and return the result
		# Multi Push Rule: Multipushes are allowed (even multiple things in a tile and etc) unless another rule prohibits it.
		var strength_modifier = 0;
		pushers_list.append(actor);
		for actor_there in pushables_there:			
			# Strength Rule
			if !strength_check(actor.strength + strength_modifier, actor_there.heaviness):
				if (actor.phases_into_actors()):
					pushables_there.clear();
					break;
				else:
					pushers_list.pop_front();
					return Success.No;
		var result = Success.Yes;
				
		var surprises = [];
		result = Success.Yes;
		for actor_there in pushables_there:
			var actor_there_result = move_actor_relative(actor_there, dir, chrono, true, is_gravity, pushers_list);
			if actor_there_result == Success.No:
				if (actor.phases_into_actors()):
					pushables_there.clear();
					result = Success.Yes;
					break;
				elif (!actor.broken and pushables_there.size() == 1 and actor_there.can_swap and actor.is_character and !is_gravity):
					# When making a non-gravity move, if the push fails, Dolphin can swap with a swappable crate.
					# since swappable crate did a bump, Dolphin needs to do a bump too to sync up animations
					add_to_animation_server(actor, [Animation.bump, dir, -1]);
					move_actor_relative(actor_there, -dir, chrono, false, is_gravity, [], false, Success.Yes);
					pushables_there.erase(actor_there);
				else:
					pushers_list.pop_front();
					return Success.No;
			if actor_there_result == Success.Surprise:
				result = Success.Surprise;
				surprises.append(actor_there);
		
		if (!hypothetical):
			if (result == Success.Surprise):
				for actor_there in surprises:
					move_actor_relative(actor_there, dir, chrono, hypothetical, is_gravity, pushers_list);
			else:
				for actor_there in pushables_there:
					actor_there.just_moved = true;
					move_actor_relative(actor_there, dir, chrono, hypothetical, is_gravity, pushers_list);
				for actor_there in pushables_there:
					actor_there.just_moved = false;
		
		pushers_list.pop_front();
		return result;
	
	return Success.Yes;

func lose(reason: String, suspect: Actor) -> void:
	lost = true;
	winlabel.change_text(reason + "\n\nUndo or Restart to continue.")
	
func end_lose() -> void:
	lost = false;
	lost_speaker.stop();

func set_actor_var(actor: ActorBase, prop: String, value, chrono: int) -> void:
	var old_value = actor.get(prop);
	if (true):
		actor.set(prop, value);
		
		# and now to fix some airborne bugs, all revolving around 2:
		# if you go to 2, emit an event to 1 instead.
		#If you go from 2 to 1, ignore it.
		#If you go from 2 to anything else, pretend you came from 1.
		
		if (prop == "airborne"):
			if (value == 2):
				value = 1;
				add_undo_event([Undo.set_actor_var, actor, prop, old_value, value], chrono);
			elif (value == 1 and old_value == 2):
				pass
			elif (old_value == 2):
				old_value = 1;
				add_undo_event([Undo.set_actor_var, actor, prop, old_value, value], chrono);
			else:
				add_undo_event([Undo.set_actor_var, actor, prop, old_value, value], chrono);
		else:
			add_undo_event([Undo.set_actor_var, actor, prop, old_value, value], chrono);

		# sound effects for airborne changes
		if (prop == "airborne"):
			pass
#			if actor.actorname == Actor.Name.Heavy:
#				if is_retro:
#					if old_value >= 1 and value <= 0:
#						add_to_animation_server(actor, [Animation.sfx, "heavyuncoyote"]);
#					elif old_value == -1 and value != -1:
#						add_to_animation_server(actor, [Animation.sfx, "heavyunland"]);
#				else:
#					if value >= 1 and old_value <= 0:
#						add_to_animation_server(actor, [Animation.sfx, "heavycoyote"]);
#					elif value == -1 and old_value != -1:
#						add_to_animation_server(actor, [Animation.sfx, "heavyland"]);
#			elif actor.actorname == Actor.Name.Light:
#				if is_retro:
#					if old_value >= 1 and value <= 0:
#						add_to_animation_server(actor, [Animation.sfx, "lightuncoyote"]);
#					elif old_value == -1 and value != -1:
#						add_to_animation_server(actor, [Animation.sfx, "lightunland"]);
#				else:
#					if value >= 1 and old_value <= 0:
#						add_to_animation_server(actor, [Animation.sfx, "lightcoyote"]);
#					elif value == -1 and old_value != -1:
#						add_to_animation_server(actor, [Animation.sfx, "lightland"]);

		add_to_animation_server(actor, [Animation.set_next_texture, actor.get_next_texture(), actor.facing_left, actor.gem_status()])

func add_undo_event(event: Array, chrono: int = Chrono.MOVE) -> void:
	if (chrono == Chrono.MOVE):
		while (undo_buffer.size() <= turn):
			undo_buffer.append([]);
		undo_buffer[turn].push_front(event);

func append_replay(move: String) -> void:
	user_replay += move;
	
func undo_replay() -> bool:
	user_replay = user_replay.left(user_replay.length() - 1);
	return true;

func clone_actor_but_dont_add_it(actor : Actor) -> Actor:
	# TODO: poorly refactored with make_actor
	var new = Actor.new();
	new.gamelogic = self;
	new.actorname = actor.actorname;
	new.texture = actor.texture;
	new.offset = actor.offset;
	new.position = terrainmap.map_to_world(actor.pos);
	new.pos = actor.pos;
	new.broken = actor.broken;
	new.airborne = actor.airborne;
	new.strength = actor.strength;
	new.heaviness = actor.heaviness;
	new.durability = actor.durability;
	new.fall_speed = actor.fall_speed;
	new.climbs = actor.climbs;
	new.buoyancy = actor.buoyancy;
	new.can_swap = actor.can_swap;
	new.is_character = actor.is_character;
	new.facing_left = actor.facing_left;
	new.flip_h = actor.flip_h;
	new.frame_timer = actor.frame_timer;
	new.frame_timer_max = actor.frame_timer_max;
	new.hframes = actor.hframes;
	new.frame = actor.frame;
	new.post_mortem = actor.post_mortem;
	return new;

func finish_animations(chrono: int) -> void:
	undo_effect_color = Color.transparent;
	
	if (chrono >= Chrono.UNDO):
		for actor in actors:
			actor.animation_timer = 0;
			actor.animations.clear();
	else:
		# new logic instead of clearing animations - run animations over and over until we're done
		# this should get rid of all bugs of the form 'if an animation is skipped over some side effect never completes' 5ever
		while true:
			update_animation_server(true);
			for actor in actors:
				while (actor.animations.size() > 0):
					actor.animation_timer = 99;
					actor._process(0);
				actor.animation_timer = 0;
			if animation_server.size() <= 0:
				break;
			
	for actor in actors:
		actor.position = terrainmap.map_to_world(actor.pos);
		actor.update_graphics();
	for goal in goals:
		goal.animations.clear();
		goal.update_graphics();
	animation_server.clear();
	animation_substep = 0;
	
func goal_here(pos: Vector2, terrain: Array) -> bool:
	return terrain.has(Tiles.Goal);
	
func check_won() -> void:
	won = false;
	
	if (lost):
		return
	Shade.on = false;
	
	if (!player.broken and goal_here(player.pos, terrain_in_tile(player.pos))):
		won = true;
		
		if (won and test_mode):
			var level_info = terrainmap.get_node_or_null("LevelInfo");
			if (level_info != null):
				level_info.level_replay = annotate_replay(user_replay);
				floating_text("Test successful, recorded replay!");
		if (won == true and !doing_replay):
			play_won("winentwined");
			var levels_save_data = save_file["levels"];
			if (!levels_save_data.has(level_name)):
				levels_save_data[level_name] = {};
			var level_save_data = levels_save_data[level_name];
			if (level_save_data.has("won") and level_save_data["won"]):
				pass
			else:
				level_save_data["won"] = true;
				levelstar.previous_modulate = Color(1, 1, 1, 0);
				levelstar.flash();
				if (!is_custom):
					puzzles_completed += 1;
			if (!level_save_data.has("replay")):
				level_save_data["replay"] = annotate_replay(user_replay);
			else:
				var old_replay = level_save_data["replay"];
				var old_replay_parts = old_replay.split("$");
				var old_replay_data = old_replay_parts[old_replay_parts.size()-2];
				var old_replay_mturn_parts = old_replay_data.split("=");
				var old_replay_mturn = int(old_replay_mturn_parts[1]);
				if (old_replay_mturn > turn):
					level_save_data["replay"] = annotate_replay(user_replay);
				elif (old_replay_mturn == turn):
					# same meta-turn but shorter replay also wins
					var old_replay_payload = old_replay_parts[old_replay_parts.size()-1];
					if (len(user_replay) <= len(old_replay_payload)):
						level_save_data["replay"] = annotate_replay(user_replay);
			update_level_label();
			save_game();
	
	winlabel.visible = won;
	virtualbuttons.get_node("Others/EnterButton").visible = won and virtualbuttons.visible;
	virtualbuttons.get_node("Others/EnterButton").disabled = !won or !virtualbuttons.visible;
	if (won):
		won_cooldown = 0;
		if !using_controller and !doing_replay:
			winlabel.change_text("You have won!\n\n[Enter]: Watch Replay\nMade by Patashu (Everything but Art) and Teal Knight (Art)")
		elif !using_controller and doing_replay:
			winlabel.change_text("You have won!\n\n[Enter]: Watch Replay\nMade by Patashu (Everything but Art) and Teal Knight (Art)")
		elif using_controller and !doing_replay:
			winlabel.change_text("You have won!\n\n[Bottom Face Button]: Watch Replay\nMade by Patashu (Everything but Art) and Teal Knight (Art)")
		else:
			winlabel.change_text("You have won!\n\n[Bottom Face Button]: Watch Replay\nMade by Patashu (Everything but Art) and Teal Knight (Art)")
		won_fade_started = false;
		tutoriallabel.visible = false;
		call_deferred("adjust_winlabel_deferred");
	elif won_fade_started:
		won_fade_started = false;
		player.modulate.a = 1;
	
func adjust_winlabel_deferred() -> void:
	call_deferred("adjust_winlabel");
	
func adjust_winlabel() -> void:
	var winlabel_rect_size = winlabel.get_rect_size();
	winlabel.set_rect_position(Vector2(pixel_width/2 - int(floor(winlabel_rect_size.x/2)), win_label_default_y));
	var tries = 1;
	var player_rect = player.get_rect();
	var label_rect = Rect2(winlabel.get_rect_position(), winlabel_rect_size);
	player_rect.position = terrainmap.map_to_world(player.pos) + terrainmap.global_position;
	while (tries < 99):
		if player_rect.intersects(label_rect):
			var polarity = 1;
			if (tries % 2 == 0):
				polarity = -1;
			winlabel.set_rect_position(Vector2(winlabel.get_rect_position().x, winlabel.get_rect_position().y + 8*tries*polarity));
			label_rect.position.y += 8*tries*polarity;
		else:
			break;
		tries += 1;
	
func undo_one_event(event: Array, chrono : int) -> void:
	#if (debug_prints):
	#	print("undo_one_event", " ", event, " ", chrono);
		

	if (event[0] == Undo.move):
		var actor = event[1];
		var dir = event[2];
		move_actor_relative(actor, -dir, chrono, false, false, []);
	elif (event[0] == Undo.set_actor_var):
		var actor = event[1];
		set_actor_var(actor, event[2], event[3], chrono);
	elif (event[0] == Undo.animation_substep):
		# don't need to emit a new event as meta undoing and beyond is a teleport
		animation_substep += 1;

func meta_undo_a_restart() -> bool:
	if (user_replay_before_restarts.size() > 0):
		user_replay = "";
		end_replay();
		toggle_replay();
		cut_sound();
		play_sound("metarestart");
		level_replay = user_replay_before_restarts.pop_back();
		meta_undo_a_restart_mode = true;
		next_replay = -1;
		return true;
	return false;

func undo(is_silent: bool = false) -> bool:
	end_lose();
	finish_animations(Chrono.MOVE);
	if (turn <= 0):
		if (!doing_replay):
			if (meta_undo_a_restart()):
				return true;
		if !is_silent:
			play_sound("bump");
		return false;
	var events = undo_buffer.pop_back();
	for event in events:
		undo_one_event(event, Chrono.UNDO);
	adjust_turn(-1);
	if (!is_silent):
		cut_sound();
		play_sound("metaundo");
	undo_effect_strength = 0.08;
	undo_effect_per_second = undo_effect_strength*(1/0.2);
	for whatever in underactorsparticles.get_children():
		whatever.queue_free();
	for whatever in overactorsparticles.get_children():
		whatever.queue_free();
	finish_animations(Chrono.UNDO);
	undo_effect_color = arbitrary_color;
	return undo_replay();

func restart(_is_silent: bool = false) -> void:
	load_level(0);
	cut_sound();
	play_sound("restart");
	undo_effect_strength = 0.5;
	undo_effect_per_second = undo_effect_strength*(1/0.5);
	finish_animations(Chrono.TIMELESS);
	undo_effect_color = arbitrary_color;
	
func escape() -> void:
	if (test_mode):
		level_editor();
		test_mode = false;
		return;
	
	if (ui_stack.size() > 0):
		# can happen if we click the button directly
		var topmost_ui = ui_stack.pop_front();
		topmost_ui.queue_free();
		return;
	var levelselect = preload("res://Menu.tscn").instance();
	ui_stack.push_back(levelselect);
	levelscene.add_child(levelselect);
	
func level_editor() -> void:
	var a = preload("res://level_editor/LevelEditor.tscn").instance();
	ui_stack.push_back(a);
	levelscene.add_child(a);
	
#func level_select() -> void:
#	if (test_mode):
#		level_editor();
#		test_mode = false;
#		return;
#
#	if (ui_stack.size() > 0):
#		# can happen if we click the button directly
#		var topmost_ui = ui_stack.pop_front();
#		topmost_ui.queue_free();
#		return;
#	var levelselect = preload("res://LevelSelect.tscn").instance();
#	ui_stack.push_back(levelselect);
#	levelscene.add_child(levelselect);
	
func trying_to_load_locked_level() -> bool:
	if (is_custom):
		return false;
	if save_file.has("unlock_everything") and save_file["unlock_everything"]:
		return false;
	if (level_names[level_number] == "Chrono Lab Reactor" and !save_file["levels"].has("Chrono Lab Reactor")):
		return true;
	var unlock_requirement = 0;
	if (!level_is_extra):
		unlock_requirement = chapter_standard_unlock_requirements[chapter];
	else:
		unlock_requirement = chapter_advanced_unlock_requirements[chapter];
	if puzzles_completed < unlock_requirement:
		return true;
	return false;
	
func setup_chapter_etc() -> void:
	if (is_custom):
		return;
	chapter = 0;
	level_is_extra = false;
	for i in range(chapter_names.size()):
		if level_number < chapter_standard_starting_levels[i + 1]:
			chapter = i;
			if level_number >= chapter_advanced_starting_levels[i]:
				level_is_extra = true;
				level_in_chapter = level_number - chapter_advanced_starting_levels[i];
			else:
				level_in_chapter = level_number - chapter_standard_starting_levels[i];
			break;
	if (target_sky != chapter_skies[chapter]):
		sky_timer = 0;
		sky_timer_max = 3.0;
		old_sky = current_sky;
		target_sky = chapter_skies[chapter];
	if (target_track != chapter_tracks[chapter]):
		target_track = chapter_tracks[chapter];
		if (current_track == -1):
			play_next_song();
		else:
			fadeout_timer = max(fadeout_timer, 0); #so if we're in the middle of a fadeout it doesn't reset
			fadeout_timer_max = 3.0;
	
func play_next_song() -> void:
	current_track = target_track;
	fadeout_timer = 0;
	fadeout_timer_max = 0;
	if (is_instance_valid(now_playing)):
		now_playing.queue_free();
	now_playing = null;
	
	if (current_track > -1 and current_track < music_tracks.size() and current_track < music_info.size()):
		music_speaker.stream = music_tracks[current_track];
		music_speaker.play();
		var value = save_file["music_volume"];
		if (value > -30 and !muted): #music is not muted
			now_playing = preload("res://NowPlaying.tscn").instance();
			self.get_parent().call_deferred("add_child", now_playing);
			#self.get_parent().add_child(now_playing);
			now_playing.initialize(music_info[current_track]);
	else:
		music_speaker.stop();
	
	
func load_level_direct(new_level: int) -> void:
	is_custom = false;
	end_replay();
	var impulse = new_level - self.level_number;
	load_level(impulse);
	
func load_level(impulse: int) -> void:
	if (impulse != 0 and test_mode):
		level_editor();
		test_mode = false;
	
	if (impulse != 0):
		is_custom = false; # at least until custom campaigns :eyes:
	level_number = posmod(int(level_number), level_list.size());
	
	if (impulse != 0):
		user_replay_before_restarts.clear();
	elif user_replay.length() > 0:
		user_replay_before_restarts.push_back(user_replay);
	
	if (impulse != 0):
		level_number += impulse;
		level_number = posmod(int(level_number), level_list.size());
	
	setup_chapter_etc();
	
	# we might try to F1/F2 onto a level we don't have access to. if so, back up then show level select.
	if trying_to_load_locked_level():
		impulse *= -1;
		if (impulse == 0):
			impulse = -1;
		for _i in range(999):
			level_number += impulse;
			level_number = posmod(int(level_number), level_list.size());
			setup_chapter_etc();
			if !trying_to_load_locked_level():
				break;
		# buggy if the game just loaded, for some reason, but I didn't want it anyway
		if (ready_done):
			pass
			#level_select();
			
	if (impulse != 0):
		in_insight_level = false;
		save_file["level_number"] = level_number;
		save_game();
	
	var level = null;
	if (is_custom):
		load_custom_level(custom_string);
		return;
	level = level_list[level_number].instance();
	levelfolder.remove_child(terrainmap);
	terrainmap.queue_free();
	levelfolder.add_child(level);
	terrainmap = level;
	terrain_layers.clear();
	terrain_layers.append(terrainmap);
	for child in terrainmap.get_children():
		if child is TileMap:
			terrain_layers.push_front(child);
	
	ready_map();

func valid_voluntary_airborne_move(actor: Actor, dir: Vector2) -> bool:
	if actor.fall_speed == 0:
		return true;
	if (actor.airborne <= -1):
		return true;
	# rule change for fall speed 1 actors:
	# if airborne 0+ you can only move left or right.
	if (actor.fall_speed == 1):
		if dir == Vector2.LEFT:
			return true;
		if dir == Vector2.RIGHT:
			return true;
		return false;
	# fall speed 2+ and -1 (infinite)
	if actor.airborne == 0:
		# no air control for fast falling actors
		return false;
	else: # airborne 1+ fall speed 2+ can only move left/right now
		if dir == Vector2.LEFT:
			return true;
		if dir == Vector2.RIGHT:
			return true;
		return false;

func character_move(dir: Vector2) -> bool:
	if (won or lost): return false;
	var chr = "";
	if (dir == Vector2.UP):
		chr = "w";
	elif (dir == Vector2.DOWN):
		chr = "s";
	elif (dir == Vector2.LEFT):
		chr = "a";
	elif (dir == Vector2.RIGHT):
		chr = "d";
	finish_animations(Chrono.MOVE);
	var result = false;
	if (player.broken):
		play_sound("bump");
		return false;
	if (!valid_voluntary_airborne_move(player, dir)):
		result = Success.Surprise;
	else:
		result = move_actor_relative(player, dir, Chrono.MOVE,
		false, false, [], true);
	if (result == Success.Yes):
		play_sound("step");
		if (dir == Vector2.UP):
			if falling_direction(player) != Vector2.ZERO:
				set_actor_var(player, "airborne", 2, Chrono.MOVE);
		elif (dir == Vector2.DOWN):
			pass
	if (result != Success.No):
		append_replay(chr);
	if (result != Success.No):
		time_passes(Chrono.MOVE);
		if anything_happened():
			adjust_turn(1);
	if (result != Success.Yes):
		play_sound("bump")
	return result != Success.No;

func anything_happened(destructive: bool = true) -> bool:
	while (undo_buffer.size() <= turn):
		undo_buffer.append([]);
	for event in undo_buffer[turn]:
		if event[0] == Undo.animation_substep:
			continue;
		else:
			return true;
	undo_buffer.pop_at(turn);
	return false;

func falling_direction(actor: Actor) -> Vector2:
	# logic: floating things float up to and on top of water. neutral things float if in water. sinking things sink.
	if actor.buoyancy > 0:
		return Vector2.DOWN; #always falls
	elif actor.buoyancy == 0:
		var terrain = terrain_in_tile(actor.pos);
		if terrain.has(Tiles.Water):
			return Vector2.ZERO;
		return Vector2.DOWN;
	else: #actor.buoyancy < 0:
		var terrain = terrain_in_tile(actor.pos);
		if terrain.has(Tiles.Water):
			return Vector2.UP;
		terrain = terrain_in_tile(actor.pos + Vector2.DOWN);
		if terrain.has(Tiles.Water):
			return Vector2.ZERO;
		return Vector2.DOWN;

func time_passes(chrono: int) -> void:
	animation_substep(chrono);
	var time_actors = []
			
	if chrono < Chrono.UNDO:
		for actor in actors:
			time_actors.push_back(actor);
	
	# Decrement airborne by one (min zero).
	# AD02: Maybe this should be a +1/-1 instead of a set. Haven't decided yet. Doesn't seem to matter until strange matter.
	var has_fallen = {};
	for actor in time_actors:
		has_fallen[actor] = 0;
		if actor.airborne > 0 and actor.fall_speed() != 0:
			set_actor_var(actor, "airborne", actor.airborne - 1, chrono);
			
	# AD09: ALL actors go from airborne 2 to 1. (blue/red levels are kind of fucky without this)
	for actor in actors:
		if actor.airborne >= 2:
			set_actor_var(actor, "airborne", 1, chrono);
			
	# GRAVITY
	# For each actor in the list, in order of lowest down to highest up, repeat the following loop until nothing happens:
	# * If airborne is -1 and it COULD push-move down, set airborne to (1 for light, 0 for heavy).
	# * If airborne is 0, push-move down (unless this actor is light and already has this loop). If the push-move fails, set airborne to -1.
	time_actors.sort_custom(self, "bottom_up");
	var something_happened = true;
	var tries = 99;
	# just_moved logic for stacked actors falling together without clipping through e.g. Heavies sticky topping them down:
	# 1) Peek one time_actor ahead.
	# 1a) If it shares our pos, we're part of a stack - before we try to move, set just_moved, and keep it set if we did move.
	# 1b) If it doesn't or it's empty, then we're ending a stack or were never in a stack - unset all just_moveds at the end of the tick
	# This will probably break in some esoteric level editor cases with Heavy sticky top or boost pads, but it's good enough for my needs.
	var just_moveds = [];
	var clear_just_moveds = false;
	while (something_happened and tries > 0):
		animation_substep(chrono);
		tries -= 1;
		something_happened = false;
		var size = time_actors.size();
		for i in range(size):
			var actor = time_actors[i];
			if (actor.fall_speed() >= 0 and has_fallen[actor] >= actor.fall_speed()):
				continue;
			
			# multi-falling stack check
			if (i < (size - 1)):
				var next_actor = time_actors[i+1];
				if actor.pos != next_actor.pos:
					clear_just_moveds = true;
				else:
					actor.just_moved = true;
					just_moveds.append(actor);
			else:
				clear_just_moveds = true;
			
			var fall = falling_direction(actor);
			if actor.airborne == -1 and fall != Vector2.ZERO:
				var could_fall = try_enter(actor, fall, chrono, true, true, true);
				# we'll say that falling due to gravity onto spikes/a pressure plate makes you airborne so we try to do it, but only once
				if (could_fall != Success.No and (could_fall == Success.Yes or has_fallen[actor] <= 0)):
					if actor.floats():
						set_actor_var(actor, "airborne", 1, chrono);
					else:
						set_actor_var(actor, "airborne", 0, chrono);
					something_happened = true;
			
			if actor.airborne == 0:
				var did_fall = Success.No;
				if (fall == Vector2.ZERO):
					did_fall = Success.No;
				else:
					did_fall = move_actor_relative(actor, fall, chrono, false, true);
				
				if (did_fall != Success.No):
					something_happened = true;
					# so Heavy can break a glass block and not fall further, surprises break your fall immediately
					if (did_fall == Success.Surprise):
						has_fallen[actor] += 999;
					else:
						has_fallen[actor] += 1;
				if (did_fall != Success.Yes):
					actor.just_moved = false;
					set_actor_var(actor, "airborne", -1, chrono);
			
			if clear_just_moveds:
				clear_just_moveds = false;
				for a in just_moveds:
					a.just_moved = false;
				just_moveds.clear();
	
	#possible to leak this out the for loop
	for a in just_moveds:
		a.just_moved = false;
	
	animation_substep(chrono);
	
	# NEW (as part of AD07) post-gravity cleanups: If an actor is airborne 1 and would be grounded next fall,
	# land.
	# (UPDATE AD08: Now it's 'and the tile under you is no_push solid', so Heavy can land on Light, because
	# it's an interesting mechanic)
	# It was vaguely tolerable for Light but I don't know if it was ever a mechanic I was like 'whoo' about,
	#and now it definitely sucks.
	for actor in time_actors:
		if (actor.airborne == 0):
			var fall = falling_direction(actor);
			if fall == Vector2.ZERO:
				set_actor_var(actor, "airborne", -1, chrono);
				continue;
			var could_fall = try_enter(actor, fall, chrono, false, true, true);
			if (could_fall == Success.No):
				set_actor_var(actor, "airborne", -1, chrono);
				continue;
	
	animation_substep(chrono);
	
func bottom_up(a, b) -> bool:
	# TODO: make this tiebreak by x, then by layer or id, so I can use it as a stable sort in general?
	return a.pos.y > b.pos.y;
	
func replay_interval() -> float:
	if unit_test_mode:
		return 0.01;
	if meta_undo_a_restart_mode:
		return 0.01;
	return replay_interval;
	
func authors_replay() -> void:
	if (ui_stack.size() > 0):
		return;
	
	if (!doing_replay):
		if (!unit_test_mode):
			if (!save_file.has("authors_replay") or save_file["authors_replay"] != true):
				var modal = preload("res://AuthorsReplayModalPrompt.tscn").instance();
				ui_stack.push_back(modal);
				levelscene.add_child(modal);
				return;
	
	toggle_replay();
	
func toggle_replay() -> void:
	meta_undo_a_restart_mode = false;
	unit_test_mode = false;
	if (doing_replay):
		end_replay();
		return;
	doing_replay = true;
	replaybuttons.visible = true;
	restart();
	replay_paused = false;
	replay_turn = 0;
	next_replay = replay_timer + replay_interval();
	unit_test_mode = OS.is_debug_build() and Input.is_action_pressed(("shift"));
	
var double_unit_test_mode : bool = false;
var unit_test_mode_do_second_pass : bool = false;
	
func do_one_replay_turn() -> void:
	if (!doing_replay):
		return;
	if replay_turn >= level_replay.length():
		meta_undo_a_restart_mode = false;
		if (unit_test_mode and won and level_number < (level_list.size() - 1)):
			doing_replay = true;
			replaybuttons.visible = true;
			if (double_unit_test_mode):
				if unit_test_mode_do_second_pass:
					unit_test_mode_do_second_pass = false;
					var replay = user_replay;
					load_level(0);
					level_replay = replay;
				else:
					unit_test_mode_do_second_pass = true;
					load_level(1);
			else:
				load_level(1);
			replay_turn = 0;
			next_replay = replay_timer + replay_interval();
			return;
		else:
			if (unit_test_mode):
				floating_text("Tested up to level: " + str(level_number) + " (This is 0 indexed lol)" );
				end_replay();
			return;
	next_replay = replay_timer+replay_interval();
	var replay_char = level_replay[replay_turn];
	var old_turn = turn;
	replay_turn += 1;
	if (replay_char == "w"):
		character_move(Vector2.UP);
	elif (replay_char == "a"):
		character_move(Vector2.LEFT);
	elif (replay_char == "s"):
		character_move(Vector2.DOWN);
	elif (replay_char == "d"):
		character_move(Vector2.RIGHT);
	elif (replay_char == "z"):
		undo();
	if old_turn == turn:
		replay_turn -= 1;
		# replay contains a bump - silently delete the bump so we don't desync when trying to meta-undo it
		level_replay = level_replay.left(replay_turn) + level_replay.right(replay_turn + 1)
	
func end_replay() -> void:
	doing_replay = false;
	update_level_label();
	
func pause_replay() -> void:
	if replay_paused:
		replay_paused = false;
		floating_text("Replay unpaused");
		replay_timer = next_replay;
	else:
		replay_paused = true;
		floating_text("Replay paused");
	update_info_labels();
	
func replay_advance_turn(amount: int) -> void:
	if amount > 0:
		for _i in range(amount):
			if (replay_turn < (level_replay.length())):
				do_one_replay_turn();
			else:
				play_sound("bump");
				break;
	elif (replay_turn <= 0):
		play_sound("bump");
	else:
		var target_turn = replay_turn + amount;
		if (target_turn < 0):
			target_turn = 0;
		
		# Restart and advance the puzzle from the start if:
		# 1) voidlike_puzzle (contains void elements or the replay contains a meta undo)
		# 2) it's a long jump, and going forward from the start would be quicker
		# (currently assuming an undo is 2.1x as fast as a forward move, which seems roughly right)
		var restart_and_advance = false;
		if amount < -50 and target_turn*2.1 < -amount:
			restart_and_advance = true;
			
		if (restart_and_advance):
			var replay = level_replay;
			user_replay = ""; #to not pollute meta undo a restart buffer
			var old_muted = muted;
			muted = true;
			load_level(0);
			start_specific_replay(replay);
			for _i in range(target_turn):
				do_one_replay_turn();
			finish_animations(Chrono.TIMELESS);
			muted = old_muted;
			# weaker and slower than meta-undo
			undo_effect_strength = 0.04;
			undo_effect_per_second = undo_effect_strength*(1/0.4);
			play_sound("voidundo");
		else:
			var iterations = replay_turn - target_turn;
			for _i in range(iterations):
				var last_input = level_replay[replay_turn - 1];
				undo();
				replay_turn -= 1;
	replay_paused = true;
	update_info_labels();

func update_level_label() -> void:
	var levelnumberastext = ""
	if (is_custom):
		levelnumberastext = "CUSTOM";
	else:
		var chapter_string = str(chapter);
		if chapter_replacements.has(chapter):
			chapter_string = chapter_replacements[chapter];
		var level_string = str(level_in_chapter);
		if (level_replacements.has(level_number)):
			level_string = level_replacements[level_number];
		levelnumberastext = chapter_string + "-" + level_string;
		if (level_is_extra):
			levelnumberastext += "X";
	#levellabel.text = levelnumberastext + " - " + level_name;
	levellabel.text = level_name;
	if (level_author != "" and level_author != "Patashu"):
		levellabel.text += " (By " + level_author + ")"
	if (doing_replay):
		levellabel.text += " (REPLAY)"
		if (heavy_max_moves < 11 and light_max_moves < 11):
			if (using_controller):
				levellabel.text += " (L2/R2 ADJUST SPEED)";
			else:
				pass #there are now virtual buttons for kb+m players
	if save_file["levels"].has(level_name) and save_file["levels"][level_name].has("won") and save_file["levels"][level_name]["won"]:
		if (levelstar.next_modulates.size() > 0):
			# in the middle of a flash from just having won
			pass
		else:
			levelstar.modulate = Color(1, 1, 1, 1);
		var string_size = preload("res://standardfont.tres").get_string_size(levellabel.text);
		var label_middle = levellabel.rect_position.x + int(floor(levellabel.rect_size.x / 2));
		var string_left = label_middle - int(floor(string_size.x/2));
		levelstar.position = Vector2(string_left-14, levellabel.rect_position.y);
	else:
		levelstar.finish_animations();
		levelstar.modulate = Color(1, 1, 1, 0);
	
func update_info_labels() -> void:

	metainfolabel.text = "Turn: " + str(turn)
	
	if (doing_replay):
		replaybuttons.visible = true;
		replayturnlabel.text = "Input " + str(replay_turn) + "/" + str(level_replay.length());
		replayturnsliderset = true;
		replayturnslider.max_value = level_replay.length();
		replayturnslider.value = replay_turn;
		replayturnsliderset = false;
		if (replay_paused):
			replayspeedlabel.text = "Replay Paused";
		else:
			replayspeedlabel.text = "Speed: " + "%0.2f" % (replay_interval) + "s";
	else:
		replaybuttons.visible = false;
	
#	if (!is_custom):
#		if (level_number >= 2 and level_number <= 4):
#			if (heavy_selected):
#				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("#7FC9FF", "#FF7459");
#			else:
#				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("#FF7459", "#7FC9FF");
#
#		if tutoriallabel.visible:
#			if using_controller:
#				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("Arrows:", "D-Pad/Either Stick:");
#				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("X:", "Bottom Face Button:");
#				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("Z:", "Right Face Button:");
#				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("C:", "Top Face Button:");
#				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("R:", "Select:");
#			else:
#				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("D-Pad/Either Stick:", "Arrows:");
#				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("Bottom Face Button:", "X:");
#				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("Right Face Button:", "Z:");
#				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("Top Face Button:", "C:");
#				tutoriallabel.bbcode_text = tutoriallabel.bbcode_text.replace("Select:", "R:");

func animation_substep(chrono: int) -> void:
	animation_substep += 1;
	add_undo_event([Undo.animation_substep], chrono);

func add_to_animation_server(actor: ActorBase, animation: Array) -> void:
	while animation_server.size() <= animation_substep:
		animation_server.push_back([]);
	animation_server[animation_substep].push_back([actor, animation]);

func handle_global_animation(animation: Array) -> void:
	pass

func update_animation_server(skip_globals: bool = false) -> void:
	# don't interrupt ongoing animations
	for actor in actors:
		if actor.animations.size() > 0:
			return;
	
	# look for new animations to play
	while animation_server.size() > 0 and animation_server[0].size() == 0:
		animation_server.pop_front();
	if animation_server.size() == 0:
		# won_fade starts here
		if ((won or lost) and !won_fade_started):
			won_fade_started = true;
			if (lost):
				fade_in_lost();
			add_to_animation_server(player, [Animation.fade]);
		return;
	
	# we found new animations - give them to everyone at once
	var animations = animation_server.pop_front();
	for animation in animations:
		if animation[0] == null:
			if !skip_globals:
				handle_global_animation(animation[1]);
		else:
			animation[0].animations.push_back(animation[1]);

func floating_text(text: String) -> void:
	var label = preload("res://FloatingText.tscn").instance();
	levelscene.add_child(label);
	label.rect_position.x = 0;
	label.rect_size.x = pixel_width;
	label.rect_position.y = pixel_height/2-16;
	label.text = text;

func is_valid_replay(replay: String) -> bool:
	var replay_parts = replay.split("$");
	replay = replay_parts[replay_parts.size()-1];
	replay = replay.strip_edges();
	replay = replay.to_lower();
	if replay.length() <= 0:
		return false;
	for letter in replay:
		if !(letter in "wasdz"):
			return false;
	return true;

func start_specific_replay(replay: String) -> void:
	var replay_parts = replay.split("$");
	replay = replay_parts[replay_parts.size()-1];
	replay = replay.strip_edges();
	replay = replay.to_lower();
	if (!is_valid_replay(replay)):
		floating_text("Ctrl+V: Invalid replay");
		return;
	end_replay();
	toggle_replay();
	level_replay = replay;
	update_info_labels();

func replay_from_clipboard() -> void:
	var replay = OS.get_clipboard();
	start_specific_replay(replay);

func start_saved_replay() -> void:
	if (doing_replay):
		end_replay();
		return;
	
	var levels_save_data = save_file["levels"];
	if (!levels_save_data.has(level_name)):
		floating_text("F11: Level not beaten");
		return;
	var level_save_data = levels_save_data[level_name];
	if (!level_save_data.has("replay")):
		floating_text("F11: Level not beaten");
		return;
	var replay = level_save_data["replay"];
	start_specific_replay(replay);

func annotate_replay(replay: String) -> String:
	return level_name + "$" + "mturn=" + str(turn) + "$" + replay;

#func get_afterimage_material_for(color: Color) -> Material:
#	if (afterimage_server.has(color)):
#		return afterimage_server[color];
#	var new_material = preload("res://afterimage_shadermaterial.tres").duplicate();
#	new_material.set_shader_param("color", color);
#	afterimage_server[color] = new_material;
#	return new_material;
#
#func afterimage(actor: Actor) -> void:
#	if undo_effect_color == Color.transparent:
#		return;
#	# ok, we're mid undo.
#	var afterimage = preload("res://Afterimage.tscn").instance();
#	afterimage.actor = actor;
#	afterimage.set_material(get_afterimage_material_for(undo_effect_color));
#	underactorsparticles.add_child(afterimage);
#
#func afterimage_terrain(texture: Texture, position: Vector2, color: Color) -> void:
#	var afterimage = preload("res://Afterimage.tscn").instance();
#	afterimage.texture = texture;
#	afterimage.position = position;
#	afterimage.set_material(get_afterimage_material_for(color));
#	underactorsparticles.add_child(afterimage);
#
func last_level_of_section() -> bool:
	var chapter_standard_starting_level = chapter_standard_starting_levels[chapter+1];
	var chapter_advanced_starting_level = chapter_advanced_starting_levels[chapter];
	if (level_number+1 == chapter_standard_starting_level or level_number+1 == chapter_advanced_starting_level):
		return true;
	return false;
		
func unwin() -> void:
	floating_text("Shift+F11: Unwin");
	if (save_file["levels"].has(level_name) and save_file["levels"][level_name].has("won") and save_file["levels"][level_name]["won"]):
		puzzles_completed -= 1;
	if (save_file["levels"].has(level_name)):
		save_file["levels"][level_name].clear();
	save_game();
	update_level_label();
	
func serialize_current_level() -> String:
	# keep in sync with LevelEditor.gd serialize_current_level()
	var result = "SwimmingInCratesPuzzleStart: " + level_name + " by " + level_author + "\n";
	var level_metadata = {};
	var metadatas = ["level_name", "level_author",  "map_x_max", "map_y_max"];
	for metadata in metadatas:
		level_metadata[metadata] = self.get(metadata);
	
	# we now have to grab the original values for: terrain_layers, heavy_max_moves, light_max_moves
	# has to be kept in sync with load_level/ready_map and any custom level logic we end up adding
	var level = null;
	level = level_list[level_number].instance();
		
	var level_info = level.get_node("LevelInfo");
	level_metadata["level_replay"] = level_info.level_replay;
		
	var layers = [];
	layers.append(level);
	for child in level.get_children():
		if child is TileMap:
			layers.push_front(child);
			
	level_metadata["layers"] = layers.size();
			
	result += to_json(level_metadata);
	
	for i in layers.size():
		result += "\nLAYER " + str(i) + ":\n";
		var layer = layers[layers.size() - 1 - i];
		for y in range(map_y_max+1):
			for x in range(map_x_max+1):
				if (x > 0):
					result += ",";
				var tile = layer.get_cell(x, y);
				if tile >= 0 and tile <= 9:
					result += "0" + str(tile);
				else:
					result += str(tile);
			result += "\n";
	
	result += "SwimmingInCratesPuzzleEnd"
	level.queue_free();
	return result;
	
func copy_level() -> void:
	var result = serialize_current_level();
	floating_text("Ctrl+Shift+C: Level copied to clipboard!");
	OS.set_clipboard(result);
	
func clipboard_contains_level() -> bool:
	var clipboard = OS.get_clipboard();
	clipboard = clipboard.strip_edges();
	if clipboard.find("SwimmingInCratesPuzzleStart") >= 0 and clipboard.find("SwimmingInCratesPuzzleEnd") >= 0:
		return true
	return false
	
func deserialize_custom_level(custom: String) -> Node:
	var lines = custom.split("\n");
	for i in range(lines.size()):
		lines[i] = lines[i].strip_edges();
	
	if (lines[0].find("SwimmingInCratesPuzzleStart") == -1):
		floating_text("Assert failed: Line 1 should start SwimmingInCratesPuzzleStart");
		return null;
	if (lines[(lines.size() - 1)] != "SwimmingInCratesPuzzleEnd"):
		floating_text("Assert failed: Last line should be SwimmingInCratesPuzzleEnd");
		return null;
	var json_parse_result = JSON.parse(lines[1])
	
	var result = null;
	
	if json_parse_result.error == OK:
		var data = json_parse_result.result;
		if typeof(data) == TYPE_DICTIONARY:
			result = data;
	
	if (result == null):
		floating_text("Assert failed: Line 2 should be a valid dictionary")
		return null;
	
	var metadatas = ["level_name", "level_author", "level_replay", "map_x_max", "map_y_max",
	"layers"];
	
	for metadata in metadatas:
		if (!result.has(metadata)):
			floating_text("Assert failed: Line 2 is missing " + metadata);
			return null;
	
	var layers = result["layers"];
	var xx = 2;
	var xxx = result["map_y_max"] + 1 + 1 + 1; #1 for the header, 1 for the off-by-one, 1 for the blank line
	var terrain_layers = [];
	var terrainmap = null;
	for i in range(layers):
		var tile_map = TileMap.new();
		tile_map.tile_set = preload("res://DefaultTiles.tres");
		tile_map.cell_size = Vector2(cell_size, cell_size);
		var a = xx + xxx*i;
		var header = lines[a];
		if (header != "LAYER " + str(i) + ":"):
			floating_text("Assert failed: Line " + str(a) + " should be 'LAYER " + str(i) + ":'.");
			return null;
		for j in range(result["map_y_max"] + 1):
			var layer_line = lines[a + 1 + j];
			var layer_cells = layer_line.split(",");
			for k in range(layer_cells.size()):
				var layer_cell = layer_cells[k];
				tile_map.set_cell(k, j, int(layer_cell));
		terrain_layers.append(tile_map);
		tile_map.update_bitmask_region();
	terrainmap = terrain_layers[0];
	for i in range(layers - 1):
		terrainmap.add_child(terrain_layers[i + 1]);
	
	var level_info = Node.new();
	level_info.set_script(preload("res://levels/LevelInfo.gd"));
	level_info.name = "LevelInfo";
	for metadata in metadatas:
		level_info.set(metadata, result[metadata]);
	terrainmap.add_child(level_info);
			
	return terrainmap;
	
func load_custom_level(custom: String) -> void:
	var level = deserialize_custom_level(custom);
	if level == null:
		return;
	
	is_custom = true;
	custom_string = custom;
	var level_info = level.get_node("LevelInfo");
	level_name = level_info["level_name"];
	level_author = level_info["level_author"];
	level_replay = level_info["level_replay"];
	map_x_max = int(level_info["map_x_max"]);
	map_y_max = int(level_info["map_y_max"]);
	
	levelfolder.remove_child(terrainmap);
	terrainmap.queue_free();
	levelfolder.add_child(level);
	terrainmap = level;
	terrain_layers.clear();
	terrain_layers.append(terrainmap);
	for child in terrainmap.get_children():
		if child is TileMap:
			terrain_layers.push_front(child);
	
	ready_map();
	
func give_up_and_restart() -> void:
	is_custom = false;
	custom_string = "";
	restart();
	
func paste_level() -> void:
	var clipboard = OS.get_clipboard();
	clipboard = clipboard.strip_edges();
	end_replay();
	load_custom_level(clipboard);
	
func adjust_next_replay_time(old_replay_interval: float) -> void:
	next_replay += replay_interval - old_replay_interval;
	
var last_dir_release_times = [0, 0, 0, 0];
	
func _process(delta: float) -> void:
	if (Input.is_action_just_pressed("any_controller") or Input.is_action_just_pressed("any_controller_2")) and !using_controller:
		using_controller = true;
		menubutton.text = "Menu (Start)";
		menubutton.rect_position.x = 222;
		update_info_labels();
	
	if Input.is_action_just_pressed("any_keyboard") and using_controller:
		using_controller = false;
		menubutton.text = "Menu (Esc)";
		menubutton.rect_position.x = 226;
		menubutton.rect_size.x = 60;
		update_info_labels();
	
	#hysteresis: dynamically update dead zone based on if a direction is currently held or not
	#(this should happen even when ui_stack is filled so it applies to menus as well)
	#debouncing: if the player uses a controller to re-press a direction within (debounce_ms) ms,
	#allow it but in gameplay code ignore movement this frame
	#(this means debouncing doesn't work in menus since I don't control focus logic.)
	#(maybe it's somehow possible another way?)
	var get_debounced = false;
	if (using_controller):
		if (!save_file.has("deadzone")):
			save_file["deadzone"] = InputMap.action_get_deadzone("ui_up");
		if (!save_file.has("debounce")):
			save_file["debounce"] = 40;
		
		var normal = save_file["deadzone"];
		var debounce_ms = save_file["debounce"];
		var held = normal*0.95;
		var dirs = ["ui_up", "ui_down", "ui_left", "ui_right"];
		for i in range(dirs.size()):
			
			var dir = dirs[i];
			var current_time = Time.get_ticks_msec();
			
			if Input.is_action_just_pressed(dir):
				if ((current_time - debounce_ms) < last_dir_release_times[i]):
					get_debounced = true;
					#floating_text("get debounced");
			elif Input.is_action_just_released(dir):
				last_dir_release_times[i] = current_time;
				
			if Input.is_action_pressed(dir):
				InputMap.action_set_deadzone(dir, held);
			else:
				InputMap.action_set_deadzone(dir, normal);
				
		#tutoriallabel.text = str(Input.get_action_raw_strength("ui_up"));
			
	sounds_played_this_frame.clear();
	
	if (won):
		won_cooldown += delta;
	
	if (doing_replay and !replay_paused):
		replay_timer += delta;
		
	# handle current music volume
	var value = save_file["music_volume"];
	music_speaker.volume_db = value + music_discount;
	if fadeout_timer < fadeout_timer_max:
		fadeout_timer += delta;
		if (fadeout_timer >= fadeout_timer_max):
			play_next_song();
		else:
			music_speaker.volume_db = music_speaker.volume_db - 30*(fadeout_timer/fadeout_timer_max);
		
	# duck when a fanfare is playing. this might need tweaking...
	var new_fanfare_duck_db = 0;
	if (lost_speaker.playing and lost_speaker.volume_db > -30):
		new_fanfare_duck_db += lost_speaker.volume_db + 30;
	if (won_speaker.playing and won_speaker.volume_db > -30):
		new_fanfare_duck_db += won_speaker.volume_db + 10; # try ducking less for won
	if (new_fanfare_duck_db > 0):
		fanfare_duck_db = new_fanfare_duck_db;
	else:
		fanfare_duck_db -= delta*100;
	if (fanfare_duck_db < 0):
		fanfare_duck_db = 0;
	music_speaker.volume_db = music_speaker.volume_db - fanfare_duck_db;
		
	if (sky_timer < sky_timer_max):
		sky_timer += delta;
		if (sky_timer > sky_timer_max):
			sky_timer = sky_timer_max;
		# rgb lerp (I tried hsv lerp but the hue changing feels super nonlinear)
		var current_r = lerp(old_sky.r, target_sky.r, sky_timer/sky_timer_max);
		var current_g = lerp(old_sky.g, target_sky.g, sky_timer/sky_timer_max);
		var current_b = lerp(old_sky.b, target_sky.b, sky_timer/sky_timer_max);
		current_sky = Color(current_r, current_g, current_b);
		VisualServer.set_default_clear_color(current_sky);
		
	if ui_stack.size() == 0:
		var dir = Vector2.ZERO;
		
		if (doing_replay and replay_timer > next_replay):
			do_one_replay_turn();
			update_info_labels();
		
		if (won and Input.is_action_just_pressed("ui_accept")):
			# must be kept in sync with Menu
			start_saved_replay();
			update_info_labels();
#			end_replay();
#			if (in_insight_level):
#				gain_insight();
#			elif last_level_of_section():
#				level_select();
#			else:
#				load_level(1);
		elif (Input.is_action_just_pressed("escape")):
			#end_replay(); #done in escape();
			escape();
		#elif (Input.is_action_just_pressed("previous_level")
		#and (!using_controller or ((!doing_replay or won) and (!won or won_cooldown > 0.5)))):
		#	pass
#			if (!using_controller or won or lost or meta_turn <= 0):
#				end_replay();
#				load_level(-1);
#			else:
#				play_sound("bump");
		#elif (Input.is_action_just_pressed("next_level")
		#and (!using_controller or ((!doing_replay or won) and (!won or won_cooldown > 0.5)))):
		#	pass
#			if (!using_controller or won or lost or meta_turn <= 0):
#				end_replay();
#				load_level(1);
#			else:
#				play_sound("bump");
		elif (Input.is_action_just_pressed("mute")):
			toggle_mute();
		elif (doing_replay and Input.is_action_just_pressed("replay_back1")):
			replay_advance_turn(-1);
		elif (doing_replay and Input.is_action_just_pressed("replay_fwd1")):
			replay_advance_turn(1);
		elif (doing_replay and Input.is_action_just_pressed("replay_pause")):
			pause_replay();
		elif (Input.is_action_just_pressed("speedup_replay")):
			var old_replay_interval = replay_interval;
			if (Input.is_action_pressed("shift")):
				replay_interval = 0.015;
			else:
				replay_interval *= (2.0/3.0);
			replayspeedsliderset = true;
			replayspeedslider.value = 100 - floor(replay_interval * 100);
			replayspeedsliderset = false;
			adjust_next_replay_time(old_replay_interval);
			update_info_labels();
		elif (Input.is_action_just_pressed("slowdown_replay")):
			var old_replay_interval = replay_interval;
			if (Input.is_action_pressed("shift")):
				replay_interval = 0.5;
			elif replay_interval < 0.015:
				replay_interval = 0.015;
			else:
				replay_interval /= (2.0/3.0);
			if (replay_interval > 2.0):
				replay_interval = 2.0;
			replayspeedsliderset = true;
			replayspeedslider.value = 100 - floor(replay_interval * 100);
			replayspeedsliderset = false;
			adjust_next_replay_time(old_replay_interval);
			update_info_labels();
		elif (Input.is_action_just_pressed("start_saved_replay")):
			if (Input.is_action_pressed("shift")):
				# must be kept in sync with Menu
				if (won):
					if (!save_file["levels"].has(level_name)):
						save_file["levels"][level_name] = {};
					save_file["levels"][level_name]["replay"] = annotate_replay(user_replay);
					save_game();
					floating_text("Shift+F11: Replay force saved!");
			else:
				# must be kept in sync with Menu
				start_saved_replay();
				update_info_labels();
		elif (Input.is_action_just_pressed("start_replay")):
			# must be kept in sync with Menu
			authors_replay();
			update_info_labels();
		elif (Input.is_action_pressed("ctrl") and Input.is_action_just_pressed("copy")):
			if (Input.is_action_pressed("shift")):
				copy_level();
			else:
				# must be kept in sync with Menu
				OS.set_clipboard(annotate_replay(user_replay));
				floating_text("Ctrl+C: Replay copied");
		elif (Input.is_action_pressed("ctrl") and Input.is_action_just_pressed("paste")):
			# must be kept in sync with Menu
			if (clipboard_contains_level()):
				paste_level();
			else:
				replay_from_clipboard();
		elif (Input.is_action_just_pressed("undo")):
			end_replay();
			undo();
			update_info_labels();
		elif (Input.is_action_just_pressed("restart")):
			# must be kept in sync with Menu "restart"
			end_replay();
			restart();
			update_info_labels();
		#elif (Input.is_action_just_pressed("level_select")):
		#	pass
			#level_select();
		#elif (Input.is_action_just_pressed("gain_insight")):
		#	pass
			#end_replay();
			#gain_insight();
		elif (!get_debounced):
			if (Input.is_action_just_pressed("ui_left")):
				dir = Vector2.LEFT;
			if (Input.is_action_just_pressed("ui_right")):
				dir = Vector2.RIGHT;
			if (Input.is_action_just_pressed("ui_up")):
				dir = Vector2.UP;
			if (Input.is_action_just_pressed("ui_down")):
				dir = Vector2.DOWN;
				
			if dir != Vector2.ZERO:
				end_replay();
				character_move(dir);
				update_info_labels();
		
	update_targeter();
	update_animation_server();

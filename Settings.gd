extends Node2D
class_name Settings

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var holder : Control = get_node("Holder");
onready var pointer : Sprite = get_node("Holder/Pointer");
onready var okbutton : Button = get_node("Holder/OkButton");
onready var pixelscale : SpinBox = get_node("Holder/PixelScale");
onready var vsync : CheckBox = get_node("Holder/VSync");
onready var sfxslider : HSlider = get_node("Holder/SFXSlider");
onready var fanfareslider : HSlider = get_node("Holder/FanfareSlider");
onready var musicslider : HSlider = get_node("Holder/MusicSlider");
onready var animationslider : HSlider = get_node("Holder/AnimationSlider");
onready var labelsfx : Label = get_node("Holder/LabelSFX");
onready var labelfanfare : Label = get_node("Holder/LabelFanfare");
onready var labelmusic : Label = get_node("Holder/LabelMusic");
onready var labelanimation : Label = get_node("Holder/LabelAnimation");
onready var puzzlecheckerboard : CheckBox = get_node("Holder/PuzzleCheckerboard");
onready var virtualbuttons : SpinBox = get_node("Holder/VirtualButtons");

func floating_text(text: String) -> void:
	var label = preload("res://FloatingText.tscn").instance();
	get_node("Holder").add_child(label);
	label.rect_position.x = 0;
	label.rect_size.x = holder.rect_size.x;
	label.rect_position.y = holder.rect_size.y/2-16;
	label.text = text;

func _ready() -> void:
	okbutton.connect("pressed", self, "destroy");
	okbutton.grab_focus();
	if (gamelogic.save_file.has("vsync_enabled")):
		vsync.pressed = gamelogic.save_file["vsync_enabled"];
	if (gamelogic.save_file.has("pixel_scale")):
		pixelscale.value = gamelogic.save_file["pixel_scale"];
	if (gamelogic.save_file.has("sfx_volume")):
		sfxslider.value = gamelogic.save_file["sfx_volume"];
		updatelabelsfx(sfxslider.value);
	if (gamelogic.save_file.has("fanfare_volume")):
		fanfareslider.value = gamelogic.save_file["fanfare_volume"];
		updatelabelfanfare(fanfareslider.value);
	if (gamelogic.save_file.has("music_volume")):
		musicslider.value = gamelogic.save_file["music_volume"];
		updatelabelmusic(musicslider.value);
	if (gamelogic.save_file.has("animation_speed")):
		animationslider.value = gamelogic.save_file["animation_speed"];
		updatelabelanimation(animationslider.value);
	if (gamelogic.save_file.has("puzzle_checkerboard")):
		puzzlecheckerboard.pressed = gamelogic.save_file["puzzle_checkerboard"];
	if (gamelogic.save_file.has("virtual_buttons")):
		virtualbuttons.value = gamelogic.save_file["virtual_buttons"];
	
	vsync.connect("pressed", self, "_vsync_pressed");
	pixelscale.connect("value_changed", self, "_pixelscale_value_changed");
	sfxslider.connect("value_changed", self, "_sfxslider_value_changed");
	fanfareslider.connect("value_changed", self, "_fanfareslider_value_changed");
	musicslider.connect("value_changed", self, "_musicslider_value_changed");
	animationslider.connect("value_changed", self, "_animationslider_value_changed");
	puzzlecheckerboard.connect("pressed", self, "_puzzlecheckerboard_pressed");
	virtualbuttons.connect("value_changed", self, "_virtualbuttons_value_changed");

func _vsync_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["vsync_enabled"] = vsync.pressed;
	OS.vsync_enabled = vsync.pressed;

func _pixelscale_value_changed(value: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["pixel_scale"] = value;
	gamelogic.setup_resolution();
	
func _sfxslider_value_changed(value: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["sfx_volume"] = value;
	gamelogic.setup_volume();
	gamelogic.play_sound("switch");
	updatelabelsfx(value);
	
func _fanfareslider_value_changed(value: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["fanfare_volume"] = value;
	gamelogic.setup_volume();
	gamelogic.play_won("winentwined");
	updatelabelfanfare(value);
		
func _musicslider_value_changed(value: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["music_volume"] = value;
	gamelogic.setup_volume();
	updatelabelmusic(value);
	
func _animationslider_value_changed(value: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["animation_speed"] = value;
	gamelogic.setup_animation_speed();
	updatelabelanimation(value);

func _puzzlecheckerboard_pressed() -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["puzzle_checkerboard"] = puzzlecheckerboard.pressed;
	gamelogic.checkerboard.visible = puzzlecheckerboard.pressed;

func _virtualbuttons_value_changed(value: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	gamelogic.save_file["virtual_buttons"] = value;
	gamelogic.setup_virtual_buttons();
	
func updatelabelsfx(value: int) -> void:
	if (value <= -30):
		labelsfx.text = "SFX Volume: Muted";
	else:
		labelsfx.text = "SFX Volume: " + str(value) + " dB";
		
func updatelabelfanfare(value: int) -> void:
	if (value <= -30):
		labelfanfare.text = "Fanfare Volume: Muted";
	else:
		labelfanfare.text = "Fanfare Volume: " + str(value) + " dB";
		
func updatelabelmusic(value: int) -> void:
	if (value <= -30):
		labelmusic.text = "Music Volume: Muted";
	else:
		labelmusic.text = "Music Volume: " + str(value) + " dB";

func updatelabelanimation(value: float) -> void:
	labelanimation.text = "Animation Speed: " + ("%0.1f" % value) + "x";

func destroy() -> void:
	gamelogic.save_game();
	self.queue_free();
	gamelogic.ui_stack.erase(self);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	if (Input.is_action_just_released("escape")):
		destroy();
	if (Input.is_action_just_pressed("ui_cancel")):
		destroy();
		
	var focus = holder.get_focus_owner();
	if (focus == null):
		okbutton.grab_focus();
		focus = okbutton;
		
	# spinbox correction hack
	var parent = focus.get_parent();
	if parent is SpinBox:
		focus = parent;

	var focus_middle_x = round(focus.rect_position.x + focus.rect_size.x / 2);
	pointer.position.y = round(focus.rect_position.y + focus.rect_size.y / 2);
	if (focus_middle_x > holder.rect_size.x / 2):
		pointer.texture = preload("res://assets/tutorial_arrows/LeftArrow.tres");
		pointer.position.x = round(focus.rect_position.x + focus.rect_size.x + 12);
	else:
		pointer.texture = preload("res://assets/tutorial_arrows/RightArrow.tres");
		pointer.position.x = round(focus.rect_position.x - 12);

func _draw() -> void:
	draw_rect(Rect2(0, 0,
	gamelogic.pixel_width, gamelogic.pixel_height), Color(0, 0, 0, 0.5), true);

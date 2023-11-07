extends Node2D
class_name LevelInfoEdit

onready var gamelogic = get_node("/root/LevelScene").gamelogic;
onready var holder : Control = get_node("Holder");
onready var pointer : Sprite = get_node("Holder/Pointer");
onready var okbutton : Button = get_node("Holder/OkButton");
onready var levelname : TextEdit = get_node("Holder/LevelName");
onready var levelauthor : TextEdit = get_node("Holder/LevelAuthor");
onready var levelreplay : TextEdit = get_node("Holder/LevelReplay");
onready var wiring : TextEdit = get_node("Holder/Wiring");

func _ready() -> void:
	okbutton.connect("pressed", self, "destroy");
	okbutton.grab_focus();
	
	var parent = get_parent();
	
	levelname.text = parent.level_info.level_name;
	levelauthor.text = parent.level_info.level_author;
	levelreplay.text = parent.level_info.level_replay;
	wiring.text = parent.level_info.wiring;

func destroy() -> void:
	var parent = get_parent();
	
	parent.level_info.level_name = levelname.text;
	parent.level_info.level_author = levelauthor.text;
	parent.level_info.level_replay = levelreplay.text;
	parent.level_info.wiring = wiring.text;
	
	self.queue_free();
	gamelogic.ui_stack.erase(self);

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (gamelogic.ui_stack.size() > 0 and gamelogic.ui_stack[gamelogic.ui_stack.size() - 1] != self):
		return;
	
	if (Input.is_action_just_released("escape")):
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

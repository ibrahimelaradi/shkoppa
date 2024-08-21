@tool
class_name PlayingCard;
extends AnimatedSprite2D

#region Exported Settings
@export_group("Card Settings")
@export_enum("spades", "hearts", "clubs", "diamonds") var card_class = "spades";
@export_range(1, 10) var card_no = 1;

@export_group("Back Settings")
@export_range(1, 15) var back_type: int = 1;
@export var face_down = false:
	set(value):
		face_down = value;
		if not Engine.is_editor_hint():
			_sync_visuals();

@export_group("Selection")
@export var card_size := Vector2(140, 190):
	set(value):
		card_size = value;
		queue_redraw();
@export var selected := false:
	set(value):
		selected = value;
		queue_redraw();

func _draw():
	if selected:
		draw_rect(Rect2(-card_size/2, card_size), Color.GOLDENROD, false, 8);
	pass;
#endregion

#region Visual Sync
var value: String:
	get:
		return card_class[0] + str(card_no);
	set(value):
		if not validate_value(value):
			push_error("Invalid card value " + str(value));
			return;
		
		match value[0]:
			"s": card_class = "spades";
			"d": card_class = "diamonds";
			"c": card_class = "clubs";
			"h": card_class = "hearts";
		card_no = value.substr(1).to_int();
		if not Engine.is_editor_hint():
			_sync_visuals();

func _sync_visuals():
	if face_down:
		animation = "back";
		frame = back_type;
	else:
		animation = card_class;
		frame = card_no - 1;

static func validate_value(value: String) -> bool:
	if not ["s", "h", "c", "d"].has(value[0]):
		return false;
	
	var n = value.substr(1);
	if not n.is_valid_int() or n.to_int() < 1 or n.to_int() > 10:
		return false;
	
	return true;
#endregion

@onready var input_listener: InputListener = $InputListener;

func _process(delta):
	if Engine.is_editor_hint():
		_sync_visuals();

#region Utils
static func parse_no(value: String) -> int:
	assert(validate_value(value), "Invalid value (" + value + ")");
	return value.substr(1).to_int();
static func parse_class(value: String) -> String:
	assert(validate_value(value), "Invalid value (" + value + ")");
	match value[0]:
		"s": return "spades";
		"d": return "diamonds";
		"c": return "clubs";
		_: return "hearts";
static func get_priority(value: String) -> int:
	var priority = 1;
	var card_class = parse_class(value);
	var card_no = parse_no(value);
	
	if card_class == "diamonds":
		priority += 2;
	
	if card_no == 7:
		priority += 2;
	elif card_no == 6:
		priority += 1;
	
	return priority;
#endregion

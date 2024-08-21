class_name InputListener
extends Area2D

@export_range(0.0, 1.0) var click_interval = 0.1;

var parent: Node2D;

func _ready():
	parent = get_parent();
	assert(parent != null && parent is Node2D, "InputListener must have a parent, and must inherit from Node2D!");
	mouse_entered.connect(_on_mouse_enter);
	mouse_exited.connect(_on_mouse_exit);

var is_hovering: bool = false;
signal click(bool);
signal double_click;

func _handle_mouse_input(event: InputEventMouseButton):
	if event.button_index != MOUSE_BUTTON_LEFT: return;
	if !is_hovering: return;
	
	if event.double_click:
		double_click.emit();
		return;
	
	click.emit(event.pressed);

func _handle_touch_input(event: InputEventScreenTouch):
	var col = get_node("Collision") as CollisionShape2D;
	if !col.shape.get_rect().has_point(event.position): return;
	
	if event.double_tap:
		double_click.emit();
		return;
	
	click.emit(event.pressed);

func _unhandled_input(event):
	if event is InputEventMouseButton:
		_handle_mouse_input(event);
	elif event is InputEventScreenTouch:
		_handle_touch_input(event);

func _on_mouse_enter():
	is_hovering = true;

func _on_mouse_exit():
	is_hovering = false;

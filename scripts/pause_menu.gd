extends CanvasLayer

@export var pause_process = true;

@onready var pause_hud = $pause_hud
@onready var pause_button = $pause

func _ready():
	pause_button.visible = true;
	pause_hud.visible = false;

func _pause():
	if pause_process:
		get_tree().paused = true;
	pause_button.visible = false;
	pause_hud.visible = true;

func _unpause():
	if pause_process:
		get_tree().paused = false;
	pause_button.visible = true;
	pause_hud.visible = false;

func _on_pause_pressed():
	_pause();


func _on_continue_pressed():
	_unpause();


func _on_exit_pressed():
	_unpause();
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn");

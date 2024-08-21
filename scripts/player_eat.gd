class_name PlayerEat
extends Node2D

@export var stacked_cards_speed = 0.1;
@export var main_card_speed = 0.15;
@export var stacked_cards_stagger = 0.08;
@export var idle_duration = 0.4;
@export var ending_swipe_speed = 0.14;

var eaten: Array[String];
var with: String;

var eaten_start_positions: Array[Vector2];
var with_start_position: Vector2;

@onready var card_scene = preload("res://scenes/playing_card.tscn");

func _ready():
	assert(with != null and PlayingCard.validate_value(with), "Invalid card value in <with>");
	assert(with_start_position != null, "Invalid value in <with_start_position>");
	assert(eaten != null and eaten.all(func(value): return PlayingCard.validate_value(value)), "Invalid card value in <eaten>");
	assert(eaten_start_positions != null and len(eaten_start_positions) == len(eaten), "Invalid values in <eaten_start_positions>");

func _instantiate_card(value: String) -> PlayingCard:
	var instance = card_scene.instantiate();
	instance.value = value;
	return instance;

func start():
	var with_instance = _instantiate_card(with);
	add_child(with_instance);
	with_instance.position = to_local(with_start_position);
	with_instance.z_index = len(eaten) + 1;
	var t1 = with_instance.create_tween();
	t1.set_parallel(true);
	t1.tween_property(with_instance, "position", Vector2.ZERO + Vector2.RIGHT * 25, main_card_speed);
	
	for i in range(len(eaten)):
		var card = eaten[i];
		var pos = eaten_start_positions[i];
		var instance = _instantiate_card(card);
		add_child(instance);
		instance.z_index = len(eaten) - i;
		instance.position = to_local(pos);
		
		var t2 = instance.create_tween();
		t2.set_parallel(true);
		t2.tween_property(instance, "position", Vector2.LEFT * 10 * i, stacked_cards_speed);
		await t2.tween_interval(stacked_cards_stagger).finished;
	
	var t3 = create_tween()
	t3.tween_interval(len(eaten) * stacked_cards_speed + main_card_speed + stacked_cards_stagger + idle_duration);
	t3.tween_property(self, "position", position + Vector2.LEFT * get_viewport_rect().size.x, ending_swipe_speed);
	
	await t3.finished;
	
	queue_free();

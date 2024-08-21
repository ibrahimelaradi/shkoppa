class_name Hand;
extends Node2D;

@export var card_peek_offset := 40;
@export var card_size := Vector2(140, 190);
@export var card_gap := 5.0;

var player: Player;

@onready var playing_card_scene = preload("res://scenes/playing_card.tscn");

signal card_added(PlayingCard);

func _init_player():
	player = get_parent();
	assert(player is Player, "Parent of Hand node must be a Player!");
	
	player.card_added.connect(_on_card_added);
	player.card_removed.connect(_on_card_removed);
	player.card_thrown.connect(_on_card_throw);

func _ready():
	_init_player();

func _animate_cards(stagger: bool = false):
	var card_count = get_child_count();
	var viewport_width = get_viewport_rect().size.x;
	var gap = min(
		viewport_width / float(card_count),
		card_size.x + card_gap
	);
	var start_x = -float(card_count - 1) / 2 * gap;
	
	for i in range(card_count):
		var target_position = Vector2(
			start_x + i * gap,
			0.0 - card_peek_offset
		);
		var card = get_child(i);
		if card.position == target_position: continue;
		
		var tween = card.create_tween();
		tween.set_parallel(true);
		tween.tween_property(card, "position", target_position, 0.12);
		
		if stagger:
			await tween.tween_interval(0.075).finished;

func _animate_card_out(card: PlayingCard):
	var tween = card.create_tween()
	tween.tween_property(card, "position", Vector2(0, card_size.y/2), 0.05);
	await tween.finished;
	remove_child(card);
	_animate_cards();

func _on_card_added(card: String):
	var instance: PlayingCard = playing_card_scene.instantiate();
	instance.value = card;
	add_child(instance);
	instance.position = Vector2(0, card_size.y);
	_animate_cards(true);
	card_added.emit(instance);

func _get_card_instance(card: String) -> PlayingCard:
	var matching = get_children().filter(func(ins): return ins is PlayingCard and ins.value == card);
	return null if matching.is_empty() else matching[0];

func _on_card_removed(card: String):
	var instance = _get_card_instance(card);
	assert(instance != null, "Failed to find card with value of " + card);
	remove_child(instance);
	instance.queue_free();
	_animate_cards();

func _on_card_throw(card: String):
	var instance = _get_card_instance(card);
	assert(instance != null, "Failed to find card with value of " + card);
	remove_child(instance);
	instance.queue_free();
	_animate_cards();

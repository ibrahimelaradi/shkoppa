class_name Controller
extends Node

var player: Player;
var hand: Hand;
var pile: Pile;

var selected: Array[String] = [];

@onready var eat_scene = preload("res://scenes/player_eat.tscn");

func _init_player():
	player = get_parent();
	assert(player != null and player is Player, "Controller must have a parent of type Player");

func _init_hand():
	hand = player.get_node("Hand");
	assert(hand != null and hand is Hand, "Player must have a child node of type Hand");
	
	hand.card_added.connect(_on_card_added_to_hand);

func _init_pile():
	pile = player.get_parent().get_node("Pile");
	assert(pile != null and pile is Pile, "No Pile found");
	
	pile.card_added.connect(_on_card_added_to_pile);

func _ready():
	_init_player();
	_init_hand();
	_init_pile();

func _eat(cards: Array, with: String):
	var eaten = Array(cards, TYPE_STRING, &"", null);
	var eaten_positions = [];
	
	for card in eaten:
		eaten_positions.append(pile.get_card_position(card));
		pile.remove_card(card);
	
	var with_position = player.get_card_position(with);
	player.remove_card(with);
	
	var eat_instance = eat_scene.instantiate();
	eat_instance.eaten = eaten.duplicate();
	eat_instance.with = with;
	eat_instance.eaten_start_positions = Array(eaten_positions, TYPE_VECTOR2, &"", null);
	eat_instance.with_start_position = with_position;
	
	player.add_child(eat_instance);
	
	eat_instance.position = Vector2.LEFT * player.get_viewport_rect().size.x / 4 + Vector2.UP * 180;
	eat_instance.start();
	
	eaten.append(with);
	
	if pile.is_empty():
		player.add_eat(eaten, PlayingCard.parse_no(with));
	else:
		player.add_eat(eaten);

func _try_auto_eat(card: PlayingCard) -> bool:
	var possibilities = pile.get_possible_eats(card.card_no);
	
	if possibilities.is_empty():
		return false;
	
	if len(possibilities) == 1:
		_eat(possibilities[0], card.value);
		return true;
	var best = possibilities[0];
	var priority = best.reduce(func(acc, curr): return acc + PlayingCard.get_priority(curr), 0);
	
	for possibility in possibilities:
		var current_priority = possibility.reduce(func(acc, curr): return acc + PlayingCard.get_priority(curr), 0);
		if current_priority > priority:
			best = possibility;
	
	_eat(best, card.value);
	return true;

func _handle_card_select(card: PlayingCard):
	var pile_selection = pile.get_selected();
	if pile_selection.is_empty() and _try_auto_eat(card):
		player.played.emit();
		return;
	elif pile_selection.is_empty():
		pile.throw_card(card.value, card.global_position);
		player.throw_card(card.value);
		player.played.emit();
		return;
	
	var selection_sum = pile_selection.reduce(func(acc: int, value: String): return acc + PlayingCard.parse_no(value), 0);
	if selection_sum != card.card_no:
		print("Sum of cards selected from pile (" + str(selection_sum) + ") is not equal to selected hand card value (" + str(card.card_no) + ")");
		return;
	
	
	_eat(pile_selection, card.value);
	player.played.emit();

func _create_hand_card_dclick_listener(card: PlayingCard):
	return func():
		if player.is_turn:
			print(card.value + " clicked");
			_handle_card_select(card);

func _create_pile_card_click_listener(card: PlayingCard):
	return func(down: bool):
		if down and player.is_turn:
			print(card.value + " clicked");
			card.selected = !card.selected;

func _on_card_added_to_hand(card: PlayingCard):
	card.input_listener.double_click.connect(_create_hand_card_dclick_listener(card));

func _on_card_added_to_pile(card: PlayingCard):
	card.input_listener.click.connect(_create_pile_card_click_listener(card));

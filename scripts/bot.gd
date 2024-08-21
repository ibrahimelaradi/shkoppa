extends Node

var player: Player;
var hand: Hand;
var pile: Pile;

@onready var eat_scene = preload("res://scenes/player_eat.tscn");

func _init_player():
	player = get_parent();
	assert(player != null and player is Player, "Controller must have a parent of type Player");

func _init_pile():
	pile = player.get_parent().get_node("Pile");
	assert(pile != null and pile is Pile, "No Pile found");

func _ready():
	_init_player();
	_init_pile();

var play_lock := false;

func _process(delta):
	if player.is_turn and !play_lock:
		play_lock = true;
		_play();
	if !player.is_turn:
		play_lock = false;

func _eat(cards: Array, with: String):
	var eaten = Array(cards, TYPE_STRING, &"", null);
	var eaten_positions = [];
	
	for card in eaten:
		eaten_positions.append(pile.get_card_position(card));
		pile.remove_card(card);
	
	var with_position = Vector2.DOWN * 190/2;
	player.remove_card(with);
	
	var eat_instance = eat_scene.instantiate();
	eat_instance.eaten = eaten.duplicate();
	eat_instance.with = with;
	eat_instance.eaten_start_positions = Array(eaten_positions, TYPE_VECTOR2, &"", null);
	eat_instance.with_start_position = with_position;
	
	player.add_child(eat_instance);
	
	eat_instance.position = Vector2.LEFT * player.get_viewport_rect().size.x / 4 + Vector2.DOWN * 180;
	eat_instance.start();
	
	eaten.append(with);
	
	if pile.is_empty():
		player.add_eat(eaten, PlayingCard.parse_no(with));
	else:
		player.add_eat(eaten);

func _play():
	await get_tree().create_timer(1).timeout;
	
	var with: String = "";
	var best_possibility: Array = [];
	var best_priority = 0;
	
	for card in player.hand:
		var possibilities = pile.get_possible_eats(PlayingCard.parse_no(card));
		if possibilities.is_empty(): continue;
		
		for possibility in possibilities:
			var priority = possibility.reduce(func(acc, card): return acc + PlayingCard.get_priority(card), 0);
			if priority > best_priority:
				with = card;
				best_possibility = possibility;
				best_priority = priority;
				continue;
	
	if with == "":
		player.hand.sort_custom(func(a, b): return PlayingCard.parse_no(a) < PlayingCard.parse_no(b));
		var smallest_card = player.hand[0];
		player.throw_card(smallest_card);
		pile.throw_card(smallest_card, player.position);
		player.played.emit();
		return;
	
	_eat(best_possibility, with);
	
	player.played.emit();




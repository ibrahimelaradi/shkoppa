extends Node;

@export var deck: Deck;
@export var pile: Pile;
@export var players: Array[Player];
@export var initial_winning_score: int = 41;

var last_eater: Player;
var current_winning_score: int;
var scores = [0, 0];
var winner: Array[Player] = [];

func _init_deck():
	if deck == null:
		deck = get_node_or_null("Deck");
	assert(deck != null, "Deck is not assigned, failed to find in scene tree!");

func _init_players():
	assert(len(players) == 2 or len(players) == 4, "Must assign 2 or 4 players to the game!");
	for player in players:
		player.played.connect(_next);
		player.ate.connect(func(eat):
			last_eater = player);

func _init_pile():
	if pile == null:
		pile = get_node_or_null("Pile");
	assert(pile != null and pile is Pile, "Must have a node of type Pile!");

func _ready():
	_init_deck();
	_init_players();
	_init_pile();
	_start_game();
	current_winning_score = initial_winning_score;

func _start_game():
	deck.shuffle();
	_deal_from_deck(true);
	_rotate_turns();

# Returns true if game is over
func _check_scores_threshold() -> bool:
	var breaking_threshold = current_winning_score - (current_winning_score % 10);
	
	if scores[0] >= current_winning_score and scores[1] < breaking_threshold:
		winner = [players[0]];
		return true;
	
	if scores[0] < breaking_threshold and scores[1] >= current_winning_score:
		winner = [players[1]];
		return true;
	
	if scores[0] >= breaking_threshold and scores[1] >= breaking_threshold:
		current_winning_score += 10;
	
	return false;
	

# Returns true if game is over
func _wrap_up_scores() -> bool:
	assert(len(players) == 2, "Score calculation for 4 player games is not supported");
	var total_cards = (players[0].eats.reduce(func(acc, eat): return acc + len(eat.cards), 0)\
	+ players[1].eats.reduce(func(acc, eat): return acc + len(eat.cards), 0));
	assert(
		total_cards == 40,
		"Total cards of eats are not equal to 40!"
	);
	
	var diamonds_count = players[0].eats.reduce(func(acc, curr): return acc + curr.get_diamonds_count(), 0);
	
	if diamonds_count == 10:
		winner = [players[0]];
		return true;
	if diamonds_count == 0:
		winner = [players[1]];
		return true;
	
	if diamonds_count == 9:
		scores[1] = 0;
		return false;
	if diamonds_count == 1:
		scores[0] = 0;
		return false;
	
	var shkoppas = [
		players[0].eats.reduce(func(acc, eat): return acc + eat.shkoppa_value, 0),
		players[1].eats.reduce(func(acc, eat): return acc + eat.shkoppa_value, 0),
	];
	scores[0] += shkoppas[0];
	scores[1] += shkoppas[1];
	
	if diamonds_count == 8:
		scores[0] += 10;
		return _check_scores_threshold();
	if diamonds_count == 2:
		scores[1] += 10;
		return _check_scores_threshold();
	
	var has_snake = players[0].eats.any(func(eat): return eat.has_snake());
	scores[0 if has_snake else 1] += 1;
	
	var card_count = players[0].eats.reduce(func(acc, eat): return acc + len(eat.cards), 0)
	if card_count != 20:
		scores[0 if card_count > 20 else 1] += 1;
	
	var seven_count = players[0].eats.reduce(func(acc, eat): return acc + eat.get_seven_count(), 0)
	if seven_count != 2:
		scores[0 if seven_count > 2 else 1] += 1;
	else:
		var six_count = players[0].eats.reduce(func(acc, eat): return acc + eat.get_six_count(), 0);
		if six_count != 2:
			scores[0 if six_count > 2 else 1] += 1;
	
	return _check_scores_threshold();

func _round_over():
	if !pile.is_empty():
		var remaining_cards = pile.cards.duplicate();
		pile.eat_cards(remaining_cards, last_eater.position);
		last_eater.add_eat(remaining_cards);
	
	if _wrap_up_scores():
		print("Game over, " + winner[0].name + " has won!");
		return;
	
	print("Current scores:");
	
	for player in players:
		print(player.name + ": " + str(scores[players.find(player)]));
		player.clear_eats();
	deck.reset();
	_start_game();

func _next():
	var hands_empty = players.all(func(player: Player): return player.hand.is_empty())
	if hands_empty and deck.is_empty():
		_round_over();
		return;
	elif hands_empty:
		_deal_from_deck();
	_rotate_turns();

func _get_current_turn_player() -> Player:
	var arr = players.filter(func(p): return p is Player and p.is_turn)
	if len(arr) != 1: return null;
	return arr[0];

func _deal_from_deck(throw_to_pile: bool = false):
	for i in range(len(players)):
		if throw_to_pile and i == len(players) - 1:
			_throw_to_pile(4);
			await get_tree().create_timer(0.2).timeout;
		_deal_to_player(players[i], 3);
		if i != len(players) - 1:
			await get_tree().create_timer(0.2).timeout;

func _rotate_turns():
	var current = _get_current_turn_player();
	if current != null:
		var index = players.find(current);
		var new_index = (index + 1) % len(players);
		players[index].is_turn = false;
		players[new_index].is_turn = true;
		return;
	
	players[0].is_turn = true;

func _deal_to_player(player: Player, count: int):
	for i in range(count):
		var card = deck.draw_card();
		player.add_card(card);

func _throw_to_pile(count: int):
	for i in range(count):
		var card = deck.draw_card();
		pile.add_card(card);

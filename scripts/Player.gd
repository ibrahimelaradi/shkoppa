class_name Player
extends Node2D

class Eat:
	var cards: Array[String];
	var shkoppa_value: int;
	
	func _init(values: Array[String], shkoppa: int = 0):
		cards = values;
		shkoppa_value = shkoppa;
	
	func get_diamonds_count() -> int:
		return len(cards.filter(func(card): return card[0] == "d"));
	func has_snake() -> bool:
		return cards.has("d7");
	func get_seven_count() -> int:
		return len(cards.filter(func(card): return PlayingCard.parse_no(card) == 7));
	func get_six_count() -> int:
		return len(cards.filter(func(card): return PlayingCard.parse_no(card) == 6));

var is_turn = false;

var hand: Array[String] = [];
var eats: Array[Eat] = [];

signal card_added(String);
signal card_removed(String);
signal card_thrown(String);
signal ate(Eat);
signal played;

func add_card(card: String):
	hand.append(card);
	card_added.emit(card);
	print(name + " received a card \"" + card + "\"");

func remove_card(card: String) -> bool:
	var index = hand.find(card);
	if index >= 0:
		hand.remove_at(index);
		card_removed.emit(card);
		print(name + " removed a card \"" + card + "\"");
		return true;
	push_error("Tried to remove card \"" + card + "\" but it was not found in player hand!");
	return false;

func throw_card(card: String):
	var index = hand.find(card);
	if index >= 0:
		hand.remove_at(index);
		card_thrown.emit(card);
		print(name + " threw a card \"" + card + "\"");
		return true;
	push_error("Tried to throw card \"" + card + "\" but it was not found in player hand!");
	return false;

func add_eat(cards: Array[String], shkoppa: int = 0):
	var eat = Eat.new(cards, shkoppa);
	eats.append(eat);
	ate.emit(eat);
	print(name + " ate " + str(cards));
	if shkoppa > 0:
		print(name + " ate a shkoppa with value " + str(shkoppa));

func clear_eats():
	eats.clear();

func get_card_position(card: String) -> Vector2:
	var hand_node = get_node_or_null("Hand");
	assert(hand_node != null, "Tried to get a card position for a player that does not have a hand");
	var hand_cards = hand_node.get_children().filter(func(child): return child is PlayingCard and child.value == card);
	assert(len(hand_cards) == 1, "Failed to get a card of value " + card + " from " + name + "'s hand");
	return hand_cards[0].global_position;

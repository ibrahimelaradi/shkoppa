class_name Deck
extends Node2D

var cards := [
	"s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10",
	"d1", "d2", "d3", "d4", "d5", "d6", "d7", "d8", "d9", "d10",
	"c1", "c2", "c3", "c4", "c5", "c6", "c7", "c8", "c9", "c10",
	"h1", "h2", "h3", "h4", "h5", "h6", "h7", "h8", "h9", "h10",
];

func reset():
	cards = [
		"s1", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10",
		"d1", "d2", "d3", "d4", "d5", "d6", "d7", "d8", "d9", "d10",
		"c1", "c2", "c3", "c4", "c5", "c6", "c7", "c8", "c9", "c10",
		"h1", "h2", "h3", "h4", "h5", "h6", "h7", "h8", "h9", "h10",
	];

func shuffle():
	print("Shuffling deck cards: " + str(cards));
	cards.shuffle();
	print("Deck cards shuffled: " + str(cards));

func is_empty() -> bool: return cards.is_empty();

func draw_card() -> String:
	return cards.pop_back();

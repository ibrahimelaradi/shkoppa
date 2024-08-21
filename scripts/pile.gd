@tool
class_name Pile
extends Node2D

@export var size: Vector2:
	set(value):
		size = value;
		queue_redraw();
@export var grid: Vector2i = Vector2i.ONE * 4;
@export var gap: Vector2i = Vector2i.ONE * 10;

@onready var card_scene = preload("res://scenes/playing_card.tscn");

signal card_added(PlayingCard);

func _draw():
	if Engine.is_editor_hint():
		var color = Color.AQUA;
		color.a = 0.25
		draw_rect(Rect2(-size/2, size), color, true);
		draw_rect(Rect2(-size/2, size), Color.AQUA, false, 4);

var cards: Array[String] = [];

func _organize_cards(stagger: bool = false):
	var child_count = get_child_count();
	
	var cols = min(grid.y, child_count);
	var rows = min(grid.x, ceili(float(child_count) / cols));
	
	var slot_size = Vector2(
		(size.x - gap.x * (grid.x - 1)) / grid.x,
		(size.y - gap.y * (grid.y - 1)) / grid.y
	);
	var start_point = Vector2(
		-float(cols - 1) / 2 * (gap.x + slot_size.x),
		-float(rows - 1) / 2 * (gap.y + slot_size.y),
	);
	
	for i in range(rows):
		var i_cols = min(child_count - i * cols, cols)
		for j in range(i_cols):
			var child = get_child(j + i * cols);
			var new_position = Vector2(
				start_point.x + j * (slot_size.x + gap.x),
				start_point.y + i * (slot_size.y + gap.y),
			);
			
			var tween = child.create_tween();
			tween.set_parallel(true);
			tween.tween_property(child, "position", new_position, 0.2);
			
			if stagger:
				await tween.tween_interval(0.12).finished;

func is_empty() -> bool: return cards.is_empty();

func add_card(card: String):
	cards.append(card);
	
	var instance = card_scene.instantiate();
	instance.value = card;
	add_child(instance);
	instance.position.y = 120;
	instance.position.x = -get_viewport_rect().size.x;
	_organize_cards(true);
	
	card_added.emit(instance);

func throw_card(card: String, pos: Vector2):
	cards.append(card);
	
	var instance = card_scene.instantiate();
	instance.value = card;
	add_child(instance);
	instance.position = to_local(pos);
	
	_organize_cards();
	
	card_added.emit(instance);

func remove_card(card: String):
	cards.erase(card);
	
	for child in get_children():
		if child.value == card:
			remove_child(child);
			child.queue_free();
			_organize_cards();

func _get_card_instance(card: String) -> PlayingCard:
	var matching = get_children().filter(func(ins): return ins is PlayingCard and ins.value == card);
	return null if matching.is_empty() else matching[0];

func eat_cards(to_eat: Array[String], pos: Vector2):
	get_tree().create_timer(0.08 * len(to_eat) + 0.001).timeout.connect(_organize_cards);
	for card in to_eat:
		cards.erase(card);
		var instance = _get_card_instance(card);
		var tween = instance.create_tween();
		tween.set_parallel(true);
		var new_pos = (get_viewport_rect().size.y / 2 + 100) * position.direction_to(pos);
		tween.tween_property(instance, "position", new_pos, 0.08);
		tween.finished.connect(func(): remove_child(instance));
		await tween.tween_interval(0.04).finished;

func get_selected() -> Array:
	return get_children().filter(func(card): return card is PlayingCard and card.selected).map(func(card: PlayingCard): return card.value);

func get_possible_eats(sum: int) -> Array:
	var possible = [];
	var card_count = len(cards);
	var lock_sums = false;
	var sorted = cards.duplicate();
	sorted.sort_custom(func(a, b): return PlayingCard.parse_no(a) > PlayingCard.parse_no(b));
	for i in range(card_count):
		var i_val = PlayingCard.parse_no(sorted[i]);
		if i_val == sum:
			possible.append([sorted[i]]);
			lock_sums = true;
			continue;
		if lock_sums:
			continue;
		
		var running_sum_cards = [sorted[i]];
		var running_sum = i_val;
		
		for j in range(i + 1, card_count):
			var j_val = PlayingCard.parse_no(sorted[j]);
			
			if (running_sum + j_val) == sum:
				running_sum_cards.append(sorted[j]);
				running_sum += j_val;
				break;
			
			if (running_sum + j_val) < sum:
				running_sum_cards.append(sorted[j]);
				running_sum += j_val;
				continue;
		
		if running_sum == sum:
			possible.append(running_sum_cards);
	
	return possible;

func get_card_position(card: String) -> Vector2:
	var pile_cards = get_children().filter(func(child): return child is PlayingCard and child.value == card);
	assert(len(pile_cards) == 1, "Failed to get a card of value " + card + " from the pile");
	return pile_cards[0].global_position;

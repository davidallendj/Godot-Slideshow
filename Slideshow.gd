extends Control

@onready var button_next 		:= %Next
@onready var button_previous 	:= %Previous
@onready var content 			:= %Content
@onready var frame				:= %Frame

var current_index 	:= 0
var duration 		:= 0.5

func _ready() -> void:
	_initialize()


func _initialize() -> void:
	button_next.pressed.connect(_cycle_next)
	button_previous.pressed.connect(_cycle_previous)
	
	# move all slides off screen and fit to content frame (if not ignoring sizes)
	_content_fit_size()
	_content_reset_positions()
	var initial_slide := content.get_child(0)
	initial_slide.set_position(content.get_position())


func _content_fit_size() -> void:
	for slide in content.get_children():
		slide.set_size(content.get_size())


func _content_reset_positions() -> void:
	for slide in content.get_children():
		slide.set_position(
			Vector2(
				frame.get_position().x - frame.get_size().x,
				frame.get_position().y
			)
		)


func _cycle_next() -> void:
	# get the index of the next node
	var next_index := current_index + 1
	var slide_count := content.get_child_count()
	if next_index >= slide_count:
		next_index = 0
	
	# set the initial position of next slide to the left of content before moving
	var next_node := content.get_child(next_index)
	next_node.set_position(
		Vector2(
			frame.get_position().x - content.get_size().x,
			content.get_position().y
		)
	)
	
	# slide the current and next nodes to the right simultaneously
	var current_slide := content.get_child(current_index)
	var tween := get_tree().create_tween().set_parallel(true)
	tween.tween_property(
		current_slide, 
		"position:x", 
		frame.get_position().x + frame.get_size().x, # at end of frame
		duration
	).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(
		next_node, 
		"position:x",
		content.get_position().x,	# at beginning of content
		duration
	).set_trans(Tween.TRANS_CUBIC)
	
	# set the current index to the next one
	current_index = next_index


func _cycle_previous() -> void:
	# get the index of the previous node
	var previous_index := current_index - 1
	var slide_count := content.get_child_count()
	if previous_index < 0:
		previous_index = slide_count - 1
		
	# set the initial position of previous slide to the right of content before moving
	var previous_node := content.get_child(previous_index)
	previous_node.set_position(
		Vector2(
			content.get_position().x + content.get_size().x,
			content.get_position().y
		)
	)
	
	# slide the current and previous nodes to the left simultaneously
	var current_slide := content.get_child(current_index)
	var tween := get_tree().create_tween().set_parallel(true)
	tween.tween_property(
		current_slide, 
		"position:x", 
		frame.get_position().x - frame.get_size().x, # at left of frame
		duration
	).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(
		previous_node, 
		"position:x",
		content.get_position().x,	# at beginning of content
		duration
	).set_trans(Tween.TRANS_CUBIC)
	
	# set the current index to the previous one
	current_index = previous_index

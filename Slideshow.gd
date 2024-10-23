extends Control

class_name Slideshow

@onready var button_next 		:= %Next
@onready var button_previous 	:= %Previous
@onready var content 			:= %Content
@onready var frame				:= %Frame

@export var transition_duration := 0.5
@export var time_per_slide		:= 5.0
@export var enable_timed_slides := true
@export var enable_slide_inputs := true
var _current_slide_index 		:= 0
var _slide_reset_time			:= 0.0
var _block_inputs				:= false


func add_content(new_content: Control) -> void:
	content.add_child(new_content)
	if content.get_child_count() > 1:
		_show_buttons(true)


func _ready() -> void:
	_initialize()


func _physics_process(delta: float) -> void:
	if enable_timed_slides:
		time_per_slide -= delta
		# time's up so go to next slide and reset time
		if time_per_slide <= 0:
			_cycle_next()
			time_per_slide = _slide_reset_time


func _initialize() -> void:
	button_next.pressed.connect(_cycle_next)
	button_previous.pressed.connect(_cycle_previous)
	content.gui_input.connect(_handle_input)
	
	# set the temporary variable to hold the value
	_slide_reset_time = time_per_slide
	
	# move all slides off screen and fit to content frame (if not ignoring sizes)
	_content_fit_size()
	_content_reset_positions()
	
	# set the initial slide position if it exists
	if content.get_child_count() > 0:
		var initial_slide := content.get_child(_current_slide_index)
		initial_slide.set_position(content.get_position())
	
	# hide the next/previous buttons if slides <= 1
	if content.get_child_count() <= 1:
		_show_buttons(false)


func _show_buttons(is_visible: bool) -> void:
	button_next.set_visible(is_visible)
	button_previous.set_visible(is_visible)


func _content_fit_size() -> void:
	for slide in content.get_children():
		slide.set_size(content.get_size())


func _content_reset_positions() -> void:
	# move all slides off the screen to the left
	for slide in content.get_children():
		slide.set_position(
			Vector2(
				frame.get_position().x - frame.get_size().x,
				frame.get_position().y
			)
		)


func _set_to_frame_left(slide: Control) -> void:
	slide.set_position(
		Vector2(
			frame.get_position().x - frame.get_size().x,
			slide.get_position().y
		)
	)


func _set_to_frame_right(slide: Control) -> void:
	slide.set_position(
		Vector2(
			frame.get_position().x + frame.get_size().x,
			slide.get_position().y
		)
	)


func _set_slide() -> void:
	# TODO: add a way to go directly to slide in deck
	pass


func _cycle_next() -> void:
	# if there's only one node or less or inputs are blocked, do nothing
	var slide_count := content.get_child_count()
	if slide_count <= 1 or _block_inputs:
		return
	
	# set variable to block trying to cycle to next/previous slide
	_block_inputs = true
	
	# get the index of the next node
	var next_index := _current_slide_index + 1
	if next_index >= slide_count:
		next_index = 0
	
	# set the initial position of next slide to the left of content before moving
	var next_slide := content.get_child(next_index)
	_set_to_frame_left(next_slide)
	
	# slide the current and next nodes to the right simultaneously
	var current_slide := content.get_child(_current_slide_index)
	var tween := get_tree().create_tween().set_parallel(true)
	tween.tween_property(
		current_slide, 
		"position:x", 
		frame.get_position().x + frame.get_size().x, # at end of frame
		transition_duration
	).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(
		next_slide, 
		"position:x",
		frame.get_position().x,	# target position
		transition_duration
	).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(func() -> void: _block_inputs = false)
	
	# set the current index to the next one
	_current_slide_index = next_index
	time_per_slide = _slide_reset_time


func _cycle_previous() -> void:
	# if there's only one node or less or inputs are blocked, do nothing
	var slide_count := content.get_child_count()
	if slide_count <= 1 or _block_inputs:
		return
	
	# set variable to block trying to cycle to next/previous slide
	_block_inputs = true
	
	# get the index of the previous node
	var previous_index := _current_slide_index - 1
	if previous_index < 0:
		previous_index = slide_count - 1
		
	# set the initial position of previous slide to the right of content before moving
	var previous_slide := content.get_child(previous_index)
	_set_to_frame_right(previous_slide)
	
	# slide the current and previous nodes to the left simultaneously
	var current_slide := content.get_child(_current_slide_index)
	var tween := get_tree().create_tween().set_parallel(true)
	tween.tween_property(
		current_slide, 
		"position:x", 
		frame.get_position().x - frame.get_size().x, # at left of frame
		transition_duration
	).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(
		previous_slide, 
		"position:x",
		frame.get_position().x,	# target position
		transition_duration
	).set_trans(Tween.TRANS_CUBIC)
	tween.chain().tween_callback(func() -> void: _block_inputs = false)
	
	# set the current index to the previous one and reset timer
	_current_slide_index = previous_index
	time_per_slide = _slide_reset_time


func _handle_input(event: InputEvent) -> void:
	# handle inputs if enabled
	if !enable_slide_inputs:
		return
	
	# handle left and mouse clicks from mouse buttons only
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.is_released():
			_cycle_next()
		if event.button_index == MOUSE_BUTTON_RIGHT and event.is_released():
			_cycle_previous()
	
	# TODO: handle events from touch screen

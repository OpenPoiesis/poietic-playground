class_name CanvasLabelPrompt extends LineEdit
# FIXME: [REFACTORING] Convert this to CanvasPrompt type

signal editing_submitted(object_id: int, new_text: String)
signal editing_cancelled(object_id: int)

@export var grow_duration: float = 0.05

## Currently edited object.
##
@export var edited_object_id: int = -1

@export var canvas: DiagramCanvas
@export var prompt_manager: CanvasPromptManager

var _original_center: Vector2
var _target_width: float = 0.0
var _is_active: bool = false


func initialize(canvas: DiagramCanvas, manager: CanvasPromptManager):
	self.canvas = canvas
	self.prompt_manager = manager

func open(object_id: int, text: String, center: Vector2):
	assert(object_id != null, "Edited object ID not provided")
	self.edited_object_id = object_id
	self.text = text
	
	var block = canvas.represented_block(object_id)
	block.hide_labels()
	
	_original_center = center
	_target_width = calculate_editor_width()
	self.size.x = _target_width
	global_position = Vector2(center.x - _target_width / 2, center.y)
	
	_is_active = true
	show()
	grab_focus()
	select_all()
	set_process(true)

func close():
	if !_is_active:
		return

	var node = canvas.get_diagram_node(edited_object_id)
	node.finish_label_edit()

	set_process(false)
	editing_cancelled.emit(edited_object_id)
	hide()
	_is_active = false
	edited_object_id = -1

func calculate_editor_width() -> float:
	var font = get_theme_font("font")
	var font_size = get_theme_font_size("font_size")
	var width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	var padding = get_theme_constant("horizontal_padding", "Label") * 2
	return max(width + padding, self.get_minimum_size().x)

func _ready():
	hide()
	set_process(false)
	focus_exited.connect(_on_focus_exited)
	text_changed.connect(_on_text_changed)
	text_submitted.connect(_on_text_submitted)

func _process(delta):
	var target_position = Vector2(_original_center.x - _target_width/2, global_position.y)

	# Animate
	if abs(size.x - _target_width) > 1.0:
		var from_x = size.x
		size.x = lerp(size.x, _target_width, delta * (1.0/grow_duration))
		global_position.x = lerp(global_position.x,
								 target_position.x,
								 delta * (1.0/grow_duration))
	else:
		size.x = _target_width
		global_position.x = target_position.x

func _on_text_changed(new_text: String):
	_target_width = calculate_editor_width()

func _on_text_submitted(new_text: String):
	if !_is_active:
		return
		
	set_process(false)
	hide()
	editing_submitted.emit(edited_object_id, new_text)
	_is_active = false
	edited_object_id = -1

func _on_focus_exited():
	if visible:
		close()

func _input(event):
	if visible and event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()

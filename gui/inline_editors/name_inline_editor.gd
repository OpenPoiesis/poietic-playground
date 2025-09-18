class_name NameInlineEditor extends CanvasInlineEditor
# FIXME: [REFACTORING] Convert this to CanvasPrompt type

@onready var edit_field: LineEdit = $LabelEditField

@export var grow_duration: float = 0.05

var _original_center: Vector2
var _target_width: float = 0.0
var _is_active: bool = false

func open(object_id: int, attribute: String, value: Variant):
	if attribute != "name":
		push_warning("Name editor called for attribute '" + attribute +"'")
		return

	self.object_id = object_id
	edit_field.text = String(value)
	
	var block = canvas_ctrl.canvas.represented_block(object_id)
	block.begin_label_edit()
	
	_original_center = position
	_target_width = calculate_editor_width()
	edit_field.size.x = _target_width
	#global_position = Vector2(position.x - _target_width / 2, position.y)
	
	_is_active = true
	show()
	edit_field.grab_focus()
	edit_field.select_all()
	set_process(true)

func close():
	if !_is_active:
		return

	var block = canvas_ctrl.canvas.represented_block(object_id)
	if block != null:
		block.finish_label_edit()

	_is_active = false
	object_id = -1
	set_process(false)
	hide()

func calculate_editor_width() -> float:
	var font = get_theme_font("font")
	var font_size = get_theme_font_size("font_size")
	var width = font.get_string_size(edit_field.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	var padding = get_theme_constant("horizontal_padding", "Label") * 2
	return max(width + padding, self.get_minimum_size().x)

func _ready():
	hide()
	set_process(false)
	edit_field.focus_exited.connect(_on_focus_exited)
	edit_field.text_changed.connect(_on_text_changed)
	edit_field.text_submitted.connect(_on_text_submitted)

func _process(delta):
	var target_position = Vector2(_original_center.x - _target_width/2, global_position.y)

	# Animate
	if abs(edit_field.size.x - _target_width) > 1.0:
		var from_x = edit_field.size.x
		edit_field.size.x = lerp(edit_field.size.x,
								 _target_width,
					  			 delta * (1.0/grow_duration))
		global_position.x = lerp(edit_field.global_position.x,
								 target_position.x,
								 delta * (1.0/grow_duration))
	else:
		edit_field.size.x = _target_width
		global_position.x = target_position.x

func _on_text_changed(new_text: String):
	_target_width = calculate_editor_width()

func _on_text_submitted(new_text: String):
	if !_is_active:
		return
		
	set_process(false)
	hide()
	canvas_ctrl.commit_name_edit(object_id, new_text)
	_is_active = false
	object_id = -1

func _on_focus_exited():
	if visible:
		close()

func _input(event):
	if !visible:
		return
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()

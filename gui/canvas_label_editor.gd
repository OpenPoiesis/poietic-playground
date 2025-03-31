class_name CanvasLabelEditor extends LineEdit

signal editing_submitted(new_text: String)
signal editing_cancelled

@export var grow_duration: float = 0.05

var _original_center: Vector2
var _target_width: float = 0.0

func open(text: String, center: Vector2):
	self.text = text
	
	_original_center = center
	_target_width = calculate_editor_width()
	self.size.x = _target_width
	global_position = Vector2(center.x - _target_width / 2, center.y)
	
	show()
	grab_focus()
	select_all()
	set_process(true)
	
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
	set_process(false)
	hide()
	editing_submitted.emit(new_text)

func _on_focus_exited():
	if visible:
		set_process(false)
		hide()
		editing_cancelled.emit()

func _input(event):
	if visible and event is InputEventKey:
		if event.keycode == KEY_ESCAPE:
			set_process(false)
			hide()
			editing_cancelled.emit()
			get_viewport().set_input_as_handled()

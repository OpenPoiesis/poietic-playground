class_name FormulaInlineEditor extends CanvasInlineEditor

@onready var formula_field: LineEdit = %FormulaField
@export var grow_duration: float = 0.05

var _is_active: bool = false

func open(object: PoieticObject, attribute: String, value: Variant):
	self.object_id = object.object_id
	self.original_value = String(value)
	%FormulaField.text = self.original_value
	
	%FormulaField.grab_focus()
	%FormulaField.select_all()

	_is_active = true
	set_process(true)
	show()

func _on_reject_formula_button_pressed():
	cancel()

func _on_accept_formula_button_pressed():
	accept_formula(%FormulaField.text)

func _on_formula_field_text_submitted(new_text):
	accept_formula(new_text)

func accept_formula(new_text: String):
	if !_is_active:
		return
	
	set_process(false)
	hide()
	canvas_ctrl.commit_formula_edit(object_id, new_text)
	_is_active = false
	object_id = -1

func close():
	if !_is_active:
		return
	set_process(false)
	hide()
	_is_active = false
	object_id = -1

func cancel():
	if !_is_active:
		return
	close()

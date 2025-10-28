class_name NumericAttributeEditor extends CanvasInlineEditor

enum ValueType {
	NUMERIC,
	STRING
}

# TODO: This is unused for now, use it
@export var edited_value_type: ValueType = ValueType.NUMERIC

func set_icon(texture: Texture):
	if texture:
		%Icon.texture = texture
		%Icon.show()
	else:
		%Icon.hide()
		
func set_label(text: String):
	if text:
		%Label.text = text
		%Label.show()
	else:
		%Label.hide()
	
func open(object: PoieticObject, attribute: String, value: Variant):
	self.object_id = object.object_id
	self.attribute_name = attribute
	
	%ValueField.text = String(value)
	
	#global_position = Vector2(position.x - self.size.x / 2, position.y)
	
	is_active = true
	show()
	%ValueField.grab_focus()
	%ValueField.select_all()
	set_process(true)

func close():
	if !is_active:
		return
	set_process(false)
	hide()
	is_active = false
	object_id = -1

func _on_value_field_text_submitted(new_text):
	if !is_active:
		return
	
	set_process(false)
	hide()
	canvas_ctrl.commit_numeric_attribute_edit(object_id, attribute_name, new_text)
	is_active = false

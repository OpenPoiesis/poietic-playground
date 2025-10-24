extends InspectorTraitPanel

@onready var allows_negative_check: TriStateCheckButton = %AllowsNegativeCheck

func on_selection_changed():
	var distinct_allow_negative = design_ctrl.get_distinct_values(selection, "allows_negative")
	
	match len(distinct_allow_negative):
		0:
			allows_negative_check.disabled = true
		1:
			allows_negative_check.disabled = false
			if bool(distinct_allow_negative[0]):
				allows_negative_check.set_state_no_signal(TriStateCheckButton.State.CHECKED)
			else:
				allows_negative_check.set_state_no_signal(TriStateCheckButton.State.UNCHECKED)
		_:
			allows_negative_check.disabled = false
			allows_negative_check.set_state_no_signal(TriStateCheckButton.State.INDETERMINATE)

	var distinct_colors = design_ctrl.get_distinct_values(selection, "color")
	match len(distinct_colors):
		0:
			%ColorPicker.set_selected_color_no_signal("")
		1:
			%ColorPicker.set_selected_color_no_signal(distinct_colors[0])
		_:
			%ColorPicker.set_selected_color_no_signal("")


func update_allows_negative(flag: bool):
	var trans = design_ctrl.new_transaction()
	
	for id in selection:
		trans.set_attribute(id, "allows_negative", flag)

	design_ctrl.accept(trans)

func _on_allows_negative_check_toggled(toggled_on):
	update_allows_negative(toggled_on)


func _on_color_picker_color_selected(color_name):
	var trans = design_ctrl.new_transaction()

	if color_name == "":	
		for id in selection:
			trans.set_attribute(id, "color", null)
	else:
		for id in selection:
			trans.set_attribute(id, "color", color_name)

	design_ctrl.accept(trans)

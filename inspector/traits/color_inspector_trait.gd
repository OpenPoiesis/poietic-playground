extends InspectorTraitPanel

func on_selection_changed():
	var distinct_colors = design_ctrl.get_distinct_values(selection, "color")
	match len(distinct_colors):
		0:
			%ColorPicker.set_selected_color_no_signal("")
		1:
			%ColorPicker.set_selected_color_no_signal(distinct_colors[0])
		_:
			%ColorPicker.set_selected_color_no_signal("")

func _on_color_picker_color_selected(color_name):
	var trans = design_ctrl.new_transaction()

	if color_name == "":	
		for id in selection:
			trans.set_attribute(id, "color", null)
	else:
		for id in selection:
			trans.set_attribute(id, "color", color_name)

	design_ctrl.accept(trans)

extends InspectorTraitPanel

@onready var duration_input: IndeterminateSpinBox = $VBoxContainer/DurationInput


func on_selection_changed():
	var distinct_duration = Global.app.design_controller.get_distinct_values(selection, "delay_duration")

	if len(distinct_duration) == 0:
		duration_input.editable = false
	elif len(distinct_duration) == 1:
		duration_input.editable = true
		var value = int(distinct_duration[0])
		duration_input.is_indeterminate = false
		if value:
			duration_input.value = value
		else:
			duration_input.value = 0
	else:
		duration_input.is_indeterminate = true
		duration_input.editable = true
		duration_input.value = 0	

func update_delay_duration(value: int):
	var trans = Global.app.design_controller.new_transaction()
	
	for id in selection:
		trans.set_attribute(id, "delay_duration", value)

	Global.app.design_controller.accept(trans)


func _on_duration_input_value_changed(value):
	update_delay_duration(int(value))
	

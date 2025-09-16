extends InspectorTraitPanel

@onready var allows_negative_check: TriStateCheckButton = %AllowsNegativeCheck

func on_selection_changed():
	var distinct_allow_negative = design_ctrl.get_distinct_values(selection, "allows_negative")
	if len(distinct_allow_negative) == 0:
		allows_negative_check.disabled = true
	elif len(distinct_allow_negative) == 1:
		allows_negative_check.disabled = false
		if bool(distinct_allow_negative[0]):
			allows_negative_check.set_state_no_signal(TriStateCheckButton.State.CHECKED)
		else:
			allows_negative_check.set_state_no_signal(TriStateCheckButton.State.UNCHECKED)
	else:
		allows_negative_check.disabled = false
		allows_negative_check.set_state_no_signal(TriStateCheckButton.State.INDETERMINATE)

func update_allows_negative(flag: bool):
	var trans = Global.design.new_transaction()
	
	for id in selection:
		trans.set_attribute(id, "allows_negative", flag)

	Global.design.accept(trans)

func _on_allows_negative_check_toggled(toggled_on):
	update_allows_negative(toggled_on)

extends InspectorTraitPanel

@onready var label: Label = $VBoxContainer/Label
@onready var name_field: LineEdit = $VBoxContainer/NameField

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func on_selection_changed():
	var distinct_label = Global.app.design_controller.get_distinct_values(selection, "name")

	if len(distinct_label) == 0:
		name_field.text = ""
	elif len(distinct_label) == 1:
		name_field.text = str(distinct_label[0])
	else:
		name_field.text = "(multiple)"

func _on_name_field_text_submitted(new_name):
	var trans = Global.app.design_controller.new_transaction()
	
	for id in selection.get_ids():
		trans.set_attribute(id, "name", new_name)

	Global.app.design_controller.accept(trans)

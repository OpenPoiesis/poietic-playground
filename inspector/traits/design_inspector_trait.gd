extends InspectorTraitPanel

@onready var title_field: LineEdit = $VBoxContainer/TitleField
@onready var description_field: TextEdit = $VBoxContainer/DescriptionField

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func on_selection_changed():
	var info: PoieticObject = design_ctrl.get_special_object("DesignInfo")

	if info == null:
		return
		
	var title = info.get_attribute("title")
	if title != null:
		title_field.text = title
	else:
		title_field.text = ""

	var desc = info.get_attribute("description")
	if desc != null:
		description_field.text = desc
	else:
		description_field.text = ""

func _on_name_field_text_submitted(new_name):
	var trans = Global.app.design_controller.new_transaction()
	
	for id in selection:
		trans.set_attribute(id, "name", new_name)

	Global.app.design_controller.accept(trans)

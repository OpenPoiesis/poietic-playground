class_name InspectorPanel extends PanelContainer

@onready var inspector_title_label = %InspectorTitle
@onready var traits_container = %TraitsContainer

## Panel for inspecting diagram elements.
##

var selection: Selection

func get_type_id(type_name: String):
	match type_name:
		"stock": return 1
		"flow": return 2
		"auxiliary": return 3
		_: return 0
		
func _on_diagram_canvas_selection_changed(new_selection):
	set_selection(new_selection)
	
func set_selection(new_selection):
	self.selection = new_selection
	print("Selection changed: ", selection.count(), " nodes selected")
	
	var type_names = selection.get_type_names()

	if len(type_names) == 0:
		inspector_title_label.text = "nothing selected"
	elif len(type_names) == 1:
		var text: String = type_names[0]
		if selection.count() > 1:
			text += " (" + str(selection.count()) + " selected)"
		inspector_title_label.text = text
	else:
		var text = "Multiple types (" + str(selection.count()) + " selected)"
		inspector_title_label.text = text
		
	set_traits(selection.distinct_traits())
	
	for panel in traits_container.get_children():
		panel.set_selection(new_selection)

func set_traits(traits: Array[String]):
	for child in traits_container.get_children():
		traits_container.remove_child(child)
		
	for trait_name in traits:
		var panel = InspectorTraitPanel.panel_for_trait(trait_name)
		if not panel:
			continue
		traits_container.add_child(panel)

static func group_with_name(name: String) -> Container:
	match name:
		"Name":
			var container: VBoxContainer = VBoxContainer.new()
			var label: Label = Label.new()
			var field: LineEdit = LineEdit.new()
			
			container.add_child(label)
			container.add_child(field)
				
			return container
		_:
			return null
			

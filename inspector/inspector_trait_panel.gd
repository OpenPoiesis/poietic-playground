class_name InspectorTraitPanel extends PanelContainer


signal set_object_attribute(trait_name: String, name: String, value: Variant)

var selection: PackedInt64Array
var design_ctrl: DesignController

func set_controller(design_ctrl: DesignController):
	self.design_ctrl = design_ctrl
	self.selection = PackedInt64Array()

func set_selection(new_selection):
	self.selection = new_selection
	on_selection_changed()

func on_selection_changed():
	pass

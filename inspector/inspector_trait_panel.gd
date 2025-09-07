class_name InspectorTraitPanel extends PanelContainer

static var _trait_panels: Dictionary[String,InspectorTraitPanel] = {}

signal set_object_attribute(trait_name: String, name: String, value: Variant)

var selection: SelectionManager

static func _initialize_panels():
	_trait_panels = {
		# "Name": preload("res://inspector/traits/name_inspector_trait.tscn").instantiate(),
		# "Formula": preload("res://inspector/traits/formula_inspector_trait.tscn").instantiate(),
		"Stock": preload("res://inspector/traits/stock_inspector_trait.tscn").instantiate(),
		"Delay": preload("res://inspector/traits/delay_inspector_trait.tscn").instantiate(),
		# "Errors": preload("res://inspector/traits/errors_inspector_trait.tscn").instantiate(),
	}

static func panel_for_trait(name: String) -> InspectorTraitPanel:
	var panel = _trait_panels.get(name)
	if panel:
		return panel as InspectorTraitPanel
	else:
		return null

func set_selection(new_selection):
	self.selection = new_selection
	on_selection_changed()

func on_selection_changed():
	pass

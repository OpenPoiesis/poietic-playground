class_name InspectorPanel extends PanelContainer

@onready var overview_traits_container = %OverviewTraitsContainer
@onready var settings_traits_container = %SettingsTraitsContainer

# Panels for known traits. See: instantiate_default_panels.
static var overview_panels: Dictionary[String,InspectorTraitPanel] = {}
static var settings_panels: Dictionary[String,InspectorTraitPanel] = {}

@onready var title_label = %InspectorTitle
@onready var subtitle_label = %InspectorSubtitle
@onready var secondary_attribute_label = %SecondaryAttributeLabel
# @onready var primary_attribute_icon = %PrimaryAttributeIcon

var selection: PackedInt64Array

@export var design_ctrl: DesignController
@export var player: ResultPlayer

static func instantiate_default_panels():
	overview_panels = {
		"NumericIndicator": preload("res://inspector/traits/time_series_inspector_trait.tscn").instantiate(),
		"Design": preload("res://inspector/traits/design_inspector_trait.tscn").instantiate(),
	}
	settings_panels = {
		# "Name": preload("res://inspector/traits/name_inspector_trait.tscn").instantiate(),
		# "Formula": preload("res://inspector/traits/formula_inspector_trait.tscn").instantiate(),
		"Stock": preload("res://inspector/traits/stock_inspector_trait.tscn").instantiate(),
		"Delay": preload("res://inspector/traits/delay_inspector_trait.tscn").instantiate(),
		# "Errors": preload("res://inspector/traits/errors_inspector_trait.tscn").instantiate(),
	}

func initialize(design_ctrl: DesignController, player: ResultPlayer):
	self.design_ctrl = design_ctrl
	self.player = player
	
	selection = PackedInt64Array()

	design_ctrl.design_changed.connect(_on_design_changed)
	design_ctrl.simulation_finished.connect(_on_simulation_success)
	design_ctrl.simulation_failed.connect(_on_simulation_failed)
	design_ctrl.selection_manager.selection_changed.connect(_on_selection_changed)

func _on_simulation_success(result: PoieticResult):
	for child in overview_traits_container.get_children():
		if child as InspectorTraitPanel:
			child._on_result_updated(result)
	
func _on_simulation_failed():
	for child in overview_traits_container.get_children():
		if child as InspectorTraitPanel:
			child._on_result_removed()

func _on_selection_changed(selection_manager: SelectionManager):
	# TODO: Do we need new selection? We should query the canvas one.
	set_selection(selection_manager.get_ids())
	
func _on_design_changed(success: bool):
	# Just re-apply current selection
	set_selection(design_ctrl.selection_manager.get_ids())

func set_selection(new_selection: PackedInt64Array):
	self.selection = new_selection
	
	var distinct_types = design_ctrl.get_distinct_types(selection)
	var distinct_name_values = design_ctrl.get_distinct_values(selection, "name")
	var distinct_names: Array[String] = []
	for value in distinct_name_values:
		var name = str(value)
		if name != null:
			distinct_names.append(name)
		
	self.update_title(distinct_types, distinct_names)
	
	var traits: Array[String] = []
	if selection.is_empty():
		traits = ["Design"]
	else:
		traits = design_ctrl.get_shared_traits(selection)
	
	# Set traits
	var new_overview_panels: Array[InspectorTraitPanel] = []
	var new_settings_panels: Array[InspectorTraitPanel] = []
	for trait_name in traits:
		if overview_panels.has(trait_name):
			var panel = overview_panels[trait_name]
			new_overview_panels.append(panel)
		elif settings_panels.has(trait_name):
			var panel = settings_panels[trait_name]
			new_settings_panels.append(panel)
		
	if design_ctrl.has_issues() and overview_panels.has("Errors"):
		var panel = overview_panels["Errors"]
		new_overview_panels.append(panel)

	set_panels(new_overview_panels, overview_traits_container, new_selection)
	set_panels(new_settings_panels, settings_traits_container, new_selection)
	
	# Chart
	# TODO: Check whether having a chart is relevant
	# chart.series_ids = selection

	# chart.show()
	# chart.update_from_result(player.result)

func update_title(types: Array[String], names: Array[String]):
	var type_label: String = ""
	
	match len(types):
		0:
			subtitle_label.text = ""
		1:
			subtitle_label.text = types[0]
			type_label = types[0]
		_: 
			type_label = "multiple types"
			subtitle_label.text = type_label
	
	match len(names):
		0:
			if selection.is_empty():
				title_label.text = "Design"
				subtitle_label.text = "Design"
			else:
				title_label.text = "(no name)"
		1:
			title_label.text = names[0]
		_:
			title_label.text = str(len(selection)) + " of " + type_label

	
func set_panels(panels: Array[InspectorTraitPanel], container: VBoxContainer, selection: PackedInt64Array):
	for child in container.get_children():
		container.remove_child(child)
		
	for panel in panels:
		container.add_child(panel)
		panel.set_controller(design_ctrl)
		panel.set_selection(selection)

func inspect_design():
	pass
	
	# TODO: Use Global.app.design_controller.get_object()
	# Design Info Attributes:
	#	- title
	#   - abstract
	#   - author
	#   - date
	

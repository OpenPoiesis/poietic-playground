class_name InspectorPanel extends PanelContainer

# Panels for known traits. See: instantiate_default_panels.
static var _trait_panels: Dictionary[String,InspectorTraitPanel] = {}

@onready var title_label = %InspectorTitle
@onready var subtitle_label = %InspectorSubtitle
@onready var chart = %Chart
@onready var primary_attribute_label = %PrimaryAttributeLabel
# @onready var primary_attribute_icon = %PrimaryAttributeIcon
@onready var traits_container = %TraitsContainer

var selection: PackedInt64Array

@export var design_ctrl: DesignController
@export var player: ResultPlayer

static func instantiate_default_panels():
	_trait_panels = {
		# "Name": preload("res://inspector/traits/name_inspector_trait.tscn").instantiate(),
		# "Formula": preload("res://inspector/traits/formula_inspector_trait.tscn").instantiate(),
		"Stock": preload("res://inspector/traits/stock_inspector_trait.tscn").instantiate(),
		"Delay": preload("res://inspector/traits/delay_inspector_trait.tscn").instantiate(),
		# "Errors": preload("res://inspector/traits/errors_inspector_trait.tscn").instantiate(),
	}

static func panel_for_trait(name: String) -> InspectorTraitPanel:
	return _trait_panels.get(name)

func initialize(design_ctrl: DesignController, player: ResultPlayer):
	self.design_ctrl = design_ctrl
	self.player = player
	
	selection = PackedInt64Array()

	design_ctrl.design_changed.connect(_on_design_changed)
	design_ctrl.simulation_finished.connect(_on_simulation_success)
	design_ctrl.simulation_failed.connect(_on_simulation_failed)
	design_ctrl.selection_manager.selection_changed.connect(_on_selection_changed)

func _on_simulation_success(result):
	chart.update_from_result(result)
	
func _on_simulation_failed():
	chart.update_from_result(player.result)

func _on_selection_changed(selection_manager: SelectionManager):
	# TODO: Do we need new selection? We should query the canvas one.
	set_selection(selection_manager.get_ids())
	
func _on_design_changed(success: bool):
	# Just re-apply current selection
	set_selection(design_ctrl.selection_manager.get_ids())

func set_selection(new_selection: PackedInt64Array):
	self.selection = new_selection
	
	var type_label: String = ""
	var type_names = design_ctrl.get_distinct_types(selection)
	
	if len(type_names) == 0:
		subtitle_label.text = ""
	elif len(type_names) == 1:
		subtitle_label.text = type_names[0]
		type_label = type_names[0]
	else:
		type_label = "multiple types"
		subtitle_label.text = type_label
	
	var distinct_names = design_ctrl.get_distinct_values(selection, "name")

	if selection.is_empty():
		inspect_design()
		return
	elif len(selection) == 1:
		var object: PoieticObject = design_ctrl.get_object(selection[0])
		if object and object.object_name:
			title_label.text = object.object_name
		else:
			title_label.text = "Unnamed"
	else:
		title_label.text = str(len(selection)) + " of " + type_label
	
	
	var traits = design_ctrl.get_shared_traits(selection)
	set_traits(traits)
	
	for panel in traits_container.get_children():
		panel.set_selection(new_selection)

	# Chart
	# TODO: Check whether having a chart is relevant
	chart.series_ids = selection

	chart.show()
	chart.update_from_result(player.result)


func set_traits(traits: Array[String]):
	for child in traits_container.get_children():
		traits_container.remove_child(child)
		
	for trait_name in traits:
		var panel = panel_for_trait(trait_name)
		if not panel:
			continue
		panel.set_controller(design_ctrl)
		traits_container.add_child(panel)
		
	if design_ctrl.has_issues():
		var panel = panel_for_trait("Errors")
		if panel:
			panel.set_controller(design_ctrl)
			traits_container.add_child(panel)

func inspect_design():
	for child in traits_container.get_children():
		traits_container.remove_child(child)

	
	# TODO: Use Global.app.design_controller.get_object()
	# Design Info Attributes:
	#	- title
	#   - abstract
	#   - author
	#   - date
	
	title_label.text = "Design"
	subtitle_label.text = "Design"
	chart.hide()
	var panel = panel_for_trait("Design")
	if not panel:
		return
	panel.set_controller(design_ctrl)
	traits_container.add_child(panel)

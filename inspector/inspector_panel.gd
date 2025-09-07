class_name InspectorPanel extends PanelContainer

@onready var title_label = %InspectorTitle
@onready var subtitle_label = %InspectorSubtitle
@onready var chart = %Chart
@onready var primary_attribute_label = %PrimaryAttributeLabel
# @onready var primary_attribute_icon = %PrimaryAttributeIcon
@onready var traits_container = %TraitsContainer

var selection: SelectionManager

@export var design_ctrl: DesignController
@export var player: ResultPlayer
@export var canvas: DiagramCanvas

func initialize(design_ctrl: DesignController, player: ResultPlayer, canvas: DiagramCanvas):
	self.design_ctrl = design_ctrl
	self.player = player
	self.canvas = canvas
	
	selection = design_ctrl.selection_manager

	design_ctrl.design_changed.connect(_on_design_changed)
	design_ctrl.simulation_finished.connect(_on_simulation_success)
	design_ctrl.simulation_failed.connect(_on_simulation_failed)
	design_ctrl.selection_manager.selection_changed.connect(_on_selection_changed)

func _on_simulation_success(result):
	chart.update_from_result(result)
	
func _on_simulation_failed():
	chart.update_from_result(player.result)

func _on_selection_changed(new_selection):
	# TODO: Do we need new selection? We should query the canvas one.
	set_selection(new_selection)
	
func _on_design_changed(success: bool):
	# Just re-apply current selection
	set_selection(selection)

func set_selection(new_selection):
	self.selection = new_selection
	
	var type_label: String = ""
	var type_names = Global.design.get_distinct_types(selection)
	
	if len(type_names) == 0:
		subtitle_label.text = ""
	elif len(type_names) == 1:
		subtitle_label.text = type_names[0]
		type_label = type_names[0]
	else:
		type_label = "multiple types"
		subtitle_label.text = type_label
	
	
	var distinct_names = Global.design.get_distinct_values(selection, "name")

	if selection.is_empty():
		inspect_design()
		return
	elif selection.count() == 1:
		var object: PoieticObject = Global.design.get_object(selection.get_ids()[0])
		if object and object.object_name:
			title_label.text = object.object_name
		else:
			title_label.text = "Unnamed"
	else:
		title_label.text = str(selection.count()) + " of " + type_label
	
	
	var traits = Global.design.get_shared_traits(selection)
	set_traits(traits)
	
	for panel in traits_container.get_children():
		panel.set_selection(new_selection)

	# Chart
	# TODO: Check whether having a chart is relevant
	var ids = selection.get_ids()
	if ids:
		chart.series_ids = ids
	else:
		chart.series_ids = []

	chart.show()
	chart.update_from_result(player.result)


func set_traits(traits: Array[String]):
	for child in traits_container.get_children():
		traits_container.remove_child(child)
		
	for trait_name in traits:
		var panel = InspectorTraitPanel.panel_for_trait(trait_name)
		if not panel:
			continue
		traits_container.add_child(panel)
		
	if Global.design.has_issues():
		var panel = InspectorTraitPanel.panel_for_trait("Errors")
		if panel:
			traits_container.add_child(panel)

func inspect_design():
	for child in traits_container.get_children():
		traits_container.remove_child(child)

	
	# TODO: Use Global.design.get_design_object()
	# Design Info Attributes:
	#	- title
	#   - abstract
	#   - author
	#   - date
	
	title_label.text = "Design"
	subtitle_label.text = "Design"
	chart.hide()
	var panel = InspectorTraitPanel.panel_for_trait("Design")
	if not panel:
		return
	traits_container.add_child(panel)

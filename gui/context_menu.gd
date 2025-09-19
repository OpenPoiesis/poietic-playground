class_name ContextMenu extends Control

# signal context_menu_item_selected(item: int)
# signal context_menu_cancelled()

@onready var items_container: HBoxContainer = %ItemsContainer

class ContextItem:
	var name: String
	var traits: Array[String]
	# var types: Array[String]
	var allow_multiple: bool
	var issues_only: bool

	func _init(name: String, traits: Array[String], allow_multiple: bool, issues_only: bool = false):
		self.name = name
		self.traits = traits
		self.allow_multiple = allow_multiple
		self.issues_only = issues_only
		
	func matches(traits: Array[String], is_multiple: bool, has_issues: bool) -> bool:
		if is_multiple and !self.allow_multiple:
			return false
		if self.issues_only and !has_issues:
			return false
		if traits.is_empty():
			return true
		for name in traits:
			if self.traits.has(name):
				return true
		return false

@export var canvas_ctrl: CanvasController
@export var selection: PackedInt64Array

func initialize(canvas_ctrl: CanvasController):
	self.canvas_ctrl = canvas_ctrl

func get_single_selection_object() -> PoieticObject:
	if len(selection) != 1:
		return null
	else:
		var single_id = selection[0]
		return canvas_ctrl.design_controller.get_object(single_id)

static var context_items: Array[ContextItem] = [
	ContextItem.new("ResetHandles", ["DiagramConnector"], true),
	ContextItem.new("EditFormula", ["Formula"], false),
	ContextItem.new("EditDelay", ["Delay"], false),
	ContextItem.new("EditSmoothWindow", ["Smooth"], false),
	ContextItem.new("AutoRepair", ["Formula"], true, true),
#	ContextItem.new("Delete", [], true),
]

func update(selection: PackedInt64Array):
	var traits = canvas_ctrl.design_controller.get_shared_traits(selection)
	var has_issues = false
	var count = len(selection)
	for id in selection:
		if !canvas_ctrl.design_controller.issues_for_object(id).is_empty():
			has_issues = true
			break

	for item in context_items:
		var child = items_container.find_child(item.name)
		if not child:
			push_warning("No context menu item: ", item.name)
			continue
		var flag = item.matches(traits, count > 1, has_issues)
		child.visible = flag

	self.reset_size()

func _on_name_button_pressed():
	pass

func _on_formula_button_pressed():
	var single_id = canvas_ctrl.design_controller.selection_manager.selection_of_one()
	if single_id == null:
		return
	var object = canvas_ctrl.design_controller.get_object(single_id)
	
	if not object:
		return
	if not object.has_trait("Formula"):
		return
		
	canvas_ctrl.open_inline_editor("formula", single_id, "formula")
	
func _on_auto_button_pressed():
	canvas_ctrl.close_inline_popup()
	var ids = canvas_ctrl.design_controller.selection_manager.get_ids()

	# FIXME: [REFACTORING] Use selection as provided originally (IMPORTANT!)
	canvas_ctrl.design_controller.auto_connect_parameters(ids)


func _on_delete_button_pressed():
	canvas_ctrl.close_inline_popup()
	# FIXME: [REFACTORING] Move to change controller
	canvas_ctrl.design_controller.delete_selection()


func _on_reset_button_pressed():
	canvas_ctrl.close_inline_popup()
	# FIXME: [REFACTORING] Move to change controller
	canvas_ctrl.design_controller.remove_connector_midpoints_in_selection()


func _on_edit_delay_pressed():
	canvas_ctrl.close_inline_popup()
	var object = canvas_ctrl.get_single_selection_object()
	if object == null:
		return
	canvas_ctrl.open_inline_editor("numeric_attribute", object.object_id, "delay_duration")

func _on_edit_smooth_window_pressed():
	canvas_ctrl.close_inline_popup()
	var object = canvas_ctrl.get_single_selection_object()
	if object == null:
		return
	canvas_ctrl.open_inline_editor("numeric_attribute", object.object_id, "window_time")

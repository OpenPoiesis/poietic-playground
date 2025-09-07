class_name ContextMenu extends CanvasPrompt

# signal context_menu_item_selected(item: int)
# signal context_menu_cancelled()

@onready var items_container: HBoxContainer = %ItemsContainer
var _is_active: bool = false

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

static var context_items: Array[ContextItem] = [
	ContextItem.new("ResetHandles", ["DiagramConnector"], true),
	ContextItem.new("EditFormula", ["Formula"], false),
	ContextItem.new("EditDelay", ["Delay"], false),
	ContextItem.new("EditSmoothWindow", ["Smooth"], false),
	ContextItem.new("AutoRepair", ["Formula"], true, true),
#	ContextItem.new("Delete", [], true),
]

func open(selection: SelectionManager, desired_position: Vector2):
	var traits = Global.design.get_shared_traits(selection)
	var count = selection.count()
	var has_issues = false
	for id in selection.get_ids():
		if !Global.design.issues_for_object(id).is_empty():
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

	self.global_position = Vector2(desired_position.x - get_rect().size.x/2, desired_position.y)
	self.set_process(true)
	self.show()

func close():
	self.set_process(false)
	self.hide()

func _on_name_button_pressed():
	pass

func _on_formula_button_pressed():
	print("Formula pressed")
	var ids = canvas.selection.get_ids()
	assert(len(ids)> 0)
	if len(ids) != 1:
		push_warning("Requested formula edit for multiple objects, using first one in the selection")

	self.close()

	prompt_manager.open_formula_editor_for(ids[0])
	
func _on_auto_button_pressed():
	self.close()
	# FIXME: [REFACTORING] Move to change controller
	# FIXME: [REFACTORING] Use selection as provided originally (IMPORTANT!)
	Global.design.auto_connect_parameters(canvas.selection.get_ids())


func _on_delete_button_pressed():
	self.close()
	# FIXME: [REFACTORING] Move to change controller
	canvas.delete_selection()


func _on_reset_button_pressed():
	self.close()
	# FIXME: [REFACTORING] Move to change controller
	canvas.remove_midpoints_in_selection()


func _on_edit_delay_pressed():
	var ids = canvas.selection.get_ids()
	assert(len(ids)> 0)
	if len(ids) != 1:
		push_warning("Requested value edit for multiple objects, using first one in the selection")

	self.close()

	prompt_manager.open_attribute_editor_for(ids[0], "delay_duration")

func _on_edit_smooth_window_pressed():
	var ids = canvas.selection.get_ids()
	assert(len(ids)> 0)
	if len(ids) != 1:
		push_warning("Requested value edit for multiple objects, using first one in the selection")

	self.close()

	prompt_manager.open_attribute_editor_for(ids[0], "window_time")

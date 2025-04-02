class_name ContextMenu extends PanelContainer

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
	ContextItem.new("AutoRepair", ["Formula"], true, true),
#	ContextItem.new("Delete", [], true),
]

func _ready():
	pass

func _process(delta):
	pass

func update_for_selection(selection: PoieticSelection):
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

func close():
	self.set_process(false)
	self.hide()

func _on_name_button_pressed():
	pass

func _on_formula_button_pressed():
	print("Formula pressed")
	var ids = Global.canvas.selection.get_ids()
	assert(len(ids)> 0)
	if len(ids) != 1:
		push_warning("Requested formula edit for multiple objects, using first one in the selection")

	self.close()
	Global.canvas.open_formula_prompt(ids[0])

func _on_auto_button_pressed():
	self.close()
	Global.design.auto_connect_parameters(Global.canvas.selection.get_ids())


func _on_delete_button_pressed():
	self.close()
	Global.canvas.delete_selection()
	Global.close_modal(Global.modal_node)


func _on_reset_button_pressed():
	self.close()
	Global.canvas.remove_midpoints_in_selection()

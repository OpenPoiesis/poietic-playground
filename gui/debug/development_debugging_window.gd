extends Window

var design_ctrl: DesignController
@export var object_ids: PackedInt64Array = PackedInt64Array()

@onready var object_list: ItemList = %ObjectList
@onready var id_label: Label = %IDLabel
@onready var type_label: Label = %TypeLabel
@onready var traits_label: Label = %TraitsLabel
@onready var structure_label: Label = %StructureLabel
@onready var attribute_tree: Tree = %AttributeTree

func _ready():
	close_requested.connect(_on_close_requested)
	attribute_tree.set_column_title(0, "Attribute")
	attribute_tree.set_column_title(1, "Value")
	attribute_tree.set_column_titles_visible(true)
	clear_details()

func initialize(design_ctrl: DesignController):
	self.design_ctrl = design_ctrl
	load_object_list()

func load_object_list():
	object_list.clear()

	if object_ids.is_empty():
		object_list.add_item("(No objects)")
		return

	var sorted_ids = object_ids
	sorted_ids.sort()

	for object_id in sorted_ids:
		var item_label: String	
		var object: PoieticObject = design_ctrl.get_object(object_id)
		if object == null:
			item_label = str(object_id) + " (not found)"
		else:
			var object_name: String
			if object.object_name == null:
				object_name = ""
			else:
				object_name = " " + object.object_name
			
			item_label = str(object_id) + object_name + " - " + object.type_name
			
		var index = object_list.add_item(item_label)
		object_list.set_item_metadata(index, object_id)

func _on_object_list_item_selected(index: int):
	var object_id = object_list.get_item_metadata(index)
	if object_id == null:
		clear_details()
		return

	display_object_details(object_id)
	
	design_ctrl.selection_manager.replace(PackedInt64Array([object_id]))

func display_object_details(object_id: int):
	if design_ctrl == null:
		show_error("Design controller not initialized")
		return

	var object: PoieticObject = design_ctrl.get_object(object_id)
	if object == null:
		show_error("Object not found: " + str(object_id))
		return

	# Display ID and Type
	id_label.text = "ID: " + str(object.object_id)
	type_label.text = "Type: " + str(object.type_name)

	# Display Traits
	var traits = object.get_traits()
	if traits.is_empty():
		traits_label.text = "(none)"
	else:
		traits_label.text = ", ".join(traits)

	# Display Attributes
	attribute_tree.clear()
	var root = attribute_tree.create_item()

	var attribute_keys = object.get_attribute_keys()
	if attribute_keys.is_empty():
		var item = attribute_tree.create_item(root)
		item.set_text(0, "(no attributes)")
		item.set_text(1, "")
	else:
		for attr_key in attribute_keys:
			var value = object.get_attribute(attr_key)
			var item = attribute_tree.create_item(root)
			item.set_text(0, attr_key)

			if value == null:
				item.set_text(1, "(null)")
			else:
				item.set_text(1, str(value))

	# Display edge information if this is an edge
	if object.origin != null and object.target != null:
		structure_label.text = "Structure: edge " + str(object.origin) + " → " + str(object.target)
	else:
		structure_label.text = "Structure: node"

func clear_details():
	id_label.text = "ID: -"
	type_label.text = "Type: -"
	traits_label.text = "-"
	attribute_tree.clear()

func show_error(message: String):
	clear_details()
	id_label.text = "Error"
	type_label.text = message

func refresh():
	"""Reload the object list and clear selection"""
	load_object_list()
	clear_details()

func _on_close_requested():
	hide()

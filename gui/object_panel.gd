class_name ObjectPanel extends PanelContainer

signal selection_changed(identifier: String)

@onready var object_list: GridContainer = $ObjectList
var prototype_item: Button

var items: Array[Button] = []

var selected_item: String = "":
	set(value):
		for item in items:
			if item.get_meta(&"object_type_name") == value:
				item.set_pressed_no_signal(true)
			else:
				item.set_pressed_no_signal(false)
			
		selected_item = value
		selection_changed.emit(selected_item)

# Called when the node enters the scene tree for the first time.
func _ready():
	var item: Button = Button.new()
	item.focus_mode = Control.FOCUS_NONE
	item.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	item.expand_icon = true
	item.theme_type_variation = "ObjectListItem"
	item.custom_minimum_size = Vector2(60,50)
	item.toggle_mode = true
	
	prototype_item = item

	clear()
	# Global.tool_changed.connect(_on_tool_changed)
	# hide()

func clear():
	var children = object_list.get_children()
	for child in children:
		object_list.remove_child(child)
	items.clear()
	
func _on_tool_changed(tool: CanvasTool):
	if tool is SelectionTool:
		self.hide()
		pass
	elif tool is PlaceTool:
		self.show()
		load_node_pictograms()
	elif tool is ConnectTool:
		self.show()
		load_connector_pictograms()
	else:
		pass # unknown tool

func load_node_pictograms():
	var placeable_node_types: Array[String] = ["Stock", "FlowRate", "Auxiliary", "Delay", "Smooth"]
	clear()
	for name in placeable_node_types:
		var pictogram = Global.get_pictogram(name)
		add_item(pictogram.name.capitalize(), pictogram.name, pictogram.get_texture())

func load_connector_pictograms():
	clear()

	var flow_texture = load("res://resources/icons/white/arrow-outlined.png")
	add_item("Flow", "Flow", flow_texture)	

	var param_texture = load("res://resources/icons/white/arrow-parameter.png")
	add_item("Parameter", "Parameter", param_texture)

func add_item(label: String, type_name: String, texture: Texture):
	var item: Button = prototype_item.duplicate()
	object_list.add_child(item)

	item.text = label
	item.icon = texture
	item.set_meta(&"object_type_name", type_name)
	items.append(item)
	item.pressed.connect(_on_item_pressed.bind(item))
	
func _on_item_pressed(item: Button):
	var type_name = item.get_meta(&"object_type_name")
	selected_item = type_name
	print("Item pressed: ", type_name)

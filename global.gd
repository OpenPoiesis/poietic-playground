extends Node

# Constants

const icon_scale: float = 1.0
const all_icon_names: Array[String] = ["select", "place", "connect", "run", "stop", "restart", "loop"]

# Tools

var selection_tool = SelectionTool.new()
var place_tool = PlaceTool.new()
var connect_tool = ConnectTool.new()

# Poietic

var metamodel: PoieticMetamodel
var design: PoieticDesignController

# Resources

var icons: Array[Icon] = []

# State

var modal_node: Node = null
var current_tool: CanvasTool = selection_tool
var canvas: DiagramCanvas = null

signal tool_changed(tool: CanvasTool)

func initialize():
	print("Initializing globals ...")
	InspectorTraitPanel._initialize_panels()
	_initialize_icons()
	Pictogram._load_pictograms()

	print("Initializing design ...")

	metamodel = PoieticMetamodel.new()
	print("Metamodel types: ", metamodel.get_type_list())
	print("Metamodel traits: ", metamodel.get_trait_list())

	design = PoieticDesignController.new()
	_create_demo_design()
	
	print("Done initializing.")
	
func _initialize_icons():
	for name in all_icon_names:
		var icon = Icon.new(name)
		var path = "res://resources/icons/" + name + ".svg"
		icon.load_from_path(path)
		icons.append(icon)

func _create_demo_design():
	var trans = design.new_transaction()
	var a = trans.create_node("Stock", "source", {"position": Vector2(400, 300), "formula": str(randi() % 100)})
	var b = trans.create_node("FlowRate", "flow", {"position": Vector2(600, 300), "formula": str(randi() % 100)})
	var c = trans.create_node("Stock", "target", {"position": Vector2(800, 300), "formula": str(randi() % 100)})
	var ab = trans.create_edge("Flow", a, b)
	var bc = trans.create_edge("Flow", b, c)
	design.accept(trans)
	print("Created demo nodes: ", design.get_diagram_nodes(), " edges: ", design.get_diagram_edges())
	# TODO: Emit Design changed signal to compile and init simulation
	GlobalSimulator.initialize_result()


func _initialize_toolbar_icons():
	pass

func get_icon(name: String) -> Icon:
	for icon in icons:
		if icon.name == name:
			return icon
	return null


	# "res://resources/icons/connect.svg"
func get_gui() -> Node:
	return get_node("/root/Main/Gui")
	
func set_modal(node: Node):
	if modal_node:
		push_warning("Setting modal while having one already set")
		get_gui().remove_child(modal_node)

	modal_node = node
	get_gui().add_child(modal_node)

func close_modal(node: Node):
	if node != modal_node:
		# Sanity check
		push_error("Trying to close a different modal")
	if modal_node:
		get_gui().remove_child(modal_node)
		modal_node = null

func change_tool(tool: CanvasTool) -> void:
	if current_tool:
		current_tool.release()
	current_tool = tool
	tool_changed.emit(tool)

func open_object_context_menu(object: Variant, position: Vector2):
	var menu = CallOut.new()
	var box = HBoxContainer.new()
	menu.add_child(box)
	var b1 = Button.new()
	b1.text = "one"
	box.add_child(b1)
	menu.set_callout_point(position)
	# canvas.add_child(palette)
	Global.set_modal(menu)

extends Node

# View Preferences

var show_value_indicators: bool = true

# Canvas Tools
var selection_tool = SelectionTool.new()
var place_tool = PlaceTool.new()
var connect_tool = ConnectTool.new()

# Poietic: Data
var metamodel: PoieticMetamodel
var result: PoieticResult

# Poietic: Controllers/Managers/Functioning components
var design: PoieticDesignController
var player: PoieticPlayer

# Application State
var modal_node: Node = null
var current_tool: CanvasTool = selection_tool
var canvas: DiagramCanvas = null

signal tool_changed(tool: CanvasTool)

static var _all_pictograms: Dictionary[String,Pictogram] = {}
static var default_pictogram: Pictogram

func initialize():
	print("Initializing globals ...")

	InspectorTraitPanel._initialize_panels()
	self._load_pictograms()

	metamodel = PoieticMetamodel.new()
	design = PoieticDesignController.new()
	
	print("Done initializing globals.")

static func _load_pictograms():
	# TODO: Adjust the scales based on the rules for the pictogram sizes (not yet defined)
	var circle = CircleShape2D.new()
	circle.radius = Pictogram.tile_size / Pictogram.default_image_scale
	var square = RectangleShape2D.new()
	square.size = Vector2(Pictogram.tile_size, Pictogram.tile_size)
	var rectangle = RectangleShape2D.new()
	rectangle.size = Vector2(Pictogram.tile_size * 3, Pictogram.tile_size * 2)
	var flow_shape = CircleShape2D.new()
	flow_shape.radius = Pictogram.tile_size * 0.8
	
	_all_pictograms.clear()
	
	default_pictogram = Pictogram.new("Unknown", square)
	_all_pictograms["default"] = default_pictogram
	var pictograms: Array[Pictogram]= [
		Pictogram.new("Stock", rectangle),
		Pictogram.new("FlowRate", flow_shape),
		Pictogram.new("Auxiliary", circle),
		Pictogram.new("GraphicalFunction", circle),
		Pictogram.new("Smooth", square),
		Pictogram.new("Delay", square)
	]
	for pictogram in pictograms:
		_all_pictograms[pictogram.name] = pictogram
		
	# TODO: Aliases
	# _all_pictograms["FlowRate"] = _all_pictograms["Flow"]
	
static func get_pictogram(name: String) -> Pictogram:
	var pictogram = _all_pictograms.get(name)
	if pictogram:
		return pictogram
	else:
		push_warning("Unknown pictogram: ", name)
		return default_pictogram


static func get_placeable_pictograms() -> Array[Pictogram]:
	var result: Array[Pictogram]
	for name in Global.metamodel.get_type_list_with_trait("DiagramNode"):
		result.append(get_pictogram(name))
	return result


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
		current_tool.tool_released()
	current_tool = tool
	current_tool.tool_selected()
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

func _notification(what):
	if what == Node.NOTIFICATION_WM_CLOSE_REQUEST:
		_all_pictograms.clear()

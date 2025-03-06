class_name ToolBar extends PanelContainer

const empty_options_tab = 0
const connect_options_tab = 1

@onready var undo_button: TextureButton = %UndoButton
@onready var redo_button: TextureButton = %RedoButton

@onready var selection_tool_button: IconButton = %SelectionToolButton
@onready var place_tool_button: IconButton = %PlaceToolButton
@onready var connection_tool_button: IconButton = %ConnectToolButton

@onready var tool_options: TabContainer = %ToolOptions
@onready var options_separator: VSeparator = %OptionsSeparator
# var tool_options: PanelContainer

var items: Array[Item] = []

class Item:
	var tag: int
	var label: String
	var icon: Icon
	
	func _init(tag: int, label: String, icon: Icon):
		self.tag = tag
		self.label = label
		self.icon = icon

func _ready():
	_initialize_connection_types()
	tool_options.visible = false
	Global.get_gui().add_child.call_deferred(tool_options)

	Global.tool_changed.connect(_on_tool_changed)
	Global.change_tool(Global.selection_tool)

func _initialize_connection_types():
	var connection_types: Array[String] = ["Flow", "Parameter", "Comment"]
	for type in connection_types:
		pass

func _on_tool_changed(tool: CanvasTool):
	if tool is SelectionTool:
		selection_tool_button.set_pressed_no_signal(true)
		place_tool_button.set_pressed_no_signal(false)
		connection_tool_button.set_pressed_no_signal(false)
		tool_options.current_tab = empty_options_tab
	elif tool is PlaceTool:
		selection_tool_button.set_pressed_no_signal(false)
		place_tool_button.set_pressed_no_signal(true)
		connection_tool_button.set_pressed_no_signal(false)
		tool_options.current_tab = empty_options_tab
	elif tool is ConnectTool:
		selection_tool_button.set_pressed_no_signal(false)
		place_tool_button.set_pressed_no_signal(false)
		connection_tool_button.set_pressed_no_signal(true)
		tool_options.current_tab = connect_options_tab
	else:
		push_error("Unknown tool: ", tool)
	selection_tool_button.update_shader()
	place_tool_button.update_shader()
	connection_tool_button.update_shader()

func _on_selection_tool_button_pressed():
	Global.change_tool(Global.selection_tool)

func _on_place_tool_button_pressed():
	Global.change_tool(Global.place_tool)

func _on_connect_tool_button_pressed():
	Global.change_tool(Global.connect_tool)


func _on_undo_button_pressed():
	if Global.design.can_undo():
		Global.design.undo()
	else:
		printerr("Trying to undo while having nothing to undo")

func _on_redo_button_pressed():
	if Global.design.can_redo():
		Global.design.redo()
	else:
		printerr("Trying to redo while having nothing to redo")


func _on_tool_options_button_toggled(toggled_on):
	tool_options.visible = toggled_on
	options_separator.visible = toggled_on
	print("Tool options toggled: ", toggled_on)


func _on_flow_connection_type_button_pressed():
	print("Flow type selected")
	%ConnectOptions/FlowConnectionTypeButton.set_pressed_no_signal(true)
	%ConnectOptions/ParameterConnectionTypeButton.set_pressed_no_signal(false)
	Global.connect_tool.type_name = "Flow"


func _on_parameter_connection_type_button_pressed():
	print("Param type selected")
	%ConnectOptions/FlowConnectionTypeButton.set_pressed_no_signal(false)
	%ConnectOptions/ParameterConnectionTypeButton.set_pressed_no_signal(true)
	Global.connect_tool.type_name = "Parameter"

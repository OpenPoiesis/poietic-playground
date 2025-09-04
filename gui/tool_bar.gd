class_name ToolBar extends PanelContainer

@onready var selection_tool_button: Button = %SelectionToolButton
@onready var place_tool_button: Button = %PlaceToolButton
@onready var connection_tool_button: Button = %ConnectToolButton
@onready var pan_tool_button: Button = %PanToolButton

func _on_tool_changed(tool: CanvasTool):
	if tool is SelectionTool:
		selection_tool_button.set_pressed_no_signal(true)
		place_tool_button.set_pressed_no_signal(false)
		connection_tool_button.set_pressed_no_signal(false)
		pan_tool_button.set_pressed_no_signal(false)
	elif tool is PlaceTool:
		selection_tool_button.set_pressed_no_signal(false)
		place_tool_button.set_pressed_no_signal(true)
		connection_tool_button.set_pressed_no_signal(false)
		pan_tool_button.set_pressed_no_signal(false)
	elif tool is ConnectTool:
		selection_tool_button.set_pressed_no_signal(false)
		place_tool_button.set_pressed_no_signal(false)
		connection_tool_button.set_pressed_no_signal(true)
		pan_tool_button.set_pressed_no_signal(false)
	elif tool is PanTool:
		selection_tool_button.set_pressed_no_signal(false)
		place_tool_button.set_pressed_no_signal(false)
		connection_tool_button.set_pressed_no_signal(false)
		pan_tool_button.set_pressed_no_signal(true)
	else:
		push_error("Unknown tool: ", tool)

func _on_selection_tool_button_pressed():
	Global.change_tool(Global.selection_tool)

func _on_place_tool_button_pressed():
	Global.change_tool(Global.place_tool)

func _on_connect_tool_button_pressed():
	Global.change_tool(Global.connect_tool)

func _on_pan_tool_button_pressed():
	Global.change_tool(Global.pan_tool)

class_name CanvasTool extends Node

# FIXME: REFACTORING BEGIN
var canvas: PoieticCanvas
var diagram_controller: PoieticDiagramController
var design: PoieticDesignController
var prompt_manager: CanvasPromptManager

var object_panel: ObjectPanel
var last_selected_object_identifier: String = ""

# FIXME: REFACTORING END

var initial_pointer_position: Vector2 = Vector2()
var is_engaged: bool = false

func initialize(diagram_controller: PoieticDiagramController, design: PoieticDesignController, prompt_manager: CanvasPromptManager):
	self.diagram_controller = diagram_controller
	self.canvas = diagram_controller.canvas
	self.design = design
	self.prompt_manager = prompt_manager

func tool_name() -> String:
	return "default"

func wants_hover_events() -> bool:
	return false # Override this

func handle_input(event: InputEvent) -> bool:
	var is_consumed: bool = false
	if event is InputEventMouseButton:
		var mouse_position = event.global_position
		if event.is_pressed():
			initial_pointer_position = mouse_position
			is_consumed = input_began(event, mouse_position)
		elif event.is_released():
			is_consumed = input_ended(event, mouse_position)
			initial_pointer_position = Vector2()
	elif event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_LEFT:
			is_consumed = input_moved(event, event.relative / canvas.zoom_level)
		elif wants_hover_events():  # Only process hover if tool wants it
			is_consumed = input_hover(event, event.global_position)
	elif event.is_canceled():
		is_consumed = input_cancelled(event)
		initial_pointer_position = Vector2()
	return is_consumed

func tool_selected():
	if object_panel:
		object_panel.hide()

func input_began(_event: InputEvent, _pointer_position: Vector2) -> bool:
	return false
	
func input_ended(_event: InputEvent, _pointer_position: Vector2) -> bool:
	return false
	
func input_moved(_event: InputEvent, _move_delta: Vector2) -> bool:
	return false
	
func input_cancelled(_event: InputEvent) -> bool:
	return false

func input_hover(_event: InputEvent, _pointer_position: Vector2) -> bool:
	return false  # Default implementation consumes nothing

## Release the tool.
## Called when another tools is selected.
func tool_released():
	pass

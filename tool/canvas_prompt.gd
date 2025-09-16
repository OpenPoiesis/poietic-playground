class_name CanvasPrompt extends Control

# TODO: Use this
#class Context:
	#var objetcs: PackedInt64Array
	#var attribute: String
	#var value: Variant

@export var canvas: DiagramCanvas
@export var prompt_manager: CanvasPromptManager
@export var is_active: bool

func initialize(canvas: DiagramCanvas, manager: CanvasPromptManager):
	self.canvas = canvas
	self.prompt_manager = manager

func NEW_open(position: Vector2, attribute: String, object: Variant):
	pass
	
func NEW_close():
	pass
	
func NEW_cancel():
	pass
	

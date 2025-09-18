class_name CanvasInlineEditor extends Control

# TODO: Use this
#class Context:
	#var objetcs: PackedInt64Array
	#var attribute: String
	#var value: Variant

@export var canvas_ctrl: CanvasController
@export var is_active: bool

## ID of object being edited
@export var object_id: int

## Attribute being edited
@export var attribute_name: String

## Original attribute value. Type depeds on the attribute, object and editor.
@export var original_value: Variant

func initialize(canvas_ctrl: CanvasController):
	self.canvas_ctrl = canvas_ctrl

func open(object_id: int, attribute: String, value: Variant):
	push_error("Editor must override 'begin_editing(...)'")

func close():
	pass
	
func cancel():
	pass

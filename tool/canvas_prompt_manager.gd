## Prompt manager manages context specific user inputs that are associated phyisically and visually
## with objects in the canvas.
##
## Prompt manager opens and closes prompts, makes sure only one prompt is open and hands-off
## prompt results in form of signals.
##
class_name DEPRECATED_CanvasPromptManager extends Node

@onready var formula_prompt: FormulaInlineEditor = $FormulaPrompt
@onready var label_prompt: NameInlineEditor = $LabelPrompt
@onready var attribute_prompt: NumericAttributeEditor = $AttributePrompt
@onready var context_menu: ContextMenu = $ContextMenu
@onready var issue_prompt: IssuesPopup = $IssuePrompt

var current_prompt: Control = null
var canvas_ctrl: CanvasController = null
var canvas: DiagramCanvas = null

func open_formula_editor(object_id: int, text: String, center: Vector2):
	close()
	current_prompt = formula_prompt
	formula_prompt.open(object_id, "formula", text, center)

func open_formula_editor_for(object_id: int):
	var object: PoieticObject = Global.design.get_object(object_id)
	if object == null:
		return
	var position = canvas.prompt_position(object_id)
	var formula = object.get_attribute("formula")
	open_formula_editor(object_id, formula, position)

func open_attribute_editor(object_id: int, text: String, center: Vector2, attribute: String):
	close()
	current_prompt = attribute_prompt
	
	attribute_prompt.set_label(attribute)
	attribute_prompt.open(object_id, attribute, text, center)

func open_attribute_editor_for(object_id: int, attribute: String):
	var position = canvas.default_prompt_position(object_id)
	var object: PoieticObject = Global.design.get_object(object_id)
	var value = object.get_attribute(attribute)
	var string_value: String
	if value:
		string_value = str(value)
	else:
		string_value = ""
	open_attribute_editor(object_id, string_value, position, attribute)

func open_context_menu(selection: SelectionManager, desired_position: Vector2):
	# var menu: PanelContainer = preload("res://gui/context_menu.tscn").instantiate()
	close()
	current_prompt = context_menu
	# FIXME: Open this
	context_menu.open(selection, adjust_position(context_menu, desired_position))


func open_issues_for(object_id: int):
	close()
	current_prompt = issue_prompt

	var position = canvas.default_prompt_position(object_id)
	var object: PoieticObject = Global.design.get_object(object_id)
	var issues = Global.design.issues_for_object(object_id)
	
	issue_prompt.open(object_id, issues, position)

func adjust_position(prompt, position: Vector2) -> Vector2:
	var result: Vector2 = position
	var prompt_size = prompt.get_size()
	var vp_size = get_viewport().size
	if result.x < 0:
		result.x = 0
	if result.y < 0:
		result.y = 0
	if result.x + prompt_size.x > vp_size.x:
		result.x = vp_size.x - prompt_size.x
	if result.y + prompt_size.y > vp_size.y:
		result.y = vp_size.y - prompt_size.y
	return result

func close():
	if current_prompt:
		current_prompt.close()
	current_prompt = null

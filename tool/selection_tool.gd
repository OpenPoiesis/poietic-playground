class_name SelectionTool extends CanvasTool

# TODO: Target Priority
# 1. Selection -> Handles
# 2. Objects
# 3. Prompts
# Canvas should sort by (is selected?, z-index, target type)
# Where:
# selected > not selected
# handle > object > prompt

var last_pointer_position = Vector2()
enum SelectToolState {
	EMPTY, OBJECT_HIT, OBJECT_SELECT, OBJECT_MOVE, HANDLE_HIT, HANDLE_MOVE
}
var state: SelectToolState = SelectToolState.EMPTY

var dragging_handle: Handle = null

func tool_name() -> String:
	return "select"

func tool_released():
	if prompt_manager:
		prompt_manager.close()
	
func input_began(event: InputEvent, pointer_position: Vector2) -> bool:
	print("HERE INPTSDSF A")
	
	var target: DiagramCanvas.HitTarget = canvas.hit_target(pointer_position)
	# TODO: Do not close formula editor
	prompt_manager.close()
	if not target:
		canvas.selection.clear()
		state = SelectToolState.OBJECT_SELECT
		return true

	print("TARGET: ", target, " TYPE: ", target.type, " (debugging pictogram hit)")
	match target.type:
		DiagramCanvas.HitTargetType.OBJECT:
			var object: DiagramObject = target.object as DiagramObject
			if event.shift_pressed:
				canvas.selection.toggle(object.object_id)
			else:
				if canvas.selection.is_empty() or !canvas.selection.contains(object.object_id):
					canvas.selection.replace(PackedInt64Array([object.object_id]))
				else:
					# FIXME: [REFACTORING] Make this DesignCanvas.get_context_menu_position(click_position)
					var box = canvas.selection_bounding_box()
					var position = 	Vector2(box.get_center().x, box.end.y)
					prompt_manager.open_context_menu(canvas.selection, canvas.to_global(position))

			last_pointer_position = pointer_position
			state = SelectToolState.OBJECT_HIT
		DiagramCanvas.HitTargetType.HANDLE:
			state = SelectToolState.HANDLE_HIT
			dragging_handle = target.object as Handle
		DiagramCanvas.HitTargetType.NAME:
			# TODO: Move this to Canvas
			var node: DiagramNode = target.object as DiagramNode
			canvas.selection.replace(PackedInt64Array([node.object_id]))
			prompt_manager.open_name_editor_for(node.object_id)
		DiagramCanvas.HitTargetType.PRIMARY_ATTRIBUTE:
			# TODO: Not sure whether this is a good idea, but it is only directly visible way
			var node: DiagramNode = target.object as DiagramNode
			canvas.selection.replace(PackedInt64Array([node.object_id]))
			prompt_manager.open_formula_editor_for(node.object_id)
		DiagramCanvas.HitTargetType.ERROR_INDICATOR:
			var node: DiagramNode = target.object as DiagramNode
			canvas.selection.replace(PackedInt64Array([node.object_id]))
			prompt_manager.open_issues_for(node.object_id)
		_ :
			push_warning("Unhandled hit target type: ", target.type)
	return true

func input_moved(event: InputEvent, move_delta: Vector2) -> bool:
	var mouse_position = event.global_position
	last_pointer_position += move_delta
	prompt_manager.close()

	match state:
		SelectToolState.OBJECT_SELECT:
			pass
		SelectToolState.OBJECT_HIT:
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
			canvas.begin_drag_selection(mouse_position)
			state = SelectToolState.OBJECT_MOVE
		SelectToolState.OBJECT_MOVE:
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
			canvas.drag_selection(move_delta)
		SelectToolState.HANDLE_HIT:
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
			canvas.begin_drag_handle(dragging_handle, mouse_position)
			state = SelectToolState.HANDLE_MOVE
		SelectToolState.HANDLE_MOVE:
			Input.set_default_cursor_shape(Input.CURSOR_DRAG)
			canvas.drag_handle(dragging_handle, move_delta)
	return true
	
func input_ended(_event: InputEvent, mouse_position: Vector2) -> bool:
	match state:
		SelectToolState.OBJECT_SELECT:
			pass
		SelectToolState.OBJECT_HIT:
			pass
		SelectToolState.OBJECT_MOVE:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			canvas.finish_drag_selection(mouse_position)
		SelectToolState.HANDLE_MOVE:
			Input.set_default_cursor_shape(Input.CURSOR_ARROW)
			canvas.finish_drag_handle(dragging_handle, mouse_position)
			dragging_handle = null

	state = SelectToolState.EMPTY
	return true

class_name SelectionTool extends CanvasTool

var last_pointer_position = Vector2()
enum SelectToolState {
	EMPTY, OBJECT_HIT, OBJECT_SELECT, OBJECT_MOVE, HANDLE_HIT, HANDLE_MOVE
}
var state: SelectToolState = SelectToolState.EMPTY

var dragging_handle: Handle = null

func tool_name() -> String:
	return "select"
	
func input_began(event: InputEvent, pointer_position: Vector2) -> bool:
	var target: DiagramCanvas.HitTarget = canvas.hit_target(pointer_position)
	if not target:
		Global.get_label_editor().cancel()
		close_context_menu()
		canvas.selection.clear()
		state = SelectToolState.OBJECT_SELECT
		return true

	Global.get_label_editor().cancel()
	match target.type:
		DiagramCanvas.HitTargetType.OBJECT:
			var object: DiagramObject = target.object as DiagramObject
			if event.shift_pressed:
				canvas.selection.toggle(object.object_id)
			else:
				if canvas.selection.is_empty() or !canvas.selection.contains(object.object_id):
					canvas.selection.replace(PackedInt64Array([object.object_id]))
				else:
					open_context_menu(pointer_position)
			last_pointer_position = pointer_position
			state = SelectToolState.OBJECT_HIT
		DiagramCanvas.HitTargetType.HANDLE:
			state = SelectToolState.HANDLE_HIT
			dragging_handle = target.object as Handle
		DiagramCanvas.HitTargetType.NAME:
			# TODO: Move this to Canvas
			var node: DiagramNode = target.object as DiagramNode
			canvas.selection.replace(PackedInt64Array([node.object_id]))
			var center = Vector2(node.global_position.x, node.name_label.global_position.y)
			node.begin_label_edit()
			Global.get_label_editor().open(node.object_id, node.object_name, center)
			
	return true

func input_moved(event: InputEvent, move_delta: Vector2) -> bool:
	var mouse_position = event.global_position
	last_pointer_position += move_delta
	close_context_menu()
	Global.get_label_editor().cancel()
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

# Context Menu
# ------------------------------------------------------------
func open_context_menu(pointer_position: Vector2):
	# var menu: PanelContainer = preload("res://gui/context_menu.tscn").instantiate()
	var menu: ContextMenu = Global.get_context_menu()
	var size = menu.get_rect().size
	
	var box = canvas.selection_bounding_box()
	
	menu.global_position = Vector2(box.get_center().x - size.x/2, box.end.y)
	menu.update_for_selection(canvas.selection)
	prints("--- open context at: ", pointer_position)
	menu.set_process(true)
	menu.show()

func close_context_menu():
	var menu: ContextMenu = Global.get_context_menu()
	menu.set_process(false)
	menu.hide()

func is_context_menu_open() -> bool:
	return Global.modal_node != null

# Label Editor
# ------------------------------------------------------------
func _on_label_edit_submitted(object_id: int, new_text: String):
	Global.get_label_editor().hide()

	assert(object_id != -1, "Editing cancelled with placeholder object ID (-1)")
		
	var object = canvas.get_diagram_node(object_id)
	assert(object, "Editing finished with unknown node ID")
	
	object.finish_label_edit()

	if object.object_name == new_text:
		print("Name not changed")
		return

	var trans = Global.design.new_transaction()
	trans.set_attribute(object_id, "name", new_text)
	Global.design.accept(trans)

func _on_label_edit_cancelled(object_id: int):
	assert(object_id != -1, "Editing cancelled with placeholder object ID (-1)")
	print("Cancelled")
	Global.get_label_editor().hide()

	var object = canvas.get_diagram_node(object_id)
	assert(object, "Editing cancelled with unknown node ID")

	object.finish_label_edit()

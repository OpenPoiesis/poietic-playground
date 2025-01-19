class_name SelectionTool extends CanvasTool

var last_pointer_position = Vector2()

enum SelectToolState {
	EMPTY, HIT, SELECT, MOVE
}
var state: SelectToolState = SelectToolState.EMPTY

func tool_name() -> String:
	return "select"
	
func input_began(event: InputEvent, pointer_position: Vector2):
	var candidate = canvas.object_at_position(pointer_position)
	if candidate:
		if event.shift_pressed:
			canvas.selection.toggle(candidate)
		else:
			if canvas.selection.is_empty() or !canvas.selection.contains(candidate):
				canvas.selection.replace([candidate])

		last_pointer_position = pointer_position
		state = SelectToolState.HIT
	else:
		# print("Clearing selection")
		canvas.selection.clear()
		state = SelectToolState.SELECT
		# Initiate rubber band

func input_moved(event: InputEvent, move_delta: Vector2):
	match state:
		SelectToolState.SELECT:
			pass
		SelectToolState.HIT, SelectToolState.MOVE:
			canvas.move_selection(move_delta)
			last_pointer_position += move_delta
			state == SelectToolState.MOVE

func input_ended(event: InputEvent, mouse_position: Vector2):
	state = SelectToolState.EMPTY

func input_cancelled(event: InputEvent):
	pass

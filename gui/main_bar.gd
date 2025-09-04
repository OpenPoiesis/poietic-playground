extends PanelContainer

@onready var undo_button: Button = %UndoButton
@onready var redo_button: Button = %RedoButton

func _on_undo_button_pressed():
	if Global.app.can_undo():
		Global.app.undo()
	else:
		printerr("Trying to undo while having nothing to undo")

func _on_redo_button_pressed():
	if Global.app.can_redo():
		Global.app.redo()
	else:
		printerr("Trying to redo while having nothing to redo")

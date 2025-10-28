class_name GraphCurvesInlineEditor extends CanvasInlineEditor

@export var editor_window: GraphicalCurvesEditorWindow

@onready var curve_editor: FunctionCurveEditor = $MarginContainer/VBoxContainer/CurveEditor

var _is_active: bool = false

func open(object: PoieticObject, attribute: String, value: Variant):
	self.object_id = object.object_id

	var points: PackedVector2Array = object.get_attribute(attribute)
	if (points as PackedVector2Array) == null:
		points = PackedVector2Array()

	var interpolation_method = object.get_attribute("interpolation_method")
	if (interpolation_method as String)	== null:
		interpolation_method = "linear"

	curve_editor.points = points
	curve_editor.set_interpolation_method_name(interpolation_method.to_lower())
	
	prints("--> inline edit curves: ",points, curve_editor.interpolation_method_name())
	
	if editor_window == null:
		%OpenEditorWindowButton.hide()
	else:
		%OpenEditorWindowButton.show()
	
	_is_active = true
	set_process(true)
	show()

func _on_reject_curves_button_pressed():
	cancel()

func _on_open_editor_window_button_pressed():
	var window = editor_window as GraphicalCurvesEditorWindow
	if window == null:
		push_error("No curves editor window assigned")
		return

	window.set_content(
		object_id,
		curve_editor.points,
		curve_editor.interpolation_method_name()
	)
	window.show()
	if !window.curves_submitted.is_connected(_on_window_curves_submitted):
		window.curves_submitted.connect(_on_window_curves_submitted)
	if !window.curves_submitted.is_connected(_on_window_curves_dismissed):
		window.curves_dismissed.connect(_on_window_curves_dismissed)
	self.close()

func _on_accept_curves_button_pressed():
	accept_curves(self.object_id, curve_editor.points, curve_editor.interpolation_method_name())

func _on_window_curves_submitted(points: PackedVector2Array, interpolation_name: String):
	var window = editor_window as GraphicalCurvesEditorWindow
	if window == null:
		push_error("Unknown curves edit window submit request")
		return
		
	if window.object_id == -1:
		push_error("Window object ID not set")
		dismiss_window()
	
	print("Accept window curves: ", window.object_id, points, interpolation_name)
	accept_curves(window.object_id, points, interpolation_name)
	dismiss_window()

func _on_window_curves_dismissed():
	dismiss_window()

func dismiss_window():
	if editor_window != null:
		editor_window.object_id = -1
		editor_window.curves_submitted.disconnect(_on_window_curves_submitted)
		editor_window.curves_dismissed.disconnect(_on_window_curves_dismissed)
		editor_window.hide()

func accept_curves(object_id: int, points: PackedVector2Array, interpolation_name: String):
	prints("--- ACCEPT CURVES: ", object_id, points, interpolation_name)
	set_process(false)
	hide()
	canvas_ctrl.commit_graphical_curves_edit(object_id, points, interpolation_name)
	_is_active = false
	object_id = -1

func close():
	if !_is_active:
		return
	set_process(false)
	hide()
	_is_active = false
	object_id = -1

func cancel():
	if !_is_active:
		return
	close()

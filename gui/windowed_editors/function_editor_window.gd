class_name GraphicalCurvesEditorWindow extends Window

signal curves_submitted(points: PackedVector2Array, interpolation: String)
signal curves_dismissed()

# Data
## Object ID the window is editing the curves for
@export var object_id: int
@export var column_x_label: String = "X"
@export var column_y_label: String = "Y"

# Node references
@onready var curve_editor: FunctionCurveEditor = %GraphControl
@onready var points_table: Tree = %PointsTable
@onready var add_button: Button = %AddButton
@onready var remove_button: Button = %RemoveButton
@onready var min_x_edit: LineEdit = %MinXEdit
@onready var max_x_edit: LineEdit = %MaxXEdit
@onready var min_y_edit: LineEdit = %MinYEdit
@onready var max_y_edit: LineEdit = %MaxYEdit
@onready var linear_button: Button = %LinearButton
@onready var step_button: Button = %StepButton
@onready var cubic_button: Button = %CubicButton
@onready var cancel_button: Button = %CancelButton
@onready var set_button: Button = %SetButton

func _ready():
	close_requested.connect(_on_close_requested)

	# Setup graph control signals
	curve_editor.point_added.connect(_on_graph_point_added)
	curve_editor.point_moved.connect(_on_graph_point_moved)
	curve_editor.point_selected.connect(_on_graph_point_selected)
	curve_editor.points_changed.connect(_on_graph_points_changed)

	# Setup table
	points_table.set_column_title(0, column_x_label)
	points_table.set_column_title(1, column_y_label)
	points_table.set_column_titles_visible(true)
	points_table.item_edited.connect(_on_table_item_edited)
	points_table.item_selected.connect(_on_table_item_selected)

	# Initialize with default points if empty
	if curve_editor.points.is_empty():
		curve_editor.points = PackedVector2Array([
			Vector2(0.0, 0.0),
			Vector2(50.0, 50.0),
			Vector2(100.0, 100.0)
		])

	update_range_from_input()
	update_table()
	update_interpolation_buttons()

## Initialize the editor with custom data
func set_content(object_id: int,
				 initial_points: PackedVector2Array = PackedVector2Array(),
				 interpolation_method: String = "linear",
				 x_label: String = "X",
				 y_label: String = "Y",):
	curve_editor.points = initial_points.duplicate()
	self.object_id = object_id
	column_x_label = x_label
	column_y_label = y_label

	curve_editor.set_interpolation_method_name(interpolation_method)

	if is_node_ready():
		points_table.set_column_title(0, column_x_label)
		points_table.set_column_title(1, column_y_label)
		update_table()
		update_input_from_range()
		update_interpolation_buttons()

# Graph Control Signal Handlers
# ----------------------------------------------------------------------------

func _on_graph_point_added(_index: int):
	update_table()

func _on_graph_point_moved(_index: int):
	adapt_range()
	update_table()

func _on_graph_point_selected(_index: int):
	pass

func _on_graph_points_changed():
	update_table()

# Table Management
# ----------------------------------------------------------------------------

func update_table():
	points_table.clear()
	var root = points_table.create_item()

	var sorted_points = curve_editor.get_sorted_points()
	for point in sorted_points:
		var item = points_table.create_item(root)
		item.set_text(0, "%.2f" % point.x)
		item.set_text(1, "%.2f" % point.y)
		item.set_editable(0, true)
		item.set_editable(1, true)

func _on_table_item_edited():
	var selected = points_table.get_selected()
	if selected == null:
		return

	var index = selected.get_index()
	if index < 0 or index >= curve_editor.points.size():
		return

	var x_text = selected.get_text(0)
	var y_text = selected.get_text(1)

	var x_value = x_text.to_float()
	var y_value = y_text.to_float()
	var new_point = Vector2(x_value, y_value)

	adapt_range_for_point(new_point)

	# Find the point in unsorted array and update it
	var sorted_points = curve_editor.get_sorted_points()
	if index < sorted_points.size():
		var old_point = sorted_points[index]
		for i in range(curve_editor.points.size()):
			if curve_editor.points[i].is_equal_approx(old_point):
				curve_editor.points[i] = new_point
				break

	curve_editor.sort_points()
	update_table()
	curve_editor.queue_redraw()

func _on_table_item_selected():
	var selected = points_table.get_selected()
	if selected == null:
		curve_editor.selected_point_index = -1
	else:
		curve_editor.selected_point_index = selected.get_index()
	curve_editor.queue_redraw()

# Point Management
# ----------------------------------------------------------------------------

func _on_add_button_pressed():
	# Add point at midpoint of range
	var new_point = Vector2(
		(curve_editor.min_x + curve_editor.max_x) / 2.0,
		(curve_editor.min_y + curve_editor.max_y) / 2.0
	)
	curve_editor.add_point(new_point)
	update_table()

func _on_remove_button_pressed():
	if curve_editor.selected_point_index >= 0:
		curve_editor.remove_point(curve_editor.selected_point_index)
		update_table()

# Range Controls
# ----------------------------------------------------------------------------

func _on_range_changed(_new_text: String = ""):
	update_range_from_input()
	curve_editor.queue_redraw()

func update_input_from_range():
	min_x_edit.text = "%.2f" % curve_editor.min_x
	max_x_edit.text = "%.2f" % curve_editor.max_x
	min_y_edit.text = "%.2f" % curve_editor.min_y
	max_y_edit.text = "%.2f" % curve_editor.max_y

func update_range_from_input():
	var min_x = min_x_edit.text.to_float()
	var max_x = max_x_edit.text.to_float()
	var min_y = min_y_edit.text.to_float()
	var max_y = max_y_edit.text.to_float()

	# Ensure max > min
	var tmp: float
	if max_x <= min_x:
		tmp = max_x
		max_x = min_x
		min_x = tmp
	if max_y <= min_y:
		max_y = min_y + 1.0
		max_y_edit.text = "%.2f" % max_y

	curve_editor.set_range(min_x, max_x, min_y, max_y)

func adapt_range_for_point(point: Vector2):
	curve_editor.adapt_range_for_point(point)
	var range_changed = false

	if point.x < curve_editor.min_x:
		min_x_edit.text = "%.2f" % point.x
	if point.x > curve_editor.max_x:
		max_x_edit.text = "%.2f" % point.x
	if point.y < curve_editor.min_y:
		min_y_edit.text = "%.2f" % point.y
	if point.y > curve_editor.max_y:
		max_y_edit.text = "%.2f" % point.y

	if range_changed:
		curve_editor.queue_redraw()

func adapt_range():
	for point in curve_editor.points:
		adapt_range_for_point(point)

# Interpolation Method
# ----------------------------------------------------------------------------

func _on_interpolation_button_pressed(method: String):
	curve_editor.set_interpolation_method_name(method)
	update_interpolation_buttons()
	curve_editor.queue_redraw()

func update_interpolation_buttons():
	linear_button.button_pressed = (curve_editor.interpolation == FunctionCurveEditor.InterpolationMethod.LINEAR)
	step_button.button_pressed = (curve_editor.interpolation == FunctionCurveEditor.InterpolationMethod.STEP)
	cubic_button.button_pressed = (curve_editor.interpolation == FunctionCurveEditor.InterpolationMethod.CUBIC)

# Action Buttons
# ----------------------------------------------------------------------------

func _on_set_button_pressed():
	var method_name = ""
	match curve_editor.interpolation:
		FunctionCurveEditor.InterpolationMethod.LINEAR: method_name = "linear"
		FunctionCurveEditor.InterpolationMethod.STEP: method_name = "step"
		FunctionCurveEditor.InterpolationMethod.CUBIC: method_name = "cubic"

	curves_submitted.emit(curve_editor.get_sorted_points(), method_name)
	hide()

func _on_cancel_button_pressed():
	curves_dismissed.emit()
	hide()

func _on_close_requested():
	curves_dismissed.emit()
	hide()

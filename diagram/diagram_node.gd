class_name DiagramNode extends DiagramObject
# Physics: extends RigidBody2D

const label_offset = 10
const formula_offset = 32
const default_radius = 50
const highlight_padding = 5

## Value to be displayed using a value indicator.
##
## Typically a computed simulation value of the node.
##
var display_value: Variant = 0.0:
	set(value):
		if value is float or value == null:
			display_value = value
			update_indicator()
		else:
			push_warning("Invalid display value for node ID ", object_id, ": ", value)

# Node Components (Children)
@export var shape: Shape2D

@export var image: Sprite2D
@export var name_label: Label
@export var formula_label: Label
@export var value_indicator: ValueIndicator
@export var has_value_indicator: bool
@export var has_name: bool
@export var has_formula: bool
@export var indicator_offset = 30

# TODO: Physics
# var collision: CollisionShape2D = CollisionShape2D.new()

var children_needs_update: bool = true

# Select Tool
var touchable_outline: PackedVector2Array = []
		
var is_dragged: bool = false
var selection_highlight_shape: Shape2D = null
var target_position: Vector2 = Vector2():
	set(value):
		# TODO: Remove this for Physics
		self.position = target_position

func _init():
	shape = CircleShape2D.new()
	shape.radius = default_radius

	name_label = Label.new()
	name_label.theme_type_variation = "NodeNameLabel"
	self.add_child(name_label)

	formula_label = Label.new()
	formula_label.theme_type_variation = "NodeFormulaLabel"
	self.add_child(formula_label)
## Updates the diagram node based on a design object.
##
## This method should be called whenever the source of truth is changed.
func _update_from_design_object(object: PoieticObject):
	self.object_name = object.object_name
	var position = object.get_position()
	if position is Vector2:
		self.position = position
		
	var formula = object.get_attribute("formula")
	if formula is String:
		formula_label.text = formula

	self.has_value_indicator = object.has_trait("NumericIndicator")
	self.has_name = object.has_trait("Name")
	self.has_formula = object.has_trait("Formula")
	
	queue_layout()

func _ready():
	update_children()
	var canvas:DiagramCanvas = get_parent()
	self.formula_label.visible = canvas.formulas_visible
	self.name_label.visible = canvas.labels_visible

func _draw():
	# FIXME: Should we keep drawing the selection like this?
	# TODO: Move to pictogram or somewhere. This can be computed only once
	if is_selected and selection_highlight_shape:
		var curve = DiagramGeometry.shape_outline(shape)
		var points = curve.tessellate()
		var polygons = Geometry2D.offset_polygon(points, 10, Geometry2D.JOIN_ROUND)
		var color = DiagramCanvas.default_selection_color
		color.a = 0.1

		for poly in polygons:
			draw_polygon(poly, [color])
			poly.append(poly[0])
			draw_polyline(poly, DiagramCanvas.default_selection_color, 2)

		# DiagramGeometry.draw_shape(self, selection_highlight_shape, DiagramCanvas.default_selection_color, 2)
		
func _process(_delta):
	if children_needs_update:
		update_children()
		children_needs_update = false
	value_indicator.visible = self.has_value_indicator and Global.show_value_indicators
	if name_label:
		name_label.visible = self.has_name
	if formula_label:
		formula_label.visible = self.has_formula

func bounding_box() -> Rect2:
	var rect = shape.get_rect()
	rect.position = Vector2(position.x - rect.size.x / 2, position.y - rect.size.y / 2)
	return rect
	
func queue_layout():
	children_needs_update = true

func update_children() -> void:
	var theme = ThemeDB.get_project_theme()
	update_pictogram()
	update_indicator()
	var shape_rect = shape.get_rect()

	# Label
	if not object_name:
		var font = theme.get_font(&"missing_name_font", &"NodeNameLabel")
		name_label.add_theme_font_override(&"font", font)
		var color = theme.get_color(&"missing_name_color", &"NodeNameLabel")
		name_label.add_theme_color_override(&"font_color", color)
		name_label.text = "(unnamed)"
	else:
		name_label.remove_theme_font_override(&"font")
		name_label.remove_theme_color_override(&"font_color")
		name_label.text = object_name
		name_label.queue_redraw()

	var shape_bottom = shape_rect.size.y / 2		
	var label_size = name_label.get_minimum_size()
	name_label.position = Vector2(-label_size.x / 2, shape_bottom + label_offset)

	var formula_size = formula_label.get_minimum_size()
	formula_label.position = Vector2(-formula_size.x / 2, shape_bottom + formula_offset)
	# Indicators
	
	if issues_indicator == null:
		#var height: float = (sqrt(3.0) / 2.0) * default_issues_indicator_size
		#issues_indicator = Polygon2D.new()
		#var polygon: PackedVector2Array = [
			#Vector2(-default_issues_indicator_size, -height),
			#Vector2(+default_issues_indicator_size, -height),
			#Vector2(0, height),
			#Vector2(-default_issues_indicator_size, -height),
		#]
		#issues_indicator.z_index = DiagramCanvas.issues_indicator_z_index
		#issues_indicator.polygon = polygon
		#issues_indicator.color = Color.RED
		#issues_indicator.position = Vector2(0, -shape_rect.size.y/2) + default_issues_indicator_offset
		#issues_indicator.visible = false
		issues_indicator = IssueIndicator.new()
		self.add_child(issues_indicator)
		
	children_needs_update = false

func update_pictogram():
	if image == null:
		image = Sprite2D.new()
		add_child(image)

	var pictogram: Pictogram = Global.get_pictogram(type_name)
	image.texture = ImageTexture.create_from_image(pictogram.get_image())
	shape = pictogram.shape
	# TODO: Use offset shape, not grow shape.
	selection_highlight_shape = DiagramGeometry.offset_shape(shape, 6)

func update_indicator():
	if value_indicator == null:
		var indicator = ValueIndicator.new()
		indicator.position = Vector2(0, - shape.get_rect().size.y / 2 - indicator_offset)
		indicator.min_value = 0
		indicator.max_value = 100
		var fill_style = StyleBoxFlat.new()
		fill_style.bg_color = Color.YELLOW
		fill_style.border_color = Color.LIME_GREEN
		fill_style.set_border_width_all(0)
		indicator.normal_style = fill_style
		var bg_style = StyleBoxFlat.new()
		bg_style.bg_color = Color.BLACK
		bg_style.border_color = Color.DIM_GRAY
		bg_style.set_border_width_all(2)
		indicator.bg_style = bg_style
		add_child(indicator)
		value_indicator = indicator
		
	# TODO: Make indicator display some "unknown status" when the value is null
	if self.display_value != null:
		value_indicator.value = self.display_value
	else:
		# push_warning("No display value")
		value_indicator.value = null
		
func contains_point(point: Vector2):
	var local_point = to_local(point)
	
	var touch_shape: Shape2D = CircleShape2D.new()
	touch_shape.radius = 10
	var collision_trans = self.transform.translated(local_point)

	return shape.collide(self.transform, touch_shape, collision_trans)

func begin_label_edit():
	name_label.visible = false

func finish_label_edit():
	name_label.visible = true

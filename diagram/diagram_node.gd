class_name DiagramNode extends DiagramObject
# Physics: extends RigidBody2D

const label_offset = 10
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
@export var image: Sprite2D
@export var shape: Shape2D
@export var label_text: Label
@export var value_indicator: ValueIndicator
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
	
## Updates the diagram node based on a design object.
##
## This method should be called whenever the source of truth is changed.
func _update_from_design_object(object: PoieticObject):
	self.object_name = object.object_name
	var position = object.get_position()
	if position is Vector2:
		self.position = position

	queue_layout()

func _ready():
	update_children()

func _draw():
	if is_selected and selection_highlight_shape:
		DiagramGeometry.draw_shape(self, selection_highlight_shape, DiagramCanvas.default_selection_color, 2)
		
func _process(_delta):
	if children_needs_update:
		update_children()
		children_needs_update = false
	value_indicator.visible = Global.show_value_indicators

func queue_layout():
	children_needs_update = true

func update_children() -> void:
	update_pictogram()
	update_indicator()
	if label_text == null:
		label_text = Label.new()
		self.add_child(label_text)
		label_text.add_theme_color_override("font_color", DiagramCanvas.default_label_color)

	var shape_rect = shape.get_rect()

	if object_name == null:
		label_text.text = ""
	else:
		label_text.text = object_name
		label_text.queue_redraw()
	var label_size = label_text.get_minimum_size()
	label_text.position = Vector2(-label_size.x * 0.5, shape_rect.size.y / 2 + label_offset)
	children_needs_update = false
	
	if issues_indicator == null:
		var height: float = (sqrt(3.0) / 2.0) * default_issues_indicator_size
		issues_indicator = Polygon2D.new()
		var polygon: PackedVector2Array = [
			Vector2(-default_issues_indicator_size, -height),
			Vector2(+default_issues_indicator_size, -height),
			Vector2(0, height),
			Vector2(-default_issues_indicator_size, -height),
		]
		issues_indicator.z_index = DiagramCanvas.issues_indicator_z_index
		issues_indicator.polygon = polygon
		issues_indicator.color = Color.RED
		issues_indicator.position = Vector2(0, -shape_rect.size.y/2) + default_issues_indicator_offset
		issues_indicator.visible = false
		self.add_child(issues_indicator)

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

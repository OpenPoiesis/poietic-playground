class_name DiagramConnection extends Node2D

const default_line_color = Color.GREEN

# Diagram Properties
var origin: DiagramNode
var target: Node2D

# Children and Shapes
var line: Line2D
var arrow_head: Line2D
var arrow_tail: Line2D

# Select Tool
var touchable_outline: PackedVector2Array = []
var is_selected: bool = false
var selection_highlight: Node2D = null

# Debug
var debug_outline_shape: Shape2D
var debug_outline: Polygon2D

func _ready():
	line = Line2D.new()
	line.name = "line"
	line.default_color = default_line_color
	line.width = 2.0
	add_child(line)

	arrow_head = Line2D.new()
	arrow_head.width = 2.0
	arrow_head.default_color = default_line_color
	add_child(arrow_head)
	
	arrow_tail = Line2D.new()
	arrow_tail.width = 2.0
	arrow_tail.default_color = default_line_color
	add_child(arrow_tail)
	
	debug_outline = Polygon2D.new()
	debug_outline.color = Color.RED
	debug_outline.z_index = -100
	# add_child(debug_outline)
	
	selection_highlight = Line2D.new()
	selection_highlight.width = 2.0
	add_child(selection_highlight)


@warning_ignore("shadowed_variable")
func set_connection(origin: DiagramNode, target: Node2D):
	self.origin = origin
	self.target = target
	update_shape()

@warning_ignore("shadowed_variable")
func set_target(target: DiagramNode):
	self.target = target
	update_shape()
	
func update_shape():
	if origin == null or target == null:
		push_warning("Updating connector shape without origin or target")
		return
	line.clear_points()
	
	var origin_center = to_global(origin.position)
	var target_center = to_global(target.position)

	var origin_trans = origin.global_transform
	var target_trans = target.global_transform
	
	var origin_inter = ShapeCreator.intersect_line_with_shape(origin_center, target_center, origin.shape, origin.global_transform)

	var arrow_origin: Vector2
	var arrow_target: Vector2
	
	if len(origin_inter) >= 1:
		arrow_origin = to_local(origin_inter[0])
	else:
		arrow_origin = to_local(origin_center)

	if target is DiagramNode:
		var target_inter = ShapeCreator.intersect_line_with_shape(target_center, origin_center, target.shape, target.global_transform)
		if len(target_inter) >= 1:
			arrow_target = to_local(target_inter[0])
		else:
			arrow_target = to_local(target_center)
	else:
		arrow_target = to_local(target_center)
		
	line.add_point(arrow_origin)
	line.add_point(arrow_target)
	
	var head = ShapeCreator.arrow_points(arrow_origin, arrow_target, ShapeCreator.ArrowHeadType.STICK, 30)
	arrow_head.clear_points()
	if len(head) > 0:
		for point in head:
			arrow_head.add_point(point)
		arrow_head.show()
	else:
		arrow_head.hide()
		
	# Debug Outline
	#
	var polygons = Geometry2D.offset_polyline(line.points, 10, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
	if len(polygons) >= 1:
		debug_outline.set_polygon(polygons[0])
		touchable_outline = polygons[0]

	update_highlight()
	
func update_highlight():
	if is_selected:
		selection_highlight.clear_points()

		var polygons = Geometry2D.offset_polyline(line.points, 10, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
		if len(polygons) >= 1:
			for point in polygons[0]:
				selection_highlight.add_point(point)
			self.add_child(selection_highlight)
		selection_highlight.default_color = Selection.default_selection_color
		selection_highlight.show()
	else:
		selection_highlight.hide()

func set_selected(flag: bool):
	self.is_selected = flag
	update_highlight()

func contains_point(point: Vector2):
	var local = to_local(point)
	return Geometry2D.is_point_in_polygon(local, touchable_outline)
	

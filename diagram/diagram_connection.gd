class_name DiagramConnection extends Node2D

# DampedSpringJoint2D
# Diagram Properties
var type_name: String
var object_id: int
var origin: DiagramNode
var target: Node2D

var label: String

var arrow_origin: Vector2 = Vector2()
var arrow_target: Vector2 = Vector2()
var previous_origin_pos: Vector2
var previous_target_pos: Vector2

# Physics
# var joint: DampedSpringJoint2D

# Select Tool
var touchable_outline: PackedVector2Array = []
var is_selected: bool = false

var children_needs_update: bool = true

func queue_layout():
	children_needs_update = true

func _process(_delta: float) -> void:
	var new_origin_pos = to_local(origin.global_position)
	var new_target_pos = to_local(target.global_position)
	if new_origin_pos != previous_origin_pos or new_target_pos != previous_target_pos:
		previous_origin_pos = new_origin_pos
		previous_target_pos = new_target_pos
		update_arrow()

## Updates the diagram node based on a design object.
##
## This method should be called whenever the source of truth is changed.
func update_from(object: DesignObject):
	var position = object.attribute("position")
	if position is Vector2:
		self.position = position

	var text = object.attribute("name")
	if text is String:
		self.label = text
	queue_layout()

@warning_ignore("shadowed_variable")
func set_connection(origin: DiagramNode, target: Node2D):
	self.origin = origin
	self.target = target
	# TODO: Physics
	# if joint == null:
		#joint = DampedSpringJoint2D.new()
		#add_child(joint)
	#if joint != null:
		#joint.node_a = joint.get_path_to(origin)
		#joint.node_b = joint.get_path_to(target)
	update_arrow()
	
@warning_ignore("shadowed_variable")
func set_target(target: DiagramNode):
	self.target = target
	update_arrow()
	
func _draw() -> void:
	draw_arrow()

func update_arrow():
	if origin == null or target == null:
		push_warning("Updating connector shape without origin or target")
		return
	var origin_center = origin.global_position
	var target_center = target.global_position

	var origin_inter = ShapeCreator.intersect_line_with_shape(origin_center, target_center, origin.shape, origin.global_transform)
	
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
		
	var polygons = Geometry2D.offset_polyline([arrow_origin, arrow_target], 10, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
	if len(polygons) >= 1:
		touchable_outline = polygons[0]
	else:
		touchable_outline = []
	
	queue_redraw()

func draw_arrow():
	draw_line(arrow_origin, arrow_target, DiagramCanvas.default_pictogram_color, 2.0)

	var head_points = ShapeCreator.arrow_points(arrow_origin, arrow_target, ShapeCreator.ArrowHeadType.STICK, 30)
	if len(head_points) > 0:
		draw_polyline(head_points, DiagramCanvas.default_pictogram_color, 2.0)
		
	if is_selected:
		var polygons = Geometry2D.offset_polyline([arrow_origin, arrow_target], 10, Geometry2D.JOIN_ROUND, Geometry2D.END_ROUND)
		if len(polygons) >= 1:
			draw_polyline(polygons[0], DiagramCanvas.default_selection_color, 2.0)

func set_selected(flag: bool):
	self.is_selected = flag
	queue_redraw()

func contains_point(point: Vector2):
	var local = to_local(point)
	return Geometry2D.is_point_in_polygon(local, touchable_outline)

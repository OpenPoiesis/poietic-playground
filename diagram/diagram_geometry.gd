class_name DiagramGeometry extends Object

static func intersect_line_with_shape(line_start: Vector2, line_end: Vector2, shape: Shape2D, shape_position: Vector2) -> PackedVector2Array:
	if shape is CircleShape2D:
		return intersect_line_with_circle(line_start, line_end, shape_position, shape.radius)
	elif shape is RectangleShape2D:
		var rect = shape.get_rect()
		rect.position += shape_position
		var result = intersect_line_with_rect(line_start, line_end, rect)
		return result
	elif shape is CapsuleShape2D:
		push_warning("Not implemented: Capsule shape intersection, using circle instead")
		return intersect_line_with_circle(line_start, line_end,shape_position, shape.radius)
	return []

static func intersect_line_with_rect(line_start: Vector2, line_end: Vector2, rect: Rect2) -> PackedVector2Array:
	var p0 = rect.position
	var p1 = rect.position + Vector2(rect.size.x, 0)
	var p3 = rect.position + Vector2(0, rect.size.y)
	var p2 = rect.end

	var result: PackedVector2Array = PackedVector2Array()
	var inter1 = Geometry2D.segment_intersects_segment(p0, p1, line_start, line_end)
	if inter1:
		result.append(inter1)
	var inter2 = Geometry2D.segment_intersects_segment(p1, p2, line_start, line_end)
	if inter2:
		result.append(inter2)
	var inter3 = Geometry2D.segment_intersects_segment(p2, p3, line_start, line_end)
	if inter3:
		result.append(inter3)
	var inter4 = Geometry2D.segment_intersects_segment(p3, p0, line_start, line_end)
	if inter4:
		result.append(inter4)

	return result

static func intersect_line_with_circle(line_start: Vector2, line_end: Vector2, center: Vector2, radius: float) -> PackedVector2Array:
	var d = line_end - line_start
	var f = line_start - center

	var a = d.dot(d)
	var b = 2 * f.dot(d)
	var c = f.dot(f) - radius * radius

	var discriminant = b * b - 4 * a * c

	if discriminant < 0:
		return []

	discriminant = sqrt(discriminant)

	var t1 = (-b - discriminant) / (2 * a)
	var t2 = (-b + discriminant) / (2 * a)

	var result: PackedVector2Array = PackedVector2Array()

	if 0 <= t1 and t1 <= 1:
		result.append(line_start + t1 * d)
	if 0 <= t2 and t2 <= 1:
		result.append(line_start + t2 * d)

	return result

static func grow_shape(shape: Shape2D, factor: float) -> Shape2D:
	if shape is RectangleShape2D:
		var new_shape = RectangleShape2D.new()
		new_shape.size = shape.size * factor
		return new_shape
	elif shape is CircleShape2D:
		var new_shape = CircleShape2D.new()
		new_shape.radius = shape.radius * factor
		return new_shape
	elif shape is CapsuleShape2D:
		var new_shape = CapsuleShape2D.new()
		new_shape.radius = shape.radius * factor
		new_shape.height = shape.height * factor
		return new_shape
	elif shape is ConvexPolygonShape2D:
		var new_shape = ConvexPolygonShape2D.new()
		var polys = grow_polygon(shape.points, factor)
		new_shape.points = polys[0]
		return new_shape
	else:
		push_warning("Unsupported shape type: ", shape.get_class())
		return shape

static func offset_shape(shape: Shape2D, offset: float) -> Shape2D:
	if shape is RectangleShape2D:
		var new_shape = RectangleShape2D.new()
		new_shape.size = shape.size + Vector2(offset * 2, offset * 2)
		return new_shape
	elif shape is CircleShape2D:
		var new_shape = CircleShape2D.new()
		new_shape.radius = shape.radius + offset
		return new_shape
	elif shape is CapsuleShape2D:
		var new_shape = CapsuleShape2D.new()
		new_shape.radius = shape.radius + (offset)
		new_shape.height = shape.height + (offset * 2)
		return new_shape
	elif shape is ConvexPolygonShape2D:
		var new_shape = ConvexPolygonShape2D.new()
		var polys = offset_polygon(shape.points, offset)
		new_shape.points = polys[0]
		return new_shape
	else:
		push_warning("Unsupported shape type: ", shape.get_class())
		return shape

static func grow_polygon(polygon: PackedVector2Array, factor: float) -> PackedVector2Array:
	if polygon.is_empty():
		return polygon
	
	var centroid := Vector2.ZERO
	for point in polygon:
		centroid += point
	centroid /= polygon.size()

	var scaled_polygon := PackedVector2Array(polygon)
	for index in range(0, len(polygon)):
		scaled_polygon[index] = centroid + (scaled_polygon[index] - centroid) * factor

	return scaled_polygon

static func offset_polygon(polygon: PackedVector2Array, offset: float) -> PackedVector2Array:
	if polygon.is_empty():
		return polygon
	
	var centroid := Vector2.ZERO
	for point in polygon:
		centroid += point
	centroid /= polygon.size()

	var scaled_polygon := PackedVector2Array(polygon)
	for index in range(0, len(polygon)):
		var vec = scaled_polygon[index] - centroid
		
		scaled_polygon[index] = centroid + (vec.normalized() * (vec.length + offset))

	return scaled_polygon

static func circle_curve(center: Vector2, radius: float) -> Curve2D:
	# https://spencermortensen.com/articles/bezier-BALL/
	# P0=(0,a), P1=(b,c), P2=(c,b), P3=(a,0)
	var curve = Curve2D.new()
	var magic = radius * 0.552285  # Approximation factor for Bézier control points
	var a=1.00005519
	var b=0.55342686
	# var c=0.99873585

	var p1: Vector2 = Vector2()
	var p2: Vector2 = Vector2()
	
	p1 = Vector2(b, 0) * radius
	p2 = Vector2(0, b) * radius
	curve.add_point(center + (Vector2(0, a) * radius), Vector2.ZERO, p1)
	curve.add_point(center + (Vector2(a, 0) * radius), p2, -p2)
	curve.add_point(center + (Vector2(0, -a) * radius), p1, -p1)
	curve.add_point(center + (Vector2(-a, 0) * radius), -p2, p2)
	curve.add_point(center + (Vector2(0, a) * radius), -p1, Vector2.ZERO)

	return curve

static func shape_outline(shape: Shape2D) -> Curve2D:
	var curve: Curve2D
	if shape is RectangleShape2D:
		curve = Curve2D.new()
		var half_size: Vector2 = shape.size / 2
		curve.add_point(-half_size)
		curve.add_point(Vector2(half_size.x, -half_size.y))
		curve.add_point(half_size)
		curve.add_point(Vector2(-half_size.x, +half_size.y))
		curve.add_point(-half_size)
	elif shape is CircleShape2D:
		curve = circle_curve(Vector2.ZERO, shape.radius)
	elif shape is CapsuleShape2D:
		var radius = shape.radius
		var height = shape.height
		pass
	elif shape is ConvexPolygonShape2D:
		var points = shape.points
		pass
	else:
		print("Unsupported shape type: ", shape.get_class())
	return curve

static func draw_shape(canvas: CanvasItem, shape: Shape2D, color: Color = Color.WHITE, width: float = -1):
	if shape is RectangleShape2D:
		canvas.draw_rect(Rect2(-shape.size/2, shape.size), color, false, width)
	elif shape is CircleShape2D:
		canvas.draw_circle(Vector2.ZERO, shape.radius, color, false, width)
	elif shape is CapsuleShape2D:
		var radius = shape.radius
		var height = shape.height
		draw_capsule(canvas, Vector2.ZERO, radius, height, color, width)
	elif shape is ConvexPolygonShape2D:
		var points = shape.points
		canvas.draw_polygon(points, [color])
	else:
		print("Unsupported shape type: ", shape.get_class())

static func draw_capsule(canvas: CanvasItem, position: Vector2, radius: float, height: float, color: Color, width: float = -1.0):
	var half_height = height / 2
	# Draw the two semicircles
	canvas.draw_arc(position + Vector2(0, -half_height), radius, PI, 2 * PI, 32, color, width)
	canvas.draw_arc(position + Vector2(0, half_height), radius, 0, PI, 32, color, width)
	# Draw the two lines connecting the semicircles
	canvas.draw_line(position + Vector2(-radius, -half_height), position + Vector2(-radius, half_height), color, width)
	canvas.draw_line(position + Vector2(radius, -half_height), position + Vector2(radius, half_height), color, width)

func merge_multiple_polygons(polygons: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	if polygons.is_empty():
		return []
	
	var merged: Array[PackedVector2Array] = [polygons[0]]
	
	for current in polygons:
		var new_merged: Array[PackedVector2Array] = []
		var merged_this_round = false
		
		# Try to merge with existing merged polygons
		for index in range(merged.size()):
			var result = Geometry2D.merge_polygons(merged[index], current)
			
			if result.size() == 1:
				# Successfully merged
				new_merged.append_array(result)
				merged_this_round = true
				# Add any remaining merged polygons that weren't processed yet
				new_merged.append_array(merged.slice(index + 1, merged.size()))
				break
			else:
				# Couldn't merge with this one, keep it for now
				new_merged.append(merged[index])
		
		if not merged_this_round:
			# Couldn't merge with any existing polygon, add as new
			new_merged.append(current)
		
		merged = new_merged
	
	return merged

static func convex_hull_from_rects(rects: Array[Rect2]) -> PackedVector2Array:
	var points := PackedVector2Array()
	
	for rect in rects:
		points.append(rect.position)
		points.append(rect.position + Vector2(rect.size.x, 0))
		points.append(rect.position + rect.size)
		points.append(rect.position + Vector2(0, rect.size.y))
	
	return Geometry2D.convex_hull(points)

static func merge_polygons(polygons: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var merged: Array[PackedVector2Array] = []
	var to_process: Array[PackedVector2Array] = polygons.duplicate()

	while to_process.size() > 0:
		var current = to_process.pop_back()
		var merged_this_round = false
		
		for i in range(merged.size()):
			var merge_result = Geometry2D.merge_polygons(current, merged[i])
			if merge_result.size() == 1:
				merged[i] = merge_result[0]
				merged_this_round = true
				break
		
		# If couldn't merge, add as new polygon
		if not merged_this_round:
			merged.append(current)
	return merged

static func centroid(points: PackedVector2Array) -> Vector2:
	var result := Vector2.ZERO
	for point in points:
		result += point
	return result / points.size()

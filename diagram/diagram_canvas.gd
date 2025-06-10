class_name DiagramCanvas extends Node2D

# TODO: Add error indicators at the canvas edges if there are objects with errors at that direction

signal canvas_view_changed(offset: Vector2, zoom_level: float)

var diagram_objects: Dictionary[int, DiagramObject] = {} 
@export var selection: PoieticSelection = PoieticSelection.new()

@export var zoom_level: float = 1.0
@export var canvas_offset: Vector2 = Vector2.ZERO
@export var _design_sync_needed: bool = true

@export var formulas_visible_zoom_level: float = 1.0
@export var formulas_visible: bool = true:
	set(flag):
		formulas_visible = flag
		set_formulas_visible(flag)

@export var charts_visible: bool = false:
	set(flag):
		charts_visible = flag
		set_charts_visible(flag)

@export var labels_visible: bool = true:
	set(flag):
		labels_visible = flag
		set_labels_visible(flag)

const default_pictogram_color = Color.WHITE
const default_label_color = Color.WHITE
const default_formula_color = Color.SKY_BLUE
const default_selection_color: Color = Color(0.75,0.6,0)
const handle_outline_color = Color.ROYAL_BLUE
const handle_color = Color.DODGER_BLUE

const issues_indicator_z_index = 1000
const handle_z_index = 900

enum HitTargetType {
	# Type            Object
	OBJECT,         # Diagram object
	HANDLE,         # Handle (parent must be diagram object)
	NAME,           # Diagram object
	PRIMARY_ATTRIBUTE, # Formula
	ERROR_INDICATOR,
	# VALUE_INDICATOR,
}

class HitTarget:
	var type: HitTargetType
	var object: Node2D
	var index: int
	func _init(type: HitTargetType, object: Node2D, index: int = -1):
		assert(object != null, "Hit target object must be not null")
		self.type = type
		self.object = object
		self.index = index

func selection_bounding_boxes() -> Array[Rect2]:
	var result: Array[Rect2] = []
	for id in self.selection.get_ids():
		var obj: DiagramObject = diagram_objects.get(id)
		if not obj:
			continue
		result.append(obj.bounding_box())

	return result

func selection_bounding_box() -> Rect2:
	var boxes = selection_bounding_boxes()
	if boxes.is_empty():
		return Rect2()
	var result = boxes[0]
	for box in boxes:
		result = result.merge(box)
	return result

func selection_convex_hull() -> PackedVector2Array:
	return DiagramGeometry.convex_hull_from_rects(selection_bounding_boxes())

func all_diagram_object_ids() -> PackedInt64Array:
	var result = PackedInt64Array(diagram_objects.keys())
	return result

func all_diagram_node_ids() -> PackedInt64Array:
	var result = PackedInt64Array()
	for object in diagram_objects.values():
		if object is DiagramNode:
			result.append(object.object_id)
	return result

func all_diagram_edge_ids() -> PackedInt64Array:
	var result = PackedInt64Array()
	for object in diagram_objects.values():
		if object is DiagramConnector:
			result.append(object.object_id)
	return result

func all_diagram_nodes() -> Array[DiagramNode]:
	self.get_groups()
	var result: Array[DiagramNode]
	for object in diagram_objects.values():
		if object is DiagramNode:
			result.append(object)
	return result

func all_diagram_connectors() -> Array[DiagramConnector]:
	var result: Array[DiagramConnector]
	for object in diagram_objects.values():
		if object is DiagramConnector:
			result.append(object)
	return result

func get_diagram_node(id: int) -> DiagramNode:
	var object = diagram_objects.get(id)
	if object is DiagramNode:
		return object
	else:
		return null

func get_diagram_connector(id: int) -> DiagramConnector:
	var object = diagram_objects.get(id)
	if object is DiagramConnector:
		return object
	else:
		return null

func _ready():
	add_to_group("drag_drop_targets")
	selection.selection_changed.connect(_on_selection_changed)

func _process(_delta):
	if _design_sync_needed:
		sync_design()

func _draw():
	return
	if not selection.is_empty():
		var points = selection_convex_hull()
		var polygons = Geometry2D.offset_polygon(points, 10, Geometry2D.JOIN_ROUND)
		for polygon in polygons:
			polygon.append(polygon[0])
			draw_polyline(polygon, DiagramCanvas.default_selection_color, 3.0)
			var color = DiagramCanvas.default_selection_color
			color.a = 0.1
			draw_polygon(polygon, [color])

func _on_selection_changed(objects):
	queue_redraw()
	sync_selection()

func queue_sync():
	_design_sync_needed = true

## Update indicators from the player.
##
## This method is typically called on simulation player step.
func update_indicator_values(player: PoieticPlayer):
	for id in Global.design.get_diagram_nodes():
		var object = Global.design.get_object(id)
		var diagram_node = get_diagram_node(id)
		# We might get null node when sync is queued and we do not have a canvas node yet
		if diagram_node:
			diagram_node.display_value = player.numeric_value(id)

## Remove values from indicators
##
## This method is called when design fails validation or when the simulation fails.
##
func clear_indicators():
	for node in self.all_diagram_nodes():
		node.display_value = null

## Synchronize indicators based on a simulation result.
##
## The method sets initial value of indicators and sets indicator range from the
## simulation result (time series).
##
## This method is typically called on design change.
##
func sync_indicators(result: PoieticResult):
	for id in Global.design.get_diagram_nodes():
		var diagram_node = get_diagram_node(id)
		# We might get null node when sync is queued and we do not have a canvas node yet
		if diagram_node:
			var series = result.time_series(id)
			if not series:
				push_warning("No result time series for object ", id)
				continue
			diagram_node.value_indicator.min_value = series.data_min
			diagram_node.value_indicator.max_value = series.data_max
			if series.data_min < 0:
				diagram_node.value_indicator.mid_value = 0
			else:
				diagram_node.value_indicator.mid_value = null
			diagram_node.display_value = series.first
				
	
func _unhandled_input(event):
	if event is InputEventPanGesture:
		canvas_offset += (-event.delta) * zoom_level * 10
		update_canvas_view()
	elif event is InputEventMagnifyGesture:
		set_zoom_level(zoom_level * event.factor, get_global_mouse_position())
		update_canvas_view()
	else: # Regular tool use
		var tool = Global.current_tool
		if not tool:
			return
		tool.canvas = self
		if tool.handle_input(event):
			get_viewport().set_input_as_handled()

func set_zoom_level(level: float, keep_position: Vector2) -> void:
	var t_before = Transform2D().scaled(Vector2(zoom_level, zoom_level)).translated(canvas_offset)
	var m_before = t_before.affine_inverse() * keep_position

	zoom_level = clamp(level, 0.1, 5.0)

	var t_after = Transform2D().scaled(Vector2(zoom_level, zoom_level)).translated(canvas_offset)
	var m_after = t_after.affine_inverse() * keep_position
	canvas_offset += -(m_before - m_after) * zoom_level

func update_canvas_view() -> void:
	self.position = canvas_offset
	self.scale = Vector2(zoom_level, zoom_level)
	canvas_view_changed.emit(canvas_offset, zoom_level)
	
	if zoom_level > 2:
		charts_visible = true
	else:
		charts_visible = false

	if zoom_level < formulas_visible_zoom_level:
		formulas_visible = false
	else:
		formulas_visible = true

func set_formulas_visible(flag: bool):
	for node in self.all_diagram_nodes():
		node.formula_label.visible = flag

func set_labels_visible(flag: bool):
	for node in self.all_diagram_nodes():
		node.name_label.visible = flag

func set_charts_visible(flag: bool):
	# push_warning("Visible zoomed charts are not yet implemented")
	pass

## Returns a target `HitTargetType` under position, which can be an object, handle or an indicator.
##
## See also: `hit_object(hit_position)`
##
func hit_target(hit_position: Vector2) -> HitTarget:
	var targets: Array[HitTarget] = []
	var children = get_children()
	
	# TODO: Also sort by z-index
	children.reverse()
	for child in children:
		if child is not DiagramObject:
			continue

		for handle in child.get_handles():
			if handle.visible and handle.contains_point(hit_position):
				targets.append(HitTarget.new(HitTargetType.HANDLE, handle))
			
		if child is DiagramNode and child.issues_indicator.visible:
			if child.issues_indicator.get_rect().has_point(child.to_local(hit_position)):
				targets.append(HitTarget.new(HitTargetType.ERROR_INDICATOR, child))

		if child is DiagramNode and child.name_label.visible:
			if child.name_label.get_rect().has_point(child.to_local(hit_position)):
				targets.append(HitTarget.new(HitTargetType.NAME, child))

			if child.formula_label.get_rect().has_point(child.to_local(hit_position)):
				targets.append(HitTarget.new(HitTargetType.PRIMARY_ATTRIBUTE, child))

		if child.contains_point(hit_position):
			targets.append(HitTarget.new(HitTargetType.OBJECT, child))

	prints("Targets: ", targets)
	if targets.is_empty():
		return null
	else:
		return targets[0]
	
func old_hit_target(hit_position: Vector2) -> HitTarget:
	var target: HitTarget = null

	for child in get_children():
		if child is not DiagramObject:
			continue

		for handle in child.get_handles():
			if handle.visible and handle.contains_point(hit_position):
				target = HitTarget.new(HitTargetType.HANDLE, handle)
				break
		if target:
			break
			
		if child is DiagramNode and child.issues_indicator.visible:
			if child.issues_indicator.get_rect().has_point(child.to_local(hit_position)):
				target = HitTarget.new(HitTargetType.ERROR_INDICATOR, child)
				break

		if child is DiagramNode and child.name_label.visible:
			if child.name_label.get_rect().has_point(child.to_local(hit_position)):
				target = HitTarget.new(HitTargetType.NAME, child)

			if child.formula_label.get_rect().has_point(child.to_local(hit_position)):
				target = HitTarget.new(HitTargetType.PRIMARY_ATTRIBUTE, child)

		if child.contains_point(hit_position):
			target = HitTarget.new(HitTargetType.OBJECT, child)
			if not child.is_selected:
				break   # No handles are visible, no need to test them

	return target

## Returns an object under given position.
##
## See also: `hit_target(hit_position)`
##
func hit_object(hit_position: Vector2) -> DiagramObject:
	var children = get_children()
	children.reverse()
	for child in children:
		if child is not DiagramObject:
			continue
		if child.contains_point(hit_position):
			return child
	return null

func get_connectors(node: DiagramNode) -> Array[DiagramConnector]:
	var children: Array[DiagramConnector] = []
	for conn in all_diagram_connectors():
		if conn.origin == node or conn.target == node:
			children.append(conn)
	return children

func clear_design():
	for object in diagram_objects.values():
		object.queue_free()
	diagram_objects.clear()
	
func sync_design():
	var diff = Global.design.get_difference(all_diagram_node_ids(), all_diagram_edge_ids())
	
	# We need to remove both nodes and edges first, just in case the design contains objects where
	# structure type has changed. Same ID, previously Node, now Edge.
	for id in diff.removed_nodes:
		var object = diagram_objects[id]
		diagram_objects.erase(id)
		object.queue_free()
		
	for id in diff.removed_edges:
		var object = diagram_objects[id]
		diagram_objects.erase(id)
		object.queue_free()

	# Current Nodes
	for node in all_diagram_nodes():
		var object: PoieticObject = Global.design.get_object(node.object_id)
		assert(object.type_name == node.type_name, "Object type change is not allowed")
		node._update_from_design_object(object)
		var issues = Global.design.issues_for_object(node.object_id)
		node.has_issues = !issues.is_empty()

	# Added Nodes
	for id in diff.added_nodes:
		var object: PoieticObject = Global.design.get_object(id)
		var node = create_node_from(object)
		var issues = Global.design.issues_for_object(id)
		node.has_issues = !issues.is_empty()

	# Current edges
	for conn in all_diagram_connectors():
		var object: PoieticObject = Global.design.get_object(conn.object_id)
		assert(object.type_name == conn.type_name, "Object type change is not allowed")

		var origin: DiagramNode = get_diagram_node(object.origin)
		assert(origin)
		conn.origin = origin
		var target: DiagramNode = get_diagram_node(object.target)
		assert(target)
		conn.target = target

		conn._update_from_design_object(object)
		conn.update_connector()
		var issues = Global.design.issues_for_object(conn.object_id)
		conn.has_issues = !issues.is_empty()
	
	# Added Edges
	for id in diff.added_edges:
		var object: PoieticObject = Global.design.get_object(id)
		var new_conn = create_edge_from(object)
		assert(new_conn)
		var issues = Global.design.issues_for_object(id)
		new_conn.has_issues = !issues.is_empty()

	# Finalize
	sync_selection()
	_design_sync_needed = false

func sync_selection():
	var selected_ids = selection.get_ids()
	for child in self.get_children():
		if child is DiagramObject:
			child.is_selected = selected_ids.has(child.object_id)
	queue_redraw()

func create_node_from(object: PoieticObject) -> DiagramNode:
	var node: DiagramNode = DiagramNode.new()
	node.name = "diagram_node" + str(object.object_id)
	node._set_design_object(object)
	diagram_objects[object.object_id] = node
	add_child(node)
	return node

func create_edge_from(object: PoieticObject) -> DiagramConnector:
	if object.origin == null or object.target == null:
		push_error("Trying to create connector from object without origin or target.")
		return null
	var origin: DiagramNode = get_diagram_node(object.origin)
	var target: DiagramNode = get_diagram_node(object.target)

	if origin == null:
		# This might be because we are trying to create a non-diagram connector.
		push_error("Origin ", object.origin, " is not part of canvas. Connector not created.")
		return null
	if target == null:
		# This might be because we are trying to create a non-diagram connector.
		push_error("Target ", object.target, " is not part of canvas. Connector not created.")
		return null

	var conn: DiagramConnector = DiagramConnector.new()
	add_child(conn)
	conn._set_design_object(object)
	conn.origin = origin
	conn.target = target
	conn.update_connector()
	conn.name = "connector" + str(object.object_id)
	diagram_objects[object.object_id] = conn
	return conn

# Selection
# ----------------------------------------------------------------
func get_selected_nodes() -> Array[DiagramNode]:
	var result: Array[DiagramNode] = []
	for id in selection.get_ids():
		var node = self.get_diagram_node(id)
		if node:
			result.append(node)
	return result

func get_selected_connectors() -> Array[DiagramConnector]:
	var result: Array[DiagramConnector] = []
	for id in selection.get_ids():
		var object = self.get_diagram_connector(id)
		if object:
			result.append(object)
	return result

func begin_drag_selection(_mouse_position: Vector2):
	for node in get_selected_nodes():
		node.is_dragged = true

func drag_selection(move_delta: Vector2):
	for node in get_selected_nodes():
		node.position += move_delta
	for connector in get_selected_connectors():
		var midpoints = connector.connector.midpoints
		if midpoints.is_empty():
			continue
		var new_mids: PackedVector2Array = PackedVector2Array()
		for point in midpoints:
			new_mids.append(point + move_delta)
		connector.connector.midpoints = new_mids
		connector.update_midpoint_handles()
	queue_redraw()


func finish_drag_selection(_final_position: Vector2) -> void:
	var nodes_to_move: Array[DiagramNode] = get_selected_nodes()
	if nodes_to_move.is_empty():
		return
		
	var trans = Global.design.new_transaction()
	
	for node in get_selected_nodes():
		node.is_dragged = false
		trans.set_attribute(node.object_id, "position", node.position)

	for connector in get_selected_connectors():
		var midpoints = connector.connector.midpoints
		if midpoints.is_empty():
			continue
		trans.set_attribute(connector.object_id, "midpoints", midpoints)

	Global.design.accept(trans)
	queue_redraw()

func begin_drag_handle(handle: Handle, _mouse_position: Vector2):
	pass # Nothing to do for now

func drag_handle(handle: Handle, move_delta: Vector2):
	handle.position += move_delta
	var parent = handle.get_parent()

	if parent is DiagramConnector:
		parent.set_midpoint(handle.index, handle.position)
	else:
		push_error("Unhandled handle parent: ", parent, " handle: ", handle)

func finish_drag_handle(handle: Handle, _final_position: Vector2) -> void:
	handle.position = to_local(_final_position)
	var connector: DiagramConnector = handle.get_parent()

	if connector is not DiagramConnector:
		push_error("Unhandled handle parent: ", connector, " handle: ", handle)
		return
	connector.set_midpoint(handle.index, handle.position)
		
	var trans = Global.design.new_transaction()
	
	var object = Global.design.get_object(connector.object_id)
	trans.set_attribute(connector.object_id, "midpoints", connector.connector.midpoints)
	Global.design.accept(trans)
	
		
func delete_selection():
	var trans = Global.design.new_transaction()

	for id in selection.get_ids():
		trans.remove_object(id)

	Global.design.accept(trans)

	selection.clear()
	queue_sync()

func copy_selection():
	var pasteboard_text = Global.design.copy_selection(selection.get_ids())
	DisplayServer.clipboard_set(pasteboard_text)

func cut_selection():
	copy_selection()
	delete_selection()

func paste_from_text(text: String):
	var trans = Global.design.new_transaction()
	var ids = trans.paste_from_text(text)
	
	Global.design.accept(trans)
	selection.replace(ids)

func remove_midpoints_in_selection():
	if selection.is_empty():
		return

	var connectors: Array[DiagramConnector]
	for id in selection.get_ids():
		var connector = self.get_diagram_connector(id)
		var obj: PoieticObject = Global.design.get_object(id)
		if connector and obj.get_attribute("midpoints") != null:
			connectors.append(connector)
	if connectors.is_empty():
		return
		
	var trans = Global.design.new_transaction()

	for connector in connectors:
		trans.set_attribute(connector.object_id, "midpoints", null)

	Global.design.accept(trans)

func default_prompt_position(node_id: int) -> Vector2:
	var node = get_diagram_node(node_id)
	var center = Vector2(node.global_position.x, node.name_label.global_position.y)
	return center
	
# Label Editor
# ------------------------------------------------------------
func _on_label_edit_submitted(object_id: int, new_text: String):
	var object = get_diagram_node(object_id)
	object.finish_label_edit()

	if object.object_name == new_text:
		print("Name not changed in ", object_id)
		return

	var trans = Global.design.new_transaction()
	trans.set_attribute(object_id, "name", new_text)
	Global.design.accept(trans)

func _on_label_edit_cancelled(object_id: int):
	var object = get_diagram_node(object_id)
	object.finish_label_edit()

# Formula Editor
# ------------------------------------------------------------
func _on_formula_edit_submitted(object_id: int, new_text: String):
	var object: PoieticObject = Global.design.get_object(object_id)

	if object.get_attribute("formula") == new_text:
		print("Formula not changed in ", object_id)
		return

	var trans = Global.design.new_transaction()
	trans.set_attribute(object_id, "formula", new_text)
	Global.design.accept(trans)

func _on_formula_edit_cancelled(object_id: int):
	pass

# Attribute Editor
# ------------------------------------------------------------
func _on_attribute_edit_submitted(object_id: int, attribute: String, new_text: String):
	var object: PoieticObject = Global.design.get_object(object_id)
	var current_value = object.get_attribute(attribute)

	if current_value and str(current_value) == new_text:
		print("Attribute ", attribute, " not changed in ", object_id)
		return

	var trans = Global.design.new_transaction()
	if trans.set_numeric_attribute_from_string(object_id, attribute, new_text):
		Global.design.accept(trans)
	else:
		push_error("Numeric attribute '",attribute,"' was not set: '", new_text, "'")
		Global.design.discard(trans)

func _on_attribute_edit_cancelled(object_id: int):
	pass

class_name DiagramCanvas extends Node2D

# TODO: Add error indicators at the canvas edges if there are objects with errors at that direction

var diagram_objects: Dictionary = {} # int -> Node2
var selection: PoieticSelection = PoieticSelection.new()

@export var zoom_level: float = 1.0
@export var canvas_offset: Vector2 = Vector2.ZERO
@export var sync_needed: bool = true

const default_pictogram_color = Color.WHITE
const default_label_color = Color.WHITE
const default_selection_color: Color = Color(1.0,0.8,0)

func all_diagram_nodes() -> Array[DiagramNode]:
	var result: Array[DiagramNode]
	for object in diagram_objects.values():
		if object is DiagramNode:
			result.append(object)
	return result

func all_diagram_connections() -> Array[DiagramConnection]:
	var result: Array[DiagramConnection]
	for object in diagram_objects.values():
		if object is DiagramConnection:
			result.append(object)
	return result

func get_diagram_node(id: int) -> DiagramNode:
	var object = diagram_objects.get(id)
	if object is DiagramNode:
		return object
	else:
		return null

func _init():
	pass

func _ready():
	add_to_group("drag_drop_targets")
	selection.selection_changed.connect(_on_selection_changed)

func _process(_delta):
	if sync_needed:
		sync_design()
		sync_needed = false
	
func _on_simulation_step():
	for id in Global.design.get_diagram_nodes():
		var object = Global.design.get_object(id)
		var diagram_node = get_diagram_node(id)
		# We might get null node when sync is queued and we do not have a canvas node yet
		if diagram_node != null:
			diagram_node.update_value()
	
func _on_selection_changed(objects):
	sync_selection()

func _on_design_changed():
	queue_sync()

func queue_sync():
	sync_needed = true

func _unhandled_input(event):
	if event is InputEventPanGesture:
		canvas_offset += (-event.delta) * zoom_level * 10
		update_canvas_position()
	elif event is InputEventMagnifyGesture:
		var mouse = get_global_mouse_position()
		var new_trans = transform.scaled(Vector2(event.factor, event.factor))
		var new_mouse = new_trans.affine_inverse() * mouse
		zoom_level *= event.factor
		# zoom_level = clamp(zoom_level, 0.1, 5.0)
		canvas_offset += (get_local_mouse_position() - new_mouse) * zoom_level
		update_canvas_position()
	else: # Regular tool use
		var tool = Global.current_tool
		if not tool:
			return
		tool.canvas = self
		if tool.handle_intput(event):
			get_viewport().set_input_as_handled()

func update_canvas_position() -> void:
	self.position = canvas_offset
	self.scale = Vector2(zoom_level, zoom_level)
	
func object_at_position(test_position: Vector2):
	for child in get_children():
		if child is DiagramNode:
			if child.contains_point(test_position):
				return child
		elif child is DiagramConnection:
			if child.contains_point(test_position):
				return child
			
	return null

func get_connections(node: DiagramNode) -> Array[DiagramConnection]:
	var children: Array[DiagramConnection] = []
	for conn in all_diagram_connections():
		if conn.origin == node or conn.target == node:
			children.append(conn)
	return children

func sync_design():
	print("Sync design with canvas")
	sync_nodes()
	sync_edges()
	sync_selection()
	
func sync_selection():
	var selected_ids = selection.get_ids()
	for child in self.get_children():
		if child is DiagramNode:
			child.set_selected(selected_ids.has(child.object_id))
		elif child is DiagramConnection:
			child.set_selected(selected_ids.has(child.object_id))
	
func sync_nodes():
	# 1. Get existing model node solids
	var existing: Dictionary = {}
	
	for node in self.all_diagram_nodes():
		existing[node.object_id] = node

	# 2. Update all nodes that are in the graph
	for id in Global.design.get_diagram_nodes():
		var object: PoieticObject = Global.design.get_object(id)
		var node: DiagramNode = existing.get(object.object_id)
		if node:
			node.update_from(object)
			existing.erase(object.object_id)
		else:
			node = create_node_from(object)
		var issues = Global.design.issues_for_object(id)
		node.has_errors = !issues.is_empty()
		
	# 3. Remove all orphaned nodes
	for dead in existing.values():
		diagram_objects.erase(dead.object_id)
		dead.free()

func sync_edges():
	# 1. Get existing model connections
	var existing: Dictionary[int, DiagramConnection] = {}
	
	for edge in self.all_diagram_connections():
		existing[edge.object_id] = edge

	# 2. Update all connections that are in the design
	for id in Global.design.get_diagram_edges():
		var object = Global.design.get_object(id)
		var conn: DiagramConnection = existing.get(id)
		if conn:
			var origin: DiagramNode = get_diagram_node(object.origin)
			var target: DiagramNode = get_diagram_node(object.target)
			if origin == null:
				push_error("Edge origin is not part of canvas.")
			if target == null:
				push_error("Edge target is not part of canvas.")
			else:
				conn.origin = origin
				conn.target = target

			conn.update_from(object)
			existing.erase(id)
		else:
			var new_conn = create_edge_from(object)
			if not new_conn:
				# We might be trying to create a non-diagram connection. The metamodel is lying to us.
				var type_name = object.type_name
				if not type_name:
					type_name = "(unknown type)"
				printerr("Connection ", id, " of type ", type_name, " not created")
	
	# 3. Remove all orphaned connections
	for dead in existing.values():
		diagram_objects.erase(dead.object_id)
		dead.free()
	
	# Validate
	for edge in self.all_diagram_connections():
		if not edge.origin:
			printerr("Edge ", edge, " has no origin. ID: ", edge.object_id)
		if not edge.target:
			printerr("Edge ", edge, " has no target. ID: ", edge.object_id)


func create_node_from(object: PoieticObject) -> DiagramNode:
	var node: DiagramNode = DiagramNode.new()
	node.name = "diagram_node" + str(object.object_id)
	node.type_name = object.type_name
	node.object_id = object.object_id
	diagram_objects[object.object_id] = node
	add_child(node)
	node.update_from(object)
	return node

func create_edge_from(object: PoieticObject) -> DiagramConnection:
	if object.origin == null or object.target == null:
		push_error("Trying to create connection from object without origin or target.")
		return null
	var origin: DiagramNode = get_diagram_node(object.origin)
	var target: DiagramNode = get_diagram_node(object.target)

	if origin == null:
		# This might be because we are trying to create a non-diagram connection.
		push_error("Origin ", object.origin, " is not part of canvas. Connection not created.")
		return null
	if target == null:
		# This might be because we are trying to create a non-diagram connection.
		push_error("Target ", object.target, " is not part of canvas. Connection not created.")
		return null

	var conn: DiagramConnection = DiagramConnection.new()
	conn.set_connection(origin, target)	
	conn.name = "diagram_connection" + str(object.object_id)
	conn.type_name = object.type_name
	conn.object_id = object.object_id
	diagram_objects[object.object_id] = conn
	add_child(conn)
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

func begin_drag_selection(_mouse_position: Vector2):
	for node in get_selected_nodes():
		node.is_dragged = true

func drag_selection(move_delta: Vector2):
	for node in get_selected_nodes():
		node.position += move_delta

func finish_drag_selection(_final_position: Vector2) -> void:
	var trans = Global.design.new_transaction()
	
	for node in get_selected_nodes():
		node.is_dragged = false
		var object = Global.design.get_object(node.object_id)
		trans.set_attribute(node.object_id, "position", node.position)
	# TODO: Send signal that frame has been changed
	Global.design.accept(trans)
	# FIXME: Proper change handling
		
func delete_selection():
	var trans = Global.design.new_transaction()

	for id in selection.get_ids():
		trans.remove_object(id)

	Global.design.accept(trans)

	selection.clear()
	queue_sync()

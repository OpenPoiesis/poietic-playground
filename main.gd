extends Node2D

# TODO: Save/warn about changes on Open/New Design

enum FileDialogMode {
	IMPORT_FRAME,
	OPEN_DESIGN,
	SAVE_DESIGN,
}

@export var file_dialog_mode: FileDialogMode = FileDialogMode.OPEN_DESIGN
@export var design_path: String = ""
@export var last_opened_design_path: String = ""
@export var last_import_path: String = ""
const DEFAULT_DESIGN_PATH = "user://design.poietic"
const SETTINGS_FILE = "user://settings.cfg"
const default_window_size = Vector2(1280, 720)

@onready var canvas: DiagramCanvas = %Canvas
@onready var player: PoieticPlayer = $SimulationPlayer
@onready var inspector_panel: InspectorPanel = %InspectorPanel
@onready var control_bar: ControlBar = $Gui/ControlBar

@onready var label_editor: CanvasLabelEditor = $Gui/LabelEditor
@onready var context_menu: ContextMenu = $Gui/ContextMenu

func _init():
	pass

func _ready():
	$FileDialog.use_native_dialog = true
	$FileDialog.access = FileDialog.Access.ACCESS_FILESYSTEM
	label_editor.hide()
	label_editor.set_process(false)
	context_menu.hide()
	context_menu.set_process(false)
		
	load_settings()
	get_viewport().connect("size_changed", _on_window_resized)
	
	_initialize_main_menu()
	
	Global.initialize()
	
	# FIXME: Move methods to canvas
	%LabelEditor.editing_submitted.connect(Global.selection_tool._on_label_edit_submitted)
	%LabelEditor.editing_cancelled.connect(Global.selection_tool._on_label_edit_cancelled)
	%FormulaPrompt.formula_editing_submitted.connect(Global.selection_tool._on_formula_edit_submitted)
	%FormulaPrompt.formula_editing_cancelled.connect(Global.selection_tool._on_formula_edit_cancelled)

	# Initialize and connect canvas
	Global.canvas = canvas

	Global.design.design_changed.connect(inspector_panel._on_design_changed)
	Global.design.design_changed.connect(self._on_design_changed)
	Global.design.design_reset.connect(self._on_design_reset)
	Global.design.design_changed.connect(control_bar._on_design_changed)

	canvas.selection.selection_changed.connect(inspector_panel._on_selection_changed)
	canvas.selection.selection_changed.connect(self._on_selection_changed)

	canvas.canvas_view_changed.connect(_on_canvas_view_changed)

	# TODO: See inspector panel source comment about selection
	inspector_panel.selection = canvas.selection
	
	# Simulation Player and Control Bar
	Global.player = player
	control_bar.update_simulator_state()
	
	Global.design.simulation_started.connect(self._on_simulation_started)
	Global.design.simulation_finished.connect(self._on_simulation_success)
	Global.design.simulation_finished.connect(control_bar._on_simulation_success)

	Global.design.simulation_failed.connect(self._on_simulation_failure)
	Global.design.simulation_failed.connect(control_bar._on_simulation_failure)

	# Load demo design
	var path = ""
	if OS.has_feature("editor"):
		path = ProjectSettings.globalize_path("res://resources/new_canvas_demo_design.json")
	else:
		path = OS.get_executable_path().get_base_dir().path_join("resources").path_join("new_canvas_demo_design.json")
	import_foreign_frame_from(path)
	
	# Tell everyone about demo design
	# Global.design.design_changed.emit()
	update_status_text()
	
	print("Done initializing main.")

func _initialize_main_menu():
	# Add working shortcuts here
	# $MenuBar/FileMenu.set_item_accelerator(0, KEY_MASK_META + KEY_N)
	pass

func _on_selection_changed(selection):
	_DEBUG_update_chart()

func _on_design_changed(has_issues: bool):
	# FIXME: Fix selection so that object IDs match
	canvas.sync_design()
	update_status_text()
	if has_issues:
		clear_result()

func _on_design_reset():
	canvas.clear_design()
	canvas.selection.clear()
	update_status_text()

func _on_simulation_started():
	# TODO: Show some indicator to give hope.
	pass

func _on_simulation_success(result):
	# TODO: Send signal: result changed
	set_result(result)

func _on_simulation_failure():
	# TODO: Handle this, display some error somewhere, big, red or something
	clear_result()
	
func _on_canvas_view_changed(offset: Vector2, zoom_level: float):
	update_status_text()

func set_result(result):
	Global.result = result
	player.result = result
	canvas.sync_indicators(result)
	_DEBUG_update_chart()

func clear_result():
	Global.player.stop()
	Global.result = null
	Global.player.result = null
	canvas.clear_indicators()
	
func _on_simulation_player_step():
	canvas.update_indicator_values()
	
func _DEBUG_update_chart():
	if not Global.result:
		printerr("Trying to make a chart without result")
		return
	var chart: Chart = $Gui/MakeshiftChart/Chart
	var ids = canvas.selection.get_ids()
	chart.clear_series()
	if ids and not ids.is_empty():
		for id in ids:
			var series = Global.result.time_series(id)
			if not series:
				continue
			chart.append_series(series)

func _unhandled_input(event):
	# TODO: Document inputs
	if event.is_action_pressed("selection-tool"):
		Global.change_tool(Global.selection_tool)
	elif event.is_action_pressed("place-tool"):
		Global.change_tool(Global.place_tool)
	elif event.is_action_pressed("connect-tool"):
		Global.change_tool(Global.connect_tool)

	# File
	elif event.is_action_pressed("new-design"):
		new_design()
	elif event.is_action_pressed("open-design"):
		open_design()
	elif event.is_action_pressed("save-design-as"):
		save_design_as()
	elif event.is_action_pressed("save-design"):
		save_design()
	elif event.is_action_pressed("import"):
		import_foreign_frame()

	# Edit
	elif event.is_action_pressed("undo"):
		undo()
	elif event.is_action_pressed("redo"):
		redo()
	elif event.is_action_pressed("select-all"):
		select_all()
	elif event.is_action_pressed("delete"):
		delete_selection()
		
	# Diagram
	elif event.is_action_pressed("auto-connec-parameters"):
		auto_connect_parameters()

	elif event.is_action_pressed("inspector-toggle"):
		toggle_inspector()

	elif event.is_action_pressed("edit-formula"):
		edit_formula()
	elif event.is_action_pressed("edit-name"):
		edit_name()

	# Simulation
	elif event.is_action_pressed("run"):
		toggle_run()

	# View
	elif event.is_action_pressed("zoom-actual"):
		zoom_actual()

	elif event.is_action_pressed("debug-dump"):
		debug_dump()

	elif event.is_action_pressed("cancel"):
		Global.close_modal(Global.modal_node)


func update_status_text():
	var stats = Global.design.debug_stats
	
	var text = ""
	text += "Frames: " + str(stats["frames"])
	text += " undo: " + str(stats["undo_frames"])
	text += " redo: " + str(stats["redo_frames"])
	text += " | Current ID: " + str(stats["current_frame"])
	if stats["diagram_nodes"] == stats["nodes"]:
		text += " nodes: " + str(stats["nodes"])
	else:
		text += " nodes: " + str(stats["diagram_nodes"]) + "/" + str(stats["nodes"])
	text += " edges: " + str(stats["edges"])
	text += "\n"
	text += "Design issues: " + str(stats["design_issues"])
	text += " / object issues: " + str(stats["object_issues"])
	text += " | zoom: " + str(int(canvas.zoom_level * 100)) + "%"
	$Gui/StatusText.text = text

func _on_window_resized():
	save_settings()

# Settings
# -------------------------------------------------------------------------

func load_settings():
	var config = ConfigFile.new()
	var load_result = config.load(SETTINGS_FILE)
	if load_result != OK:
		push_warning("Settings file not loaded")
		return

	var window_size = Vector2(
		config.get_value("window", "width", default_window_size.x),
		config.get_value("window", "height", default_window_size.y)
		)

	if config.get_value("inspector", "visible", true):
		$MenuBar/ViewMenu.set_item_checked(0, true)
		inspector_panel.show()
	else:
		$MenuBar/ViewMenu.set_item_checked(0, false)
		inspector_panel.hide()
		
	var last_path = config.get_value("design", "last_opened_path")
	if last_path:
		last_opened_design_path = last_path

	var last_import_path = config.get_value("design", "last_import_path")
	if last_import_path:
		self.last_import_path = last_import_path

	DisplayServer.window_set_size(window_size)

func save_settings():
	var window_size = DisplayServer.window_get_size()
	var config = ConfigFile.new()
	if config.load(SETTINGS_FILE) != OK:
		# Just warn, do not return, but proceed with new settings.
		push_warning("Unable to load settings")
	
	config.set_value("window", "width", window_size.x)
	config.set_value("window", "height", window_size.y)
	config.set_value("inspector", "visible", inspector_panel.visible)
	if design_path != "":
		config.set_value("design", "last_opened_path", design_path)
	if last_import_path != "":
		config.set_value("design", "last_import_path", last_import_path)
	config.save(SETTINGS_FILE)
	
# File Menu
# -------------------------------------------------------------------------

func new_design():
	design_path = ""
	Global.design.new_design()

func open_design():
	$FileDialog.file_mode = FileDialog.FileMode.FILE_MODE_OPEN_FILE
	$FileDialog.title = "Open Design"
	$FileDialog.ok_button_text = "Open"
	if design_path != "":
		$FileDialog.current_path = design_path
	elif last_opened_design_path != "":
		$FileDialog.current_path = last_opened_design_path
	else:
		$FileDialog.current_path = ProjectSettings.globalize_path(DEFAULT_DESIGN_PATH)
	
	$FileDialog.filters = ["*.poietic"]
	self.file_dialog_mode = FileDialogMode.OPEN_DESIGN
	$FileDialog.show()


# Save-as
func save_design_as():
	$FileDialog.file_mode = FileDialog.FileMode.FILE_MODE_SAVE_FILE
	$FileDialog.title = "Save Design"
	$FileDialog.ok_button_text = "Save"
	if design_path != "":
		$FileDialog.current_path = design_path
	elif last_opened_design_path != "":
		$FileDialog.current_path = last_opened_design_path
	else:
		$FileDialog.current_path = ProjectSettings.globalize_path(DEFAULT_DESIGN_PATH)
	
	$FileDialog.filters = ["*.poietic"]
	self.file_dialog_mode = FileDialogMode.SAVE_DESIGN
	$FileDialog.show()

func save_design():
	var path: String
	if design_path != "":
		print("Saving design: ", design_path)
		Global.design.save_to_path(design_path)
	else:
		save_design_as()
	
func import_foreign_frame():
	$FileDialog.file_mode = FileDialog.FileMode.FILE_MODE_OPEN_ANY
	$FileDialog.title = "Import Poietic Frame"
	$FileDialog.ok_button_text = "Import"	
	$FileDialog.filters = ["*.poieticframe"]
	self.file_dialog_mode = FileDialogMode.IMPORT_FRAME

	if last_import_path != "":
		$FileDialog.current_path = last_import_path
	else:
		$FileDialog.current_path = ProjectSettings.globalize_path(DEFAULT_DESIGN_PATH)

	$FileDialog.show()

func import_foreign_frame_from(path: String):
	Global.design.import_from_path(path)

# Edit Menu
# -------------------------------------------------------------------------

func undo():
	if Global.design.can_undo():
		Global.design.undo()
	else:
		printerr("Trying to undo while having nothing to undo")

func redo():
	if Global.design.can_redo():
		Global.design.redo()
	else:
		printerr("Trying to redo while having nothing to redo")

func delete_selection():
	canvas.delete_selection()

func select_all():
	var ids = canvas.all_diagram_object_ids()
	canvas.selection.replace(ids)

# Diagram Menu
# -------------------------------------------------------------------------

func auto_connect_parameters():
	Global.design.auto_connect_parameters([])

func remove_midpoints():
	canvas.remove_midpoints_in_selection()

func edit_formula():
	# TODO: Beep
	var ids = Global.canvas.selection.get_ids()
	if len(ids) != 1:
		return
	var object = Global.design.get_object(ids[0])
	if not object:
		return
	if not object.has_trait("Formula"):
		return

	Global.canvas.open_formula_prompt(ids[0])

func edit_name():
	# TODO: Beep
	var ids = Global.canvas.selection.get_ids()
	if len(ids) != 1:
		return
	var object = Global.design.get_object(ids[0])
	if not object:
		return
	if not object.has_trait("Name"):
		return

	var node: DiagramNode = Global.canvas.get_diagram_node(ids[0])
	canvas.open_name_editor(node)

# View Menu
# -------------------------------------------------------------------------

func toggle_inspector():
	if inspector_panel.visible:
		inspector_panel.hide()
		$MenuBar/ViewMenu.set_item_checked(0, false)
	else:
		$MenuBar/ViewMenu.set_item_checked(0, true)
		inspector_panel.show()
	save_settings()

func toggle_value_indicators():
	if Global.show_value_indicators:
		Global.show_value_indicators = false
		$MenuBar/ViewMenu.set_item_checked(2, false)
	else:
		Global.show_value_indicators = true
		$MenuBar/ViewMenu.set_item_checked(2, true)
	save_settings()

func zoom_actual():
	canvas.set_zoom_level(1.0, get_global_mouse_position())
	canvas.update_canvas_view()

# Simulation Menu
# -------------------------------------------------------------------------
func toggle_run():
	if Global.player.is_running:
		Global.player.stop()
	else:
		Global.player.run()

func debug_dump():
	prints("=== DEBUG DUMP BEGIN ===")
	var ids: PackedInt64Array = []
	if canvas.selection.is_empty():
		ids = canvas.diagram_objects.keys()
	else:
		ids = canvas.selection.get_ids()
	for key in ids:
		var dia_object: DiagramObject = canvas.diagram_objects[key]
		var object: PoieticObject = Global.design.get_object(dia_object.object_id)
		if not object:
			printerr("Canvas object without design object: ", dia_object.object_id)
			continue
		prints("ID: ", object.object_id, " type: ", object.type_name, " dia: ", dia_object)
		if object.origin != null:
			print("    edge: ", object.origin, " -> ", object.target)
		for attr in object.get_attribute_keys():
			var value = object.get_attribute(attr)
			print("    ", attr, " = ", value)
	prints("=== DEBUG DUMP END ===")

func _on_file_dialog_files_selected(paths):
	match file_dialog_mode:
		FileDialogMode.IMPORT_FRAME:
			for path in paths:
				print("Import frame: ", path)
				Global.design.import_from_path(path)
				last_import_path = path
				save_settings()
		FileDialogMode.OPEN_DESIGN:
			push_error("Trying to open a design from multiple paths")
		FileDialogMode.SAVE_DESIGN:
			push_error("Trying to save a design from multiple paths")
		_:
			push_warning("Unhandled file selection mode: ", file_dialog_mode)

func _on_file_dialog_dir_selected(path):
	match file_dialog_mode:
		FileDialogMode.IMPORT_FRAME:
			print("Import frame: ", path)
			Global.design.import_from_path(path)
			last_import_path = path
			save_settings()
		FileDialogMode.OPEN_DESIGN:
			push_error("Trying to open a design from a directory: ", path)
		FileDialogMode.SAVE_DESIGN:
			push_error("Trying to save a design to a directory: ", path)
		_:
			push_warning("Unhandled file selection mode: ", file_dialog_mode)

func _on_file_dialog_file_selected(path):
	match file_dialog_mode:
		FileDialogMode.IMPORT_FRAME:
			print("Import frame: ", path)
			Global.design.import_from_path(path)
			last_import_path = path
			save_settings()
		FileDialogMode.OPEN_DESIGN:
			print("Open design: ", path)
			Global.design.load_from_path(path)
			self.design_path = path
			self.last_opened_design_path = path
			save_settings()

		FileDialogMode.SAVE_DESIGN:
			print("Save design: ", path)
			Global.design.save_to_path(path)
			self.design_path = path
		_:
			push_warning("Unhandled file selection mode: ", file_dialog_mode)

# Menu

func _on_file_menu_id_pressed(id):
	match id:
		0: new_design()
		1: open_design()
		2: save_design()
		5: save_design_as()
		4: import_foreign_frame()
		_: printerr("Unknown File menu id: ", id)

func _on_edit_menu_id_pressed(id):
	match id:
		0: undo()
		1: redo()
		2: pass # separator
		3: delete_selection()
		4: pass # separator
		5: select_all()
		_: printerr("Unknown Edit menu id: ", id)

func _on_diagram_menu_id_pressed(id):
	match id:
		0: auto_connect_parameters()
		1: remove_midpoints()
		_: printerr("Unknown Diagram menu id: ", id)

func _on_view_menu_id_pressed(id):
	match id:
		0: toggle_inspector()
		1: pass # separator
		2: toggle_value_indicators()
		_: printerr("Unknown View menu id: ", id)

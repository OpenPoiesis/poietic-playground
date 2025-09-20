extends Node2D

# TODO: Save/warn about changes on Open/New Design

enum FileDialogMode {
	IMPORT_FRAME,
	OPEN_DESIGN,
	SAVE_DESIGN,
}

const NEW_DESIGN_TEMPLATE_PATH = "res://resources/new_canvas_demo_design.json"


@export var file_dialog_mode: FileDialogMode = FileDialogMode.OPEN_DESIGN
@export var design_path: String = ""
@export var last_opened_design_path: String = ""
@export var last_import_path: String = ""
const DEFAULT_DESIGN_PATH = "user://design.poietic"
const SETTINGS_FILE = "user://settings.cfg"
const default_window_size = Vector2(1280, 720)

@onready var application: PoieticApplication = $PoieticApplication
@onready var canvas: DiagramCanvas = $Canvas
@onready var canvas_ctrl: CanvasController

@onready var inspector_panel: InspectorPanel = %InspectorPanel

@onready var result_panel: PanelContainer = %ResultPanel
@onready var player: ResultPlayer = $SimulationPlayer
@onready var control_bar: PanelContainer = %PlayerControlBar
@onready var tool_bar: ToolBar = %Gui/ToolBar
@onready var tool_object_palette = %Gui/ToolObjectPalette

func _init():
	InspectorPanel.instantiate_default_panels()

func _ready():
	prints("Screen DPI:", DisplayServer.screen_get_dpi(), 
			"scale:",  DisplayServer.screen_get_scale(),
			"max scale:", DisplayServer.screen_get_max_scale(),
			"usable rect:", DisplayServer.screen_get_usable_rect().size)
	
	$FileDialog.use_native_dialog = true
	$FileDialog.access = FileDialog.Access.ACCESS_FILESYSTEM

	initialize_menu_bar()
		
	load_settings()
	get_viewport().connect("size_changed", _on_window_resized)
	
	_initialize_main_menu()

	canvas_ctrl = CanvasController.new()
	canvas_ctrl.initialize(application.design_controller, canvas)
	application.canvas_controller = canvas_ctrl
	initialize_inline_editors(canvas_ctrl)
	%ContextMenu.initialize(canvas_ctrl)
	canvas_ctrl.context_menu = %ContextMenu

	
	Global.initialize(application, player)
	application.tool_changed.connect(tool_bar._on_tool_changed)
	application.change_tool(application.selection_tool)
	application.tool_changed.connect(self._on_tool_changed)
	$Gui/ToolObjectPalette.palette_item_changed.connect(self._on_tool_palette_item_changed)

	control_bar.initialize(application.design_controller, player)
	result_panel.initialize(application.design_controller, player, canvas)
	inspector_panel.initialize(application.design_controller, player)

	var design_ctrl = application.design_controller
	design_ctrl.design_changed.connect(self._on_design_changed)
	design_ctrl.design_reset.connect(self._on_design_reset)
	design_ctrl.simulation_started.connect(self._on_simulation_started)
	design_ctrl.simulation_finished.connect(self._on_simulation_success)
	design_ctrl.simulation_failed.connect(self._on_simulation_failure)
	canvas.canvas_view_changed.connect(self._on_canvas_view_changed)

	# Load demo design
	var data = FileAccess.get_file_as_bytes(NEW_DESIGN_TEMPLATE_PATH)
	import_foreign_frame_from_data(data)
	
	update_status_text()
	_update_simulation_menu()
	
	print("Done initializing main.")

func initialize_inline_editors(canvas_ctrl: CanvasController):
	var name_editor = $Gui/InlineEditors/NameInlineEditor
	name_editor.initialize(canvas_ctrl)
	canvas_ctrl.register_inline_editor("name", name_editor)

	var formula_editor = $Gui/InlineEditors/FormulaInlineEditor
	formula_editor.initialize(canvas_ctrl)
	canvas_ctrl.register_inline_editor("formula", formula_editor)

	var numeric_attr_editor = $Gui/InlineEditors/NumericAttributeInlineEditor
	numeric_attr_editor.initialize(canvas_ctrl)
	canvas_ctrl.register_inline_editor("numeric_attribute", numeric_attr_editor)

	var issues_popup = $Gui/InlineEditors/IssuesPopup
	# issues_popup.initialize(canvas_ctrl)
	canvas_ctrl.register_inline_editor("issues", issues_popup)

func initialize_menu_bar():
	# TODO: Not sure what is going on here. On Ubuntu the menu is not displayed.
	if DisplayServer.has_feature(DisplayServer.FEATURE_GLOBAL_MENU):
		%MenuBar.prefer_global_menu = true
		print("Using system's native main menu")
		return
	print("Using Godot's built-in main menu")
	%MenuBar.prefer_global_menu = false


func _initialize_main_menu():
	# Add working shortcuts here
	# $MenuBar/FileMenu.set_item_accelerator(0, KEY_MASK_META + KEY_N)
	pass

func _on_tool_changed(tool: CanvasTool):
	if tool is SelectionTool:
		tool_object_palette.hide()
		pass
	elif tool is PlaceTool:
		tool_object_palette.load_node_pictograms()
		if tool.palette_item_identifier != null:
			tool_object_palette.selected_item = tool.palette_item_identifier
		tool_object_palette.show()
	elif tool is ConnectTool:
		tool_object_palette.load_connector_pictograms()
		if tool.palette_item_identifier != null:
			tool_object_palette.selected_item = tool.palette_item_identifier
		tool_object_palette.show()
	else:
		tool_object_palette.hide()

func _on_tool_palette_item_changed(item: String):
	prints("--- Tool palette item changed: ", item)
	application.current_tool.palette_item_identifier = item

func _on_design_changed(has_issues: bool):
	# FIXME: Fix selection so that object IDs match
	update_status_text()
	if has_issues:
		clear_result()

func _on_design_reset():
	canvas_ctrl.clear_canvas()
	# FIXME: Move selection manager to main
	canvas_ctrl.design_controller.selection_manager.clear()
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
	canvas_ctrl.sync_indicators(result)
	_update_simulation_menu()


func clear_result():
	Global.player.stop()
	Global.result = null
	Global.player.result = null
	# FIXME: Re-add this:
	# canvas.clear_indicators()
	_update_simulation_menu()
	
func _on_simulation_player_step():
	canvas.update_indicator_values(player)
	
func _unhandled_input(event):
	# TODO: Document inputs
	if event.is_action_pressed("selection-tool"):
		Global.app.change_tool(Global.app.selection_tool)
	elif event.is_action_pressed("place-tool"):
		Global.app.change_tool(Global.app.place_tool)
	elif event.is_action_pressed("connect-tool"):
		Global.app.change_tool(Global.app.connect_tool)
	elif event.is_action_pressed("pan-tool"):
		if Global.app.current_tool is PanTool:
			Global.app.change_tool(Global.app.previous_tool)
		else:
			Global.app.change_tool(Global.app.pan_tool)

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
	elif event.is_action_pressed("ui_cut"):
		cut_selection()
	elif event.is_action_pressed("ui_copy"):
		copy_selection()
	elif event.is_action_pressed("ui_paste"):
		paste()
	elif event.is_action_pressed("delete"):
		delete_selection()
	elif event.is_action_pressed("ui_paste"):
		paste()
		
	# Diagram
	elif event.is_action_pressed("auto-connec-parameters"):
		auto_connect_parameters()

	elif event.is_action_pressed("inspector-toggle"):
		toggle_inspector()

	elif event.is_action_pressed("edit-formula"):
		edit_primary_attribute()
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
		canvas_ctrl.close_inline_popup()

func update_status_text():
	var stats = application.design_controller.debug_stats
	
	var text = ""
	text += "Frames: " + str(stats["frames"])
	text += " undo: " + str(stats["undo_frames"])
	text += " redo: " + str(stats["redo_frames"])
	text += " | Current ID: " + str(stats["current_frame"])
	if stats["diagram_blocks"] == stats["nodes"]:
		text += " nodes: " + str(stats["nodes"])
	else:
		text += " nodes: " + str(stats["diagram_blocks"]) + "/" + str(stats["nodes"])
	text += " edges: " + str(stats["edges"])
	text += "\n"
	text += "Design issues: " + str(stats["design_issues"])
	text += " / object issues: " + str(stats["object_issues"])
	text += " | zoom: " + str(int(canvas.zoom_level * 100)) + "%"
	%Gui/StatusText.text = text

func _on_window_resized():
	save_settings()

# Settings
# -------------------------------------------------------------------------

func load_settings():
	var actual_window_position = DisplayServer.window_get_position()
	var config = ConfigFile.new()
	var load_result = config.load(SETTINGS_FILE)
	if load_result != OK:
		push_warning("Settings file not loaded")
		return

	var window_size = Vector2(
		config.get_value("window", "width", default_window_size.x),
		config.get_value("window", "height", default_window_size.y)
		)
	var window_position = Vector2(
		config.get_value("window", "x", actual_window_position.x),
		config.get_value("window", "y", actual_window_position.y)
		)

	if config.get_value("inspector", "visible", true):
		%MenuBar/ViewMenu.set_item_checked(0, true)
		inspector_panel.show()
	else:
		%MenuBar/ViewMenu.set_item_checked(0, false)
		inspector_panel.hide()
		
	var last_path = config.get_value("design", "last_opened_path")
	if last_path:
		last_opened_design_path = last_path

	var last_import_path = config.get_value("design", "last_import_path")
	if last_import_path:
		self.last_import_path = last_import_path

	DisplayServer.window_set_size(window_size)
	DisplayServer.window_set_position(window_position)
	
func save_settings():
	var window_position = DisplayServer.window_get_position()
	var window_size = DisplayServer.window_get_size()
	var config = ConfigFile.new()
	if config.load(SETTINGS_FILE) != OK:
		# Just warn, do not return, but proceed with new settings.
		push_warning("Unable to load settings")
	
	config.set_value("window", "x", window_position.x)
	config.set_value("window", "y", window_position.y)
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
	application.design_controller.new_design()

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
		application.design_controller.save_to_path(design_path)
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
	application.design_controller.import_from_path(path)

func import_foreign_frame_from_data(data: PackedByteArray):
	application.design_controller.import_from_data(data)

# Edit Menu
# -------------------------------------------------------------------------

func undo():
	if application.design_controller.can_undo():
		application.design_controller.undo()
	else:
		printerr("Trying to undo while having nothing to undo")

func redo():
	if application.design_controller.can_redo():
		application.design_controller.redo()
	else:
		printerr("Trying to redo while having nothing to redo")

func delete_selection():
	canvas.delete_selection()

func paste():
	var text = DisplayServer.clipboard_get()
	application.design_controller.paste_from_text(text)
	
func copy_selection():
	var pasteboard_text = application.design_controller.copy_selection_as_text()
	DisplayServer.clipboard_set(pasteboard_text)

func cut_selection():
	copy_selection()
	delete_selection()

func select_all():
	application.canvas_ctrl.select_all()

# Diagram Menu
# -------------------------------------------------------------------------

func auto_connect_parameters():
	application.design_controller.auto_connect_parameters(PackedInt64Array())

func remove_midpoints():
	canvas.remove_midpoints_in_selection()

func get_current_selection() -> PackedInt64Array:
	return application.design_controller.selection_manager.get_ids()
	
# TODO: Rename to edit_secondary_attribute
func edit_primary_attribute():
	# TODO: Beep
	var object: PoieticObject = canvas_ctrl.get_single_selection_object()
	if object == null:
		return
		
	elif object.has_trait("Formula"):
		canvas_ctrl.open_inline_editor("formula", object.object_id, "formula")
	elif object.has_trait("Delay"):
		canvas_ctrl.open_inline_editor("numeric_attribute", object.object_id, "delay_duration")
	elif object.has_trait("Smooth"):
		canvas_ctrl.open_inline_editor("numeric_attribute", object.object_id, "window_time")

func edit_name():
	# TODO: Beep
	var object: PoieticObject = canvas_ctrl.get_single_selection_object()
	if object == null:
		return
	if not object.has_trait("Name"):
		return
	prints("EDIT NAME ", object)
	canvas_ctrl.open_inline_editor("name", object.object_id, "name")

# View Menu
# -------------------------------------------------------------------------

func toggle_inspector():
	if inspector_panel.visible:
		inspector_panel.hide()
		%MenuBar/ViewMenu.set_item_checked(0, false)
	else:
		%MenuBar/ViewMenu.set_item_checked(0, true)
		inspector_panel.show()
	save_settings()

func toggle_value_indicators():
	if Global.show_value_indicators:
		Global.show_value_indicators = false
		%MenuBar/ViewMenu.set_item_checked(2, false)
	else:
		Global.show_value_indicators = true
		%MenuBar/ViewMenu.set_item_checked(2, true)
	save_settings()

func zoom_actual():
	canvas.set_zoom(1.0, get_global_mouse_position())
	canvas.update_canvas_view()

# Simulation Menu
# -------------------------------------------------------------------------
func toggle_run():
	if Global.player.is_running:
		Global.player.stop()
	else:
		Global.player.run()

func export_result_csv():
	if Global.result == null:
		return
	%CsvExportDialog.configure(Global.result, canvas.selection)
	%CsvExportDialog.show()

func debug_dump():
	prints("=== DEBUG DUMP BEGIN ===")
	var ids: PackedInt64Array = []
	if canvas.selection.is_empty():
		ids = canvas.diagram_objects.keys()
	else:
		ids = canvas.selection.get_ids()
	for key in ids:
		var dia_object: DiagramCanvasObject = canvas.diagram_objects[key]
		var object: PoieticObject = application.design_controller.get_object(dia_object.object_id)
		if not object:
			printerr("Canvas object without design object: ", dia_object.object_id)
			continue
		prints("ID: ", object.object_id, " type: ", object.type_name, " dia: ", dia_object)
		if object.origin != null:
			print("    edge: ", object.origin, " -> ", object.target)
		for attr in object.get_attribute_keys():
			var value = object.get_attribute(attr)
			if value != null:
				print("    ", attr, " = ", value)
	prints("=== DEBUG DUMP END ===")

func _on_file_dialog_files_selected(paths):
	match file_dialog_mode:
		FileDialogMode.IMPORT_FRAME:
			for path in paths:
				print("Import frame: ", path)
				application.design_controller.import_from_path(path)
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
			application.design_controller.import_from_path(path)
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
			application.design_controller.import_from_path(path)
			last_import_path = path
			save_settings()
		FileDialogMode.OPEN_DESIGN:
			print("Open design: ", path)
			application.design_controller.load_from_path(path)
			self.design_path = path
			self.last_opened_design_path = path
			save_settings()

		FileDialogMode.SAVE_DESIGN:
			print("Save design: ", path)
			application.design_controller.save_to_path(path)
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
		6: cut_selection()
		7: copy_selection()
		8: paste()
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

func _on_simulation_menu_id_pressed(id):
	match id:
		6: export_result_csv()
		_: printerr("Unknown Simulation menu id: ", id)

func _on_csv_export_requested(file_path: String, option: CSVExportDialog.ExportOption, result: PoieticResult, objects: PackedInt64Array):
	var export_objects: PackedInt64Array = []
	match option:
		CSVExportDialog.ExportOption.ALL:
			export_objects = result.get_computed_object_ids()
		CSVExportDialog.ExportOption.ALL_INCLUDING_INTERNAL:
			export_objects = []
		CSVExportDialog.ExportOption.SELECTED_NODES:
			export_objects = objects

	application.design_controller.write_to_csv(file_path, result, export_objects)

func _update_simulation_menu():
	var has_result = Global.result != null
	%MenuBar/SimulationMenu.set_item_disabled(6, not has_result)

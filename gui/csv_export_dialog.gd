class_name CSVExportDialog extends ConfirmationDialog

const DEFAULT_EXPORT_FILENAME: String = "export.csv"

signal export_requested(file_path: String, option: ExportOption, result: PoieticResult, objects: PackedInt64Array)

var result: PoieticResult
var selection: PoieticSelection

@onready var export_all_button: CheckBox = %ExportAllButton
@onready var export_all_internal_button: CheckBox = %ExportAllWithInternalButton
@onready var export_selected_button: CheckBox = %ExportSelectedButton
var _file_dialog: FileDialog

enum ExportOption {
	ALL,
	ALL_INCLUDING_INTERNAL, 
	SELECTED_NODES
}

func _ready():
	_setup_file_dialog()

func configure(result: PoieticResult, selection: PoieticSelection):
	self.result = result
	self.selection = selection
	export_selected_button.disabled = selection.is_empty()

func _setup_file_dialog():
	_file_dialog = FileDialog.new()
	_file_dialog.use_native_dialog = true
	_file_dialog.access = FileDialog.Access.ACCESS_FILESYSTEM
	_file_dialog.file_mode = FileDialog.FileMode.FILE_MODE_SAVE_FILE
	_file_dialog.title = "Export Result"
	_file_dialog.filters = ["*.csv"]
	_file_dialog.file_selected.connect(_on_file_selected)
	add_child(_file_dialog)

func _on_confirmed():
	var proposed_filename = _get_proposed_filename()
	_file_dialog.current_file = proposed_filename
	_file_dialog.show()

func _get_proposed_filename() -> String:
	var main_node = get_node("/root/Main")
	if main_node and main_node.design_path != "":
		var basename = main_node.design_path.get_file().get_basename()
		return basename + ".csv"
	else:
		return DEFAULT_EXPORT_FILENAME

func _get_selected_option() -> ExportOption:
	if export_all_button.button_pressed:
		return ExportOption.ALL
	elif export_all_internal_button.button_pressed:
		return ExportOption.ALL_INCLUDING_INTERNAL
	elif export_selected_button.button_pressed:
		return ExportOption.SELECTED_NODES
	else:
		return ExportOption.ALL

func _on_file_selected(path: String):
	export_requested.emit(path, _get_selected_option(), self.result, self.selection.get_ids())
	hide()

func _on_canceled():
	hide()

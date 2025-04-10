extends InspectorTraitPanel

@onready var error_list: ItemList = %ErrorList
@onready var tab_container: TabContainer = $VBoxContainer/TabContainer

# Called when the node enters the scene tree for the first time.
func _ready():
	error_list.add_item("Boo!")
	pass # Replace with function body.

func on_selection_changed():
	error_list.clear()
	if selection.count() == 0:
		tab_container.current_tab = 0
		return
	elif selection.count() > 1:
		tab_container.current_tab = 1
		return

	var object = selection.get_ids()[0]
	var issues:Array[PoieticIssue] = Global.design.issues_for_object(object)
	if len(issues) > 0:
		tab_container.current_tab = 2
		for issue in issues:
			error_list.add_item(issue.message)
	else: # No issues
		tab_container.current_tab = 0
		

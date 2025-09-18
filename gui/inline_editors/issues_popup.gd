class_name IssuesPopup extends CanvasInlineEditor

@onready var issue_list: ItemList = %IssueList

func open2(object_id: int, issues: Array[PoieticIssue], center: Vector2):
	assert(object_id != null, "Edited object ID not provided")
	
	global_position = Vector2(center.x - self.size.x / 2, center.y)
	
	issue_list.clear()
	for index in len(issues):
		var issue: PoieticIssue = issues[index]
		issue_list.add_item(issue.message)
		if issue.hint:
			issue_list.set_item_tooltip(index, issue.hint)
	
	is_active = true
	show()
	set_process(true)

func close():
	if !is_active:
		return
	set_process(false)
	hide()
	is_active = false

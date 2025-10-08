class_name IssuesPopup extends CanvasInlineEditor

@onready var issue_list: ItemList = %IssueList

func set_issues(object_id: int, issues: Array[PoieticIssue]):
	issue_list.clear()
	for index in len(issues):
		var issue: PoieticIssue = issues[index]
		issue_list.add_item(issue.message)
		if issue.hint:
			issue_list.set_item_tooltip(index, issue.hint)

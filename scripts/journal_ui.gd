class_name JournalUI
extends Control
## Ulysses' journal: entries the twins have found, plus the shared inventory.
## Each twin only sees entries meant for them (GameState.journal_for), so the
## journal can hold private clues too.

## A new entry this twin can see was added.
signal entry_added

var _list: ItemList
var _body: RichTextLabel
var _items: Label
var _entries: Array = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left = 80
	panel.offset_top = 60
	panel.offset_right = -80
	panel.offset_bottom = -60
	add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var title := Label.new()
	title.text = "Ulysses' Journal"
	title.add_theme_font_size_override("font_size", 28)
	col.add_child(title)

	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 16)
	col.add_child(row)

	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(260, 0)
	_list.item_selected.connect(_on_selected)
	row.add_child(_list)

	_body = RichTextLabel.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_font_size_override("normal_font_size", 20)
	row.add_child(_body)

	_items = Label.new()
	col.add_child(_items)

	var close := Label.new()
	close.text = "[J] / (Back) / [Esc] close"
	col.add_child(close)

	GameState.changed.connect(func(_key: String) -> void: refresh())
	GameState.journal_added.connect(_on_journal_added)
	refresh()


func refresh() -> void:
	var selected := _list.get_selected_items()
	_entries = GameState.journal_for(Net.my_role())
	_list.clear()
	for e in _entries:
		_list.add_item(e["title"])
	if _entries.is_empty():
		_body.text = "Nothing written yet."
	else:
		var i: int = selected[0] if not selected.is_empty() and selected[0] < _entries.size() else _entries.size() - 1
		_list.select(i)
		_on_selected(i)
	var names := GameState.inventory.values()
	_items.text = "Carrying: " + (", ".join(names) if not names.is_empty() else "nothing")


func _on_selected(index: int) -> void:
	_body.text = _entries[index]["body"]


func _on_journal_added(entry: Dictionary) -> void:
	if entry["who"] == "both" or entry["who"] == Net.my_role():
		entry_added.emit()

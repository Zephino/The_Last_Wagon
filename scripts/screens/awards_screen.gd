extends Node2D
## Every award: earned ones show what they unlocked; secret ones stay "???"
## until found. Also shows running totals across all trips.


func _ready() -> void:
	var root := UiKit.make_layer(self)
	var background := ColorRect.new()
	background.color = Color("0c0a10")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)
	var title := UiKit.label("AWARDS  %d / %d" % [Progress.awards.size(), Unlocks.AWARDS.size()], 22, UiKit.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.pin(title, root, Vector2(0.5, 0), Vector2(-300, 8), Vector2(600, 0))
	var totals := UiKit.label("Trips %d   Finished %d   Crates %d   Enemies %d   Stashes %d" % [
		Progress.stat("trips"), Progress.stat("finished"), Progress.stat("crates"),
		Progress.stat("enemies"), Progress.stat("stashes")], 10, UiKit.DIM)
	totals.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UiKit.pin(totals, root, Vector2(0.5, 0), Vector2(-300, 40), Vector2(600, 0))
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	UiKit.pin(scroll, root, Vector2(0.5, 0), Vector2(-300, 60), Vector2(600, 250))
	var list := UiKit.vbox(4)
	list.custom_minimum_size = Vector2(580, 0)
	scroll.add_child(list)
	for award: Dictionary in Unlocks.AWARDS:
		list.add_child(_award_row(award))
	var back := UiKit.button("Back", Trip.go.bind("title"), 13)
	back.custom_minimum_size = Vector2(120, 0)
	UiKit.pin(back, root, Vector2(0.5, 1), Vector2(-60, -40))


func _award_row(award: Dictionary) -> PanelContainer:
	var earned := Progress.has_award(award["id"])
	var hidden: bool = award["secret"] and not earned
	var row := UiKit.panel(Vector2(580, 0))
	var column := UiKit.vbox(1)
	row.add_child(column)
	var heading := ("[DONE] " if earned else "[    ] ") + ("??? (secret)" if hidden else str(award["name"]))
	column.add_child(UiKit.label(heading, 12, UiKit.GOOD if earned else (UiKit.DIM if hidden else UiKit.TEXT)))
	var how := "Keep exploring. Secrets hide in levels and on the road." if hidden else str(award["how"])
	column.add_child(UiKit.label(how, 9, UiKit.DIM))
	if not hidden:
		column.add_child(UiKit.label(Unlocks.describe_unlock(award["unlock"]), 9, UiKit.ACCENT if earned else UiKit.DIM))
	return row

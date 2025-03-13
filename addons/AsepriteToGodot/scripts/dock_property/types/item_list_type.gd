@tool
extends Node

## References.
@onready var dock_property: HBoxContainer = get_parent().get_parent()


# Prepares the DockProperty to function as "ItemListType".
func enter() -> void:
	# Connects the DockProperty signals.
	dock_property.value_changed.connect(_on_dock_property_value_changed)
	
	# Creates the ItemList and adds it to the DockProperty.
	var item_list: OptionButton = OptionButton.new()
	dock_property.add_child(item_list)
	
	# Configures the ItemList.
	item_list.name = "ItemList"
	item_list.size_flags_horizontal = Control.SIZE_SHRINK_END
	item_list.fit_to_longest_item = false
	item_list.theme = load("res://addons/AsepriteToGodot/resources/item_list_theme.tres")
	if dock_property.clip_text: item_list.clip_text = true
	if dock_property.shrink_end: item_list.size_flags_horizontal = 10
	else: item_list.size_flags_horizontal = 3
	
	# Connects the ItemList signals.
	item_list.item_selected.connect(_on_item_list_item_selected)
	# Adds the items to the ItemList.
	add_items()
	
	## REMOVE
	## Sets the DockProperty value as the selected item from the ItemList.
	#dock_property.value = item_list.selected


# Clears the DockProperty of "ItemListType".
func exit() -> void:
	# Removes the ItemList.
	var item_list: OptionButton = dock_property.get_node("ItemList")
	item_list.free()
	# Disconnects the DockProperty signals.
	dock_property.value_changed.disconnect(_on_dock_property_value_changed)


# Adds the items to the ItemList.
func add_items() -> void:
	var item_list: OptionButton = dock_property.get_node("ItemList")
	clear_items()
	
	# Adds the items.
	for item_i in range(dock_property.item_list.size()):
		var item_text: String = dock_property.item_list[item_i]
		var item_icon: CompressedTexture2D = dock_property.item_list_icons[item_i]
		item_list.add_icon_item(item_icon, item_text)
	
	# Keeps the previously selected item.
	if dock_property.value:
		item_list.select(dock_property.value)


# Removes the items and their icons from the ItemList.
func clear_items() -> void:
	var item_list: OptionButton = dock_property.get_node("ItemList")
	for item_i in range(item_list.item_count): 
			item_list.set_item_icon(item_i, null)
	item_list.clear()


## Signals.
# Called when an item from the ItemList is selected.
func _on_item_list_item_selected(index: int) -> void:
	if index == 0:
		dock_property.value = null
	else:
		dock_property.value = index


# Called when the DockProperty value changes.
func _on_dock_property_value_changed(value: Variant) -> void:
	# If the DockProperty value is null, the first item is selected.
	if value == null:
		dock_property.get_node("ItemList").select(0)
	
	# If the value is an Array, the items are added.
	elif value is Array:
		add_items()

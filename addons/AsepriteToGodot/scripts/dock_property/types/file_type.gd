@tool
extends Node

## References.
@onready var dock_property: HBoxContainer = get_parent().get_parent()


# Prepare the DockProperty to function as "FileType".
func enter() -> void:
	# Connect the signals of the DockProperty.
	dock_property.value_changed.connect(_on_dock_property_value_changed)
	
	# Create the file selection button and add it to the DockProperty.
	var file_button: Button = Button.new()
	dock_property.add_child(file_button)
	# Configure the FileButton.
	file_button.name = "FileButton"
	file_button.text = "<empty>"
	file_button.flat = true
	file_button.size_flags_horizontal = 10
	file_button.set_script(load("res://addons/AsepriteToGodot/scripts/dock_property/file_button.gd"))
	# Connect the signals of the FileButton.
	file_button.drop_data_received.connect(_on_file_button_drop_data_received)
	file_button.gui_input.connect(_on_file_button_gui_input)
	
	# Create the extra file selection button and add it to the DockProperty.
	var extra_file_button: Button = Button.new()
	dock_property.add_child(extra_file_button)
	# Configure the ExtraFileButton.
	extra_file_button.name = "ExtraFileButton"
	extra_file_button.icon = load("res://addons/AsepriteToGodot/icons/GuiOptionArrow.svg")
	# Connect the signals of the ExtraFileButton.
	extra_file_button.gui_input.connect(_on_extra_file_button_gui_input)


# Clear the DockProperty of the "FileType".
func exit() -> void:
	# Remove the file selection buttons.
	dock_property.get_node("FileButton").free()
	dock_property.get_node("ExtraFileButton").free()
	# Disconnect the signals from the dock_property.
	dock_property.value_changed.disconnect(_on_dock_property_value_changed)


# Check the input of the FileButton and ExtraFileButton.
func check_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed: return
	
	# Left Mouse Button.
	if event.button_index == 1:
		open_file_dialogue()
	
	# Right Mouse Button.
	elif event.button_index == 2:
		# If the dock_property has a value, the clear_option will be activated.
		var clear_option_disabled: bool = true
		if not dock_property.value == null: clear_option_disabled = false
		# Open the PopupMenu of the main_dock.
		dock_property.main_dock.open_popup_menu(clear_option_disabled)
		# Bind the signals of the PopupMenu from the main_dock.
		dock_property.main_dock.popup_menu.popup_hide.connect(_on_popup_menu_popup_hide)
		dock_property.main_dock.popup_menu.index_pressed.connect(_on_popup_menu_index_pressed)


# Open the FileDialog of the MainDock.
func open_file_dialogue() -> void:
	dock_property.main_dock.open_file_dialog(dock_property.extension_filters)
	# Connect the file_dialog to the property.
	dock_property.main_dock.file_dialog.file_selected.connect(_on_file_dialog_file_selected)
	dock_property.main_dock.file_dialog.canceled.connect(_on_file_dialog_canceled)


## Signals.
# Called when a gui_input is detected on the FileButton.
func _on_file_button_gui_input(event: InputEvent) -> void:
	check_gui_input(event)


# Called when a gui_input is detected on the FileButton.
func _on_extra_file_button_gui_input(event: InputEvent) -> void:
	check_gui_input(event)


# Called when a file is selected in the FileDialog.
func _on_file_dialog_file_selected(path: String) -> void:
	# Disconnect the signals of the FileDialog.
	dock_property.main_dock.file_dialog.file_selected.disconnect(_on_file_dialog_file_selected)
	dock_property.main_dock.file_dialog.canceled.disconnect(_on_file_dialog_canceled)
	# Set the value of the DockProperty.
	# The variable "path" is the path of the selected file.
	dock_property.value = path


# Called when the FileDialog is canceled.
func _on_file_dialog_canceled() -> void:
	# Disconnect the signals of the FileDialog.
	dock_property.main_dock.file_dialog.file_selected.disconnect(_on_file_dialog_file_selected)
	dock_property.main_dock.file_dialog.canceled.disconnect(_on_file_dialog_canceled)


# Called when an item from the PopupMenu is selected.
func _on_popup_menu_index_pressed(index: int) -> void:
	# Disconnect the signals of the PopupMenu.
	dock_property.main_dock.popup_menu.index_pressed.disconnect(_on_popup_menu_index_pressed)
	dock_property.main_dock.popup_menu.popup_hide.disconnect(_on_popup_menu_popup_hide)
	
	# Load a file.
	if index == 0:
		open_file_dialogue()
	# Clear the current value of the DockProperty.
	elif index == 1:
		dock_property.value = null


# Called when the PopupMenu is hidden.
func _on_popup_menu_popup_hide() -> void:
	# Disconnect the signals of the PopupMenu.
	await get_tree().create_timer(0.001).timeout # Prevent bugs.
	if dock_property.main_dock.popup_menu.index_pressed.is_connected(_on_popup_menu_index_pressed):
		dock_property.main_dock.popup_menu.index_pressed.disconnect(_on_popup_menu_index_pressed)
		dock_property.main_dock.popup_menu.popup_hide.disconnect(_on_popup_menu_popup_hide)


# Called when a file is dropped onto the FileButton.
func _on_file_button_drop_data_received(data: Variant) -> void:
	# Defines the value of the DockProperty as the path of the first selected file.
	dock_property.value = data.files[0]


# Called when the value of the DockProperty is changed.
func _on_dock_property_value_changed(value: Variant) -> void:
	# Change the FileButton to its empty state.
	if value == null:
		var file_button: Button = dock_property.get_node("FileButton")
		file_button.text = "<empty>"
		file_button.icon = null
	# Change the FileButton to match the value of the DockProperty.
	else:
		var file_button: Button = dock_property.get_node("FileButton")
		file_button.text = value.get_file()
		file_button.icon = dock_property.main_dock.get_icon("ResourcePreloader")

@tool
extends HBoxContainer

## Signals.
signal value_changed(value: Variant)
signal reload_button_pressed

## Enums.
enum PROPERTY_TYPE {FILE, ITEMLIST, COLOR_PICKER, CHECK_BOX}

## References.
@onready var property_name: Label = $PropertyName
@onready var property_types: Node = $PropertyTypes

## Exports.
@export var type: PROPERTY_TYPE = PROPERTY_TYPE.FILE:
	set(value):
		type = value
		if is_node_ready():
			change_type()
@export var main_dock: Control
@export var use_reset_button: bool = true
@export_group("File Type")
@export var extension_filters: PackedStringArray
@export_group("ItemList Type")
@export var item_list: PackedStringArray:
	set(new_value):
		item_list = new_value
		if has_node("ItemList"):
			get_node("PropertyTypes/ItemListType").add_items()
@export var item_list_icons: Array
@export var horizontal_expand_list: bool = false
@export var clip_text: bool = false
@export var shrink_end: bool = true

## Variables.
var current_type: Node
var value: Variant:
	set(new_value):
		value = new_value
		value_changed.emit(new_value)


func _ready() -> void:
	change_name()
	change_type()
	value_changed.connect(_on_value_changed)


# Change the name according to the name assigned to the DockProperty.
func change_name() -> void:
	var formatted_name: String
	# Add a space before each uppercase letter.
	for char_i in range(name.length()):
		var char: String = str(name)[char_i]
		if char == char.to_upper() and char_i > 0:
			formatted_name += " "
		formatted_name += char
	# Change the text of the PropertyName.
	property_name.text = formatted_name


# Prepare the DockProperty for a specific type.
func change_type() -> void:
	# Exit the current type.
	if current_type: current_type.exit()
	
	# Change the current type according to the DockProperty type.
	match type:
		PROPERTY_TYPE.FILE:
			current_type = property_types.get_node("FileType")
		PROPERTY_TYPE.ITEMLIST:
			current_type = property_types.get_node("ItemListType")
		PROPERTY_TYPE.COLOR_PICKER:
			current_type = property_types.get_node("ColorPickerType")
		PROPERTY_TYPE.CHECK_BOX:
			current_type = property_types.get_node("CheckBoxType")
	
	# Enter the new current type.
	if current_type: current_type.enter()


# Create a ReloadButton for the DockProperty.
func set_reload_button(enabled: bool) -> void:
	# Check if a ReloadButton already exists.
	if has_node("ReloadButton") and enabled: return
	
	# Create a new ReloadButton.
	if enabled:
		var reload_button: Button = Button.new()
		add_child(reload_button)
		move_child(reload_button, 2)
		# Set up the ReloadButton.
		reload_button.name = "ReloadButton"
		reload_button.icon = main_dock.get_icon("Reload")
		# Connect the signals of the ReloadButton.
		reload_button.pressed.connect(_on_reload_button_pressed)
	
	# Remove the current ReloadButton.
	else:
		if has_node("ReloadButton"):
			get_node("ReloadButton").call_deferred("free")


## Signals.
# Called when the DockProperty is renamed.
func _on_renamed() -> void:
	change_name()


# Called when the value of the DockProperty is changed.
func _on_value_changed(value: Variant) -> void:
	if not use_reset_button: return
	
	# Define the ReloadButton.
	if value: set_reload_button(true)
	else: set_reload_button(false)


# Called when the ReloadButton is pressed.
func _on_reload_button_pressed() -> void:
	reload_button_pressed.emit()
	value = null

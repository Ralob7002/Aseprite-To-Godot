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
@onready var property_timer: Timer = $PropertyTimer

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
@export_group("Property Information")
@export var property_title: String = ""
@export var property_description: String = ""
@export var popup_size: Vector2 = Vector2(100, 100)

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
		move_child(reload_button, 3)
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


func _on_mouse_entered() -> void:
	return # Dock property preview disabled.
	property_timer.start(0.8)


func _on_mouse_exited() -> void:
	return # Dock property preview disabled.
	if not main_dock: return
	if not main_dock.property_popup: return
	
	property_timer.stop()
	
	await get_tree().create_timer(0.5).timeout
	
	var popup: PopupPanel = main_dock.property_popup
	var mouse_position: Vector2 = get_global_mouse_position() + Vector2(get_window().position)
	var popup_rect: Rect2 = Rect2(
		popup.position,
		popup.position + popup.size
	)
	
	if not popup_rect.has_point(mouse_position):
		main_dock.property_popup.visible = false


func _on_property_timer_timeout() -> void:
	if main_dock:
		main_dock.open_property_popup(property_title, property_description, popup_size)

@tool
extends Node

## References.
@onready var dock_property: HBoxContainer = $"../.."

# Prepares the DockProperty to function as "CheckBoxType".
func enter() -> void:
	# Connects the DockProperty signals.
	dock_property.value_changed.connect(_on_dock_property_value_change)
	
	# Creates the CheckBox.
	var check_box: CheckBox = CheckBox.new()
	dock_property.add_child(check_box)
	
	# Configures the CheckBox.
	check_box.name = "CheckBox"
	check_box.size_flags_horizontal = 10
	check_box.focus_mode = Control.FOCUS_NONE
	
	# Connects the CheckBox signals.
	check_box.toggled.connect(_on_check_box_toggled)


# Clears the DockProperty of "CheckBoxType".
func exit() -> void:
	var check_box: CheckBox = dock_property.get_node("CheckBox")
	# Disconnects the CheckBox signals.
	check_box.toggled.connect(_on_check_box_toggled)
	# Removes the CheckBox.
	check_box.free()


## Signals.
func _on_dock_property_value_change(value: Variant) -> void:
	if value == null:
		var check_box: CheckBox = dock_property.get_node("CheckBox")
		check_box.set_pressed_no_signal(false)


func _on_check_box_toggled(toggled_on: bool) -> void:
	dock_property.value = toggled_on

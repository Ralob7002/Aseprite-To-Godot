@tool
extends Node

## References.
@onready var dock_property: HBoxContainer = $"../.."


# Prepares the DockProperty to function as "ColorPickerType".
func enter() -> void:
	# Connects the DockProperty signals.
	dock_property.value_changed.connect(_on_dock_property_value_change)
	
	# Creates the ColorButton.
	var color_button: ColorPickerButton = ColorPickerButton.new()
	dock_property.add_child(color_button)
	
	# Configures the ColorButton.
	color_button.name = "ColorButton"
	color_button.custom_minimum_size.x = 50
	color_button.size_flags_horizontal = 10
	color_button.theme = load("res://addons/AsepriteToGodot/resources/color_picker_theme.tres")
	color_button.focus_mode = Control.FOCUS_NONE
	var root = EditorInterface.get_base_control()
	color_button.color = root.get_theme_color("base_color", "Editor")
	
	# Connects the ColorButton signals.
	color_button.color_changed.connect(_on_color_button_color_changed)


# Clears the DockProperty of "ColorPickerType".
func exit() -> void:
	var color_button: ColorPickerButton = dock_property.get_node("ColorButton")
	# Connects the ColorButton signals.
	color_button.color_changed.disconnect(_on_color_button_color_changed)
	# Removes the ColorButton.
	color_button.free()


## Signals.
func _on_dock_property_value_change(value: Variant) -> void:
	if value == null:
		var preview_background: Panel = dock_property.main_dock.preview_background
		preview_background.remove_theme_stylebox_override("panel")
		var color_button: ColorPickerButton = dock_property.get_node("ColorButton")
		var root = EditorInterface.get_base_control()
		color_button.color = root.get_theme_color("base_color", "Editor")


func _on_color_button_color_changed(color: Color) -> void:
	var root = EditorInterface.get_base_control()
	var preview_background: Panel = dock_property.main_dock.preview_background
	if not color == root.get_theme_color("base_color", "Editor"):
		dock_property.value = color
		var style_box: StyleBoxFlat = StyleBoxFlat.new()
		style_box.bg_color = color
		style_box.set_corner_radius_all(3)
		preview_background.add_theme_stylebox_override("panel", style_box)
	else:
		preview_background.remove_theme_stylebox_override("panel")

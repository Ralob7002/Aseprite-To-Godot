@tool
extends EditorPlugin

## Variables.
var main_dock: Control


func _enter_tree() -> void:
	# Add the "Aseprite Importer" dock to the editor.
	main_dock = preload("res://addons/AsepriteToGodot/scenes/main_dock.tscn").instantiate()
	add_control_to_bottom_panel(main_dock, "Aseprite Importer")


func _exit_tree() -> void:
	# Remove the "Aseprite Importer" dock from the editor.
	remove_control_from_bottom_panel(main_dock)
	main_dock.free()

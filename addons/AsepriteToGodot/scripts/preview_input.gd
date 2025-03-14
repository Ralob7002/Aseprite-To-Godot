@tool
extends MarginContainer

## References.
@onready var main_dock: Control = $"../../../../.."
@onready var dock_preview: Node = %DockPreview
@onready var lock_centralized_camera: Button = $PreviewActionsContainer/LockCentralizedCamera


## Variables.
var lock_centralized_camera_pressed: bool = true


func _gui_input(event: InputEvent) -> void:
	if not main_dock.get_property("AsepriteExportJson"): return
	elif not main_dock.get_property("AnimationSpriteSheet"): return
	elif lock_centralized_camera_pressed: return
	
	var preview_camera: Camera2D = dock_preview.preview_camera
	# Camera Zoom.
	if event is InputEventMouseButton:
		var min_zoom: Vector2 = Vector2(0.1, 0.1)
		var max_zoom: Vector2 = preview_camera.zoom + Vector2(1, 1)
		if event.button_index == 4: # Wheel Up.
			preview_camera.zoom = clamp(preview_camera.zoom + Vector2(0.5, 0.5), min_zoom, max_zoom)
		elif event.button_index == 5: # Wheel Down.
			preview_camera.zoom = clamp(preview_camera.zoom - Vector2(0.5, 0.5), min_zoom, max_zoom)
		
		if preview_camera.zoom.x < 0.1:
			preview_camera.zoom = Vector2(1, 1)
	
	# Camera Movement.
	elif event is InputEventMouseMotion and event:
		if event.pressure > 0:
			preview_camera.position += event.relative * -0.1


## Signals.
func _on_center_view_button_pressed() -> void:
	dock_preview.update_preview_camera_zoom(true)


func _on_dependent_property_value_changed(value: Variant) -> void:
	if not value:
		mouse_default_cursor_shape = Control.CURSOR_ARROW
	
	if not main_dock.get_property("AsepriteExportJson"): return
	elif not main_dock.get_property("AnimationSpriteSheet"): return
	
	if not lock_centralized_camera_pressed:
		mouse_default_cursor_shape = Control.CURSOR_DRAG


func _on_lock_centralized_camera_pressed() -> void:
	lock_centralized_camera_pressed = !lock_centralized_camera_pressed
	dock_preview.auto_update_camera = lock_centralized_camera_pressed
	
	if lock_centralized_camera_pressed:
		lock_centralized_camera.icon = main_dock.get_icon("Lock")
	else:
		lock_centralized_camera.icon = main_dock.get_icon("Unlock")
	
	if not main_dock.get_property("AsepriteExportJson"): return
	elif not main_dock.get_property("AnimationSpriteSheet"): return
	
	if lock_centralized_camera_pressed:
		dock_preview.auto_update_camera = true
		dock_preview.update_preview_camera_zoom()
		mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		mouse_default_cursor_shape = Control.CURSOR_DRAG
		dock_preview.auto_update_camera = false

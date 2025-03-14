@tool
extends Control

## References.
@onready var file_dialog: FileDialog = $FileDialog
@onready var popup_menu: PopupMenu = $PopupMenu
@onready var properties: VBoxContainer = %Properties
@onready var texture_importer: Node = $TextureImporter
@onready var dependence_warning: AcceptDialog = $DependenceWarning
@onready var animation_importer: Node = $AnimationImporter
@onready var dock_preview: Node = $DockPreview
@onready var preview_background: Panel = %PreviewBackground
@onready var advanced_properties: VBoxContainer = %AdvancedProperties

## Variables.
var json_file: JSON
var last_json_md5: String

func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	check_json_modification()


# Open the FileDialog.
func open_file_dialog(filters: PackedStringArray = []) -> void:
	file_dialog.filters = filters
	file_dialog.visible = true


# Open the PopupMenu.
func open_popup_menu(clear_disabled: bool) -> void:
	popup_menu.position = get_global_mouse_position()
	popup_menu.set_item_disabled(1, clear_disabled)
	popup_menu.visible = true


# Open the DependenceWarning.
func open_dependence_warning(dialog: String) -> void:
	if file_dialog.visible: file_dialog.visible = false
	dependence_warning.dialog_text = dialog
	dependence_warning.visible = true


# Returns the value of a given property.
func get_property(property: String) -> Variant:
	if not properties or not advanced_properties: return null
	
	if properties.has_node(property):
		return properties.get_node(property).value
	elif advanced_properties.has_node(property):
		return advanced_properties.get_node(property).value
	
	return false


# Checks if the AsepriteExportJson was exported with the "Split Layers" option.
func is_splited_layers() -> bool:
	var json_path: String = get_property("AsepriteExportJson")
	var data: Dictionary = load(json_path).data
	var layer_name: String = data.meta.layers[0].name
	var target_frame_key: String = json_path.get_file().get_basename()
	target_frame_key += " (" + layer_name + ") 0"
	
	for key in data.frames.keys():
		if key.get_basename() == target_frame_key:
			return true
	return false


# Checks if the AsepriteExportJson was exported with the "Split Tags" option.
func is_splited_tags() -> bool:
	var json_path: String = get_property("AsepriteExportJson")
	if not FileAccess.file_exists(json_path): return false
	var data: Dictionary = load(json_path).data
	var tag_name: String = data.meta.frameTags[0].name
	var layer_name: String = data.meta.layers[0].name
	var target_frame_key: String = json_path.get_file().get_basename()
	target_frame_key += " #" + tag_name + " 0"
	var extra_target_frame_key: String = json_path.get_file().get_basename()
	extra_target_frame_key += " (" + layer_name + ") #" + tag_name + " 0"
	
	for key in data.frames.keys():
		if key.get_basename() == target_frame_key or key.get_basename() == extra_target_frame_key:
			return true
	return false


# Checks if the AsepriteExportJson file has been modified.
func check_json_modification() -> void:
	if not json_file or not get_property("AsepriteExportJson"): return
	
	if is_splited_tags():
		json_file = null
		open_dependence_warning('Aseprite Export Json with "Split Tags" option not supported!')
		await get_tree().create_timer(0.001).timeout # Previne Bugs.
		properties.get_node("AsepriteExportJson").value = null
	
	#if not FileAccess.file_exists(get_property("AsepriteExportJson")): return
	if not get_property("AsepriteExportJson"): return
	var current_json_md5 = FileAccess.get_md5(get_property("AsepriteExportJson"))
	if not current_json_md5 == last_json_md5:
		await get_tree().create_timer(1).timeout # Previne Bugs.
		properties.get_node("AsepriteExportJson").value = get_property("AsepriteExportJson")


# Returns a specific icon from the "icons" folder.
func get_icon(icon: String) -> CompressedTexture2D:
	return load("res://addons/AsepriteToGodot/icons/" + icon + ".svg")


## Signals.
# Called when the ImportButton is pressed.
func _on_import_button_pressed() -> void:
	# Dependencies.
	if not get_property("AsepriteExportJson"):
		open_dependence_warning('Property "Aseprite Export Json" not defined.')
		return
	elif not get_property("AnimationSpriteSheet"):
		open_dependence_warning('Property "Animation Sprite Sheet" not defined.')
		return
	
	if not FileAccess.file_exists(get_property("AsepriteExportJson")):
		return
	
	var texture_node_type = get_property("TextureNodeType")
	var target_parent: Node = get_tree().edited_scene_root
	if texture_node_type == 1: # AnimatedSprite2D.
		animation_importer.import_animation_nodes(target_parent)
	else: # Sprite2D.
		var texture_nodes: Array[Sprite2D] = texture_importer.import_texture_node(target_parent)
		animation_importer.import_animation_nodes(target_parent, texture_nodes)


# Called when the value of AsepriteExportJson is changed.
func _on_aseprite_export_json_value_changed(value: Variant) -> void:
	if value == null:
		json_file = null
	else:
		if not FileAccess.file_exists(value):
			json_file = null
			properties.get_node("AsepriteExportJson").value = null
			open_dependence_warning("File path of Aseprite Export Json has been changed or the file has been deleted!")
			return
		
		last_json_md5 = FileAccess.get_md5(value)
		json_file = load(value)
		if is_splited_tags():
			json_file = null
			open_dependence_warning('Aseprite Export Json with "Split Tags" option not supported!')
			await get_tree().create_timer(0.001).timeout # Previne Bugs.
			properties.get_node("AsepriteExportJson").value = null


# Called when the visibility of the main_dock is changed.
func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		set_process(true)
		if is_node_ready():
			dock_preview.set_process(true)
	else:
		set_process(false)
		if is_node_ready():
			dock_preview.set_process(false)

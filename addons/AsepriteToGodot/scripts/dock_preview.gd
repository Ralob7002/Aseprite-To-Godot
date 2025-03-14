@tool
extends Node

## References.
@onready var main_dock: Control = $".."
@onready var properties: VBoxContainer = %Properties
@onready var texture_importer: Node = $"../TextureImporter"
@onready var animation_importer: Node = $"../AnimationImporter"
@onready var preview_nodes: Node2D = %PreviewNodes
@onready var animation_preview: SubViewport = %AnimationPreview
@onready var preview_camera: Camera2D = %PreviewCamera
@onready var current_animation: HBoxContainer = %Animation
@onready var animations_actions: HBoxContainer = %AnimationsActions
@onready var up_container: HBoxContainer = %UpContainer
@onready var animation_progress: ProgressBar = %AnimationProgress

## Variables. Takes for the size.
var animation_node_is_playing: bool = false
var auto_update_camera: bool = true


func _ready() -> void:
	# Define the texture filter.
	var texture_filter: int = ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")
	animation_preview.canvas_item_default_texture_filter = texture_filter
	
	# Connect the ProjectSettings signals.
	ProjectSettings.settings_changed.connect(_on_project_settings_settings_changed)
	# Connect the signals of the current_animation property.
	current_animation.value_changed.connect(_on_current_animation_property_changed)
	# Connect the signals of the properties.
	for property in properties.get_children():
		property.value_changed.connect(_on_property_value_changed)
	
	# Connect the signals of the animation actions.
	animations_actions.get_node("StopAnimation").pressed.connect(_on_stop_animation_pressed)
	animations_actions.get_node("PlayAnimation").pressed.connect(_on_play_animation_pressed)
	animations_actions.get_node("PlayAnimationBackwards").pressed.connect(_on_play_animation_backwards_pressed)
	animations_actions.get_node("PlayAnimationBackwardsEnd").pressed.connect(_on_play_animation_backwards_end_pressed)
	animations_actions.get_node("PlayAnimationStart").pressed.connect(_on_play_animation_start_pressed)


func _process(delta: float) -> void:
	if not main_dock.get_property("DisableAnimationProgressBar"):
		update_animation_progress()
	else:
		animation_progress.value = 0.0


# Update the zoom of the PreviewCamera.
func update_preview_camera_zoom(ignore_auto_update: bool = false) -> void:
	if not animation_preview: return
	if not auto_update_camera and not ignore_auto_update: return
	
	# Dependencies.
	var texture_node_type: Variant = main_dock.get_property("TextureNodeType")
	if texture_node_type == 1: # AnimatedSprite2D.
		if not preview_nodes.get_node("AnimationNodes").get_child_count(): return
	else: # Sprite2D.
		if preview_nodes.get_node("Sprites").get_child_count() == 0: return
	
	# Set PreviewCamera position.
	preview_camera.position = Vector2.ZERO
	
	# Define the size of the sprite for the texture node.
	var sprite_size: Vector2
	if texture_node_type == 1: # AnimatedSprite2D.
		var animations: PackedStringArray = preview_nodes.get_node("AnimationNodes").get_child(0).sprite_frames.get_animation_names()
		var texture: Texture2D = preview_nodes.get_node("AnimationNodes").get_child(0).sprite_frames.get_frame_texture(animations[0], 0)
		sprite_size = texture.get_size()
	else: # Sprite2D.
		sprite_size = preview_nodes.get_node("Sprites").get_child(0).get_rect().size
	
	var viewport_size: Vector2 = animation_preview.size
	# Zoom of the PreviewCamera.
	var zoom_x: float = viewport_size.x / sprite_size.x
	var zoom_y: float = viewport_size.y / sprite_size.y
	var target_zoom: float = min(zoom_x, zoom_y)
	preview_camera.zoom = Vector2.ONE * (target_zoom * 0.9)


# Configures the preview for the AnimationPlayer.
func setup_animation_player_preview() -> bool:
	# Import the texture_nodes.
	var sprites_parent: Node = preview_nodes.get_node("Sprites")
	var texture_nodes: Array[Sprite2D] = texture_importer.import_texture_node(sprites_parent)
	# Import the AnimationPlayer.
	var animation_node_parent: Node = preview_nodes.get_node("AnimationNodes")
	var imported: bool = animation_importer.import_animation_nodes(animation_node_parent, texture_nodes)
	if not imported: return false
	
	# Clear the items of the current_animation property.
	current_animation.item_list_icons.clear()
	current_animation.item_list.clear()
	
	# Add the items to the current_animation property.
	var animation_player: AnimationPlayer = preview_nodes.get_node("AnimationNodes/AnimationPlayer")
	for i in range(animation_player.get_animation_list().size()):
		current_animation.item_list_icons.append(main_dock.get_icon("Animation"))
	current_animation.item_list = animation_player.get_animation_list()
	return true


# Play the animation of the AnimationPlayer.
func play_animation_player(backwards: bool = false) -> void:
	var animation_player: AnimationPlayer = preview_nodes.get_node("AnimationNodes/AnimationPlayer")
	var animations: PackedStringArray = animation_player.get_animation_list()
	
	if current_animation.value == null or current_animation.value == 0 or current_animation.value == -1:
		if backwards: animation_player.play_backwards(animations[0])
		else: animation_player.play(animations[0])
	else:
		if backwards: animation_player.play_backwards(animations[current_animation.value])
		else: animation_player.play(animations[current_animation.value])


# Configure the preview of the AnimatedSprite2D.
func setup_animated_sprite_preview() -> bool:
	# Import the AnimatedSprite2D.
	var target_parent: Node = preview_nodes.get_node("AnimationNodes")
	var imported: bool = animation_importer.import_animation_nodes(target_parent)
	if not imported: return false
	
	# Clear the items of the current_animation property.
	current_animation.item_list_icons.clear()
	current_animation.item_list.clear()
	
	# Add the items to the current_animation property.
	var animated_sprite: AnimatedSprite2D = preview_nodes.get_node("AnimationNodes").get_child(0)
	for i in range(animated_sprite.sprite_frames.get_animation_names().size()):
		current_animation.item_list_icons.append(main_dock.get_icon("Animation"))
	current_animation.item_list = animated_sprite.sprite_frames.get_animation_names()
	return true


# Play the animation of the AnimatedSprite2D.
func play_animated_sprite() -> void:
	for animated_sprite in preview_nodes.get_node("AnimationNodes").get_children():
		var animations: PackedStringArray = animated_sprite.sprite_frames.get_animation_names()
		if current_animation.value == null or current_animation.value == 0 or current_animation.value == -1:
			animated_sprite.play(animations[0])
		else:
			animated_sprite.play(animations[current_animation.value])


# Play the animation of the animation_node.
func play_animation_node(backwards: bool = false) -> void:
	if preview_nodes.get_node("AnimationNodes").get_child_count() == 0:
		return
	
	# AnimationPlayer.
	if current_animation and preview_nodes.get_node("AnimationNodes").get_child(0) is AnimationPlayer:
		play_animation_player(backwards)
	# AnimatedSprite2D.
	elif current_animation and preview_nodes.get_node("AnimationNodes").get_child(0) is AnimatedSprite2D:
		play_animated_sprite()


# Stop the animation of the animation_node.
func stop_animation_node() -> void:
	if not preview_nodes.get_node("AnimationNodes").get_child_count():
		return
	
	# AnimationPlayer.
	if current_animation and preview_nodes.get_node("AnimationNodes").get_child(0) is AnimationPlayer:
		var animation_player: AnimationPlayer = preview_nodes.get_node("AnimationNodes/AnimationPlayer")
		if animation_player.is_playing(): animation_player.pause()
		else: 
			animation_player.stop()
			animation_progress.value = 0
	# AnimatedSprite2D.
	elif current_animation and preview_nodes.get_node("AnimationNodes").get_child(0) is AnimatedSprite2D:
		for animated_sprite in preview_nodes.get_node("AnimationNodes").get_children():
			if animated_sprite.is_playing(): animated_sprite.pause()
			else: 
				animated_sprite.stop()
				animation_progress.value = 0


# Delete the texture_nodes.
func free_texture_nodes() -> void:
	for sprite in preview_nodes.get_node("Sprites").get_children():
		sprite.free()


# Delete the animation_nodes.
func free_animation_nodes() -> void:
	for animation_node in preview_nodes.get_node("AnimationNodes").get_children():
		animation_node.free()


# Enables or disables the animations_actions.
func change_up_container(enabled: bool) -> void:
	var alpha: float = 0.5
	if enabled: alpha = 1.0
	up_container.modulate.a = alpha
	animation_progress.visible = enabled
	if not enabled: animation_progress.value = 0


# Updates the AnimationProgress.
func update_animation_progress() -> void:
	if preview_nodes.get_node("AnimationNodes").get_child_count():
		var animation_node: Variant = preview_nodes.get_node("AnimationNodes").get_child(0)
		if animation_node is AnimationPlayer:
			if not animation_node.current_animation: return
			animation_progress.max_value = animation_node.current_animation_length
			animation_progress.value = animation_node.current_animation_position
		
		elif animation_node is AnimatedSprite2D:
			if not animation_node.animation: return
			var animation: String = animation_node.animation
			animation_progress.max_value = animation_node.sprite_frames.get_frame_count(animation) - 1
			animation_progress.value = animation_node.frame - (1 - animation_node.frame_progress)


## Signals.
# Called when a property value of the MainDock is changed.
func _on_property_value_changed(value: Variant) -> void:
	# Checks if the AsepriteExportJson was exported with "Split Tags".
	if main_dock.get_property("AsepriteExportJson"):
		if main_dock.is_splited_tags(): return
	
	# Deletes the texture_nodes and animation_nodes.
	free_texture_nodes()
	free_animation_nodes()
	
	# Dependencies.
	if not main_dock.get_property("AsepriteExportJson"):
		current_animation.value = 0
		current_animation.item_list_icons = []
		current_animation.item_list = []
		change_up_container(false)
		auto_update_camera = true
		return
	
	if not main_dock.get_property("AnimationSpriteSheet"):
		current_animation.value = 0
		current_animation.item_list_icons = []
		current_animation.item_list = []
		change_up_container(false)
		auto_update_camera = true
		return
	
	# Activates the top container.
	change_up_container(true)
	
	var texture_node_type = main_dock.get_property("TextureNodeType")
	var setuped: bool
	if texture_node_type == 1: # AnimatedSprite2D.
		setuped = setup_animated_sprite_preview()
	else: # Sprite2D.
		setuped = setup_animation_player_preview()
	
	if not setuped: 
		free_texture_nodes()
		main_dock.open_dependence_warning("The name of the JSON file from Aseprite Export Json and the name of the Aseprite file are not the same!")
		await get_tree().create_timer(0.001).timeout # Prevent bugs.
		main_dock.properties.get_node("AsepriteExportJson").value = null
		main_dock.json_file = null
		return
	
	if animation_node_is_playing: play_animation_node()
	update_preview_camera_zoom()


# Called when the size of the AnimationPreview is changed.
func _on_animation_preview_size_changed() -> void:
	update_preview_camera_zoom()


# Called when any project setting is changed.
func _on_project_settings_settings_changed() -> void:
	var texture_filter: int = ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter")
	animation_preview.canvas_item_default_texture_filter = texture_filter


# Called when the value of the current_animation property is changed.
func _on_current_animation_property_changed(value: Variant) -> void:
	play_animation_node()


# Called when the "Stop" animation action is pressed.
func _on_stop_animation_pressed() -> void:
	stop_animation_node()


# Called when the "Play" animation action is pressed.
func _on_play_animation_pressed() -> void:
	play_animation_node()


# Called when the "Play Backwards" animation action is pressed.
func _on_play_animation_backwards_pressed() -> void:
	play_animation_node(true)


# Called when the "Play Backwards End" animation action is pressed.
func _on_play_animation_backwards_end_pressed() -> void:
	stop_animation_node()
	play_animation_node(true)


# Called when the "Play Start" animation action is pressed.
func _on_play_animation_start_pressed() -> void:
	stop_animation_node()
	play_animation_node()

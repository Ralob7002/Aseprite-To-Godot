@tool
extends Node

## References.
@onready var main_dock: Control = $".."

# Imports the animation nodes.
func import_animation_nodes(target_parent: Node, text_nodes: Array[Sprite2D] = []) -> bool:
	var texture_node_type: Variant = main_dock.get_property("TextureNodeType")
	var animation_nodes: Array[Variant]
	
	if texture_node_type == null or texture_node_type == 0: # Sprite2D.
		animation_nodes = create_animation_player(target_parent, text_nodes)
	elif texture_node_type == 1: # AnimatedSprite2D.
		animation_nodes = create_animated_sprite(target_parent)
	
	if animation_nodes == [null]: return false
	
	# Adds the animation_nodes to the target_parent. 
	var data: Dictionary = main_dock.json_file.data
	var index: int = 0
	for node in animation_nodes:
		target_parent.add_child(node)
		node.owner = target_parent
		
		# Plays the first animation of the node to initialize it.
		if node is AnimationPlayer:
			node.play(node.get_animation_list()[0])
		elif node is AnimatedSprite2D:
			node.play(node.sprite_frames.get_animation_names()[0])
		node.stop() # Stops the animation so it doesn't keep playing.
		
		# Sets the node's name.
		if texture_node_type == null or texture_node_type == 0: # Sprite2D.
			node.name = "AnimationPlayer"
		elif texture_node_type == 1: # AnimatedSprite2D.
			if main_dock.is_splited_layers():
				var layer_name: String = data.meta.layers[index].name
				node.name = "AnimatedSprite2D (" + layer_name + ")"
			else:
				node.name = "AnimatedSprite2D"
		index += 1 # Update the index.
	return true


# Creates the AnimationPlayer.
func create_animation_player(target_parent: Node, text_nodes: Array[Sprite2D]) -> Array[Variant]:
	var animation_player: AnimationPlayer = AnimationPlayer.new()
	var data: Dictionary = main_dock.json_file.data
	var animation_library: AnimationLibrary = AnimationLibrary.new()
	
	# Defines the number of animations based on the number of tags.
	var animation_ammount: int = 1
	if data.meta.frameTags.size():
		animation_ammount = data.meta.frameTags.size()
	
	# Add the animations.
	for animation_i in range(animation_ammount):
		# Creates a new animation.
		var animation: Animation = Animation.new()
		
		# Defines the frame_tag if it exists.
		var frame_tag: Dictionary
		if data.meta.frameTags.size():
			frame_tag = data.meta.frameTags[animation_i]
		
		# Defines the number of tracks for the animation.
		var tracks_ammount: int = 1
		if main_dock.is_splited_layers():
			tracks_ammount = data.meta.layers.size()
		
		# Defines the loop mode of the animation.
		match main_dock.get_property("AnimationLoopMode"):
			null: animation.loop_mode = Animation.LOOP_NONE
			0: animation.loop_mode = Animation.LOOP_NONE
			1: animation.loop_mode = Animation.LOOP_LINEAR
			2: animation.loop_mode = Animation.LOOP_PINGPONG
		
		# Adds the tracks to the animation.
		for track_i in range(tracks_ammount):
			animation.add_track(Animation.TYPE_VALUE)
			animation.value_track_set_update_mode(track_i, Animation.UPDATE_DISCRETE)
			
			# Defines the track's path.
			var path: String = target_parent.get_path_to(text_nodes[track_i])
			match main_dock.get_property("TextureRegionMode"):
				null: path += ":region_rect"
				0: path += ":region_rect"
				1: path += ":texture:region" 
			animation.track_set_path(track_i, path)
			
			# Adds the frame indices.
			var frames_index: Array[int]
			if frame_tag:
				for ind in range(frame_tag.from, frame_tag.to + 1):
					frames_index.append(ind)
			else:
				for ind in range(data.frames.keys().size()):
					frames_index.append(ind)
		
			# Defines the keyframes of the track.
			var time: float = 0.0
			var index: int = 0
			for frame_i in frames_index:
				var layer_name: String = data.meta.layers[track_i].name
				var frame: Variant = get_frame_key(frame_i, layer_name)
				if frame == null: return [null]
				var size: Dictionary = frame.frame
				var region_rect: Rect2 = Rect2(size.x, size.y, size.w, size.h)
				# Adds the key and its value.
				animation.track_insert_key(track_i, time, index)
				animation.track_set_key_value(track_i, index, region_rect)
				# Updates the time and the index.
				time += frame.duration / 1000
				index += 1
			# Sets the duration of the animation.
			animation.length = time
		# Sets the name of the animation.
		if frame_tag:
			animation_library.add_animation(frame_tag.name, animation)
		else:
			animation_library.add_animation("Animation", animation)
	# Adds the animation library to the animation player.
	animation_player.add_animation_library("", animation_library)
	return [animation_player]


# Creates the AnimatedSprite2D.
func create_animated_sprite(target_parent: Node) -> Array[Variant]:
	var animation_nodes: Array[AnimatedSprite2D] = []
	var data: Dictionary = main_dock.json_file.data
	
	# Defines the number of animations based on the number of tags.
	var animation_ammount: int = 1
	if data.meta.frameTags.size() > 0:
		animation_ammount = data.meta.frameTags.size()
	
	# Defines the number of layers.
	var layer_ammount: int = 1
	if main_dock.is_splited_layers():
		layer_ammount = data.meta.layers.size()
	
	# Creates the layers.
	for layers_i in range(layer_ammount):
		# Create the AnimatedSprite2D.
		var animated_sprite: AnimatedSprite2D = AnimatedSprite2D.new()
		animated_sprite.sprite_frames = SpriteFrames.new()
		var sprite_frames: SpriteFrames = animated_sprite.sprite_frames
		sprite_frames.remove_animation("default")
		
		# Add the animations.
		var sprite_sheet: CompressedTexture2D = load(main_dock.get_property("AnimationSpriteSheet"))
		for animation_i in range(animation_ammount):
			# Define the frame_tag if it exists.
			var frame_tag: Dictionary
			if data.meta.frameTags.size() > 0:
				frame_tag = data.meta.frameTags[animation_i]
			
			# Create the animation.
			var animation_name: String = "Animation"
			if frame_tag:
				animation_name = frame_tag.name
			sprite_frames.add_animation(animation_name)
			sprite_frames.set_animation_speed(animation_name, 1.0)
			
			# Define the animation loop.
			match main_dock.get_property("AnimationLoopMode"):
				null: sprite_frames.set_animation_loop(animation_name, false)
				0: sprite_frames.set_animation_loop(animation_name, false)
				1: sprite_frames.set_animation_loop(animation_name, true)
				2: sprite_frames.set_animation_loop(animation_name, true)
			
			# Add the frame indexes.
			var frames_index: Array[int]
			if frame_tag:
				for ind in range(frame_tag.from, frame_tag.to + 1):
					frames_index.append(ind)
			else:
				for ind in range(data.frames.keys().size()):
					frames_index.append(ind)
			
			# Add the frames to the animation.
			for frame_i in frames_index:
				var frame: Variant = get_frame_key(frame_i, data.meta.layers[layers_i].name)
				if frame == null: return [null]
				var size: Dictionary = frame.frame
				var region_rect: Rect2 = Rect2(size.x, size.y, size.w, size.h)
				
				var frame_texture: AtlasTexture = AtlasTexture.new()
				frame_texture.atlas = sprite_sheet
				frame_texture.region = region_rect
				
				var time: float = frame.duration / 1000
				sprite_frames.add_frame(animation_name, frame_texture, time)
			
		animated_sprite.animation = animated_sprite.sprite_frames.get_animation_names()[0]
		animation_nodes.append(animated_sprite)
	return animation_nodes


# Return a specific frame_key from AsepriteExportJson.
func get_frame_key(frame_index: int, layer: Variant = "") -> Variant:
	var json_path: String = main_dock.get_property("AsepriteExportJson")
	var data = main_dock.json_file.data
	
	var frame_key: String = json_path.get_file().get_basename()
	frame_key += " " + str(frame_index)
	
	var frame_key_layer: String = json_path.get_file().get_basename()
	frame_key_layer += " (" + layer + ") " + str(frame_index)
	
	for key in data.frames.keys():
		if key.get_basename() == frame_key or key.get_basename() == frame_key_layer:
			return data.frames[key]
	
	# If this part is executed, the name of the Aseprite file is different from the JSON file.
	return null

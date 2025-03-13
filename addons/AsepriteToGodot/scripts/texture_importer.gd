@tool
extends Node

## References.
@onready var aseprite_importer_dock: Control = $".."


# Import the texture_nodes.
func import_texture_node(target_parent: Node) -> Array[Sprite2D]:
	var split_layers = aseprite_importer_dock.is_splited_layers()
	var data: Dictionary = aseprite_importer_dock.json_file.data
	var texture_nodes: Array[Sprite2D] = create_texture_node(data, split_layers)
	
	var index: int = 0
	for node in texture_nodes:
		# Add the node to the target_parent.
		target_parent.add_child(node)
		node.owner = target_parent
		# Set the name of the node.
		if not split_layers:
			node.name = "Sprite2D"
		else:
			node.name = "Sprite2D (" + data.meta.layers[index].name + ")"
		# Update the index.
		index += 1
	return texture_nodes


# Create the texture node according to the TextureNodeType.
func create_texture_node(data: Dictionary, split_layers = false) -> Array[Sprite2D]:
	var texture_nodes: Array[Sprite2D]
	var texture_type = aseprite_importer_dock.get_property("TextureNodeType")
	
	# Define the amount of textures.
	var textures_ammount: int = 1
	if split_layers:
		textures_ammount = data.meta.layers.size()
	
	# Create the Sprite2D's.
	for i in range(textures_ammount):
		texture_nodes.append(create_sprite_2d(data))
	
	return texture_nodes


# Create a Sprite2D.
func create_sprite_2d(data: Dictionary) -> Sprite2D:
	var sprite = Sprite2D.new()
	var texture = load(aseprite_importer_dock.get_property("AnimationSpriteSheet"))
	var region_mode = aseprite_importer_dock.get_property("TextureRegionMode")
	
	# Create the texture region.
	var key: String = data.frames.keys()[0]
	var frame_rect: Dictionary = data.frames[key].spriteSourceSize
	var region_rect: Rect2 = Rect2(frame_rect.x, frame_rect.y, frame_rect.w, frame_rect.h)
	
	# Define the region of the Sprite2D.
	if region_mode == null or region_mode == 0: # Sprite2D.
		sprite.texture = texture
		sprite.region_enabled = true
		sprite.region_rect = region_rect
	# Defines the region of the AtlasTexture.
	elif region_mode == 1: # AtlasTexture Region.
		sprite.texture = AtlasTexture.new()
		sprite.texture.atlas = texture
		sprite.texture.region = region_rect
	return sprite

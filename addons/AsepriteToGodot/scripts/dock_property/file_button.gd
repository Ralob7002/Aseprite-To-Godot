@tool
extends Button

## Signals.
signal drop_data_received(data: Variant)


# Check if a given file can be dragged onto the FileButton.
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data.type == "files": return false
	
	# Remove the "*." from the extension_filters.
	var cleaned_filters: Array[String]
	for ext: String in get_parent().extension_filters:
		cleaned_filters.append(ext.substr(2))
	
	# Check if the file extension is accepted.
	if cleaned_filters.has(data.files[0].get_extension()): return true
	
	return false


# File drop date.
func _drop_data(at_position: Vector2, data: Variant) -> void:
	drop_data_received.emit(data)

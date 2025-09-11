# --- CUSTOM RESOURCE FOR AUDIO LIBRARY ---
# This custom resource allows you to define a key (name) and an audio stream
# together in the Inspector, which is more user-friendly than a dictionary.
class_name AudioLibraryEntry
extends Resource

@export var key: StringName = ""
@export var stream: AudioStream

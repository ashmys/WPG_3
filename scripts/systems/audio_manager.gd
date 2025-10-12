# AudioManager.gd (Updated for Godot 4.x)
# This script should be set up as an Autoload (Singleton) in your project.
# Project -> Project Settings -> Autoload -> Add the path to this script.
extends Node
class_name Audio_Manager

# --- EXPORT VARIABLES ---
# In the Inspector, you can now add elements to these arrays.
# For each element, create a new "AudioLibraryEntry" resource,
# give it a unique key (e.g., "main_theme"), and assign the audio stream.
@export var music_library: Array[AudioLibraryEntry] = []
@export var sfx_library: Array[AudioLibraryEntry] = []

# The maximum number of sound effects that can play at once.
@export var max_sfx_players: int = 10

# The names of the audio buses to use. Make sure these exist in your Audio Bus Layout.
@export var music_bus_name: StringName = "Music"
@export var sfx_bus_name: StringName = "SFX"


# --- PRIVATE VARIABLES ---
# We will populate these dictionaries from the exported libraries for fast access.
var _music_streams: Dictionary = {}
var _sfx_streams: Dictionary = {}

var music_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []


# Called when the node enters the scene tree for the first time.
func _ready():
	# Populate the internal dictionaries from the exported arrays for fast lookups.
	for entry in music_library:
		if entry and entry.stream and not entry.key.is_empty():
			if _music_streams.has(entry.key):
				push_warning("Duplicate music key found: '%s'. It will be overwritten." % entry.key)
			_music_streams[entry.key] = entry.stream
		else:
			push_warning("Invalid music library entry found. Ensure it has a key and a stream.")
			
	for entry in sfx_library:
		if entry and entry.stream and not entry.key.is_empty():
			if _sfx_streams.has(entry.key):
				push_warning("Duplicate SFX key found: '%s'. It will be overwritten." % entry.key)
			_sfx_streams[entry.key] = entry.stream
		else:
			push_warning("Invalid SFX library entry found. Ensure it has a key and a stream.")

	# Create a single player for music.
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	add_child(music_player)
	music_player.bus = music_bus_name

	# Create a pool of players for sound effects.
	for i in range(max_sfx_players):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer_" + str(i)
		add_child(sfx_player)
		sfx_player.bus = sfx_bus_name
		sfx_players.append(sfx_player)


# --- MUSIC FUNCTIONS ---

# Plays a music track from the library.
func play_music(key: String, volume_db: float = 0.0, should_loop: bool = true):
	if not _music_streams.has(key):
		push_warning("Audio_Manager: No music found with key: '%s'" % key)
		return
	
	var track: AudioStream = _music_streams[key]
	
	# Don't restart the music if it's already playing.
	if music_player.stream == track and music_player.is_playing():
		return

	music_player.stream = track
	music_player.volume_db = volume_db
	
	# For looping, it's best to set the 'Loop' mode in the audio file's Import settings.
	# This code attempts to set it at runtime, which only works for OGG and MP3 files.
	if track is AudioStreamOggVorbis:
		track.loop = should_loop
	elif track is AudioStreamMP3:
		track.loop = should_loop
	elif should_loop:
		push_warning("Looping at runtime is not supported for '%s'. Please set it in the Import dock." % track.resource_path)
		
	music_player.play()


# Stops the currently playing music.
func stop_music():
	music_player.stop()


# Fades from the current music to a new track over a given duration.
func fade_music_to(key: String, time: float = 1.0, to_volume_db: float = 0.0):
	if not _music_streams.has(key):
		push_warning("Audio_Manager: No music found with key: '%s'" % key)
		return
		
	var new_track: AudioStream = _music_streams[key]

	# Create a temporary player for the new track to allow for a smooth crossfade.
	var crossfade_player = AudioStreamPlayer.new()
	crossfade_player.name = "MusicPlayer_Crossfade"
	add_child(crossfade_player)
	crossfade_player.bus = music_bus_name
	crossfade_player.stream = new_track
	crossfade_player.volume_db = -80.0 # Start completely silent.
	
	# Ensure the new track loops if it's an OGG or MP3.
	if new_track is AudioStreamOggVorbis:
		new_track.loop = true
	elif new_track is AudioStreamMP3:
		new_track.loop = true
	
	crossfade_player.play()

	# Create and configure a Tween for the crossfade animation.
	# `create_tween()` is the new method in Godot 4.
	var tween = create_tween().set_parallel()
	
	# Fade out the old track.
	tween.tween_property(music_player, "volume_db", -80.0, time)
	# Fade in the new track.
	tween.tween_property(crossfade_player, "volume_db", to_volume_db, time)
	
	# Once the tween is finished, call a function to clean up.
	tween.finished.connect(_on_crossfade_complete.bind(crossfade_player))


# Private callback function for when the crossfade tween finishes.
func _on_crossfade_complete(new_player: AudioStreamPlayer):
	# The old music player is now silent and can be stopped.
	music_player.stop()
	
	# Keep a reference to the old player so we can free it.
	var old_player = music_player
	
	# The crossfade player is now the main music player.
	music_player = new_player
	music_player.name = "MusicPlayer" # Rename for consistency in the scene tree.
	
	# Remove the old player from the scene.
	old_player.queue_free()


# --- SFX FUNCTIONS ---

# Plays a sound effect from the library.
func play_sfx(key: String, volume_db: float = 0.0, pitch_scale: float = 1.0):
	if not _sfx_streams.has(key):
		push_warning("Audio_Manager: No SFX found with key: '%s'" % key)
		return
		
	var sfx_stream: AudioStream = _sfx_streams[key]
	
	# Find an available player in the pool that is not currently playing.
	for player in sfx_players:
		if not player.is_playing():
			player.stream = sfx_stream
			player.volume_db = volume_db
			player.pitch_scale = pitch_scale
			player.play()
			return
			
	# If all players are busy, warn the user and reuse the first player in the pool.
	# This prevents sounds from being dropped entirely.
	push_warning("SFX player pool is full. Reusing the oldest player.")
	var oldest_player = sfx_players[0]
	oldest_player.stream = sfx_stream
	oldest_player.volume_db = volume_db
	oldest_player.pitch_scale = pitch_scale
	oldest_player.play()


# Stops all currently playing sound effects.
func stop_all_sfx():
	for player in sfx_players:
		player.stop()


# Checks if a specific sound effect is currently playing.
func is_sfx_playing(key: String) -> bool:
	if not _sfx_streams.has(key):
		return false
		
	var stream_to_check: AudioStream = _sfx_streams[key]
	
	for player in sfx_players:
		if player.stream == stream_to_check and player.is_playing():
			return true
			
	return false

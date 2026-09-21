extends Node

const SFX_TIMBRE = preload("res://audio/sonido/doorbell_chime.ogg")
const SFX_CAJA_REGISTRADORA = preload("res://audio/sonido/cash-register.ogg")

const MUSICA_INICIO = preload("res://audio/musica/royalty_free_music-soft-piano.wav") 

var reproductor_musica: AudioStreamPlayer

func _ready() -> void:
	reproductor_musica = AudioStreamPlayer.new()
	reproductor_musica.bus = &"Musica" if AudioServer.get_bus_index("Musica") != -1 else &"Master"
	add_child(reproductor_musica)

	reproductor_musica.finished.connect(_on_musica_finished)

	aplicar_volumen_musica(ConfigUsuario.volumen_musica)
	aplicar_volumen_sfx(ConfigUsuario.volumen_sfx)

func _on_musica_finished() -> void:
	if reproductor_musica.stream != null:
		reproductor_musica.play()

# --- GESTIÓN DE VOLUMEN DE BUSES ---
func aplicar_volumen_musica(valor_slider: float) -> void:
	ConfigUsuario.volumen_musica = valor_slider
	var bus_index = AudioServer.get_bus_index("Musica")
	if bus_index != -1:
		var lineal = valor_slider / 100.0
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(lineal))

func aplicar_volumen_sfx(valor_slider: float) -> void:
	ConfigUsuario.volumen_sfx = valor_slider
	var bus_index = AudioServer.get_bus_index("SFX")
	var lineal = valor_slider / 100.0
	
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(lineal))
	else:
		var master_index = AudioServer.get_bus_index("Master")
		AudioServer.set_bus_volume_db(master_index, linear_to_db(lineal))

# --- CONTROL DE MÚSICA DE FONDO ---
func reproducir_musica_menu() -> void:
	if MUSICA_INICIO == null:
		return
		
	if reproductor_musica.stream != MUSICA_INICIO or not reproductor_musica.playing:
		reproductor_musica.stream = MUSICA_INICIO
		reproductor_musica.play()

func detener_musica() -> void:
	reproductor_musica.stop()

# --- REPRODUCCIÓN DE EFECTOS DE SONIDO (SFX) ---
func reproducir_sfx(stream: AudioStream, volumen_db: float = 0.0) -> void:
	if stream == null:
		return
		
	var temp_player = AudioStreamPlayer.new()
	temp_player.stream = stream
	temp_player.volume_db = volumen_db
	
	temp_player.bus = &"SFX" if AudioServer.get_bus_index("SFX") != -1 else &"Master"
	
	temp_player.finished.connect(temp_player.queue_free)
	
	add_child(temp_player)
	temp_player.play()

func reproducir_timbre(volumen_db: float = -4.0) -> void:
	reproducir_sfx(SFX_TIMBRE, volumen_db)

func reproducir_ingreso(volumen_db: float = 0.0) -> void:
	reproducir_sfx(SFX_CAJA_REGISTRADORA, volumen_db)

extends Node

const SFX_TIMBRE = preload("res://audio/sonido/doorbell_chime.ogg")
const SFX_CAJA_REGISTRADORA = preload("res://audio/sonido/cash-register.ogg")

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

# --- MÉTODOS DE CONVENIENCIA ---
func reproducir_timbre(volumen_db: float = -4.0) -> void:
	reproducir_sfx(SFX_TIMBRE, volumen_db)

func reproducir_ingreso(volumen_db: float = 0.0) -> void:
	reproducir_sfx(SFX_CAJA_REGISTRADORA, volumen_db)

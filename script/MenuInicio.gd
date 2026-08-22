extends Control

# Referencias a los nodos del menú
@onready var popup_nombre: PopupPanel = $PopupNombre
@onready var input_nombre: LineEdit = $PopupNombre/VBoxContainer/InputNombre
@onready var popup_opciones: PopupPanel = $PopupOpciones

# Variables para guardar los datos (puedes pasarlas a un Autoload/Singleton más adelante)
var nombre_jugador: String = ""

func _ready() -> void:
	# Asegurarnos de que las ventanas emergentes estén ocultas al iniciar
	popup_nombre.hide()
	popup_opciones.hide()
	
	# Opcional: Configurar los Sliders de sonido con valores iniciales (0.0 a 1.0)
	$PopupOpciones/VBoxContainer/SliderMusica.value = 0.8
	$PopupOpciones/VBoxContainer/SliderSFX.value = 0.8

# --- BOTÓN: NUEVA PARTIDA ---
func _on_btn_nueva_partida_pressed() -> void:
	# Limpiamos el campo de texto y mostramos el popup centrado
	input_nombre.text = ""
	popup_nombre.popup_centered()

# --- POPUP: CONFIRMAR NOMBRE ---
func _on_btn_confirmar_nombre_pressed() -> void:
	nombre_jugador = input_nombre.text.strip_edges()
	
	if nombre_jugador != "":
		popup_nombre.hide()
		print("Nombre registrado: ", nombre_jugador)
		# Aquí cambias a la escena de tu juego. Ejemplo:
		get_tree().change_scene_to_file("res://escena/recepcion.tscn")
	else:
		# Si le da a aceptar sin escribir nada, puedes parpadear el campo o no dejarlo avanzar
		input_nombre.placeholder_text = "¡El nombre no puede estar vacío!"

# --- BOTÓN: CARGAR PARTIDA ---
func _on_btn_cargar_partida_pressed() -> void:
	print("Cargando partida guardada...")
	# Aquí implementarás tu sistema de guardado (FileAccess) más adelante

# --- BOTÓN: OPCIONES ---
func _on_btn_opciones_pressed() -> void:
	popup_opciones.popup_centered()

# --- POPUP: CERRAR OPCIONES ---
func _on_btn_cerrar_opciones_pressed() -> void:
	popup_opciones.hide()

# --- MANEJO DE SLIDERS DE AUDIO (Godot 4.5 AudioServer) ---
func _on_slider_musica_value_changed(value: float) -> void:
	# Convertimos el valor del slider al bus de audio de la música
	var bus_index = AudioServer.get_bus_index("Master") # Reemplaza "Master" por "Musica" si creaste ese bus
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

func _on_slider_sfx_value_changed(value: float) -> void:
	# Convertimos el valor del slider al bus de audio de los efectos
	var bus_index = AudioServer.get_bus_index("Master") # Reemplaza "Master" por "SFX" si creaste ese bus
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))

# --- BOTÓN: SALIR ---
func _on_btn_salir_pressed() -> void:
	get_tree().quit()

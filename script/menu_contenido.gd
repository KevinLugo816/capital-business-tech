extends Control

@onready var nombre_tienda: Label = $NombreTienda
@onready var btn_comenzar: Button = $BtnComenzar
@onready var btn_minijuego: Button = $BtnMinijuego
@onready var btn_estadistic: Button = $BtnEstadistic
@onready var btn_logros: Button = $BtnLogros
@onready var btn_opcion: Button = $BtnOpcion
@onready var btn_ayuda: Button = $BtnAyuda
@onready var boton_volver: Button = $BotonVolver

@onready var popup_salir: PopupPanel = $PopupSalir
@onready var btn_confirmar: Button = $PopupSalir/VBoxContainer/HBoxBotones/BtnConfirmar
@onready var btn_cancelar: Button = $PopupSalir/VBoxContainer/HBoxBotones/BtnCancelar

@onready var popup_opciones: PopupPanel = $PopupOpciones
@onready var slider_musica: HSlider = $PopupOpciones/VBoxContainer/SliderMusica
@onready var slider_sfx: HSlider = $PopupOpciones/VBoxContainer/SliderSFX
@onready var btn_cerrar_opciones: Button = $PopupOpciones/VBoxContainer/BtnCerrarOpciones

const CREDITOS_ESCENA = preload("res://escena/creditos.tscn")
var creditos_instancia: Node = null

func _ready() -> void:
	AudioManager.reproducir_musica_menu()
	slider_musica.value = ConfigUsuario.volumen_musica
	slider_sfx.value = ConfigUsuario.volumen_sfx
	
	_cargar_datos_interfaz()
	_conectar_senales()

func _cargar_datos_interfaz() -> void:
	if ConfigUsuario.perfil_jugador.has("nombre_tienda"):
		var tienda_nombre: String = ConfigUsuario.perfil_jugador.get("nombre_tienda", "")
		if not tienda_nombre.is_empty():
			nombre_tienda.text = tienda_nombre

func _conectar_senales() -> void:
	btn_comenzar.pressed.connect(_on_btn_comenzar_pressed)
	btn_minijuego.pressed.connect(_on_btn_minijuego_pressed)
	btn_estadistic.pressed.connect(_on_btn_estadistic_pressed)
	btn_logros.pressed.connect(_on_btn_logros_pressed)
	btn_opcion.pressed.connect(_on_btn_opcion_pressed)
	btn_ayuda.pressed.connect(_on_btn_ayuda_pressed)
	
	boton_volver.pressed.connect(_on_boton_volver_pressed)
	btn_confirmar.pressed.connect(_on_btn_confirmar_pressed)
	btn_cancelar.pressed.connect(_on_btn_cancelar_pressed)
	
	btn_cerrar_opciones.pressed.connect(_on_btn_cerrar_opciones_pressed)
	slider_musica.value_changed.connect(_on_slider_musica_value_changed)
	slider_sfx.value_changed.connect(_on_slider_sfx_value_changed)

func _on_boton_volver_pressed() -> void:
	popup_salir.popup_centered()

func _on_btn_confirmar_pressed() -> void:
	popup_salir.hide()
	get_tree().call_deferred("change_scene_to_file", "res://escena/menu_inicio.tscn")

func _on_btn_cancelar_pressed() -> void:
	popup_salir.hide()

func _on_btn_comenzar_pressed() -> void:
	get_tree().change_scene_to_file("res://escena/recepcion.tscn")

func _on_btn_minijuego_pressed() -> void:
	pass

func _on_btn_estadistic_pressed() -> void:
	pass

func _on_btn_logros_pressed() -> void:
	pass

func _on_btn_opcion_pressed() -> void:
	popup_opciones.popup_centered()

func _on_btn_cerrar_opciones_pressed() -> void:
	popup_opciones.hide()
	if not ConfigUsuario.perfil_jugador.get("nombre_jugador", "").is_empty():
		ConfigUsuario.guardar_partida_en_disco()

func _on_slider_musica_value_changed(value: float) -> void:
	AudioManager.aplicar_volumen_musica(value)
	ConfigUsuario.volumen_musica = value

func _on_slider_sfx_value_changed(value: float) -> void:
	AudioManager.aplicar_volumen_sfx(value)
	ConfigUsuario.volumen_sfx = value

func _on_btn_ayuda_pressed() -> void:
	get_tree().change_scene_to_file("res://escena/ayuda.tscn")

func _on_boton_creditos_pressed() -> void:
	if is_instance_valid(creditos_instancia):
		return
		
	creditos_instancia = CREDITOS_ESCENA.instantiate()
	add_child(creditos_instancia)

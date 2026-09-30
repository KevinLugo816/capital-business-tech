extends Control

@onready var nombre_tienda: Label = $NombreTienda
@onready var btn_comenzar: Button = $BtnComenzar
@onready var btn_minijuego: Button = $BtnMinijuego
@onready var btn_estadistic: Button = $BtnEstadistic
@onready var btn_logros: Button = $BtnLogros
@onready var btn_opcion: Button = $BtnOpcion
@onready var btn_tutorial: Button = $BtnTutorial
@onready var boton_volver: Button = $BotonVolver

@onready var popup_salir: PopupPanel = $PopupSalir
@onready var btn_confirmar: Button = $PopupSalir/VBoxContainer/HBoxBotones/BtnConfirmar
@onready var btn_cancelar: Button = $PopupSalir/VBoxContainer/HBoxBotones/BtnCancelar

const CREDITOS_ESCENA = preload("res://escena/creditos.tscn")
var creditos_instancia: Node = null

func _ready() -> void:
	AudioManager.reproducir_musica_menu()
	
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
	btn_tutorial.pressed.connect(_on_btn_tutorial_pressed)
	
	boton_volver.pressed.connect(_on_boton_volver_pressed)
	btn_confirmar.pressed.connect(_on_btn_confirmar_pressed)
	btn_cancelar.pressed.connect(_on_btn_cancelar_pressed)

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
	# Pendiente de asignar escena
	pass

func _on_btn_estadistic_pressed() -> void:
	# Pendiente de asignar escena
	pass

func _on_btn_logros_pressed() -> void:
	# Pendiente de asignar escena
	pass

func _on_btn_opcion_pressed() -> void:
	# Pendiente de asignar escena
	pass

func _on_btn_tutorial_pressed() -> void:
	# Pendiente de asignar escena
	pass

func _on_boton_creditos_pressed() -> void:
	if is_instance_valid(creditos_instancia):
		return
		
	creditos_instancia = CREDITOS_ESCENA.instantiate()
	add_child(creditos_instancia)

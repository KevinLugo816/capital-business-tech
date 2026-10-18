extends Control

@onready var input_nombre: LineEdit = $Panel/VBoxMain/GridCampos/InputNombre
@onready var spin_edad: SpinBox = $Panel/VBoxMain/GridCampos/SpinEdad
@onready var option_sexo: OptionButton = $Panel/VBoxMain/GridCampos/OptionButton
@onready var input_tienda: LineEdit = $Panel/VBoxMain/GridCampos/InputTienda

@onready var btn_anterior: Button = $Panel/VBoxMain/SelecAvatar/HBoxAvatar/BtnAnterior
@onready var btn_sig: Button = $Panel/VBoxMain/SelecAvatar/HBoxAvatar/BtnSig
@onready var texture_avatar: TextureRect = $Panel/VBoxMain/SelecAvatar/HBoxAvatar/TextureRect
@onready var lbl_nombre_avatar: Label = $Panel/VBoxMain/SelecAvatar/NombreAvatar

@onready var lbl_error: Label = $Panel/VBoxMain/LblError
@onready var btn_registrar: Button = $Panel/VBoxMain/BtnRegistrar
@onready var boton_volver: Button = $BotonVolver

var avatares: Array[String] = [
	"res://sprite/iconos/avatar/avatar_1.png",
	"res://sprite/iconos/avatar/avatar_2.png",
	"res://sprite/iconos/avatar/avatar_3.png",
	"res://sprite/iconos/avatar/avatar_4.png"
]

var avatar_index: int = 0

func _ready() -> void:
	lbl_error.hide()
	
	var line_edit = spin_edad.get_line_edit()
	line_edit.add_theme_font_size_override("font_size", 36)
	line_edit.add_theme_constant_override("outline_size", 5)
	line_edit.add_theme_color_override("font_outline_color", Color.BLACK)
	
	_actualizar_carrusel_avatar()
	_conectar_senales()

func _conectar_senales() -> void:
	btn_anterior.pressed.connect(_on_btn_anterior_pressed)
	btn_sig.pressed.connect(_on_btn_sig_pressed)
	btn_registrar.pressed.connect(_on_btn_registrar_pressed)
	boton_volver.pressed.connect(_on_boton_volver_pressed)

func _actualizar_carrusel_avatar() -> void:
	if avatares.is_empty():
		return
		
	texture_avatar.texture = load(avatares[avatar_index])
	lbl_nombre_avatar.text = "Avatar " + str(avatar_index + 1)

func _on_btn_anterior_pressed() -> void:
	avatar_index -= 1
	if avatar_index < 0:
		avatar_index = avatares.size() - 1
	_actualizar_carrusel_avatar()

func _on_btn_sig_pressed() -> void:
	avatar_index += 1
	if avatar_index >= avatares.size():
		avatar_index = 0
	_actualizar_carrusel_avatar()

func _on_btn_registrar_pressed() -> void:
	var nombre: String = input_nombre.text.strip_edges()
	var tienda: String = input_tienda.text.strip_edges()
	
	if nombre.is_empty() or tienda.is_empty():
		lbl_error.text = "¡Llenar todos los campos!"
		lbl_error.show()
		return
		
	lbl_error.hide()

	ConfigUsuario.perfil_jugador = {
		"nombre_jugador": nombre,
		"nombre_tienda": tienda,
		"edad": int(spin_edad.value),
		"genero": option_sexo.get_item_text(option_sexo.selected),
		"avatar_ruta": avatares[avatar_index]
	}

	EconomiaGlobal.dinero = 500.0
	EconomiaGlobal.dia_actual = 1
	EconomiaGlobal.reputacion = 50
	EconomiaGlobal.tasa_inflacion = 0.0
	EconomiaGlobal.deuda_actual = 0.0
	EconomiaGlobal.score_crediticio = 30
	EconomiaGlobal.dias_con_deuda_actual = 0
	EventosGlobales.limpiar_evento_actual()
	
	Inventario.stock = {
		"Memoria RAM 8GB": 5,
		"Disco SSD 480GB": 3,
		"Cargador Tipo C": 10,
		"Teléfono Gama Baja": 2
	}

	ConfigUsuario.guardar_partida_en_disco()
	get_tree().change_scene_to_file("res://escena/menu_contenido.tscn")

func _on_boton_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://escena/menu_inicio.tscn")

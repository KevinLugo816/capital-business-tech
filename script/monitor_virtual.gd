extends CanvasLayer

signal monitor_cerrado

@onready var home_menu = $Panel/Control/VBoxContainer/Principal/HomeMenu
@onready var btn_cerrar_monitor = $Panel/BotonCerrar

@onready var lbl_dinero_top = $Panel/Control/PanelContainer/Topbar/LabelDinero
@onready var lbl_inflacion_top = $Panel/Control/PanelContainer/Topbar/LabelInflacion
@onready var lbl_dia_top = $Panel/Control/PanelContainer/Topbar/LabelDia

@onready var banco_app = $Panel/Control/VBoxContainer/Principal/BancoApp
@onready var noticias_app = $Panel/Control/VBoxContainer/Principal/NoticiasApp
@onready var publicidad_app = $Panel/Control/VBoxContainer/Principal/PublicidadApp
@onready var ajustes_app = $Panel/Control/VBoxContainer/Principal/AjustesApp

@onready var fondo_rect = $Panel/TextureRect

const FONDO_AZUL = preload("res://sprite/assets/monitor/fondo_monitor_1.png")
const FONDO_ROSA = preload("res://sprite/assets/monitor/fondo_monitor_2.png")
const FONDO_VERDE = preload("res://sprite/assets/monitor/fondo_monitor_3.png")

enum EstadoMonitor { HOME, BANCO, NOTICIAS, PUBLICIDAD, AJUSTES }
var estado_actual = EstadoMonitor.HOME

func _ready() -> void:
	if is_instance_valid(ajustes_app):
		if ajustes_app.has_signal("fondo_cambiado"):
			ajustes_app.fondo_cambiado.connect(_on_fondo_cambiado)
	
	_aplicar_fondo(ConfigUsuario.fondo_monitor)
	ir_al_home()

func ocultar_todas_las_apps() -> void:
	home_menu.hide()
	banco_app.hide()
	noticias_app.hide()
	publicidad_app.hide()
	if is_instance_valid(ajustes_app):
		ajustes_app.hide()

func actualizar_escritorio_ui() -> void:
	if is_instance_valid(lbl_dinero_top):
		lbl_dinero_top.text = "$" + str(snapped(EconomiaGlobal.dinero, 0.01))
		
	if is_instance_valid(lbl_inflacion_top):
		var porc_inf = EconomiaGlobal.tasa_inflacion * 100
		lbl_inflacion_top.text = "Inf: " + str(snapped(porc_inf, 0.1)) + "%"
		
	if is_instance_valid(lbl_dia_top):
		var recepcion = get_parent()
		if is_instance_valid(recepcion) and "dia_actual" in recepcion:
			lbl_dia_top.text = "Día " + str(recepcion.dia_actual)
		else:
			lbl_dia_top.text = "Día 1"

func ir_al_home() -> void:
	ocultar_todas_las_apps()
	home_menu.show()
	estado_actual = EstadoMonitor.HOME
	actualizar_escritorio_ui()

func abrir_app(app: EstadoMonitor) -> void:
	ocultar_todas_las_apps()
	actualizar_escritorio_ui()
	
	match app:
		EstadoMonitor.BANCO:
			banco_app.show()
			estado_actual = EstadoMonitor.BANCO
			if banco_app.has_method("actualizar_ui"):
				banco_app.actualizar_ui()
				
		EstadoMonitor.NOTICIAS:
			noticias_app.show()
			estado_actual = EstadoMonitor.NOTICIAS
			if noticias_app.has_method("actualizar_ui"):
				noticias_app.actualizar_ui()
				
		EstadoMonitor.PUBLICIDAD:
			publicidad_app.show()
			estado_actual = EstadoMonitor.PUBLICIDAD
			if publicidad_app.has_method("actualizar_ui"):
				publicidad_app.actualizar_ui()

		EstadoMonitor.AJUSTES:
			if is_instance_valid(ajustes_app):
				ajustes_app.show()
				estado_actual = EstadoMonitor.AJUSTES
				if ajustes_app.has_method("actualizar_ui"):
					ajustes_app.actualizar_ui()

func _on_fondo_cambiado(nombre_color: String) -> void:
	ConfigUsuario.fondo_monitor = nombre_color
	_aplicar_fondo(nombre_color)

func _aplicar_fondo(nombre_color: String) -> void:
	if not is_instance_valid(fondo_rect):
		return

	match nombre_color:
		"azul":
			fondo_rect.texture = FONDO_AZUL
		"rosa":
			fondo_rect.texture = FONDO_ROSA
		"verde":
			fondo_rect.texture = FONDO_VERDE

func _on_btn_app_banco_pressed() -> void:
	abrir_app(EstadoMonitor.BANCO)

func _on_btn_app_noticias_pressed() -> void:
	abrir_app(EstadoMonitor.NOTICIAS)

func _on_btn_app_publicidad_pressed() -> void:
	abrir_app(EstadoMonitor.PUBLICIDAD)

func _on_btn_app_ajustes_pressed() -> void:
	abrir_app(EstadoMonitor.AJUSTES)

func _on_boton_cerrar_pressed() -> void:
	if estado_actual == EstadoMonitor.HOME:
		monitor_cerrado.emit()
		hide()
	else:
		ir_al_home()

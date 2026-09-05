extends CanvasLayer

signal monitor_cerrado

@onready var home_menu: GridContainer = $Panel/Control/VBoxContainer/Principal/HomeMenu
@onready var btn_cerrar_monitor: Button = $Panel/BotonCerrar

@onready var lbl_dinero_top: Label = $Panel/Control/PanelContainer/Topbar/LabelDinero
@onready var lbl_inflacion_top: Label = $Panel/Control/PanelContainer/Topbar/LabelInflacion
@onready var lbl_dia_top: Label = $Panel/Control/PanelContainer/Topbar/LabelDia

@onready var contenedor_principal: MarginContainer = $Panel/Control/VBoxContainer/Principal

@onready var panel_alerta: PanelContainer = $Panel/Control/PanelContainer/Topbar/Alerta
@onready var lbl_texto_cliente: Label = $Panel/Control/PanelContainer/Topbar/Alerta/HBoxContainer/LabelTexto
@onready var progress_bar_mini: ProgressBar = $Panel/Control/PanelContainer/Topbar/Alerta/HBoxContainer/Mini

@onready var fondo_rect: TextureRect = $Panel/TextureRect

const FONDOS: Dictionary = {
	"azul": preload("res://sprite/assets/monitor/fondo_monitor_1.png"),
	"rosa": preload("res://sprite/assets/monitor/fondo_monitor_2.png"),
	"verde": preload("res://sprite/assets/monitor/fondo_monitor_3.png")
}

enum EstadoMonitor { HOME, BANCO, NOTICIAS, PUBLICIDAD, AJUSTES }
var estado_actual: EstadoMonitor = EstadoMonitor.HOME

var style_mini_fill: StyleBoxFlat
var _cliente_referencia: Node2D = null
var _timer_paciencia_ref: Timer = null

func _ready() -> void:
	configurar_estilo_barra()
	_conectar_senales_globales()
	_aplicar_fondo(ConfigUsuario.get("fondo_monitor") if "fondo_monitor" in ConfigUsuario else "azul")
	ir_al_home()

func _conectar_senales_globales() -> void:
	if not EconomiaGlobal.dinero_cambiado.is_connected(_on_dinero_cambiado):
		EconomiaGlobal.dinero_cambiado.connect(_on_dinero_cambiado)
		
	if not EconomiaGlobal.inflacion_cambiada.is_connected(_on_inflacion_cambiada):
		EconomiaGlobal.inflacion_cambiada.connect(_on_inflacion_cambiada)
	
	if EconomiaGlobal.has_signal("nuevo_dia_comenzado") and not EconomiaGlobal.nuevo_dia_comenzado.is_connected(_on_nuevo_dia_comenzado):
		EconomiaGlobal.nuevo_dia_comenzado.connect(_on_nuevo_dia_comenzado)
	
	var ajustes_app = contenedor_principal.get_node_or_null("AjustesApp")
	if is_instance_valid(ajustes_app) and ajustes_app.has_signal("fondo_cambiado"):
		if not ajustes_app.fondo_cambiado.is_connected(_on_fondo_cambiado):
			ajustes_app.fondo_cambiado.connect(_on_fondo_cambiado)

func _process(_delta: float) -> void:
	actualizar_indicador_cliente()

func ocultar_todas_las_apps() -> void:
	if not is_instance_valid(contenedor_principal):
		return
		
	for child in contenedor_principal.get_children():
		if child is Control:
			child.hide()

func actualizar_escritorio_ui() -> void:
	if is_instance_valid(lbl_dinero_top):
		lbl_dinero_top.text = "$" + str(snapped(EconomiaGlobal.dinero, 0.01))
		
	if is_instance_valid(lbl_inflacion_top):
		var porc_inf = EconomiaGlobal.tasa_inflacion * 100.0
		lbl_inflacion_top.text = "Inf: " + str(snapped(porc_inf, 0.1)) + "%"
		
	if is_instance_valid(lbl_dia_top):
		lbl_dia_top.text = "Día " + str(EconomiaGlobal.dia_actual)

func configurar_estilo_barra() -> void:
	if is_instance_valid(panel_alerta):
		panel_alerta.hide()
		
	if is_instance_valid(progress_bar_mini):
		style_mini_fill = StyleBoxFlat.new()
		style_mini_fill.set_corner_radius_all(4)
		progress_bar_mini.add_theme_stylebox_override("fill", style_mini_fill)

func actualizar_indicador_cliente() -> void:
	if not is_instance_valid(panel_alerta):
		return
		
	var recepcion = get_tree().current_scene
	
	if is_instance_valid(recepcion) and "cliente_actual" in recepcion and is_instance_valid(recepcion.cliente_actual):
		var cliente = recepcion.cliente_actual

		if _cliente_referencia != cliente:
			_cliente_referencia = cliente
			_timer_paciencia_ref = cliente.get_node_or_null("PatienceTimer") if cliente.has_node("PatienceTimer") else null
			
		if is_instance_valid(_timer_paciencia_ref) and not _timer_paciencia_ref.is_stopped():
			panel_alerta.show()
			
			if is_instance_valid(lbl_texto_cliente):
				lbl_texto_cliente.text = "1"
			
			var tiempo_total = cliente.tiempo_espera if "tiempo_espera" in cliente else _timer_paciencia_ref.wait_time
			var porcentaje = (_timer_paciencia_ref.time_left / tiempo_total) * 100.0
			
			if is_instance_valid(progress_bar_mini):
				progress_bar_mini.value = porcentaje
			
			if style_mini_fill:
				if porcentaje > 50.0:
					style_mini_fill.bg_color = Color("2ecc71")
				elif porcentaje > 20.0:
					style_mini_fill.bg_color = Color("f1c40f")
				else:
					style_mini_fill.bg_color = Color("e74c3c")
			return

	_cliente_referencia = null
	_timer_paciencia_ref = null
	panel_alerta.hide()

func ir_al_home() -> void:
	ocultar_todas_las_apps()
	if is_instance_valid(home_menu):
		home_menu.show()
	estado_actual = EstadoMonitor.HOME
	actualizar_escritorio_ui()

func abrir_app_por_nombre(nombre_nodo: String, estado: EstadoMonitor) -> void:
	ocultar_todas_las_apps()
	actualizar_escritorio_ui()
	
	var app = contenedor_principal.get_node_or_null(nombre_nodo)
	if is_instance_valid(app):
		app.show()
		estado_actual = estado
		if app.has_method("actualizar_ui"):
			app.actualizar_ui()

func _aplicar_fondo(nombre_color: String) -> void:
	if not is_instance_valid(fondo_rect):
		return

	if FONDOS.has(nombre_color):
		fondo_rect.texture = FONDOS[nombre_color]
	else:
		fondo_rect.texture = FONDOS["azul"]

func _on_dinero_cambiado(_monto: float) -> void: actualizar_escritorio_ui()
func _on_inflacion_cambiada(_tasa: float) -> void: actualizar_escritorio_ui()
func _on_nuevo_dia_comenzado() -> void: actualizar_escritorio_ui()

func _on_fondo_cambiado(nombre_color: String) -> void:
	ConfigUsuario.fondo_monitor = nombre_color
	_aplicar_fondo(nombre_color)

func _on_btn_app_banco_pressed() -> void: abrir_app_por_nombre("BancoApp", EstadoMonitor.BANCO)
func _on_btn_app_noticias_pressed() -> void: abrir_app_por_nombre("NoticiasApp", EstadoMonitor.NOTICIAS)
func _on_btn_app_publicidad_pressed() -> void: abrir_app_por_nombre("PublicidadApp", EstadoMonitor.PUBLICIDAD)
func _on_btn_app_ajustes_pressed() -> void: abrir_app_por_nombre("AjustesApp", EstadoMonitor.AJUSTES)

func _on_boton_cerrar_pressed() -> void:
	if estado_actual == EstadoMonitor.HOME:
		monitor_cerrado.emit()
		hide()
	else:
		ir_al_home()

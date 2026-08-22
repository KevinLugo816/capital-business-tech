extends CanvasLayer

signal celular_cerrado

# --- REFERENCIAS A LAS PANTALLAS INTERNAS ---
@onready var home_menu = $Panel/MarginContainer/VBoxContainer/Principal/HomeMenu
@onready var mayorista_panel = $Panel/MarginContainer/VBoxContainer/Principal/MayoristaPanel
@onready var banco_panel = $Panel/MarginContainer/VBoxContainer/Principal/BancoPanel
@onready var noticias_panel = $Panel/MarginContainer/VBoxContainer/Principal/NoticiasPanel

# --- BOTÓN FÍSICO INFERIOR ---
@onready var btn_home_fisico = $Panel/BotonCerrar

# --- COMPONENTES DE LA APP DEL BANCO ---
@onready var lbl_deuda = $Panel/MarginContainer/VBoxContainer/Principal/BancoPanel/VBoxContainer/LabelDeuda
@onready var lbl_estado_credito = $Panel/MarginContainer/VBoxContainer/Principal/BancoPanel/VBoxContainer/LabelEstado
@onready var btn_solicitar = $Panel/MarginContainer/VBoxContainer/Principal/BancoPanel/VBoxContainer/BtnSolicitar
@onready var btn_pagar = $Panel/MarginContainer/VBoxContainer/Principal/BancoPanel/VBoxContainer/BtnPagar

# --- COMPONENTES DE LA APP DE NOTICIAS ---
@onready var lbl_noticia_inflacion = $Panel/MarginContainer/VBoxContainer/Principal/NoticiasPanel/VBoxContainer/LabelNoticia

# --- VARIABLES DE COSTO PROVEEDOR (MAYORISTA) ---
var precios_base_proveedor = {
	"Memoria RAM 8GB": 20.0,
	"Disco SSD 480GB": 25.0,
	"Cargador Tipo C": 7.0,
	"Teléfono Gama Baja": 75.0
}
@onready var lista_productos_mayorista = $Panel/MarginContainer/VBoxContainer/Principal/MayoristaPanel/MayorMargin/MayorCont/ListaProductos

enum EstadoCelular { HOME, MAYORISTA, BANCO, NOTICIAS }
var estado_actual = EstadoCelular.HOME
var tamaño_fuente_global: int = 22

func _ready() -> void:
	ir_al_home()
	configurar_fuentes_fijas()

# Coloca las fuentes del tamaño correcto a los botones del escritorio
func configurar_fuentes_fijas() -> void:
	for boton in home_menu.get_children():
		if boton is Button:
			boton.add_theme_font_size_override("font_size", tamaño_fuente_global)
	btn_home_fisico.add_theme_font_size_override("font_size", tamaño_fuente_global)

func ocultar_todas_las_apps() -> void:
	home_menu.hide()
	mayorista_panel.hide()
	banco_panel.hide()
	noticias_panel.hide()

func ir_al_home() -> void:
	ocultar_todas_las_apps()
	home_menu.show()
	estado_actual = EstadoCelular.HOME

func abrir_app(app: EstadoCelular) -> void:
	ocultar_todas_las_apps()
	
	match app:
		EstadoCelular.MAYORISTA:
			mayorista_panel.show()
			estado_actual = EstadoCelular.MAYORISTA
			dibujar_lista_mayorista()
		EstadoCelular.BANCO:
			banco_panel.show()
			estado_actual = EstadoCelular.BANCO
			actualizar_banco_ui()
		EstadoCelular.NOTICIAS:
			noticias_panel.show()
			estado_actual = EstadoCelular.NOTICIAS
			actualizar_noticias_ui()

# =========================================================
# LÓGICA DE LA APP: MAYORISTA
# =========================================================
func dibujar_lista_mayorista() -> void:
	for n in lista_productos_mayorista.get_children():
		n.queue_free()
	
	for producto in Inventario.stock.keys():
		var cantidad_actual = Inventario.obtener_cantidad(producto)
		var precio_compra_inflado = precios_base_proveedor[producto] * (1.0 + EconomiaGlobal.tasa_inflacion)
		
		var fila = HBoxContainer.new()
		fila.alignment = BoxContainer.ALIGNMENT_CENTER
		fila.add_theme_constant_override("separation", 20)
		
		var lbl_info = Label.new()
		lbl_info.text = producto + " (Stock: " + str(cantidad_actual) + ") "
		lbl_info.custom_minimum_size.x = 320
		lbl_info.add_theme_font_size_override("font_size", tamaño_fuente_global)
		
		var lbl_precio = Label.new()
		lbl_precio.text = "Costo: $" + str(snapped(precio_compra_inflado, 0.01)) + " "
		lbl_precio.custom_minimum_size.x = 150
		lbl_precio.add_theme_font_size_override("font_size", tamaño_fuente_global)
		
		var btn_comprar = Button.new()
		btn_comprar.text = " Invertir +1 "
		btn_comprar.add_theme_font_size_override("font_size", tamaño_fuente_global)
		btn_comprar.pressed.connect(func(): procesar_compra_mayorista(producto, precio_compra_inflado))
		
		fila.add_child(lbl_info)
		fila.add_child(lbl_precio)
		fila.add_child(btn_comprar)
		lista_productos_mayorista.add_child(fila)

func procesar_compra_mayorista(producto: String, costo: float) -> void:
	if EconomiaGlobal.restar_dinero(costo):
		Inventario.modificar_stock(producto, 1)
		dibujar_lista_mayorista()
	else:
		print("Dinero insuficiente en caja chica.")

# =========================================================
# LÓGICA DE LA APP: BANCO
# =========================================================
func actualizar_banco_ui() -> void:
	lbl_deuda.add_theme_font_size_override("font_size", tamaño_fuente_global)
	lbl_estado_credito.add_theme_font_size_override("font_size", tamaño_fuente_global)
	btn_solicitar.add_theme_font_size_override("font_size", tamaño_fuente_global)
	btn_pagar.add_theme_font_size_override("font_size", tamaño_fuente_global)

	lbl_deuda.text = "Deuda Bancaria: $" + str(snapped(EconomiaGlobal.deuda_actual, 0.01))
	lbl_estado_credito.text = "Crédito Disponible: $" + str(snapped(EconomiaGlobal.LIMITE_CREDITO - EconomiaGlobal.deuda_actual, 0.01))
	
	btn_solicitar.disabled = (EconomiaGlobal.deuda_actual >= EconomiaGlobal.LIMITE_CREDITO)
	btn_pagar.disabled = (EconomiaGlobal.deuda_actual <= 0) or (EconomiaGlobal.dinero <= 0)

func _on_btn_solicitar_pressed() -> void:
	var monto_prestamo = 100.0
	if EconomiaGlobal.deuda_actual + monto_prestamo <= EconomiaGlobal.LIMITE_CREDITO:
		EconomiaGlobal.agregar_dinero(monto_prestamo)
		EconomiaGlobal.deuda_actual += monto_prestamo
		actualizar_banco_ui()
	else:
		print("Crédito denegado por exceso de riesgo.")

func _on_btn_pagar_pressed() -> void:
	var abono = 50.0
	if abono > EconomiaGlobal.deuda_actual:
		abono = EconomiaGlobal.deuda_actual
		
	if EconomiaGlobal.restar_dinero(abono):
		EconomiaGlobal.deuda_actual -= abono
		actualizar_banco_ui()

# =========================================================
# LÓGICA DE LA APP: NOTICIAS (ECONOMÍA)
# =========================================================
func actualizar_noticias_ui() -> void:
	lbl_noticia_inflacion.add_theme_font_size_override("font_size", tamaño_fuente_global)
	var porc_inf = EconomiaGlobal.tasa_inflacion * 100
	
	lbl_noticia_inflacion.text = "--- DIARIO ECONÓMICO DIGITAL ---\n\n"
	lbl_noticia_inflacion.text += "El indice de inflación del mercado se ubica hoy en: " + str(snapped(porc_inf, 0.1)) + "%\n\n"
	
	if porc_inf > 15.0:
		lbl_noticia_inflacion.text += "ALERTA: Inflación crítica detectada. Los proveedores del mayorista han subido agresivamente sus costos de reposición. ¡Ajuste los precios en su almacén para evitar pérdidas!"
	else:
		lbl_noticia_inflacion.text += "ESTADO: El mercado se mantiene estable. Buen momento para invertir en stock masivo al por mayor."

# =========================================================
# LÓGICA DE MARKETING
# =========================================================
# Conecta el botón de tu UI que dice "Lanzar Campaña ($50)" a esta función
func _on_boton_publicidad_pressed() -> void:
	var costo_campaña = 50.0
	
	if EconomiaGlobal.restar_dinero(costo_campaña):
		EconomiaGlobal.reputacion += 20
		print("Campaña de marketing exitosa. ¡Tu negocio se está dando a conocer!")
		
		# Forzamos una actualización por si el jugador va al banco o navega por el cel
		if estado_actual == EstadoCelular.BANCO:
			actualizar_banco_ui()
	else:
		print("No tienes suficiente dinero en caja para pagar publicidad.")

# =========================================================
# SEÑALES DE LOS BOTONES DEL HOME (ESCRITORIO)
# =========================================================
func _on_boton_app_mayorista_pressed() -> void:
	abrir_app(EstadoCelular.MAYORISTA)

func _on_boton_app_banco_pressed() -> void:
	abrir_app(EstadoCelular.BANCO)

func _on_boton_app_noticias_pressed() -> void:
	abrir_app(EstadoCelular.NOTICIAS)

# =========================================================
# ACCIÓN DEL BOTÓN HOME FÍSICO (VOLVER O CERRAR)
# =========================================================
func _on_boton_home_fisico_pressed() -> void:
	if estado_actual == EstadoCelular.HOME:
		celular_cerrado.emit()
		hide() # Oculta el CanvasLayer por completo
	else:
		ir_al_home()

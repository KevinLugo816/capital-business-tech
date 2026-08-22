extends CanvasLayer

signal inventario_cerrado

@onready var tabla_cabecera = $Panel/Inventario/InvenCont/TablaCabecera
@onready var lista_inventario = $Panel/Inventario/InvenCont/ScrollContainer/ListaInventario

@onready var inven_margin: MarginContainer = $Panel/Inventario
@onready var mayorista_margin: MarginContainer = $Panel/Mayorista
@onready var btn_ir_mayorista: Button = $Panel/Bar/BotonMercado

@onready var panel_alerta: PanelContainer = $Alerta
@onready var lbl_texto_cliente: Label = $Alerta/HBoxContainer/LabelTexto
@onready var progress_bar_mini: ProgressBar = $Alerta/HBoxContainer/Mini
@onready var label_dinero: Label = $Panel/Bar/LabelDinero
@onready var label_inflacion: Label = $Panel/Bar/LabelInflacion
@onready var label_almacen: Label = $Panel/Bar/LabelAlmacen

var style_mini_fill: StyleBoxFlat
var dinero_anterior: float = -1.0

var marcas_productos = {
	"Memoria RAM 8GB": "Princeston",
	"Disco SSD 480GB": "Winxx",
	"Cargador Tipo C": "EARM",
	"Teléfono Gama Baja": "Xamo"
}

var precios_base_proveedor = {
	"Memoria RAM 8GB": 20.0,
	"Disco SSD 480GB": 25.0,
	"Cargador Tipo C": 7.0,
	"Teléfono Gama Baja": 75.0
}

const CAPACIDAD_MAXIMA_ALMACEN: int = 50

const ANCHO_COL_IMAGEN = 120
const ANCHO_COL_PRODUCTO = 240
const ANCHO_COL_MARCA = 160
const ANCHO_COL_STOCK = 100
const ANCHO_COL_PRECIO = 200
const ANCHO_COL_ALERTA = 380
const SEPARACION_COLUMNAS = 50
const SEPARACION_FILAS = 15

func _ready() -> void:
	if has_node("Panel/Inventario/InvenCont"):
		var inven_cont = $Panel/Inventario/InvenCont
		if inven_cont is VBoxContainer:
			inven_cont.add_theme_constant_override("separation", 6)

	if lista_inventario is VBoxContainer:
		lista_inventario.add_theme_constant_override("separation", SEPARACION_FILAS)

	crear_cabecera_tabla()
	dibujar_inventario_local()
	configurar_estilo_barra()
	
	if is_instance_valid(inven_margin): inven_margin.show()
	if is_instance_valid(mayorista_margin): mayorista_margin.hide()
	
	if is_instance_valid(btn_ir_mayorista):
		btn_ir_mayorista.pressed.connect(abrir_vista_mayorista)
		
	if is_instance_valid(mayorista_margin):
		if mayorista_margin.has_signal("volver_al_inventario_solicitado"):
			mayorista_margin.volver_al_inventario_solicitado.connect(abrir_vista_inventario)
		if mayorista_margin.has_signal("compra_realizada"):
			mayorista_margin.compra_realizada.connect(actualizar_ui)

	if EconomiaGlobal.has_signal("dinero_cambiado"):
		EconomiaGlobal.dinero_cambiado.connect(_on_dinero_cambiado)
	if EconomiaGlobal.has_signal("inflacion_cambiada"):
		EconomiaGlobal.inflacion_cambiada.connect(_on_inflacion_cambiada)

	actualizar_ui()

func _process(_delta: float) -> void:
	actualizar_indicador_cliente()

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
	
	if is_instance_valid(recepcion) and "cliente_actual" in recepcion:
		var cliente = recepcion.cliente_actual
		
		if is_instance_valid(cliente) and cliente.has_node("PatienceTimer"):
			var timer: Timer = cliente.get_node("PatienceTimer")
			
			if timer and not timer.is_stopped():
				panel_alerta.show()
				
				if is_instance_valid(lbl_texto_cliente):
					lbl_texto_cliente.text = "1"
				
				var tiempo_total = cliente.tiempo_espera if "tiempo_espera" in cliente else timer.wait_time
				var porcentaje = (timer.time_left / tiempo_total) * 100.0
				
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
				
	panel_alerta.hide()

func crear_cabecera_tabla() -> void:
	for n in tabla_cabecera.get_children():
		n.queue_free()
	
	tabla_cabecera.add_theme_constant_override("separation", SEPARACION_COLUMNAS)
	
	var font_size_cabecera = 26
	var titulos = [
		{"texto": "Producto", "ancho": ANCHO_COL_IMAGEN},
		{"texto": "Modelo", "ancho": ANCHO_COL_PRODUCTO},
		{"texto": "Marca", "ancho": ANCHO_COL_MARCA},
		{"texto": "Stock", "ancho": ANCHO_COL_STOCK},
		{"texto": "Precio Venta", "ancho": ANCHO_COL_PRECIO},
		{"texto": "Estado / Rentabilidad", "ancho": ANCHO_COL_ALERTA}
	]
	
	for col in titulos:
		var lbl = Label.new()
		lbl.text = col["texto"]
		lbl.custom_minimum_size.x = col["ancho"]
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		lbl.add_theme_font_size_override("font_size", font_size_cabecera)
		lbl.add_theme_color_override("font_color", Color.ORANGE)
		lbl.add_theme_constant_override("outline_size", 5)
		lbl.add_theme_color_override("font_outline_color", Color.BLACK)
		
		tabla_cabecera.add_child(lbl)

func dibujar_inventario_local() -> void:
	for n in lista_inventario.get_children():
		n.queue_free()
	
	var font_size_datos = 24
	var anchos = {
		"imagen": ANCHO_COL_IMAGEN,
		"producto": ANCHO_COL_PRODUCTO,
		"marca": ANCHO_COL_MARCA,
		"stock": ANCHO_COL_STOCK,
		"precio": ANCHO_COL_PRECIO,
		"alerta": ANCHO_COL_ALERTA,
		"separacion": SEPARACION_COLUMNAS
	}
	
	for producto in Inventario.stock.keys():
		var stock_actual = Inventario.obtener_cantidad(producto)
		var precio_actual = Inventario.precios_venta_publico[producto]
		var marca = marcas_productos.get(producto, "Genérico")
		
		var fila = InventarioUIFactory.crear_fila_producto(
			producto,
			stock_actual,
			precio_actual,
			marca,
			font_size_datos,
			anchos,
			Callable(self, "_on_precio_producto_cambiado"),
			Callable(self, "mostrar_popup_imagen")
		)
		
		lista_inventario.add_child(fila)
		
		var lbl_advertencia = fila.get_child(fila.get_child_count() - 1) as Label
		evaluar_precio_producto(producto, precio_actual, lbl_advertencia)

func _on_precio_producto_cambiado(producto: String, nuevo_valor: float, lbl_advertencia: Label) -> void:
	Inventario.precios_venta_publico[producto] = nuevo_valor
	evaluar_precio_producto(producto, nuevo_valor, lbl_advertencia)

func evaluar_precio_producto(producto: String, precio_jugador_base: float, label_feedback: Label) -> void:
	var inflacion = EconomiaGlobal.tasa_inflacion
	var iva = EconomiaGlobal.tasa_iva
	
	var costo_adquisicion_inflado = precios_base_proveedor[producto] * (1.0 + inflacion)
	var precio_final_cliente = precio_jugador_base * (1.0 + iva)
	
	var precio_justo_mercado = precios_base_proveedor[producto] * (1.0 + inflacion)
	var precio_justo_con_iva = precio_justo_mercado * (1.0 + iva)
	var factor_tolerancia = 1.15 if EconomiaGlobal.reputacion > 75 else 1.05
	var precio_maximo_aceptable = precio_justo_con_iva * factor_tolerancia
	
	if precio_jugador_base <= costo_adquisicion_inflado:
		label_feedback.text = "¡Alerta! Venta a pérdida o sin margen."
		label_feedback.add_theme_color_override("font_color", Color.YELLOW)
	elif precio_final_cliente > precio_maximo_aceptable:
		label_feedback.text = "¡Sobreprecio! + IVA ($" + str(snapped(precio_final_cliente, 0.01)) + ")"
		label_feedback.add_theme_color_override("font_color", Color.RED)
	else:
		var ganancia_neta_estimada = precio_jugador_base - costo_adquisicion_inflado
		label_feedback.text = "Precio óptimo. Margen neto: +$" + str(snapped(ganancia_neta_estimada, 0.01))
		label_feedback.add_theme_color_override("font_color", Color.GREEN)

func abrir_vista_mayorista() -> void:
	if is_instance_valid(btn_ir_mayorista):
		btn_ir_mayorista.disabled = true
		
	if mayorista_margin.has_method("actualizar_catalogo"):
		mayorista_margin.actualizar_catalogo()
		
	if is_instance_valid(inven_margin): inven_margin.hide()
	if is_instance_valid(mayorista_margin): mayorista_margin.show()

func abrir_vista_inventario() -> void:
	if is_instance_valid(btn_ir_mayorista):
		btn_ir_mayorista.disabled = false
		
	dibujar_inventario_local()
	if is_instance_valid(mayorista_margin): mayorista_margin.hide()
	if is_instance_valid(inven_margin): inven_margin.show()

func mostrar_popup_imagen(textura: Texture2D, nombre_producto: String) -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	margin.add_theme_constant_override("margin_right", 25)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var lbl_titulo = Label.new()
	lbl_titulo.text = nombre_producto
	lbl_titulo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_titulo.add_theme_font_size_override("font_size", 34)
	lbl_titulo.add_theme_color_override("font_color", Color.ORANGE)
	lbl_titulo.add_theme_constant_override("outline_size", 6)
	lbl_titulo.add_theme_color_override("font_outline_color", Color.BLACK)

	var img_grande = TextureRect.new()
	img_grande.texture = textura
	img_grande.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img_grande.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	img_grande.custom_minimum_size = Vector2(720, 720)

	var btn_cerrar = Button.new()
	btn_cerrar.text = "Cerrar"
	btn_cerrar.custom_minimum_size = Vector2(160, 50)
	btn_cerrar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_cerrar.add_theme_font_size_override("font_size", 24)
	btn_cerrar.add_theme_constant_override("outline_size", 4)
	btn_cerrar.pressed.connect(func(): overlay.queue_free())

	overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			overlay.queue_free()
	)

	vbox.add_child(lbl_titulo)
	vbox.add_child(img_grande)
	vbox.add_child(btn_cerrar)
	margin.add_child(vbox)
	panel.add_child(margin)
	overlay.add_child(panel)

	add_child(overlay)

func actualizar_ui() -> void:
	_on_dinero_cambiado(EconomiaGlobal.dinero)
	_on_inflacion_cambiada(EconomiaGlobal.tasa_inflacion)
	_actualizar_label_almacen()

func _on_dinero_cambiado(nuevo_monto: float) -> void:
	if dinero_anterior >= 0.0:
		var diferencia = nuevo_monto - dinero_anterior
		
		if diferencia != 0.0 and is_instance_valid(label_dinero):
			AnimUiManager.animar_dinero(
				diferencia, 
				label_dinero.global_position + Vector2(10, 20), 
				self
			)
	dinero_anterior = nuevo_monto
	
	if is_instance_valid(label_dinero):
		label_dinero.text = "Dinero: $" + str(snapped(nuevo_monto, 0.01))

func _on_inflacion_cambiada(nueva_tasa: float) -> void:
	if is_instance_valid(label_inflacion):
		var porcentaje = nueva_tasa * 100.0
		label_inflacion.text = "Inflación: " + str(snapped(porcentaje, 0.1)) + "%"

func _actualizar_label_almacen() -> void:
	if not is_instance_valid(label_almacen):
		return
		
	var stock_ocupado = 0
	for producto in Inventario.stock.keys():
		stock_ocupado += Inventario.obtener_cantidad(producto)
		
	label_almacen.text = "Almacén: %d/%d un." % [stock_ocupado, CAPACIDAD_MAXIMA_ALMACEN]
	
	if stock_ocupado >= CAPACIDAD_MAXIMA_ALMACEN:
		label_almacen.add_theme_color_override("font_color", Color("e74c3c"))
	else:
		label_almacen.add_theme_color_override("font_color", Color.VIOLET)

func _on_boton_cerrar_pressed() -> void:
	inventario_cerrado.emit()
	queue_free()

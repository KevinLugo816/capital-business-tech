extends MarginContainer

signal volver_al_inventario_solicitado
signal compra_realizada
signal solicitud_popup_imagen(textura: Texture2D, nombre_producto: String)

@onready var lista_productos_mayorista = $MayorCont/ScrollContainer/ListaMayor
@onready var btn_volver = $MayorCont/HeaderBar/VolverInv

const CAPACIDAD_MAXIMA_ALMACEN: int = 50

var precios_base_proveedor = {
	"Memoria RAM 8GB": 20.0,
	"Disco SSD 480GB": 25.0,
	"Cargador Tipo C": 7.0,
	"Teléfono Gama Baja": 75.0
}

const ANCHO_COL_IMAGEN: float = 120.0
const ANCHO_COL_NOMBRE: float = 280.0
const ANCHO_COL_STOCK: float = 100.0
const ANCHO_COL_PRECIO: float = 200.0
const ANCHO_COL_SPINBOX: float = 90.0
const ANCHO_COL_TOTAL: float = 150.0

func _ready() -> void:
	if is_instance_valid(btn_volver) and not btn_volver.pressed.is_connected(_on_btn_volver_pressed):
		btn_volver.pressed.connect(_on_btn_volver_pressed)
		
	if EconomiaGlobal.has_signal("nuevo_dia_comenzado") and not EconomiaGlobal.nuevo_dia_comenzado.is_connected(actualizar_catalogo):
		EconomiaGlobal.nuevo_dia_comenzado.connect(actualizar_catalogo)
		
	actualizar_catalogo()

func _exit_tree() -> void:
	if EconomiaGlobal.has_signal("nuevo_dia_comenzado") and EconomiaGlobal.nuevo_dia_comenzado.is_connected(actualizar_catalogo):
		EconomiaGlobal.nuevo_dia_comenzado.disconnect(actualizar_catalogo)

func _on_btn_volver_pressed() -> void:
	volver_al_inventario_solicitado.emit()

func actualizar_catalogo() -> void:
	if not is_instance_valid(lista_productos_mayorista):
		return

	if lista_productos_mayorista is VBoxContainer:
		lista_productos_mayorista.add_theme_constant_override("separation", 25)

	for n in lista_productos_mayorista.get_children():
		n.queue_free()
	
	var font_size_datos = 24
	var stock_ocupado = obtener_stock_ocupado_total()
	var espacio_disponible = max(0, CAPACIDAD_MAXIMA_ALMACEN - stock_ocupado)
	
	for producto in Inventario.stock.keys():
		if not precios_base_proveedor.has(producto):
			continue

		var cantidad_actual = Inventario.obtener_cantidad(producto)
		var es_oferta_hoy = (producto == EconomiaGlobal.producto_en_oferta)
		
		var costo_base = precios_base_proveedor[producto] * (1.0 + EconomiaGlobal.tasa_inflacion)
		var porcentaje_descuento = EconomiaGlobal.PORCENTAJE_OFERTA if "PORCENTAJE_OFERTA" in EconomiaGlobal else 0.25
		var precio_unitario = costo_base * (1.0 - porcentaje_descuento) if es_oferta_hoy else costo_base
		
		var fila = HBoxContainer.new()
		fila.alignment = BoxContainer.ALIGNMENT_BEGIN
		fila.add_theme_constant_override("separation", 15)
		fila.custom_minimum_size.y = 110

		var tex_rect = TextureRect.new()
		tex_rect.texture = Inventario.obtener_textura_producto(producto)
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(ANCHO_COL_IMAGEN, 96)
		tex_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tex_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		tex_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		tex_rect.gui_input.connect(_on_imagen_producto_gui_input.bind(tex_rect.texture, producto))

		var lbl_nombre = Label.new()
		lbl_nombre.text = producto
		lbl_nombre.custom_minimum_size.x = ANCHO_COL_NOMBRE
		lbl_nombre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_nombre.add_theme_font_size_override("font_size", font_size_datos)
		lbl_nombre.add_theme_constant_override("outline_size", 4)
		lbl_nombre.add_theme_color_override("font_outline_color", Color.BLACK)

		var lbl_stock = Label.new()
		lbl_stock.text = str(cantidad_actual) + " un."
		lbl_stock.custom_minimum_size.x = ANCHO_COL_STOCK
		lbl_stock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_stock.add_theme_font_size_override("font_size", font_size_datos)
		lbl_stock.add_theme_constant_override("outline_size", 4)
		lbl_stock.add_theme_color_override("font_outline_color", Color.BLACK)
		
		if cantidad_actual == 0:
			lbl_stock.add_theme_color_override("font_color", Color("e74c3c"))
		elif cantidad_actual <= 3:
			lbl_stock.add_theme_color_override("font_color", Color("f1c40f"))
		else:
			lbl_stock.add_theme_color_override("font_color", Color.WHITE)
		
		var lbl_precio = Label.new()
		var texto_precio = "P/U: $" + str(snapped(precio_unitario, 0.01))
		
		if es_oferta_hoy:
			texto_precio += " (-" + str(int(porcentaje_descuento * 100)) + "%)"
			lbl_precio.add_theme_color_override("font_color", Color("f39c12"))
			
		lbl_precio.text = texto_precio
		lbl_precio.custom_minimum_size.x = ANCHO_COL_PRECIO
		lbl_precio.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_precio.add_theme_font_size_override("font_size", font_size_datos)
		lbl_precio.add_theme_constant_override("outline_size", 4)
		lbl_precio.add_theme_color_override("font_outline_color", Color.BLACK)
		
		var selector_cantidad = SpinBox.new()
		selector_cantidad.min_value = 1
		selector_cantidad.max_value = max(1, espacio_disponible)
		selector_cantidad.value = 1
		selector_cantidad.custom_minimum_size.x = ANCHO_COL_SPINBOX
		selector_cantidad.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		selector_cantidad.get_line_edit().add_theme_font_size_override("font_size", font_size_datos)
		selector_cantidad.get_line_edit().alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		var lbl_total = Label.new()
		lbl_total.text = "Total: $" + str(snapped(precio_unitario * selector_cantidad.value, 0.01))
		lbl_total.custom_minimum_size.x = ANCHO_COL_TOTAL
		lbl_total.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl_total.add_theme_font_size_override("font_size", font_size_datos)
		lbl_total.add_theme_constant_override("outline_size", 4)
		lbl_total.add_theme_color_override("font_outline_color", Color.BLACK)
		lbl_total.add_theme_color_override("font_color", Color("2ecc71"))
		
		selector_cantidad.value_changed.connect(_on_cantidad_cambiada.bind(precio_unitario, lbl_total))
		
		var btn_comprar = Button.new()
		btn_comprar.text = "Comprar"
		btn_comprar.custom_minimum_size = Vector2(110, 45)
		btn_comprar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn_comprar.add_theme_font_size_override("font_size", font_size_datos)
		
		if espacio_disponible <= 0:
			btn_comprar.disabled = true
			selector_cantidad.editable = false
		
		btn_comprar.pressed.connect(_on_btn_comprar_pressed.bind(producto, precio_unitario, selector_cantidad))
		
		fila.add_child(tex_rect)
		fila.add_child(lbl_nombre)
		fila.add_child(lbl_stock)
		fila.add_child(lbl_precio)
		fila.add_child(selector_cantidad)
		fila.add_child(lbl_total)
		fila.add_child(btn_comprar)
		
		lista_productos_mayorista.add_child(fila)

func _on_imagen_producto_gui_input(event: InputEvent, textura: Texture2D, producto: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		solicitud_popup_imagen.emit(textura, producto)

func _on_cantidad_cambiada(nueva_cantidad: float, precio_unitario: float, lbl_total: Label) -> void:
	var costo_calculado = precio_unitario * nueva_cantidad
	lbl_total.text = "Total: $" + str(snapped(costo_calculado, 0.01))

func _on_btn_comprar_pressed(producto: String, precio_unitario: float, selector_cantidad: SpinBox) -> void:
	var cantidad = int(selector_cantidad.value)
	procesar_compra(producto, precio_unitario, cantidad)

func obtener_stock_ocupado_total() -> int:
	var total = 0
	for prod in Inventario.stock.keys():
		total += Inventario.obtener_cantidad(prod)
	return total

func procesar_compra(producto: String, costo_unitario: float, cantidad: int) -> void:
	var stock_ocupado = obtener_stock_ocupado_total()
	
	if stock_ocupado + cantidad > CAPACIDAD_MAXIMA_ALMACEN:
		print("¡Espacio insuficiente en el almacén!")
		return

	var costo_total = costo_unitario * cantidad

	if EconomiaGlobal.restar_dinero(costo_total):
		Inventario.modificar_stock(producto, cantidad)
		EconomiaGlobal.gastos_mayorista_hoy += costo_total
		actualizar_catalogo()
		compra_realizada.emit()
	else:
		print("Dinero insuficiente en caja chica.")

extends MarginContainer

signal volver_al_inventario_solicitado
signal compra_realizada

@onready var lista_productos_mayorista = $MayorCont/ScrollContainer/ListaMayor
@onready var btn_volver = $MayorCont/HeaderBar/VolverInv

const CAPACIDAD_MAXIMA_ALMACEN: int = 50

var precios_base_proveedor = {
	"Memoria RAM 8GB": 20.0,
	"Disco SSD 480GB": 25.0,
	"Cargador Tipo C": 7.0,
	"Teléfono Gama Baja": 75.0
}

var producto_en_oferta: String = ""
const PORCENTAJE_OFERTA: float = 0.25

const ANCHO_COL_IMAGEN: float = 120.0
const ANCHO_COL_NOMBRE: float = 280.0
const ANCHO_COL_STOCK: float = 100.0
const ANCHO_COL_PRECIO: float = 200.0
const ANCHO_COL_SPINBOX: float = 90.0
const ANCHO_COL_TOTAL: float = 150.0

func _ready() -> void:
	if is_instance_valid(btn_volver):
		btn_volver.pressed.connect(func(): volver_al_inventario_solicitado.emit())
		
	if EconomiaGlobal.has_signal("nuevo_dia_comenzado"):
		EconomiaGlobal.nuevo_dia_comenzado.connect(actualizar_catalogo)
		
	actualizar_catalogo()

func actualizar_catalogo() -> void:
	if lista_productos_mayorista is VBoxContainer:
		lista_productos_mayorista.add_theme_constant_override("separation", 25)

	if not is_instance_valid(lista_productos_mayorista):
		return

	for n in lista_productos_mayorista.get_children():
		n.queue_free()
	
	var font_size_datos = 24
	var stock_ocupado = obtener_stock_ocupado_total()
	var espacio_disponible = max(0, CAPACIDAD_MAXIMA_ALMACEN - stock_ocupado)
	
	for producto in Inventario.stock.keys():
		var cantidad_actual = Inventario.obtener_cantidad(producto)
		var es_oferta_hoy = (producto == EconomiaGlobal.producto_en_oferta)
		
		var costo_base = precios_base_proveedor[producto] * (1.0 + EconomiaGlobal.tasa_inflacion)
		var precio_unitario = costo_base * (1.0 - EconomiaGlobal.PORCENTAJE_OFERTA) if es_oferta_hoy else costo_base
		
		var fila = HBoxContainer.new()
		fila.alignment = BoxContainer.ALIGNMENT_BEGIN
		fila.add_theme_constant_override("separation", 15)
		fila.custom_minimum_size.y = 110

		var tex_rect = TextureRect.new()
		var ruta_imagen = InventarioUIFactory.TEXTURAS_PRODUCTOS.get(producto, InventarioUIFactory.TEXTURA_DEFAULT)
		
		if ResourceLoader.exists(ruta_imagen):
			tex_rect.texture = load(ruta_imagen)
		else:
			tex_rect.texture = load(InventarioUIFactory.TEXTURA_DEFAULT)
			
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex_rect.custom_minimum_size = Vector2(ANCHO_COL_IMAGEN, 96)
		tex_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tex_rect.mouse_filter = Control.MOUSE_FILTER_STOP
		tex_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		tex_rect.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				var inventario_menu = get_tree().current_scene.find_child("InventarioMenu", true, false)
				if inventario_menu and inventario_menu.has_method("mostrar_popup_imagen"):
					inventario_menu.mostrar_popup_imagen(tex_rect.texture, producto)
		)

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
			texto_precio += " (-25%)"
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
		
		selector_cantidad.value_changed.connect(func(nueva_cantidad):
			var costo_calculado = precio_unitario * nueva_cantidad
			lbl_total.text = "Total: $" + str(snapped(costo_calculado, 0.01))
		)
		
		var btn_comprar = Button.new()
		btn_comprar.text = "Comprar"
		btn_comprar.custom_minimum_size = Vector2(110, 45)
		btn_comprar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn_comprar.add_theme_font_size_override("font_size", font_size_datos)
		
		if espacio_disponible <= 0:
			btn_comprar.disabled = true
			selector_cantidad.editable = false
		
		btn_comprar.pressed.connect(func(): 
			var cantidad = int(selector_cantidad.value)
			procesar_compra(producto, precio_unitario, cantidad)
		)
		
		fila.add_child(tex_rect)
		fila.add_child(lbl_nombre)
		fila.add_child(lbl_stock)
		fila.add_child(lbl_precio)
		fila.add_child(selector_cantidad)
		fila.add_child(lbl_total)
		fila.add_child(btn_comprar)
		
		lista_productos_mayorista.add_child(fila)

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
		actualizar_catalogo()
		compra_realizada.emit()
	else:
		print("Dinero insuficiente en caja chica.")

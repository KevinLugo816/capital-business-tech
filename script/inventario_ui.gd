class_name InventarioUIFactory
extends Node

static func crear_fila_producto(
	producto: String,
	stock_actual: int,
	precio_actual: float,
	marca: String,
	font_size: int,
	anchos: Dictionary,
	on_precio_cambiado: Callable,
	on_imagen_clicada: Callable,
	local_abierto: bool = false
) -> HBoxContainer:

	var fila = HBoxContainer.new()
	fila.add_theme_constant_override("separation", anchos.get("separacion", 20))
	fila.custom_minimum_size.y = 110

	var tex_rect = TextureRect.new()
	tex_rect.texture = Inventario.obtener_textura_producto(producto)

	tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.custom_minimum_size = Vector2(anchos.get("imagen", 120), 96)
	tex_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	tex_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	tex_rect.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	tex_rect.gui_input.connect(
		func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if on_imagen_clicada.is_valid():
					on_imagen_clicada.call(tex_rect.texture, producto)
	)

	fila.add_child(tex_rect)

	var lbl_nombre = Label.new()
	lbl_nombre.text = producto
	lbl_nombre.custom_minimum_size.x = anchos.get("producto", 240)
	lbl_nombre.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_nombre.add_theme_font_size_override("font_size", font_size)
	lbl_nombre.add_theme_constant_override("outline_size", 5)
	lbl_nombre.add_theme_color_override("font_outline_color", Color.BLACK)
	fila.add_child(lbl_nombre)

	var lbl_marca = Label.new()
	lbl_marca.text = marca
	lbl_marca.custom_minimum_size.x = anchos.get("marca", 160)
	lbl_marca.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_marca.add_theme_font_size_override("font_size", font_size)
	lbl_marca.add_theme_constant_override("outline_size", 5)
	lbl_marca.add_theme_color_override("font_outline_color", Color.BLACK)
	fila.add_child(lbl_marca)

	var lbl_stock = Label.new()
	lbl_stock.text = str(stock_actual) + " un."
	lbl_stock.custom_minimum_size.x = anchos.get("stock", 100)
	lbl_stock.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_stock.add_theme_font_size_override("font_size", font_size)
	lbl_stock.add_theme_constant_override("outline_size", 5)
	lbl_stock.add_theme_color_override("font_outline_color", Color.BLACK)
	
	if stock_actual == 0:
		lbl_stock.add_theme_color_override("font_color", Color("e74c3c"))
	elif stock_actual <= 3:
		lbl_stock.add_theme_color_override("font_color", Color("f1c40f"))
	else:
		lbl_stock.add_theme_color_override("font_color", Color.WHITE)
	fila.add_child(lbl_stock)

	var contenedor_precio = HBoxContainer.new()
	contenedor_precio.custom_minimum_size.x = anchos.get("precio", 200)
	contenedor_precio.alignment = BoxContainer.ALIGNMENT_BEGIN
	
	var lbl_signo = Label.new()
	lbl_signo.text = "$ "
	lbl_signo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_signo.add_theme_font_size_override("font_size", font_size)
	lbl_signo.add_theme_constant_override("outline_size", 5)
	lbl_signo.add_theme_color_override("font_outline_color", Color.BLACK)
	
	var selector_precio = SpinBox.new()
	selector_precio.min_value = 1.0
	selector_precio.max_value = 2000.0
	selector_precio.step = 0.5
	selector_precio.value = precio_actual
	selector_precio.custom_minimum_size = Vector2(120, 50)
	selector_precio.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	selector_precio.get_line_edit().add_theme_font_size_override("font_size", font_size)
	
	if local_abierto:
		selector_precio.editable = false
		selector_precio.tooltip_text = "No puedes cambiar precios con el local abierto."
	
	contenedor_precio.add_child(lbl_signo)
	contenedor_precio.add_child(selector_precio)
	fila.add_child(contenedor_precio)

	var lbl_advertencia = Label.new()
	lbl_advertencia.custom_minimum_size.x = anchos.get("alerta", 380)
	lbl_advertencia.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_advertencia.add_theme_font_size_override("font_size", 20)
	lbl_advertencia.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl_advertencia.add_theme_constant_override("outline_size", 3)
	lbl_advertencia.add_theme_color_override("font_outline_color", Color.BLACK)
	fila.add_child(lbl_advertencia)

	selector_precio.value_changed.connect(
		func(nuevo_valor: float):
			if on_precio_cambiado.is_valid():
				on_precio_cambiado.call(producto, nuevo_valor, lbl_advertencia)
	)

	return fila

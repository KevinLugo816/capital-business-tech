extends Node2D

@onready var spawn_clientes = $Entorno/SpawnClte
@onready var menu_recepcion = $UI/Menu
@onready var texto_pedido = $UI/Menu/PanelDialogo/TextoPedido
@onready var panel_previa = $UI/Menu/PanelPrevia
@onready var imagen_producto = $UI/Menu/PanelPrevia/VBoxContainer/ImagenProd
@onready var label_stock = $UI/Menu/PanelPrevia/VBoxContainer/LabelStock

@onready var label_dinero = $UI/TopBar/HBoxContainer/LabelDinero
@onready var label_dia = $UI/TopBar/HBoxContainer/LabelDia
@onready var label_inflacion = $UI/TopBar/HBoxContainer/LabelInflacion
@onready var label_reputacion = $UI/TopBar/HBoxContainer/LabelReputacion
@onready var boton_abrir_local = $UI/BtnComenzar
@onready var label_estado_local = $UI/LblEstadoLocal
@onready var boton_monitor = $UI/BotonMonitor
@onready var boton_inventario = $UI/BotonInventario

const CLIENTE_ESCENA = preload("res://escena/clientes.tscn")
const INVENTARIO_MENU_ESCENA = preload("res://escena/inventario_menu.tscn")
const BALANCE_ESCENA = preload("res://escena/balance.tscn")
const MONITOR_ESCENA = preload("res://escena/monitor_virtual.tscn")

var clientes_atendidos_hoy: int = 0
var max_clientes_hoy: int = 5
var cliente_actual: Node2D = null
var datos_venta_actual: Dictionary = {}

var monitor_instancia: CanvasLayer = null
var local_abierto: bool = false
var receso_realizado: bool = false
var respuesta_en_proceso: bool = false

func _ready() -> void:
	menu_recepcion.hide()
	
	EconomiaGlobal.dinero_cambiado.connect(_on_dinero_cambiado)
	EconomiaGlobal.inflacion_cambiada.connect(_on_inflacion_cambiada)
	Inventario.inventario_actualizado.connect(_on_inventario_actualizado)
	
	if EconomiaGlobal.has_signal("reputacion_cambiada"):
		EconomiaGlobal.reputacion_cambiada.connect(_on_reputacion_cambiada)
	
	actualizar_ui()
	
	local_abierto = false
	
	label_estado_local.text = "TIENDA CERRADA (Presiona Abrir Local)"
	label_estado_local.show()
	
	boton_abrir_local.text = "Abrir Local"
	boton_abrir_local.show()

func _on_boton_abrir_local_pressed() -> void:
	if local_abierto:
		return
		
	local_abierto = true
	boton_abrir_local.hide()
	label_estado_local.hide()
	
	await get_tree().create_timer(1.5).timeout
	
	if local_abierto:
		generar_cliente()

func generar_cliente() -> void:
	if not local_abierto:
		return

	cliente_actual = CLIENTE_ESCENA.instantiate()
	spawn_clientes.add_child(cliente_actual)
	AudioManager.reproducir_timbre()
	
	cliente_actual.paciencia_agotada.connect(_on_cliente_paciencia_agotada)
	cliente_actual.iniciar_espera()
	
	datos_venta_actual = cliente_actual.generar_solicitud_compra()
	respuesta_en_proceso = false
	actualizar_interfaz_dialogo()

func actualizar_interfaz_dialogo() -> void:
	if datos_venta_actual.is_empty():
		return

	var producto = datos_venta_actual["producto"]
	var cantidad = datos_venta_actual["cantidad"]
	var total_dinero = datos_venta_actual["total"]

	var mensaje = "Cliente: ¡Hola! Me gustaría comprar:\n"
	mensaje += "- " + str(cantidad) + "x [color=#ffde21]" + producto + "[/color]\n"
	mensaje += "Total a Pagar: [color=#2ecc71]$" + str(snapped(total_dinero, 0.01)) + "[/color]"

	texto_pedido.text = mensaje

	var stock_actual = Inventario.obtener_cantidad(producto)
	if Inventario.has_method("obtener_textura_producto"):
		imagen_producto.texture = Inventario.obtener_textura_producto(producto)

	label_stock.text = "Stock: " + str(stock_actual)
	
	if stock_actual >= cantidad:
		label_stock.add_theme_color_override("font_color", Color("2ecc71"))
	else:
		label_stock.add_theme_color_override("font_color", Color("e74c3c"))

	menu_recepcion.show()

func _on_button_aceptar_pressed() -> void:
	if respuesta_en_proceso:
		return
	respuesta_en_proceso = true

	menu_recepcion.hide()
	
	var producto = datos_venta_actual["producto"]
	var cantidad = datos_venta_actual["cantidad"]
	var ingreso = datos_venta_actual["total"]
	var esta_especulando = datos_venta_actual["especulando"]
	
	if not Inventario.tiene_producto(producto, cantidad):
		print("Venta fallida por falta de stock.")
		EconomiaGlobal.reputacion -= 5
		_actualizar_label_reputacion(EconomiaGlobal.reputacion)
		AnimUiManager.animar_reputacion(-5, label_reputacion.global_position + Vector2(10, 20))
		
		despachar_cliente()
		return

	if esta_especulando:
		print("¡El cliente se dio cuenta del sobreprecio y canceló la compra!")
		EconomiaGlobal.reputacion -= 15 
		_actualizar_label_reputacion(EconomiaGlobal.reputacion)
		AnimUiManager.animar_reputacion(-15, label_reputacion.global_position + Vector2(10, 20))
		
		texto_pedido.text = "Cliente: [color=#e74c3c]¡Qué abuso! Ese precio es ridículamente alto. ¡No pienso comprar aquí![/color]"
		menu_recepcion.show()
		
		if is_instance_valid(cliente_actual) and cliente_actual.has_method("detener_espera"):
			cliente_actual.detener_espera()

		await get_tree().create_timer(2.0).timeout
		menu_recepcion.hide()
		despachar_cliente()

	else:
		Inventario.modificar_stock(producto, -cantidad)
		EconomiaGlobal.registrar_ingreso_venta(ingreso)
		AudioManager.reproducir_ingreso()
		AnimUiManager.animar_dinero(ingreso, label_dinero.global_position + Vector2(10, 20))
		
		var iva_retenido = datos_venta_actual["iva"]
		EconomiaGlobal.iva_acumulado_hoy += iva_retenido
		
		var precio_justo_total = datos_venta_actual["precio_justo"] * cantidad
		var cambio_rep = 0
		
		if ingreso <= (precio_justo_total * 0.85):
			cambio_rep = 8
		else:
			cambio_rep = 2
			print("Venta procesada con éxito")
			
		var rep_antes = EconomiaGlobal.reputacion
		
		EconomiaGlobal.reputacion += cambio_rep
		_actualizar_label_reputacion(EconomiaGlobal.reputacion)
		
		if EconomiaGlobal.reputacion > rep_antes or cambio_rep < 0:
			AnimUiManager.animar_reputacion(cambio_rep, label_reputacion.global_position + Vector2(10, 20))

		despachar_cliente()

func _on_button_rechazar_pressed() -> void:
	if respuesta_en_proceso:
		return
	respuesta_en_proceso = true

	menu_recepcion.hide()
	print("El jugador rechazó la oferta voluntariamente.")
	EconomiaGlobal.reputacion -= 1
	_actualizar_label_reputacion(EconomiaGlobal.reputacion)
	AnimUiManager.animar_reputacion(-1, label_reputacion.global_position + Vector2(10, 20))
	
	despachar_cliente()

func despachar_cliente() -> void:
	if is_instance_valid(cliente_actual):
		if cliente_actual.paciencia_agotada.is_connected(_on_cliente_paciencia_agotada):
			cliente_actual.paciencia_agotada.disconnect(_on_cliente_paciencia_agotada)
			
		if cliente_actual.has_method("detener_espera"):
			cliente_actual.detener_espera()
		cliente_actual.queue_free()
		cliente_actual = null

	datos_venta_actual.clear()
	clientes_atendidos_hoy += 1
	
	var mitad_dia = int(round(max_clientes_hoy / 2.0))
	if clientes_atendidos_hoy == mitad_dia and not receso_realizado:
		receso_realizado = true
		local_abierto = false
		print("--- Receso de Mediodía Alcanzado ---")
		
		await get_tree().create_timer(1.5).timeout
		label_estado_local.text = "RECESO DE MEDIODÍA (Aprovecha para ajustar precios o reponer stock)"
		label_estado_local.show()
		
		boton_abrir_local.text = "Reabrir Local"
		boton_abrir_local.show()
		return

	if clientes_atendidos_hoy >= max_clientes_hoy:
		print("Jornada laboral finalizada.")
		local_abierto = false
		
		if is_instance_valid(boton_monitor):
			boton_monitor.disabled = true
		if is_instance_valid(boton_inventario):
			boton_inventario.disabled = true
		
		label_estado_local.text = "JORNADA FINALIZADA"
		label_estado_local.show()
		
		await get_tree().create_timer(2.0).timeout
		EconomiaGlobal.simular_inflacion_diaria()

		var balance_instancia = BALANCE_ESCENA.instantiate()
		balance_instancia.dia_finalizado.connect(_on_nuevo_dia_iniciado)
		add_child(balance_instancia)
		balance_instancia.mostrar_balance(EconomiaGlobal.dia_actual, clientes_atendidos_hoy, max_clientes_hoy)
	else:
		var factor_espera = 1.0 + ((100 - EconomiaGlobal.reputacion) / 20.0)
		var tiempo_espera = randf_range(1.5, 4.0) * factor_espera

		await get_tree().create_timer(tiempo_espera).timeout
		if local_abierto:
			generar_cliente()

func _on_cliente_paciencia_agotada(_cliente: Node2D) -> void:
	if respuesta_en_proceso:
		return
	respuesta_en_proceso = true

	print("¡El cliente perdió la paciencia y se fue!")
	menu_recepcion.hide()

	EconomiaGlobal.reputacion -= 5
	_actualizar_label_reputacion(EconomiaGlobal.reputacion)

	AnimUiManager.animar_reputacion(-5, label_reputacion.global_position + Vector2(10, 20))
	despachar_cliente()

func _on_boton_monitor_pressed() -> void:
	if not is_instance_valid(monitor_instancia):
		monitor_instancia = MONITOR_ESCENA.instantiate()
		add_child(monitor_instancia)
	else:
		monitor_instancia.show()
		if monitor_instancia.has_method("ir_al_home"):
			monitor_instancia.ir_al_home()

func _on_boton_inventario_pressed() -> void:
	var inv_instancia = INVENTARIO_MENU_ESCENA.instantiate()
	add_child(inv_instancia)

func actualizar_ui() -> void:
	_on_dinero_cambiado(EconomiaGlobal.dinero)
	_on_inflacion_cambiada(EconomiaGlobal.tasa_inflacion)
	_actualizar_label_reputacion(EconomiaGlobal.reputacion)
	label_dia.text = "Día: " + str(EconomiaGlobal.dia_actual)

func _on_dinero_cambiado(nuevo_monto: float) -> void:
	label_dinero.text = "Dinero: $" + str(snapped(nuevo_monto, 0.01))

func _on_inflacion_cambiada(nueva_tasa: float) -> void:
	var porcentaje = nueva_tasa * 100
	label_inflacion.text = "Inflación: " + str(snapped(porcentaje, 0.1)) + "%"

func _on_inventario_actualizado() -> void:
	if menu_recepcion.visible and not datos_venta_actual.is_empty():
		actualizar_interfaz_dialogo()

func _on_reputacion_cambiada(nueva_rep: int) -> void:
	_actualizar_label_reputacion(nueva_rep)

func _actualizar_label_reputacion(nueva_rep: int) -> void:
	label_reputacion.text = "Fama: " + str(nueva_rep) + "%"

func _on_nuevo_dia_iniciado() -> void:
	if is_instance_valid(monitor_instancia):
		monitor_instancia.queue_free()
		monitor_instancia = null

	for hijo in get_children():
		if hijo.has_signal("dia_finalizado") or hijo.has_method("mostrar_balance"):
			hijo.queue_free()

	EconomiaGlobal.iniciar_nuevo_dia()
	label_dia.text = "Día: " + str(EconomiaGlobal.dia_actual)
	clientes_atendidos_hoy = 0
	receso_realizado = false
	
	if EconomiaGlobal.reputacion > 70:
		max_clientes_hoy = randi_range(6, 8)
	elif EconomiaGlobal.reputacion < 40:
		max_clientes_hoy = randi_range(2, 4)
	else:
		max_clientes_hoy = 5
		
	print("Nueva jornada comenzada. Clientes esperados hoy: ", max_clientes_hoy)
	
	if is_instance_valid(boton_monitor):
		boton_monitor.disabled = false
	if is_instance_valid(boton_inventario):
		boton_inventario.disabled = false
	
	local_abierto = false
	
	label_estado_local.text = "TIENDA CERRADA"
	label_estado_local.show()
	
	boton_abrir_local.text = "Abrir Local"
	boton_abrir_local.show()

extends Node2D

signal paciencia_agotada(cliente)

@onready var sprite_cliente = $Sprite2D
@onready var timer_paciencia: Timer = $PatienceTimer
@onready var progress_bar: ProgressBar = $ProgressBar

@export var variaciones_clientes: Array[Texture2D] = [
	preload("res://sprite/personajes/cliente_1.png"),
	preload("res://sprite/personajes/cliente_2.png"),
	preload("res://sprite/personajes/cliente_3.png"),
	preload("res://sprite/personajes/cliente_4.png")
]

@export var tiempo_espera: float = 60.0

var producto_solicitado: String = ""
var cantidad_solicitada: int = 1
var precio_historico_base: float = 0.0
var fue_atendido: bool = false
var style_fill: StyleBoxFlat

var catalogo_productos = [
	{"nombre": "Memoria RAM 8GB", "precio_base": 20.0},
	{"nombre": "Disco SSD 480GB", "precio_base": 25.0},
	{"nombre": "Cargador Tipo C", "precio_base": 7.0},
	{"nombre": "Teléfono Gama Baja", "precio_base": 80.0}
]

func _ready() -> void:
	asignar_aspecto_aleatorio()
	
	if timer_paciencia:
		timer_paciencia.wait_time = tiempo_espera
		timer_paciencia.one_shot = true
		timer_paciencia.timeout.connect(_on_paciencia_timeout)

	if progress_bar:
		progress_bar.max_value = 100.0
		progress_bar.value = 100.0
		
		style_fill = StyleBoxFlat.new()
		style_fill.corner_radius_top_left = 4
		style_fill.corner_radius_top_right = 4
		style_fill.corner_radius_bottom_left = 4
		style_fill.corner_radius_bottom_right = 4
		
		progress_bar.add_theme_stylebox_override("fill", style_fill)

func _process(_delta: float) -> void:
	if progress_bar and timer_paciencia and not timer_paciencia.is_stopped():
		var porcentaje = (timer_paciencia.time_left / tiempo_espera) * 100.0
		progress_bar.value = porcentaje
		
		if style_fill:
			if porcentaje > 50.0:
				style_fill.bg_color = Color("2ecc71")
			elif porcentaje > 20.0:
				style_fill.bg_color = Color("f1c40f")
			else:
				style_fill.bg_color = Color("e74c3c")

func iniciar_espera() -> void:
	if timer_paciencia:
		timer_paciencia.start()

func detener_espera() -> void:
	fue_atendido = true
	if timer_paciencia:
		timer_paciencia.stop()

func _on_paciencia_timeout() -> void:
	if not fue_atendido:
		paciencia_agotada.emit(self)

func asignar_aspecto_aleatorio() -> void:
	if variaciones_clientes.size() > 0:
		var imagen_elegida = variaciones_clientes.pick_random()
		sprite_cliente.texture = imagen_elegida
	else:
		print("Advertencia: No hay texturas asignadas en variaciones_clientes.")

func generar_solicitud_compra() -> Dictionary:
	var producto_azar = catalogo_productos.pick_random()
	producto_solicitado = producto_azar["nombre"]
	precio_historico_base = producto_azar["precio_base"]
	
	cantidad_solicitada = randi_range(1, 2) 
	
	var precio_justo_inflado = precio_historico_base * (1.0 + EconomiaGlobal.tasa_inflacion)
	var precio_justo_con_iva = precio_justo_inflado * (1.0 + EconomiaGlobal.tasa_iva)
	
	var factor_tolerancia = 1.15 if EconomiaGlobal.reputacion > 75 else 1.05
	var precio_maximo_aceptable_unitario = precio_justo_con_iva * factor_tolerancia
	
	var presupuesto_maximo_total = precio_maximo_aceptable_unitario * cantidad_solicitada
	
	var precio_jugador_base = Inventario.precios_venta_publico[producto_solicitado]
	var iva_por_unidad = precio_jugador_base * EconomiaGlobal.tasa_iva
	var precio_jugador_neto_unitario = precio_jugador_base + iva_por_unidad
	
	var total_pedido_jugador = precio_jugador_neto_unitario * cantidad_solicitada
	var total_iva_pedido = iva_por_unidad * cantidad_solicitada
	
	var es_especulacion: bool = total_pedido_jugador > presupuesto_maximo_total
	
	return {
		"producto": producto_solicitado,
		"cantidad": cantidad_solicitada,
		"subtotal": precio_jugador_base * cantidad_solicitada,
		"iva": total_iva_pedido,
		"total": total_pedido_jugador,
		"precio_justo": precio_justo_inflado,
		"especulando": es_especulacion
	}

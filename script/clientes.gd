extends Node2D

signal paciencia_agotada(cliente)

@onready var sprite_cliente = $Sprite2D
@onready var timer_paciencia: Timer = $PatienceTimer
@onready var progress_bar: ProgressBar = $ProgressBar

enum TipoPerfil { NORMAL, APURADO, TACAÑO, EXIGENTE }
var perfil_actual: TipoPerfil = TipoPerfil.NORMAL

@export var sprites_por_perfil: Dictionary = {
	TipoPerfil.NORMAL: [
		preload("res://sprite/personajes/cliente_3.png"),
		preload("res://sprite/personajes/cliente_4.png")
	],
	TipoPerfil.APURADO: [
		preload("res://sprite/personajes/cliente_5.png"),
		preload("res://sprite/personajes/cliente_6.png")
	],
	TipoPerfil.TACAÑO: [
		preload("res://sprite/personajes/cliente_1.png"),
		preload("res://sprite/personajes/cliente_4.png")
	],
	TipoPerfil.EXIGENTE: [
		preload("res://sprite/personajes/cliente_1.png"),
		preload("res://sprite/personajes/cliente_2.png")
	]
}

const DIALOGOS = {
	TipoPerfil.NORMAL: {
		"saludo": [
			"¿Qué tal?, Vengo a buscar algo rápido:\n",
			"¡Hola! ¿tendrán disponible esto?\n",
			"¡Hola! Necesito comprar lo siguiente:\n"
		],
		"queja_precio": "¡Uy, no! Me parece un abuso ese costo, mejor busco en otra parte.",
		"paciencia": "Disculpa, pero se me hace tarde. Me voy."
	},
	TipoPerfil.APURADO: {
		"saludo": [
			"¡Tengo prisa! Atiéndeme esto por favor:\n",
			"¡Buenas! Voy con el tiempo encima, necesito rápido esto:\n",
			"Oye, ¿tienes esto a la mano? Ando con prisa:\n"
		],
		"queja_precio": "¡Encima de que me haces esperar me quieres cobrar eso! ¡Me voy!",
		"paciencia": "¡No puedo perder más tiempo aquí! Adiós."
	},
	TipoPerfil.TACAÑO: {
		"saludo": [
			"Buenas... Espero que tengan buenos precios para esto:\n",
			"Hola, ando buscando esto, pero no pienso pagar una fortuna:\n",
			"Saludos. ¿A cuánto me dejas esto?\n"
		],
		"queja_precio": "¡Qué descaro! Ese precio es un robo a mano armada.",
		"paciencia": "Demasiada espera para lo cara que se ve la tienda. Me retiro."
	},
	TipoPerfil.EXIGENTE: {
		"saludo": [
			"Hola, busco productos de calidad. ¿Tienen esto?\n",
			"Buenas, requiero esto para un trabajo importante:\n"
		],
		"queja_precio": "La calidad no justifica este margen excesivo. Buscaré un negocio más razonable.",
		"paciencia": "La atención al cliente aquí deja mucho que desear. Me marcho."
	}
}

var tiempo_espera_base: float = 60.0
var tiempo_espera_real: float = 60.0

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
	asignar_aspecto_y_perfil_aleatorio()
	_configurar_paciencia()
	_configurar_barra_ui()

func asignar_aspecto_y_perfil_aleatorio() -> void:
	var roll = randf()
	if roll < 0.25:
		perfil_actual = TipoPerfil.APURADO
	elif roll < 0.50:
		perfil_actual = TipoPerfil.TACAÑO
	elif roll < 0.70:
		perfil_actual = TipoPerfil.EXIGENTE
	else:
		perfil_actual = TipoPerfil.NORMAL

	if sprites_por_perfil.has(perfil_actual):
		var opciones_sprite: Array = sprites_por_perfil[perfil_actual]
		if opciones_sprite.size() > 0:
			sprite_cliente.texture = opciones_sprite.pick_random()

func _configurar_paciencia() -> void:
	match perfil_actual:
		TipoPerfil.APURADO:
			tiempo_espera_real = tiempo_espera_base * 0.4
		TipoPerfil.EXIGENTE:
			tiempo_espera_real = tiempo_espera_base * 0.8
		TipoPerfil.TACAÑO, TipoPerfil.NORMAL:
			tiempo_espera_real = tiempo_espera_base
			
	if timer_paciencia:
		timer_paciencia.wait_time = tiempo_espera_real
		timer_paciencia.one_shot = true
		if not timer_paciencia.timeout.is_connected(_on_paciencia_timeout):
			timer_paciencia.timeout.connect(_on_paciencia_timeout)

func _configurar_barra_ui() -> void:
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
		var porcentaje = (timer_paciencia.time_left / tiempo_espera_real) * 100.0
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

func obtener_frase_saludo() -> String:
	var lista = DIALOGOS[perfil_actual]["saludo"]
	return lista.pick_random()

func obtener_frase_queja() -> String:
	return DIALOGOS[perfil_actual]["queja_precio"]

func obtener_frase_paciencia() -> String:
	return DIALOGOS[perfil_actual]["paciencia"]

func generar_solicitud_compra() -> Dictionary:
	var producto_azar = catalogo_productos.pick_random()
	producto_solicitado = producto_azar["nombre"]
	precio_historico_base = producto_azar["precio_base"]
	
	cantidad_solicitada = randi_range(1, 2)
	
	var precio_justo_inflado = precio_historico_base * (1.0 + EconomiaGlobal.tasa_inflacion)
	var precio_justo_con_iva = precio_justo_inflado * (1.0 + EconomiaGlobal.tasa_iva)
	
	var factor_tolerancia = 1.05
	if EconomiaGlobal.reputacion > 75:
		factor_tolerancia = 1.15
		
	match perfil_actual:
		TipoPerfil.TACAÑO:
			factor_tolerancia -= 0.05
		TipoPerfil.APURADO:
			factor_tolerancia += 0.08
		TipoPerfil.EXIGENTE:
			factor_tolerancia -= 0.02

	var precio_maximo_aceptable_unitario = precio_justo_con_iva * max(0.95, factor_tolerancia)
	var presupuesto_maximo_total = precio_maximo_aceptable_unitario * cantidad_solicitada
	
	var precio_jugador_base = Inventario.precios_venta_publico.get(producto_solicitado, precio_historico_base)
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
		"especulando": es_especulacion,
		"perfil": perfil_actual
	}

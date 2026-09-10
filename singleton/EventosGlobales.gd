extends Node

signal evento_activado(titulo: String, descripcion: String, tipo: String)

var evento_activo: Dictionary = {}

const DIA_INICIO_EVENTOS: int = 5

var catalogo_eventos: Array[Dictionary] = [
	{
		"id": "subsidio_estatal",
		"titulo": "SUBSIDIO COMERCIAL",
		"descripcion": "El gobierno aprobó un estímulo comercial. Los servicios básicos se reducen a la mitad por hoy.",
		"tipo": "oferta",
		"probabilidad": 0.20,
		"icono_tipo": "OFERTA",
		"dia_minimo": 5
	},
	{
		"id": "escasez_importacion",
		"titulo": "CRISIS DE IMPORTACIONES",
		"descripcion": "Retrasos en las aduanas han generado escasez de componentes electrónicos. La demanda en tienda aumentó.",
		"tipo": "alerta",
		"probabilidad": 0.20,
		"icono_tipo": "ALERTA",
		"dia_minimo": 6
	},
	{
		"id": "hiperinflacion",
		"titulo": "¡ESPIRAL INFLACIONARIA!",
		"descripcion": "Una ola especulativa dispara los precios. La inflación diaria aumenta bruscamente un [color=#e74c3c]+12%[/color].",
		"tipo": "alerta",
		"probabilidad": 0.10,
		"icono_tipo": "INFLACION",
		"dia_minimo": 10
	}
]

func evaluar_evento_del_dia() -> void:
	evento_activo.clear()
	
	if EconomiaGlobal.dia_actual < DIA_INICIO_EVENTOS:
		print("Día %d: Fase tutorial/inicial. Sin eventos económicos." % EconomiaGlobal.dia_actual)
		return

	var eventos_disponibles: Array[Dictionary] = []
	var peso_total: float = 0.0
	
	for evento in catalogo_eventos:
		if EconomiaGlobal.dia_actual >= evento.get("dia_minimo", 1):
			eventos_disponibles.append(evento)
			peso_total += evento.get("probabilidad", 0.1)

	if eventos_disponibles.is_empty():
		return

	if randf() <= 0.40:
		var evento_elegido = _seleccionar_evento_ponderado(eventos_disponibles, peso_total)
		if not evento_elegido.is_empty():
			_aplicar_efectos_evento(evento_elegido)
	else:
		print("Día %d: Mercado estable, sin eventos hoy." % EconomiaGlobal.dia_actual)

func _seleccionar_evento_ponderado(lista: Array[Dictionary], peso_total: float) -> Dictionary:
	var roll = randf_range(0.0, peso_total)
	var acumulado = 0.0
	
	for evento in lista:
		acumulado += evento.get("probabilidad", 0.1)
		if roll <= acumulado:
			return evento
			
	return lista.pick_random() if not lista.is_empty() else {}

func _aplicar_efectos_evento(evento: Dictionary) -> void:
	if evento.is_empty():
		return
		
	evento_activo = evento
	
	match evento.get("id", ""):
		"hiperinflacion":
			EconomiaGlobal.inflacion_extra_evento = 0.12
			EconomiaGlobal.tasa_inflacion += EconomiaGlobal.inflacion_extra_evento
		"escasez_importacion":
			EconomiaGlobal.reputacion = clampi(EconomiaGlobal.reputacion + 5, 0, 100)
		"subsidio_estatal":
			EconomiaGlobal.multiplicador_servicios_evento = 0.5
		_:
			print("Advertencia: Se intentó aplicar un evento sin ID válido.")
			return
			
	print("EVENTO ACTIVADO (Día %d): %s" % [EconomiaGlobal.dia_actual, evento.get("titulo", "")])
	evento_activado.emit(evento.get("titulo", ""), evento.get("descripcion", ""), evento.get("tipo", ""))

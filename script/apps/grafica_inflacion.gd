extends Control

@export_category("Configuración de Gráfica")
@export var dias_visibles: int = 15
@export var color_linea: Color = Color("#e74c3c")
@export var color_relleno: Color = Color(0.90, 0.30, 0.23, 0.15) # Sombra visual profesional
@export var color_red: Color = Color(1, 1, 1, 0.12)
@export var color_texto: Color = Color(0.8, 0.8, 0.8, 0.7)
@export var grosor_linea: float = 3.5

const MARGEN_IZQUIERDO: float = 45.0
const MARGEN_INFERIOR: float = 25.0
const MARGEN_SUPERIOR: float = 20.0
const MARGEN_DERECHO: float = 20.0

var fuente_default: Font

func _ready() -> void:
	fuente_default = ThemeDB.fallback_font
	
	if EconomiaGlobal.has_signal("nuevo_dia_comenzado"):
		EconomiaGlobal.nuevo_dia_comenzado.connect(_on_actualizar)
	if EconomiaGlobal.has_signal("inflacion_cambiada"):
		EconomiaGlobal.inflacion_cambiada.connect(_on_actualizar_inflacion)
	
	visibility_changed.connect(_on_visibility_changed)

func _exit_tree() -> void:
	if EconomiaGlobal.has_signal("nuevo_dia_comenzado") and EconomiaGlobal.nuevo_dia_comenzado.is_connected(_on_actualizar):
		EconomiaGlobal.nuevo_dia_comenzado.disconnect(_on_actualizar)
	if EconomiaGlobal.has_signal("inflacion_cambiada") and EconomiaGlobal.inflacion_cambiada.is_connected(_on_actualizar_inflacion):
		EconomiaGlobal.inflacion_cambiada.disconnect(_on_actualizar_inflacion)

func _on_actualizar() -> void:
	if is_visible_in_tree():
		queue_redraw()

func _on_actualizar_inflacion(_nueva_tasa: float) -> void:
	if is_visible_in_tree():
		queue_redraw()

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		queue_redraw()

func _draw() -> void:
	var historial_completo: Array[float] = EconomiaGlobal.historial_inflacion
	
	if historial_completo.is_empty():
		return

	var ancho_util: float = size.x - MARGEN_IZQUIERDO - MARGEN_DERECHO
	var alto_util: float = size.y - MARGEN_SUPERIOR - MARGEN_INFERIOR

	var inicio_corte: int = max(0, historial_completo.size() - dias_visibles)
	var datos: Array[float] = historial_completo.slice(inicio_corte)

	# --- ESCALADO DINÁMICO DEL EJE Y ---
	var max_valor: float = 0.10 # Mínimo escala del 10%
	for val in datos:
		if val > max_valor:
			max_valor = val
	max_valor *= 1.15 # Añade un 15% de holgura superior para que la gráfica respire

	# --- DIBUJAR LÍNEAS DE GUÍA Y EJE Y ---
	var lineas_guia: int = 4
	for i in range(lineas_guia + 1):
		var porcentaje_nivel: float = 1.0 - (float(i) / float(lineas_guia))
		var y_pos: float = MARGEN_SUPERIOR + (alto_util * (1.0 - porcentaje_nivel))
		
		draw_line(Vector2(MARGEN_IZQUIERDO, y_pos), Vector2(size.x - MARGEN_DERECHO, y_pos), color_red, 1.0)
		
		var valor_porcentaje: float = max_valor * porcentaje_nivel * 100.0
		var texto_porcentaje: String = str(snapped(valor_porcentaje, 0.1)) + "%"
		draw_string(fuente_default, Vector2(5.0, y_pos + 4.0), texto_porcentaje, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, color_texto)

	# --- CASO DE UN SÓLO DÍA / DATO ---
	if datos.size() < 2:
		var valor_porcentaje = clampf(datos[0] / max_valor, 0.0, 1.0)
		var y_pos: float = (MARGEN_SUPERIOR + alto_util) - (valor_porcentaje * alto_util)
		var p_inicio := Vector2(MARGEN_IZQUIERDO, y_pos)
		var p_fin := Vector2(size.x - MARGEN_DERECHO, y_pos)
		
		draw_line(p_inicio, p_fin, color_linea, grosor_linea)
		draw_circle(p_inicio, 5.0, color_linea)
		draw_circle(p_fin, 5.0, color_linea)
		return

	# --- CÁLCULO DE PUNTOS Y TRAZADO ---
	var puntos: PackedVector2Array = []
	var margen_x: float = ancho_util / float(datos.size() - 1)

	for i in range(datos.size()):
		var x_pos: float = MARGEN_IZQUIERDO + (float(i) * margen_x)
		var porcentaje_alto: float = clampf(datos[i] / max_valor, 0.0, 1.0)
		var y_pos: float = (MARGEN_SUPERIOR + alto_util) - (porcentaje_alto * alto_util)
		
		puntos.append(Vector2(x_pos, y_pos))

	# --- RELLENO SOMBREADO BAJO LA CURVA ---
	var puntos_poligono := PackedVector2Array(puntos)
	puntos_poligono.append(Vector2(puntos[-1].x, MARGEN_SUPERIOR + alto_util))
	puntos_poligono.append(Vector2(puntos[0].x, MARGEN_SUPERIOR + alto_util))
	draw_colored_polygon(puntos_poligono, color_relleno)

	# --- LÍNEA Y PUNTOS DE LA GRÁFICA ---
	draw_polyline(puntos, color_linea, grosor_linea, true)

	for punto in puntos:
		draw_circle(punto, 5.0, color_linea)
		draw_circle(punto, 2.5, Color.WHITE)

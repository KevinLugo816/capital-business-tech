extends Node

const RUTA_GUARDADO = "user://partida_guardada.json"

# --- CONFIGURACIONES Y PREFERENCIAS ---
var fondo_monitor: String = "azul"
var volumen_musica: float = 50.0
var volumen_sfx: float = 50.0

# --- DATOS DEL PERFIL DEL JUGADOR ---
var perfil_jugador: Dictionary = {
	"nombre_jugador": "",
	"nombre_tienda": "",
	"edad": 20,
	"genero": "Masculino",
	"avatar_ruta": "res://sprite/iconos/avatar/avatar_1.png"
}

# --- ESTADÍSTICAS GLOBALES DE LA PARTIDA ---
var estadisticas: Dictionary = {
	"clientes_atendidos_totales": 0,
	"ventas_completadas": 0,
	"ventas_rechazadas": 0,
	"dinero_historico_ganado": 0.0
}

# --- FUNCIÓN: GUARDAR EN DISCO (JSON) ---
func guardar_partida_en_disco() -> void:
	var estructura_datos: Dictionary = {
		"preferencias": {
			"fondo_monitor": fondo_monitor,
			"volumen_musica": volumen_musica,
			"volumen_sfx": volumen_sfx
		},
		"perfil": perfil_jugador,
		"progreso": {
			"dia_actual": EconomiaGlobal.dia_actual,
			"dinero": EconomiaGlobal.dinero,
			"reputacion": EconomiaGlobal.reputacion,
			"tasa_inflacion": EconomiaGlobal.tasa_inflacion,
			"deuda_actual": EconomiaGlobal.deuda_actual,
			"score_crediticio": EconomiaGlobal.score_crediticio,
			"dias_con_deuda_actual": EconomiaGlobal.dias_con_deuda_actual,
			"multiplicador_servicios_evento": EconomiaGlobal.multiplicador_servicios_evento,
			"inflacion_extra_evento": EconomiaGlobal.inflacion_extra_evento,
			"evento_activo": EventosGlobales.evento_activo.duplicate()
		},
		"estadisticas": estadisticas,
		"inventario": {
			"stock": Inventario.stock.duplicate(),
			"precios_venta": Inventario.precios_venta_publico.duplicate()
		}
	}

	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo:
		var json_texto = JSON.stringify(estructura_datos, "\t")
		archivo.store_string(json_texto)
		archivo.close()
		print("--- Datos guardados correctamente en disco ---")

# --- FUNCIÓN: CARGAR DESDE DISCO (JSON) ---
func cargar_partida_desde_disco() -> bool:
	if not FileAccess.file_exists(RUTA_GUARDADO):
		print("No existe un archivo de guardado.")
		return false

	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if not archivo:
		return false

	var json_texto = archivo.get_as_text()
	archivo.close()

	var json = JSON.new()
	if json.parse(json_texto) == OK:
		var datos: Dictionary = json.data
		
		# 1. Cargar preferencias y actualizar AudioServer
		if datos.has("preferencias"):
			fondo_monitor = datos["preferencias"].get("fondo_monitor", "azul")
			volumen_musica = datos["preferencias"].get("volumen_musica", 50.0)
			volumen_sfx = datos["preferencias"].get("volumen_sfx", 50.0)
			
			# Re-aplicar cambios al sistema de audio global
			if Engine.has_singleton("AudioManager") or get_node_or_null("/root/AudioManager"):
				AudioManager.aplicar_volumen_musica(volumen_musica)
				AudioManager.aplicar_volumen_sfx(volumen_sfx)

		# 2. Cargar perfil
		if datos.has("perfil"):
			perfil_jugador = datos["perfil"]

		# 3. Cargar estadísticas
		if datos.has("estadisticas"):
			estadisticas = datos["estadisticas"]

		# 4. Restaurar variables en EconomiaGlobal e Inventario
		if datos.has("progreso"):
			EconomiaGlobal.dia_actual = datos["progreso"].get("dia_actual", 1)
			EconomiaGlobal.dinero = datos["progreso"].get("dinero", 150.0)
			EconomiaGlobal.reputacion = datos["progreso"].get("reputacion", 50)
			
			EconomiaGlobal.tasa_inflacion = datos["progreso"].get("tasa_inflacion", 0.05)
			EconomiaGlobal.deuda_actual = datos["progreso"].get("deuda_actual", 0.0)
			EconomiaGlobal.dias_con_deuda_actual = datos["progreso"].get("dias_con_deuda_actual", 0)
			var credit_score = datos["progreso"].get("score_crediticio", 30)
			EconomiaGlobal.actualizar_score_crediticio(credit_score - EconomiaGlobal.score_crediticio)
			
			EconomiaGlobal.multiplicador_servicios_evento = datos["progreso"].get("multiplicador_servicios_evento", 1.0)
			EconomiaGlobal.inflacion_extra_evento = datos["progreso"].get("inflacion_extra_evento", 0.0)
			
			if datos["progreso"].has("evento_activo"):
				EventosGlobales.evento_activo = datos["progreso"]["evento_activo"].duplicate()
				EventosGlobales.restaurar_evento_cargado()

		if datos.has("inventario"):
			Inventario.stock = datos["inventario"].get("stock", {}).duplicate()
			Inventario.precios_venta_publico = datos["inventario"].get("precios_venta", {}).duplicate()

		print("--- Partida cargada exitosamente ---")
		return true

	return false

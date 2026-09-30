extends Node

const VERSION_JUEGO = "1.4.2"

const RUTA_SLOT_BASE = "user://partida_slot_%d.json"
const RUTA_SLOT_BAK_BASE = "user://partida_slot_%d.json.bak"
var slot_actual: int = 1

# --- CONFIGURACIONES Y PREFERENCIAS ---
var fondo_monitor: String = "azul"
var volumen_musica: float = 50.0
var volumen_sfx: float = 50.0

# --- DATOS DEL PERFIL DEL JUGADOR ---
var perfil_jugador: Dictionary = {
	"nombre_jugador": "",
	"nombre_tienda": "",
	"edad": 20,
	"genero": "Sin especificar",
	"avatar_ruta": "res://sprite/iconos/avatar/avatar_1.png"
}

# --- ESTADÍSTICAS GLOBALES DE LA PARTIDA ---
var estadisticas: Dictionary = {
	"clientes_atendidos_totales": 0,
	"ventas_completadas": 0,
	"ventas_rechazadas": 0,
	"dinero_historico_ganado": 0.0
}

# --- FUNCIÓN AUXILIAR INTERNA PARA LEER Y PARSEAR JSON ---
func _leer_json_de_ruta(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {}
		
	var archivo = FileAccess.open(ruta, FileAccess.READ)
	if not archivo:
		return {}

	var json_texto = archivo.get_as_text()
	archivo.close()

	var json = JSON.new()
	if json.parse(json_texto) == OK and json.data is Dictionary:
		return json.data
	return {}

# --- OBTENER INFORMACIÓN DE UN SLOT ---
func obtener_info_slot(num_slot: int) -> Dictionary:
	var ruta_principal = RUTA_SLOT_BASE % num_slot
	var datos = _leer_json_de_ruta(ruta_principal)
	
	if datos.is_empty():
		var ruta_backup = RUTA_SLOT_BAK_BASE % num_slot
		datos = _leer_json_de_ruta(ruta_backup)
		if not datos.is_empty():
			print("--- Slot %d recuperado exitosamente desde el archivo .bak ---" % num_slot)

	return datos

# --- GUARDAR EN DISCO CON CREACIÓN AUTOMÁTICA DE RESPALDO ---
func guardar_partida_en_disco(num_slot: int = slot_actual) -> void:
	slot_actual = num_slot
	var ruta_principal = RUTA_SLOT_BASE % num_slot
	var ruta_backup = RUTA_SLOT_BAK_BASE % num_slot
	
	if FileAccess.file_exists(ruta_principal):
		DirAccess.copy_absolute(ruta_principal, ruta_backup)
	
	var estructura_datos: Dictionary = {
		"version_save": VERSION_JUEGO,
		"fecha_guardado": Time.get_datetime_string_from_system(false, true),
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

	var archivo = FileAccess.open(ruta_principal, FileAccess.WRITE)
	if archivo:
		var json_texto = JSON.stringify(estructura_datos, "\t")
		archivo.store_string(json_texto)
		archivo.close()
		print("--- Datos guardados correctamente en el Slot ", num_slot, " (v", VERSION_JUEGO, ") ---")

# --- CARGAR DESDE DISCO DESDE UN SLOT ESPECÍFICO ---
func cargar_partida_desde_disco(num_slot: int) -> bool:
	var datos: Dictionary = obtener_info_slot(num_slot)
	if datos.is_empty():
		print("El slot ", num_slot, " está vacío o dañado.")
		return false

	slot_actual = num_slot
	var version_save: String = datos.get("version_save", "1.0.0")

	if version_save != VERSION_JUEGO:
		print("--- Cargando partida guardada en versión previa: ", version_save, " (Versión Actual: ", VERSION_JUEGO, ") ---")

	# 1. Preferencias
	if datos.has("preferencias"):
		fondo_monitor = datos["preferencias"].get("fondo_monitor", "azul")
		volumen_musica = datos["preferencias"].get("volumen_musica", 50.0)
		volumen_sfx = datos["preferencias"].get("volumen_sfx", 50.0)
		
		if Engine.has_singleton("AudioManager") or get_node_or_null("/root/AudioManager"):
			AudioManager.aplicar_volumen_musica(volumen_musica)
			AudioManager.aplicar_volumen_sfx(volumen_sfx)

	# 2. Perfil
	if datos.has("perfil"):
		perfil_jugador = datos["perfil"]

	# 3. Estadísticas
	if datos.has("estadisticas"):
		estadisticas = datos["estadisticas"]

	# 4. Progreso Economía
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

	# 5. Inventario
	if datos.has("inventario"):
		Inventario.stock = datos["inventario"].get("stock", {}).duplicate()
		Inventario.precios_venta_publico = datos["inventario"].get("precios_venta", {}).duplicate()

	print("--- Partida cargada exitosamente desde Slot ", num_slot, " ---")
	return true

# --- BORRAR ARCHIVOS DE SLOT (PRINCIPAL Y BACKUP) ---
func borrar_slot(num_slot: int) -> void:
	var ruta_principal = RUTA_SLOT_BASE % num_slot
	var ruta_backup = RUTA_SLOT_BAK_BASE % num_slot
	
	if FileAccess.file_exists(ruta_principal):
		DirAccess.remove_absolute(ruta_principal)
		
	if FileAccess.file_exists(ruta_backup):
		DirAccess.remove_absolute(ruta_backup)
		
	print("--- Slot ", num_slot, " fue eliminado ---")

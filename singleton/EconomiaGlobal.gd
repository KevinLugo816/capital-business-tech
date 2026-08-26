extends Node

# --- SEÑALES ECONÓMICAS Y DE JORNADA ---
signal dinero_cambiado(nuevo_monto)
signal inflacion_cambiada(nueva_tasa)
signal nuevo_dia_comenzado

# --- LÓGICA DEL DINERO ---
var dinero: float = 500.0 : 
	set(valor):
		dinero = valor
		dinero_cambiado.emit(dinero)

# --- LÓGICA DE INFLACIÓN ---
var tasa_inflacion: float = 0.0 : 
	set(valor):
		tasa_inflacion = valor
		inflacion_cambiada.emit(tasa_inflacion)

# --- LÓGICA DE REPUTACIÓN ---
var multiplicador_reputacion: float = 1.0
var reputacion: int = 50 :
	set(valor):
		reputacion = clampi(valor, 0, 100)
		# Si reputación es 100 -> multiplicador es 1.10 (+10% de ganancia)
		# Si reputación es 50  -> multiplicador es 1.0 (precio normal)
		# Si reputación es 0   -> multiplicador es 0.80 (-20% de pérdida)
		multiplicador_reputacion = 0.8 + (reputacion / 250.0)

# --- FINANZAS Y CONTABILIDAD DIARIA ---
var ingresos_del_dia: float = 0.0
var gastos_del_dia: float = 0.0
var costo_base_alquiler: float = 30.0
var costo_base_servicios: float = 15.0

# --- BANCO Y SISTEMA DE CRÉDITO ---
var deuda_actual: float = 0.0
var tasa_interes_diario: float = 0.05
const LIMITE_CREDITO: float = 300.0

# --- SISTEMA FISCAL (IVA) ---
var tasa_iva: float = 0.16
var iva_acumulado_hoy: float = 0.0

# --- OFERTA DIARIA DEL MAYORISTA ---
var gastos_mayorista_hoy: float = 0.0
var producto_en_oferta: String = ""
const PORCENTAJE_OFERTA: float = 0.25

var lista_productos_disponibles: Array = [
	"Memoria RAM 8GB",
	"Disco SSD 480GB",
	"Cargador Tipo C",
	"Teléfono Gama Baja"
]

# --- MÉTODOS DE MANEJO DE DINERO ---
func agregar_dinero(monto: float) -> void:
	dinero += monto

func restar_dinero(monto: float) -> bool:
	if dinero >= monto:
		dinero -= monto
		return true
	return false

func aplicar_cobro_forzoso(monto: float) -> void:
	dinero -= monto

# --- MÉTODOS DE SIMULACIÓN Y JORNADA ---
func simular_inflacion_diaria() -> void:
	tasa_inflacion += randf_range(-0.02, 0.05)

func registrar_ingreso_venta(monto: float) -> void:
	ingresos_del_dia += monto
	agregar_dinero(monto)

func aplicar_intereses_deuda() -> void:
	if deuda_actual > 0:
		deuda_actual += deuda_actual * tasa_interes_diario
		print("El banco ha aplicado intereses. Nueva deuda: $", deuda_actual)

func limpiar_impuestos_diarios() -> void:
	iva_acumulado_hoy = 0.0

func generar_oferta_del_dia() -> void:
	if randf() <= 0.30:
		producto_en_oferta = lista_productos_disponibles.pick_random()
	else:
		producto_en_oferta = ""

func iniciar_nuevo_dia() -> void:
	ingresos_del_dia = 0.0
	gastos_del_dia = 0.0
	gastos_mayorista_hoy = 0.0
	limpiar_impuestos_diarios()
	generar_oferta_del_dia()
	nuevo_dia_comenzado.emit()

func procesar_cierre_diario(dia_actual: int) -> Dictionary:
	var ingresos = ingresos_del_dia
	var impuestos_a_pagar = iva_acumulado_hoy
	
	var servicios_inflados = costo_base_servicios * (1.0 + tasa_inflacion)
	var alquiler_inflado = 0.0
	if dia_actual % 5 == 0:
		alquiler_inflado = costo_base_alquiler * (1.0 + tasa_inflacion)
	
	var costos_fijos = servicios_inflados + alquiler_inflado
	
	var intereses_hoy = 0.0
	if deuda_actual > 0:
		var deuda_previa = deuda_actual
		aplicar_intereses_deuda()
		intereses_hoy = deuda_actual - deuda_previa
		
	aplicar_cobro_forzoso(costos_fijos + impuestos_a_pagar)
	
	var total_gastos = costos_fijos + impuestos_a_pagar
	gastos_del_dia = total_gastos
	var utilidad_neta = ingresos - total_gastos - intereses_hoy
	
	return {
		"ingresos": ingresos,
		"costos_fijos": costos_fijos,
		"impuestos": impuestos_a_pagar,
		"intereses": intereses_hoy,
		"total_gastos": total_gastos,
		"utilidad_neta": utilidad_neta
	}

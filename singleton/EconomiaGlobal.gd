extends Node

# --- SEÑALES ECONÓMICAS Y DE JORNADA ---
signal dinero_cambiado(nuevo_monto)
signal inflacion_cambiada(nueva_tasa)
signal nuevo_dia_comenzado

# --- LÓGICA DEL DINERO ---
var dinero: float = 500.0 : 
	set(valor):
		dinero = max(0.0, valor)
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

# --- MÉTODOS DE SIMULACIÓN Y JORNADA ---
func simular_inflacion_diaria() -> void:
	tasa_inflacion += randf_range(-0.02, 0.05)

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
	limpiar_impuestos_diarios()
	generar_oferta_del_dia()
	nuevo_dia_comenzado.emit()

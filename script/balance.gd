extends CanvasLayer

@onready var titulo_balance = $Panel/MarginContainer/VBoxContainer/Balance
@onready var label_ingresos = $Panel/MarginContainer/VBoxContainer/Ingresos
@onready var label_gastos = $Panel/MarginContainer/VBoxContainer/Gastos
@onready var label_neto = $Panel/MarginContainer/VBoxContainer/Neto

signal dia_finalizado

func _ready() -> void:
	var tamaño_fuente_grande = 32
	titulo_balance.add_theme_font_size_override("font_size", 40)
	label_ingresos.add_theme_font_size_override("font_size", tamaño_fuente_grande)
	label_gastos.add_theme_font_size_override("font_size", tamaño_fuente_grande)
	label_neto.add_theme_font_size_override("font_size", tamaño_fuente_grande)

func mostrar_balance(dia_actual: int) -> void:
	titulo_balance.text = "REPORTE ECONÓMICO - DÍA " + str(dia_actual)
	
	var ingresos = EconomiaGlobal.ingresos_del_dia
	var inflacion = EconomiaGlobal.tasa_inflacion
	var impuestos_a_pagar = EconomiaGlobal.iva_acumulado_hoy
	
	var servicios_inflados = EconomiaGlobal.costo_base_servicios * (1.0 + inflacion)
	var alquiler_inflado = 0.0
	var es_dia_de_alquiler = (dia_actual % 5 == 0)
	
	if es_dia_de_alquiler:
		alquiler_inflado = EconomiaGlobal.costo_base_alquiler * (1.0 + inflacion)
	
	var intereses_banco_hoy = 0.0
	if EconomiaGlobal.deuda_actual > 0:
		var deuda_previa = EconomiaGlobal.deuda_actual
		EconomiaGlobal.aplicar_intereses_deuda()
		intereses_banco_hoy = EconomiaGlobal.deuda_actual - deuda_previa
	
	var costos_locales = servicios_inflados + alquiler_inflado
	EconomiaGlobal.restar_dinero(costos_locales)
	
	EconomiaGlobal.restar_dinero(impuestos_a_pagar)
	
	var total_gastos = costos_locales + impuestos_a_pagar
	EconomiaGlobal.gastos_del_dia = total_gastos
	
	var utilidad_neta = ingresos - total_gastos - intereses_banco_hoy
	
	label_ingresos.text = "Ingresos Brutos + IVA: +$" + str(snapped(ingresos, 0.01))
	
	label_gastos.text = "Gastos Fijos: -$" + str(snapped(costos_locales, 0.01))
	label_gastos.text += " | IVA Declarado: -$" + str(snapped(impuestos_a_pagar, 0.01))
	if intereses_banco_hoy > 0:
		label_gastos.text += " | Intereses: -$" + str(snapped(intereses_banco_hoy, 0.01))
	
	if utilidad_neta >= 0:
		label_neto.text = "Utilidad Neta: +$" + str(snapped(utilidad_neta, 0.01)) + " (SUPERÁVIT)"
		label_neto.add_theme_color_override("font_color", Color.DARK_GREEN)
	else:
		label_neto.text = "Balance del Día: -$" + str(snapped(abs(utilidad_neta), 0.01)) + " (DÉFICIT)"
		label_neto.add_theme_color_override("font_color", Color.DARK_RED)
	
	show()

func _on_button_siguiente_dia_pressed() -> void:
	hide()
	EconomiaGlobal.iniciar_nuevo_dia()
	dia_finalizado.emit()

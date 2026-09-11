extends CanvasLayer

signal dia_finalizado

@onready var titulo_balance = $Panel/MarginContainer/VBoxContainer/Balance
@onready var label_resumen_clientes = $Panel/MarginContainer/VBoxContainer/Clientes
@onready var label_ingresos = $Panel/MarginContainer/VBoxContainer/Ingresos
@onready var label_gastos_fijos = $Panel/MarginContainer/VBoxContainer/Gastos
@onready var label_impuestos = $Panel/MarginContainer/VBoxContainer/Impuestos
@onready var label_compras_mayorista = $Panel/MarginContainer/VBoxContainer/Compras
@onready var label_intereses = $Panel/MarginContainer/VBoxContainer/Intereses
@onready var label_deuda = $Panel/MarginContainer/VBoxContainer/EstadoDeuda
@onready var label_reputacion_fin = $Panel/MarginContainer/VBoxContainer/Reputacion
@onready var label_neto = $Panel/MarginContainer/VBoxContainer/Neto
@onready var label_alerta_sobregiro = $Panel/MarginContainer/VBoxContainer/Alertas

func _ready() -> void:
	_configurar_estilos_texto()

func _configurar_estilos_texto() -> void:
	var tamano_fuente = 32
	var tamano_titulo = 40
	
	titulo_balance.add_theme_font_size_override("font_size", tamano_titulo)
	
	for child in $Panel/MarginContainer/VBoxContainer.get_children():
		if child != titulo_balance and child != label_neto:
			if child is Label:
				child.add_theme_font_size_override("font_size", tamano_fuente)
			elif child is RichTextLabel:
				child.add_theme_font_size_override("normal_font_size", tamano_fuente)
			
	label_neto.add_theme_font_size_override("font_size", 32)

func mostrar_balance(dia_actual: int, clientes_atendidos: int, max_clientes: int) -> void:
	titulo_balance.text = "REPORTE ECONÓMICO - DÍA %d" % dia_actual
	
	var reporte = EconomiaGlobal.procesar_cierre_diario(dia_actual)
	
	label_resumen_clientes.text = "Clientes Atendidos: %d / %d" % [clientes_atendidos, max_clientes]
	label_reputacion_fin.text = "• Fama Comercial Actual: %d%%" % EconomiaGlobal.reputacion
	
	label_ingresos.text = "• Ingresos Brutos (Ventas + IVA): [color=#2ecc71]+$%s[/color]" % _f(reporte.ingresos)
	
	label_gastos_fijos.text = "• Costos Fijos (Servicios/Alquiler): [color=#e74c3c]-$%s[/color]" % _f(reporte.costos_fijos)
	label_impuestos.text = "• IVA Acumulado a Declarar: [color=#e74c3c]-$%s[/color]" % _f(reporte.impuestos)
	label_compras_mayorista.text = "• Inversión Mercado Mayorista: [color=#e74c3c]-$%s[/color]" % _f(EconomiaGlobal.gastos_mayorista_hoy)
	
	if reporte.intereses > 0:
		label_intereses.show()
		label_intereses.text = "• Intereses Bancarios por Deuda: [color=#e74c3c]-$%s[/color]" % _f(reporte.intereses)
	else:
		label_intereses.hide()
	
	if EconomiaGlobal.deuda_actual > 0:
		label_deuda.show()
		label_deuda.text = "• Deuda Pendiente con el Banco: [color=#e67e22]$%s[/color]" % _f(EconomiaGlobal.deuda_actual)
	else:
		label_deuda.hide()
	
	var utilidad = reporte.utilidad_neta - EconomiaGlobal.gastos_mayorista_hoy
	
	if utilidad >= 0:
		label_neto.text = "UTILIDAD NETA: +$%s (SUPERÁVIT)" % _f(utilidad)
		label_neto.add_theme_color_override("font_color", Color("2ecc71"))
	else:
		label_neto.text = "RESULTADO NETO: -$%s (DÉFICIT)" % _f(abs(utilidad))
		label_neto.add_theme_color_override("font_color", Color("e74c3c"))

	if EconomiaGlobal.dinero <= 0.0:
		label_alerta_sobregiro.show()
		label_alerta_sobregiro.text = "¡ALERTA: CUENTA EN SOBREGIRO ($%s)!" % _f(EconomiaGlobal.dinero)
		label_alerta_sobregiro.add_theme_color_override("font_color", Color("af1f12ff"))
	else:
		label_alerta_sobregiro.hide()

	show()

func _f(monto: float) -> String:
	return str(snapped(monto, 0.01))

func _on_button_siguiente_dia_pressed() -> void:
	hide()
	dia_finalizado.emit()

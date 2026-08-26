extends Control

@onready var lbl_deuda = $MarginContainer/VBoxContainer/LabelDeuda
@onready var lbl_estado_credito = $MarginContainer/VBoxContainer/LabelEstado
@onready var btn_solicitar = $MarginContainer/VBoxContainer/BtnSolicitar
@onready var btn_pagar = $MarginContainer/VBoxContainer/BtnPagar

func actualizar_ui() -> void:
	lbl_deuda.text = "Deuda Bancaria: $%s" % _f(EconomiaGlobal.deuda_actual)
	lbl_estado_credito.text = "Crédito Disponible: $%s" % _f(EconomiaGlobal.LIMITE_CREDITO - EconomiaGlobal.deuda_actual)
	
	btn_solicitar.disabled = (EconomiaGlobal.deuda_actual >= EconomiaGlobal.LIMITE_CREDITO)
	btn_pagar.disabled = (EconomiaGlobal.deuda_actual <= 0) or (EconomiaGlobal.dinero <= 0)

func _on_btn_solicitar_pressed() -> void:
	var monto_prestamo = 100.0
	if EconomiaGlobal.deuda_actual + monto_prestamo <= EconomiaGlobal.LIMITE_CREDITO:
		EconomiaGlobal.agregar_dinero(monto_prestamo)
		EconomiaGlobal.deuda_actual += monto_prestamo
		actualizar_ui()

func _on_btn_pagar_pressed() -> void:
	var abono = 50.0
	if abono > EconomiaGlobal.deuda_actual:
		abono = EconomiaGlobal.deuda_actual
		
	if EconomiaGlobal.restar_dinero(abono):
		EconomiaGlobal.deuda_actual -= abono
		actualizar_ui()

func _f(monto: float) -> String:
	return str(snapped(monto, 0.01))

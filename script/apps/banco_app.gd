extends Control

@onready var lbl_deuda = $VBoxContainer/LabelDeuda
@onready var lbl_estado_credito = $VBoxContainer/LabelEstado
@onready var lbl_tasa_interes = $VBoxContainer/LabelTasaInteres
@onready var lbl_score = $VBoxContainer/LabelScore
@onready var lbl_mensaje = $LabelMensaje

@onready var spin_monto = $VBoxContainer/HBoxMonto/Monto
@onready var btn_solicitar = $VBoxContainer/HBoxAcciones/BtnSolicitar
@onready var btn_pagar = $VBoxContainer/HBoxAcciones/BtnPagar

@onready var btn_max_solicitar = $VBoxContainer/HBoxMonto/BtnMaxSolicitar
@onready var btn_max_pagar = $VBoxContainer/HBoxMonto/BtnMaxPagar

var tween_mensaje: Tween

func _ready() -> void:
	if not EconomiaGlobal.dinero_cambiado.is_connected(_on_dinero_cambiado):
		EconomiaGlobal.dinero_cambiado.connect(_on_dinero_cambiado)
		
	if not EconomiaGlobal.score_cambiado.is_connected(_on_score_cambiado):
		EconomiaGlobal.score_cambiado.connect(_on_score_cambiado)
		
	if is_instance_valid(btn_max_solicitar):
		btn_max_solicitar.pressed.connect(_on_btn_max_solicitar_pressed)
	if is_instance_valid(btn_max_pagar):
		btn_max_pagar.pressed.connect(_on_btn_max_pagar_pressed)
		
	if is_instance_valid(lbl_mensaje):
		lbl_mensaje.text = ""
		
	_configurar_tamano_spinbox(36)
	actualizar_ui()

func _on_dinero_cambiado(_nuevo_monto: float) -> void:
	actualizar_ui()

func _on_score_cambiado(_nuevo_score: int, _nuevo_limite: float) -> void:
	actualizar_ui()

func _configurar_tamano_spinbox(tamano: int) -> void:
	if is_instance_valid(spin_monto):
		var line_edit = spin_monto.get_line_edit()
		line_edit.add_theme_font_size_override("font_size", tamano)

func actualizar_ui() -> void:
	var credito_disponible = max(0.0, EconomiaGlobal.limite_credito_actual - EconomiaGlobal.deuda_actual)
	
	lbl_deuda.text = "Deuda Bancaria: $%s" % _f(EconomiaGlobal.deuda_actual)
	lbl_estado_credito.text = "Crédito Disponible: $%s / $%s" % [_f(credito_disponible), _f(EconomiaGlobal.limite_credito_actual)]
	
	if is_instance_valid(lbl_score):
		lbl_score.text = "Score Crediticio: %d/100" % EconomiaGlobal.score_crediticio
	
	var tasa_total = EconomiaGlobal.tasa_interes_diario + EconomiaGlobal.tasa_inflacion
	if is_instance_valid(lbl_tasa_interes):
		lbl_tasa_interes.text = "Tasa Diaria Total: %s%%" % _f(tasa_total * 100.0)

	_validar_botones()

func _validar_botones() -> void:
	var monto = spin_monto.value if is_instance_valid(spin_monto) else 0.0
	var credito_disponible = EconomiaGlobal.limite_credito_actual - EconomiaGlobal.deuda_actual

	btn_solicitar.disabled = (monto <= 0) or (monto > credito_disponible)
	btn_pagar.disabled = (monto <= 0) or (EconomiaGlobal.deuda_actual <= 0) or (monto > EconomiaGlobal.dinero)

func _on_spin_box_monto_value_changed(_value: float) -> void:
	_validar_botones()

func _on_btn_solicitar_pressed() -> void:
	var monto = spin_monto.value

	if EconomiaGlobal.pedir_prestamo(monto):
		_mostrar_notificacion("¡Préstamo aprobado de $%s!" % _f(monto), Color.GREEN)
		actualizar_ui()
	else:
		_mostrar_notificacion("No se pudo procesar la solicitud de préstamo.", Color.RED)

func _on_btn_pagar_pressed() -> void:
	var abono = spin_monto.value
	
	if abono > EconomiaGlobal.deuda_actual:
		abono = EconomiaGlobal.deuda_actual
		
	if abono > 0 and EconomiaGlobal.restar_dinero(abono):
		EconomiaGlobal.deuda_actual -= abono
		
		if EconomiaGlobal.deuda_actual <= 0.001:
			EconomiaGlobal.deuda_actual = 0.0
			EconomiaGlobal.registrar_deuda_saldada() 
			_mostrar_notificacion("¡Felicidades! Has saldado tu deuda por completo.", Color.GREEN)
		else:
			_mostrar_notificacion("Has abonado $%s a tu deuda." % _f(abono), Color.CYAN)
			
		actualizar_ui()
	else:
		_mostrar_notificacion("Fondos insuficientes para realizar el abono.", Color.RED)

func _on_btn_max_solicitar_pressed() -> void:
	var credito_disponible = EconomiaGlobal.limite_credito_actual - EconomiaGlobal.deuda_actual
	spin_monto.value = max(0.0, credito_disponible)
	_validar_botones()

func _on_btn_max_pagar_pressed() -> void:
	var max_pagable = min(EconomiaGlobal.dinero, EconomiaGlobal.deuda_actual)
	spin_monto.value = max(0.0, max_pagable)
	_validar_botones()

func _mostrar_notificacion(texto: String, color: Color) -> void:
	if not is_instance_valid(lbl_mensaje):
		return
		
	if tween_mensaje and tween_mensaje.is_valid():
		tween_mensaje.kill()
		
	lbl_mensaje.text = texto
	lbl_mensaje.modulate = color
	
	tween_mensaje = create_tween()
	tween_mensaje.tween_interval(3.0)
	tween_mensaje.tween_property(lbl_mensaje, "modulate:a", 0.0, 0.5)
	tween_mensaje.tween_callback(func(): 
		lbl_mensaje.text = ""
		lbl_mensaje.modulate.a = 1.0
	)

func _f(monto: float) -> String:
	return str(snapped(monto, 0.01))

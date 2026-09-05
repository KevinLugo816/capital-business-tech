extends Control

@onready var lbl_reputacion: Label = $Header/VBoxContainer/LabelReputacion
@onready var lbl_estado_campana: RichTextLabel = $Header/VBoxContainer/LabelEstado

@onready var btn_volantes: Button = $Scroll/Campanas/CardVolantes/VBoxContainer/BtnContratar
@onready var btn_redes: Button = $Scroll/Campanas/CardRedes/VBoxContainer/BtnContratar
@onready var btn_valla: Button = $Scroll/Campanas/CardValla/VBoxContainer/BtnContratar

var catalogo_campanas: Dictionary = {
	"volantes": {"costo": 30.0, "reputacion": 10},
	"redes": {"costo": 80.0, "reputacion": 25},
	"valla": {"costo": 200.0, "reputacion": 60}
}

func _ready() -> void:
	if not EconomiaGlobal.nuevo_dia_comenzado.is_connected(_on_nuevo_dia_comenzado):
		EconomiaGlobal.nuevo_dia_comenzado.connect(_on_nuevo_dia_comenzado)
		
	if EconomiaGlobal.has_signal("reputacion_cambiada") and not EconomiaGlobal.reputacion_cambiada.is_connected(_on_reputacion_cambiada):
		EconomiaGlobal.reputacion_cambiada.connect(_on_reputacion_cambiada)

	if not EconomiaGlobal.dinero_cambiado.is_connected(_on_dinero_cambiado):
		EconomiaGlobal.dinero_cambiado.connect(_on_dinero_cambiado)

	_conectar_botones()
	actualizar_ui()

func _conectar_botones() -> void:
	if is_instance_valid(btn_volantes):
		btn_volantes.pressed.connect(func(): _contratar_campana("volantes"))
	if is_instance_valid(btn_redes):
		btn_redes.pressed.connect(func(): _contratar_campana("redes"))
	if is_instance_valid(btn_valla):
		btn_valla.pressed.connect(func(): _contratar_campana("valla"))

func _on_nuevo_dia_comenzado() -> void:
	EconomiaGlobal.campana_activa_hoy = false
	actualizar_ui()

func _on_reputacion_cambiada(_nueva: int) -> void: actualizar_ui()
func _on_dinero_cambiado(_monto: float) -> void: actualizar_ui()

func actualizar_ui() -> void:
	if is_instance_valid(lbl_reputacion):
		lbl_reputacion.text = "Reputación: %d/100" % EconomiaGlobal.reputacion

	var campana_activa: bool = EconomiaGlobal.get("campana_activa_hoy") if "campana_activa_hoy" in EconomiaGlobal else false
	
	if is_instance_valid(lbl_estado_campana):
		if campana_activa:
			lbl_estado_campana.text = "[color=#f1c40f]Campaña en curso. Podrás lanzar otra mañana.[/color]"
		else:
			lbl_estado_campana.text = "[color=#2ecc71]Agencia disponible para nuevas campañas.[/color]"

	_actualizar_estado_botones(campana_activa)

func _actualizar_estado_botones(campana_activa: bool) -> void:
	_validar_boton(btn_volantes, "volantes", campana_activa)
	_validar_boton(btn_redes, "redes", campana_activa)
	_validar_boton(btn_valla, "valla", campana_activa)

func _validar_boton(btn: Button, id_campana: String, campana_activa: bool) -> void:
	if is_instance_valid(btn) and catalogo_campanas.has(id_campana):
		var costo: float = catalogo_campanas[id_campana]["costo"]
		btn.disabled = campana_activa or (EconomiaGlobal.dinero < costo)

func _contratar_campana(id_campana: String) -> void:
	if not catalogo_campanas.has(id_campana):
		return

	var campana_activa: bool = EconomiaGlobal.get("campana_activa_hoy") if "campana_activa_hoy" in EconomiaGlobal else false
	if campana_activa:
		return

	var datos: Dictionary = catalogo_campanas[id_campana]
	var costo: float = datos["costo"]
	
	if EconomiaGlobal.restar_dinero(costo):
		EconomiaGlobal.reputacion += int(datos["reputacion"])
		EconomiaGlobal.campana_activa_hoy = true
		actualizar_ui()

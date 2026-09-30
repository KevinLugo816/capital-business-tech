extends CanvasLayer

signal creditos_cerrados

@onready var panel_container: PanelContainer = $PanelContainer
@onready var vbox_creditos: VBoxContainer = $PanelContainer/VBoxContainer
@onready var boton_cerrar: Button = $BtnCerrar
@onready var label_gracias: Label = $Gracias

var _cerrando: bool = false

func _ready() -> void:
	if is_instance_valid(boton_cerrar):
		boton_cerrar.pressed.connect(_on_boton_cerrar_pressed)
	
	if is_instance_valid(label_gracias):
		label_gracias.modulate.a = 0.0
	
	if is_instance_valid(panel_container):
		panel_container.hide()
	
	await get_tree().process_frame
	_animar_creditos()

func _animar_creditos() -> void:
	if not is_instance_valid(panel_container) or not is_instance_valid(vbox_creditos):
		return
		
	var alto_pantalla: float = get_viewport().get_visible_rect().size.y
	
	panel_container.global_position.y = alto_pantalla
	panel_container.show()
	
	var tween = create_tween()
	
	var destino_y: float = -vbox_creditos.size.y
	tween.tween_property(panel_container, "global_position:y", destino_y, 25.0)
	
	if is_instance_valid(label_gracias):
		tween.tween_property(label_gracias, "modulate:a", 1.0, 2.0)

func _on_boton_cerrar_pressed() -> void:
	if _cerrando:
		return
	_cerrando = true
	
	creditos_cerrados.emit()
	queue_free()

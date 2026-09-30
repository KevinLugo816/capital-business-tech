extends Control

# Referencias a los componentes del Slot 1
@onready var lbl_datos_1: RichTextLabel = $SlotsCarga/SlotContainer1/VBoxSlot1/LblDatos1
@onready var lbl_fecha_1: Label = $SlotsCarga/SlotContainer1/VBoxSlot1/LblFecha1
@onready var btn_slot_1: Button = $SlotsCarga/SlotContainer1/VBoxSlot1/HBoxContainer/BtnSlot1
@onready var btn_borrar_1: Button = $SlotsCarga/SlotContainer1/VBoxSlot1/HBoxContainer/BtnBorrar1

# Referencias a los componentes del Slot 2
@onready var lbl_datos_2: RichTextLabel = $SlotsCarga/SlotContainer2/VBoxSlot2/LblDatos2
@onready var lbl_fecha_2: Label = $SlotsCarga/SlotContainer2/VBoxSlot2/LblFecha2
@onready var btn_slot_2: Button = $SlotsCarga/SlotContainer2/VBoxSlot2/HBoxContainer/BtnSlot2
@onready var btn_borrar_2: Button = $SlotsCarga/SlotContainer2/VBoxSlot2/HBoxContainer/BtnBorrar2

# Referencias a los componentes del Slot 3
@onready var lbl_datos_3: RichTextLabel = $SlotsCarga/SlotContainer3/VBoxSlot3/LblDatos3
@onready var lbl_fecha_3: Label = $SlotsCarga/SlotContainer3/VBoxSlot3/LblFecha3
@onready var btn_slot_3: Button = $SlotsCarga/SlotContainer3/VBoxSlot3/HBoxContainer/BtnSlot3
@onready var btn_borrar_3: Button = $SlotsCarga/SlotContainer3/VBoxSlot3/HBoxContainer/BtnBorrar3

@onready var popup_confirmacion: PopupPanel = $PopupConfirmacion
@onready var label_info_popup: Label = $PopupConfirmacion/VBoxContainer/LabelInfo
@onready var btn_eliminar_popup: Button = $PopupConfirmacion/VBoxContainer/HBoxBotones/BtnEliminar
@onready var btn_cancelar_popup: Button = $PopupConfirmacion/VBoxContainer/HBoxBotones/BtnCancelar

var slot_a_borrar: int = -1

func _ready() -> void:
	btn_slot_1.pressed.connect(func(): _on_slot_pressed(1))
	btn_slot_2.pressed.connect(func(): _on_slot_pressed(2))
	btn_slot_3.pressed.connect(func(): _on_slot_pressed(3))
	
	btn_borrar_1.pressed.connect(func(): _on_borrar_pressed(1))
	btn_borrar_2.pressed.connect(func(): _on_borrar_pressed(2))
	btn_borrar_3.pressed.connect(func(): _on_borrar_pressed(3))
	
	btn_eliminar_popup.pressed.connect(_on_confirmar_eliminacion)
	btn_cancelar_popup.pressed.connect(_on_cancelar_eliminacion)
	
	_actualizar_interfaz_slots()

func _actualizar_interfaz_slots() -> void:
	_configurar_slot_ui(1, lbl_datos_1, lbl_fecha_1, btn_borrar_1)
	_configurar_slot_ui(2, lbl_datos_2, lbl_fecha_2, btn_borrar_2)
	_configurar_slot_ui(3, lbl_datos_3, lbl_fecha_3, btn_borrar_3)

func _configurar_slot_ui(num_slot: int, lbl_datos: RichTextLabel, lbl_fecha: Label, btn_borrar: Button) -> void:
	var info: Dictionary = ConfigUsuario.obtener_info_slot(num_slot)
	
	if info.is_empty():
		lbl_datos.text = "[center][color=gray]SLOT %d VACÍO\n\nPresiona Play para iniciar una nueva partida[/color][/center]" % num_slot
		lbl_fecha.text = "---"
		btn_borrar.disabled = true
	else:
		var perfil: Dictionary = info.get("perfil", {})
		var progreso: Dictionary = info.get("progreso", {})
		
		var nombre_jugador: String = perfil.get("nombre_jugador", "Jugador")
		var nombre_tienda: String = perfil.get("nombre_tienda", "Sin Local")
		var dinero: float = progreso.get("dinero", 0.0)
		var dia: int = progreso.get("dia_actual", 1)
		var fecha_raw: String = info.get("fecha_guardado", "")
		
		lbl_datos.text = "[center]%s\n\n%s\n\n[color=2ecc71]$%s[/color]\n\n[color=blue]Día %d[/color][/center]" % [
			nombre_jugador,
			nombre_tienda,
			str(snapped(dinero, 0.01)),
			dia
		]
		
		if not fecha_raw.is_empty():
			lbl_fecha.text = fecha_raw.replace("T", " ")
		else:
			lbl_fecha.text = "---"
			
		btn_borrar.disabled = false

func _on_slot_pressed(num_slot: int) -> void:
	var info: Dictionary = ConfigUsuario.obtener_info_slot(num_slot)
	
	if info.is_empty():
		ConfigUsuario.slot_actual = num_slot
		get_tree().change_scene_to_file("res://escena/registro_player.tscn")
	else:
		if ConfigUsuario.cargar_partida_desde_disco(num_slot):
			get_tree().change_scene_to_file("res://escena/menu_contenido.tscn")

func _on_borrar_pressed(num_slot: int) -> void:
	slot_a_borrar = num_slot
	label_info_popup.text = "¿Estás seguro de que quieres eliminar la partida %d?" % num_slot
	popup_confirmacion.popup_centered()

func _on_confirmar_eliminacion() -> void:
	if slot_a_borrar != -1:
		ConfigUsuario.borrar_slot(slot_a_borrar)
		slot_a_borrar = -1
		_actualizar_interfaz_slots()
	popup_confirmacion.hide()

func _on_cancelar_eliminacion() -> void:
	slot_a_borrar = -1
	popup_confirmacion.hide()

func _on_btn_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://escena/menu_inicio.tscn")

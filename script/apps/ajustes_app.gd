extends Control

signal fondo_cambiado(nombre_color: String)

@onready var btn_azul = $Panel/VBoxContainer/HBoxContainer/BtnAzul
@onready var btn_rosa = $Panel/VBoxContainer/HBoxContainer/BtnRosa
@onready var btn_verde = $Panel/VBoxContainer/HBoxContainer/BtnVerde

func _ready() -> void:
	btn_azul.pressed.connect(func(): _seleccionar_fondo("azul"))
	btn_rosa.pressed.connect(func(): _seleccionar_fondo("rosa"))
	btn_verde.pressed.connect(func(): _seleccionar_fondo("verde"))

func _seleccionar_fondo(color: String) -> void:
	fondo_cambiado.emit(color)

func actualizar_ui() -> void:
	# Método para mantener consistencia con tus otras subescenas
	pass

extends Control

@onready var popup_opciones: PopupPanel = $PopupOpciones
@onready var slider_musica: HSlider = $PopupOpciones/VBoxContainer/SliderMusica
@onready var slider_sfx: HSlider = $PopupOpciones/VBoxContainer/SliderSFX

func _ready() -> void:
	popup_opciones.hide()
	
	AudioManager.reproducir_musica_menu()
	slider_musica.value = ConfigUsuario.volumen_musica
	slider_sfx.value = ConfigUsuario.volumen_sfx

func _on_btn_nueva_partida_pressed() -> void:
	get_tree().change_scene_to_file("res://escena/registro_player.tscn")

func _on_btn_cargar_partida_pressed() -> void:
	if ConfigUsuario.cargar_partida_desde_disco():
		get_tree().change_scene_to_file("res://escena/menu_contenido.tscn")
	else:
		print("No se encontró ningún archivo de guardado.")

func _on_btn_opciones_pressed() -> void:
	popup_opciones.show()

func _on_btn_cerrar_opciones_pressed() -> void:
	popup_opciones.hide()
	ConfigUsuario.guardar_partida_en_disco()

func _on_slider_musica_value_changed(value: float) -> void:
	AudioManager.aplicar_volumen_musica(value)

func _on_slider_sfx_value_changed(value: float) -> void:
	AudioManager.aplicar_volumen_sfx(value)

func _on_btn_salir_pressed() -> void:
	get_tree().quit()

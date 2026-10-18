extends Control

@onready var logo: TextureRect = $Logo
@onready var vbox_container: VBoxContainer = $VBoxContainer
@onready var popup_opciones: PopupPanel = $PopupOpciones
@onready var slider_musica: HSlider = $PopupOpciones/VBoxContainer/SliderMusica
@onready var slider_sfx: HSlider = $PopupOpciones/VBoxContainer/SliderSFX

const CREDITOS_ESCENA = preload("res://escena/creditos.tscn")
var creditos_instancia: Node = null

func _ready() -> void:
	popup_opciones.hide()
	AudioManager.reproducir_musica_menu()
	slider_musica.value = ConfigUsuario.volumen_musica
	slider_sfx.value = ConfigUsuario.volumen_sfx
	
	AnimUiManager.animar_entrada_ui(vbox_container)
	AnimUiManager.animar_nodo_flotante(logo)

func _on_btn_nueva_partida_pressed() -> void:
	for slot in range(1, 4):
		if ConfigUsuario.obtener_info_slot(slot).is_empty():
			ConfigUsuario.slot_actual = slot
			get_tree().change_scene_to_file("res://escena/registro_player.tscn")
			return

	get_tree().change_scene_to_file("res://escena/carga_partida.tscn")

func _on_btn_cargar_partida_pressed() -> void:
	get_tree().change_scene_to_file("res://escena/carga_partida.tscn")

func _on_btn_opciones_pressed() -> void:
	popup_opciones.show()

func _on_btn_cerrar_opciones_pressed() -> void:
	popup_opciones.hide()
	if not ConfigUsuario.perfil_jugador.get("nombre_jugador", "").is_empty():
		ConfigUsuario.guardar_partida_en_disco()

func _on_slider_musica_value_changed(value: float) -> void:
	AudioManager.aplicar_volumen_musica(value)
	ConfigUsuario.volumen_musica = value

func _on_slider_sfx_value_changed(value: float) -> void:
	AudioManager.aplicar_volumen_sfx(value)
	ConfigUsuario.volumen_sfx = value

func _on_boton_creditos_pressed() -> void:
	if is_instance_valid(creditos_instancia):
		return
		
	creditos_instancia = CREDITOS_ESCENA.instantiate()
	add_child(creditos_instancia)

func _on_btn_salir_pressed() -> void:
	get_tree().quit()

func _exit_tree() -> void:
	AnimUiManager.detener_flotacion(logo)

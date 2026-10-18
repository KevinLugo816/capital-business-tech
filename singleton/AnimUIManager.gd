extends Node

const COLOR_INGRESO: Color = Color("5d902e")
const COLOR_EGRESO: Color = Color("e74c3c")
const COLOR_REP_POS: Color = Color("f3c700")
const COLOR_REP_NEG: Color = Color("e74c3c")

var _tweens_flotantes: Dictionary = {}

# --- TEXTOS FLOTANTES ---
func mostrar_texto_flotante(
	texto: String, 
	color_fuente: Color, 
	posicion_inicial: Vector2, 
	distancia_movimiento: float = 50.0, 
	hacia_abajo: bool = true,
	nodo_padre: Node = null
) -> void:
	
	var lbl = Label.new()
	lbl.text = texto
	lbl.z_index = 100
	lbl.global_position = posicion_inicial
	
	lbl.add_theme_color_override("font_color", color_fuente)
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.add_theme_color_override("font_outline_color", Color.BLACK)
	lbl.add_theme_constant_override("outline_size", 5)
	
	if nodo_padre == null:
		get_tree().current_scene.add_child(lbl)
	else:
		nodo_padre.add_child(lbl)

	var tween = create_tween()
	tween.set_parallel(true)
	
	var destino_y = posicion_inicial.y + distancia_movimiento if hacia_abajo else posicion_inicial.y - distancia_movimiento
	
	tween.tween_property(lbl, "global_position:y", destino_y, 1.2)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
		
	tween.tween_property(lbl, "modulate:a", 0.0, 1.2)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
		
	tween.chain().tween_callback(lbl.queue_free)

# --- HELPER FUNCTIONS DE DINERO Y REPUTACIÓN ---
func animar_dinero(monto: float, posicion: Vector2, nodo_padre: Node = null) -> void:
	var es_ingreso = monto >= 0
	var texto = ("+" if es_ingreso else "-") + "$" + str(snapped(abs(monto), 0.01))
	var color = COLOR_INGRESO if es_ingreso else COLOR_EGRESO
	
	mostrar_texto_flotante(texto, color, posicion, 50.0, true, nodo_padre)

func animar_reputacion(puntos: int, posicion: Vector2, nodo_padre: Node = null) -> void:
	var es_positivo = puntos >= 0
	var texto = ("+" if es_positivo else "") + str(puntos) + " Fama"
	var color = COLOR_REP_POS if es_positivo else COLOR_REP_NEG
	
	mostrar_texto_flotante(texto, color, posicion, 50.0, true, nodo_padre)

# --- NUEVAS FUNCIONES DE ANIMACIÓN UI ---
func animar_entrada_ui(nodo: Control, duracion: float = 0.6) -> void:
	if not is_instance_valid(nodo) or not nodo.is_inside_tree():
		return

	nodo.modulate.a = 0.0
	var pos_final_y: float = nodo.position.y
	nodo.position.y += 30.0

	var tween = create_tween().set_parallel(true)
	tween.tween_property(nodo, "modulate:a", 1.0, duracion)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_property(nodo, "position:y", pos_final_y, duracion)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)

func animar_nodo_flotante(nodo: Control, amplitud: float = 12.0, duracion_ciclo: float = 2.5) -> void:
	if not is_instance_valid(nodo) or not nodo.is_inside_tree():
		return

	detener_flotacion(nodo)

	var instance_id = nodo.get_instance_id()
	var pos_original_y: float = nodo.position.y

	var tween = create_tween().set_loops()
	tween.tween_property(nodo, "position:y", pos_original_y - amplitud, duracion_ciclo)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(nodo, "position:y", pos_original_y + amplitud, duracion_ciclo)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_tweens_flotantes[instance_id] = tween

# Detiene la animación de flotación de un nodo
func detener_flotacion(nodo: Control) -> void:
	if not is_instance_valid(nodo):
		return
		
	var instance_id = nodo.get_instance_id()
	if _tweens_flotantes.has(instance_id):
		var tween: Tween = _tweens_flotantes[instance_id]
		if is_instance_valid(tween) and tween.is_running():
			tween.kill()
		_tweens_flotantes.erase(instance_id)

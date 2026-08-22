extends Node

const COLOR_INGRESO: Color = Color("5d902e")
const COLOR_EGRESO: Color = Color("e74c3c")
const COLOR_REP_POS: Color = Color("f3c700")
const COLOR_REP_NEG: Color = Color("e74c3c")

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

# --- ANIMACIÓN TWEEN ---
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

# --- MÉTODOS DE CONVENIENCIA (HELPER FUNCTIONS) ---
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

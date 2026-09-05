extends Control

@onready var img_noticia: TextureRect = $PanelContainer/VBoxNoticia/TextureIcono
@onready var lbl_titular: Label = $PanelContainer/VBoxNoticia/LabelNoticia
@onready var txt_detalles: RichTextLabel = $PanelContainer/VBoxNoticia/Detalles
@onready var txt_otros: RichTextLabel = $VBoxOtros/Otros
@onready var grafica: Control = $Panel/GraficaInflacion

const ICONO_OFERTA: Texture2D = preload("res://sprite/iconos/oferta.png")
const ICONO_INFLACION: Texture2D = preload("res://sprite/iconos/inflacion.png")
const ICONO_ALERTA: Texture2D = preload("res://sprite/iconos/alerta.png")
const ICONO_ESTABLE: Texture2D = preload("res://sprite/iconos/grafico.png")

var noticias_lore: Array[String] = [
	"• [b]Logística Local:[/b] Camiones de transporte reportan fluidez en las entregas del sector.",
	"• [b]Consumo Regional:[/b] Encuestas muestran que los clientes priorizan tiendas con stock variado.",
	"• [b]Sector Comercial:[/b] Comerciantes locales debaten el impacto del costo de los alquileres.",
	"• [b]Servicios Básicos:[/b] Ajustes menores en las tarifas de energía eléctrica para comercios.",
	"• [b]Gremio de Tenderos:[/b] Advierten sobre la importancia de mantener fondos de reserva."
]

func _ready() -> void:
	if not EconomiaGlobal.inflacion_cambiada.is_connected(_on_inflacion_cambiada):
		EconomiaGlobal.inflacion_cambiada.connect(_on_inflacion_cambiada)
		
	if not EconomiaGlobal.nuevo_dia_comenzado.is_connected(_on_nuevo_dia_comenzado):
		EconomiaGlobal.nuevo_dia_comenzado.connect(_on_nuevo_dia_comenzado)

func _on_inflacion_cambiada(_nueva_tasa: float) -> void:
	actualizar_ui()

func _on_nuevo_dia_comenzado() -> void:
	actualizar_ui()

func actualizar_ui() -> void:
	if not is_instance_valid(lbl_titular) or not is_instance_valid(txt_detalles):
		return

	_procesar_noticias_del_dia()

	if is_instance_valid(grafica):
		grafica.queue_redraw()

func _procesar_noticias_del_dia() -> void:
	# 1. NOTICIA PRINCIPAL O EVENTO
	if not EventosGlobales.evento_activo.is_empty():
		var ev: Dictionary = EventosGlobales.evento_activo
		lbl_titular.text = ev.get("titulo", "")
		txt_detalles.text = ev.get("descripcion", "")
		
		match ev.get("icono_tipo", ""):
			"OFERTA": _aplicar_imagen(ICONO_OFERTA)
			"INFLACION": _aplicar_imagen(ICONO_INFLACION)
			"ALERTA": _aplicar_imagen(ICONO_ALERTA)
			_: _aplicar_imagen(null)

	elif EconomiaGlobal.producto_en_oferta != "":
		lbl_titular.text = "¡GRAN DESCUENTO MAYORISTA!"
		txt_detalles.text = "El proveedor anunció un [color=#2ecc71]25% de descuento[/color] exclusivo para el producto: [b]{prod}[/b].".format({"prod": EconomiaGlobal.producto_en_oferta})
		_aplicar_imagen(ICONO_OFERTA)

	else:
		lbl_titular.text = "MERCADO EN ESTABILIDAD"
		txt_detalles.text = "Sin variaciones bruscas en el mercado comercial para el día de hoy."
		_aplicar_imagen(ICONO_ESTABLE)

	# 2. NOTICIA SECUNDARIA
	var noticias_secundarias: Array[String] = []
	
	var acumulado_inf: float = EconomiaGlobal.tasa_inflacion * 100.0
	if acumulado_inf > 10.0:
		noticias_secundarias.append("• [b]Tendencia de Precios:[/b] La inflación se mantiene [color=#e74c3c]alta (%.1f%%)[/color]. Se recomienda ajustar precios en tienda." % acumulado_inf)
	else:
		noticias_secundarias.append("• [b]Tendencia de Precios:[/b] Inflación [color=#2ecc71]estable (%.1f%%)[/color]. Los costos de reposición son regulares." % acumulado_inf)

	var texto_lore: String = _obtener_lore_del_dia()
	noticias_secundarias.append(texto_lore)

	if is_instance_valid(txt_otros):
		txt_otros.text = "\n\n".join(noticias_secundarias)

func _obtener_lore_del_dia() -> String:
	if noticias_lore.is_empty():
		return ""
	
	var rng := RandomNumberGenerator.new()
	rng.seed = EconomiaGlobal.dia_actual * 7919
	
	var indice: int = rng.randi_range(0, noticias_lore.size() - 1)
	return noticias_lore[indice]

func _aplicar_imagen(textura: Texture2D) -> void:
	if not is_instance_valid(img_noticia):
		return
		
	if is_instance_valid(textura):
		img_noticia.texture = textura
		img_noticia.visible = true
	else:
		img_noticia.texture = null
		img_noticia.visible = false

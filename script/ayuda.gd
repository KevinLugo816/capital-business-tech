extends Control

@onready var lbl_titulo_seccion: Label = $PanelContenido/HBoxContainer/Diapositiva/LblTituloSeccion
@onready var img_diapositiva: TextureRect = $PanelContenido/HBoxContainer/Diapositiva/ImagenDiapositiva
@onready var text_info: RichTextLabel = $PanelContenido/HBoxContainer/Diapositiva/TextInfo
@onready var lbl_pagina: Label = $PanelContenido/HBoxContainer/Diapositiva/HBoxNav/LblPagina

@onready var btn_recepcion: Button = $PanelContenido/HBoxContainer/MenuNav/BtnRecepcion
@onready var btn_inventario: Button = $PanelContenido/HBoxContainer/MenuNav/BtnInventario
@onready var btn_monitor: Button = $PanelContenido/HBoxContainer/MenuNav/BtnMonitor
@onready var btn_clientes: Button = $PanelContenido/HBoxContainer/MenuNav/BtnClientes

@onready var btn_anterior: Button = $PanelContenido/HBoxContainer/Diapositiva/HBoxNav/BtnAnterior
@onready var btn_siguiente: Button = $PanelContenido/HBoxContainer/Diapositiva/HBoxNav/BtnSig
@onready var boton_volver: Button = $BotonVolver

var seccion_actual: String = "recepcion"
var pagina_actual: int = 0

var manual_datos: Dictionary = {
	"recepcion": {
		"titulo": "1. RECEPCIÓN Y JORNADA",
		"diapositivas": [
			{
				"texto": "[center][b]VISTA GENERAL DE LA RECEPCIÓN[/b][/center]\n\n" +
						 "El centro de operaciones principal de tu negocio. Desde aquí controlas la atención en el mostrador, el estado de la tienda y el acceso hacia el inventario y el monitor virtual.",
				"imagen": "res://sprite/ayuda/1.png"
			},
			{
				"texto": "[center][b]EL DINERO[/b][/center]\n\n" +
						 "[color=2ecc71]• Capital Disponible:[/color] Muestra en tiempo real tu caja chica y fondos líquidos.\n\n" +
						 "• Se actualiza instantáneamente con cada venta realizada o gasto incurrido en el día.",
				"imagen": "res://sprite/ayuda/2.png"
			},
			{
				"texto": "[center][b]LOS DÍAS[/b][/center]\n\n" +
						 "[color=3498db]• Jornada Laboral:[/color] Indica el número de día que estás transitando en la partida.\n\n" +
						 "• Al finalizar la cantidad de clientes estimados, se activará automáticamente el panel de balance diario.\n\n" +
						 "• Al transcurrir los días se irán desbloqueando eventos que te ayudan o perjudican",
				"imagen": "res://sprite/ayuda/3.png"
			},
			{
				"texto": "[center][b]LA INFLACIÓN[/b][/center]\n\n" +
						 "[color=e74c3c]• Tasa de Inflación:[/color] Porcentaje acumulado de devaluación y aumento de costos de reposición.\n\n" +
						 "• Afecta de manera directa el precio de compra en el mercado mayorista.",
				"imagen": "res://sprite/ayuda/4.png"
			},
			{
				"texto": "[center][b]LA FAMA / REPUTACIÓN[/b][/center]\n\n" +
						 "[color=f1c40f]• Nivel de Popularidad (%):[/color] Mide el prestigio de tu local ante los compradores.\n\n" +
						 "• Una alta reputación incrementa el flujo diario de clientes esperados y mejora su tolerancia durante la negociación.",
				"imagen": "res://sprite/ayuda/5.png"
			},
			{
				"texto": "[center][b]'ABRIR / REABRIR LOCAL'[/b][/center]\n\n" +
						 "• [color=2ecc71]Comienzo de Jornada:[/color] Inicia la llegada de clientes al mostrador para atender las solicitudes de compra.\n\n" +
						 "• [color=f39c12]Receso de Mediodía:[/color] A mitad de la jornada el local se pausará automáticamente para permitirte reabastecer stock o ajustar precios antes de reabrir.",
				"imagen": "res://sprite/ayuda/6.png"
			}
		]
	},
	"inventario": {
		"titulo": "2. INVENTARIO Y PRECIOS",
		"diapositivas": [
			{
				"texto": "[center][b]CONTROL DE INVENTARIO Y ALMACÉN[/b][/center]\n\n" +
						 "• Supervisa las existencias actuales de cada producto, sus marcas y el stock disponible.\n\n" +
						 "• Muestra la capacidad máxima del almacén (límite de 50 unidades) para controlar el espacio libre de almacenamiento.",
				"imagen": "res://sprite/ayuda/8.png"
			},
			{
				"texto": "[center][b]AJUSTE DE PRECIOS DE VENTA[/b][/center]\n\n" +
						 "• Modifica libremente el precio de venta al público para combatir la inflación y asegurar márgenes de ganancia.\n\n" +
						 "• El sistema evalúa de forma dinámica si el precio es óptimo, si representa una venta a pérdida o si incurre en sobreprecio.\n\n" +
						 "• [color=e74c3c]Nota:[/color] Los precios de los productos se congelan automáticamente durante el horario de atención del local.",
				"imagen": "res://sprite/ayuda/10.png"
			},
			{
				"texto": "[center][b]MERCADO MAYORISTA[/b][/center]\n\n" +
						 "• Permite reabastecer el inventario comprando mercancía al por mayor según las necesidades del negocio.\n\n" +
						 "• Ofrece la opción de aprovechar descuentos especiales en productos en oferta diaria del proveedor, respetando siempre la capacidad máxima del almacén.",
				"imagen": "res://sprite/ayuda/13.png"
			}
		]
	},
	"monitor": {
		"titulo": "3. MONITOR VIRTUAL",
		"diapositivas": [
			{
				"texto": "[center][b]ESCRITORIO KEVOS[/b][/center]\n\n" +
						 "Tu estación de trabajo digital. Desde aquí puedes acceder a aplicaciones financieras, informativas y de personalización para optimizar la gestión de tu tienda.",
				"imagen": "res://sprite/ayuda/15.png"
			},
			{
				"texto": "[center][b]APLICACIÓN: EL BANCO[/b][/center]\n\n" +
						 "• [color=2ecc71]Solicitud de Préstamos:[/color] Pide capital de emergencia basado en tu score crediticio para reabastecer tu local.\n\n" +
						 "• [color=e74c3c]Pago de Deudas:[/color] Abona o salda tus obligaciones pendientes para mejorar tu historial financiero y evitar cargos excesivos.",
				"imagen": "res://sprite/ayuda/16.png"
			},
			{
				"texto": "[center][b]APLICACIÓN: NOTICIAS ECONÓMICAS[/b][/center]\n\n" +
						 "• [color=3498db]Titulares Diarios:[/color] Lee las noticias del día para enterarte de eventos especiales o descuentos exclusivos en productos del mercado mayorista.\n\n" +
						 "• [color=f1c40f]Tendencias:[/color] Monitorea el comportamiento de la inflación y las alertas inmobiliarias (como el cobro de alquileres).",
				"imagen": "res://sprite/ayuda/17.png"
			},
			{
				"texto": "[center][b]APLICACIÓN: PUBLICIDAD[/b][/center]\n\n" +
						 "• [color=9b59b6]Campañas Comerciales:[/color] Contrata diferentes tipos de difusión (volantes, redes sociales o vallas publicitarias).\n\n" +
						 "• [color=2ecc71]Beneficio:[/color] Cada campaña aumenta tu reputación comercial y atrae más flujo de clientes a tu tienda.",
				"imagen": "res://sprite/ayuda/18.png"
			},
			{
				"texto": "[center][b]APLICACIÓN: AJUSTES / CONFIGURACIÓN[/b][/center]\n\n" +
						 "• [color=f1c40f]Personalización:[/color] Modifica el aspecto visual de tu monitor eligiendo entre los diferentes fondos de pantalla disponibles para tu espacio de trabajo.",
				"imagen": "res://sprite/ayuda/19.png"
			}
		]
	},
	"clientes": {
		"titulo": "4. CLIENTES Y NEGOCIACIÓN",
		"diapositivas": [
			{
				"texto": "[center][b]ATENCIÓN DE CLIENTES[/b][/center]\n\n" +
						 "Al abrir el local, cada cliente se presentará con un pedido específico y se clasificarán en 4 perfiles distintos según su comportamiento:\n\n" +
						 "• [color=3498db][b]Normal:[/b][/color] Comportamiento equilibrado y estándar ante los precios.\n" +
						 "• [color=e74c3c][b]Apurado:[/b][/color] Tiene prisa extrema y su tiempo de espera se reduce drásticamente.\n" +
						 "• [color=f1c40f][b]Tacaño:[/b][/color] Muy sensible a los costos; tolera poco los márgenes altos.\n" +
						 "• [color=9b59b6][b]Exigente:[/b][/color] Busca calidad pero valora la precisión en el servicio.",
				"imagen": "res://sprite/ayuda/20.png"
			},
			{
				"texto": "[center][b]LA BARRA DE PACIENCIA[/b][/center]\n\n" +
						 "• Representa el tiempo límite que el cliente está dispuesto a esperar en el mostrador.\n\n" +
						 "• [color=2ecc71]Verde (>50%):[/color] El cliente está calmado y atento.\n" +
						 "• [color=f1c40f]Amarillo (20%-50%):[/color] Comienza a impacientarse.\n" +
						 "• [color=e74c3c]Rojo (<20%):[/color] A punto de irse.\n\n" +
						 "Si la barra llega a cero sin ser atendido, el cliente se marchará molesto y perderás la venta y puntos de reputación.",
				"imagen": "res://sprite/ayuda/22.png"
			},
			{
				"texto": "[center][b]OPCIONES DE NEGOCIACIÓN[/b][/center]\n\n" +
						 "• [color=2ecc71][b]V (Aceptar):[/b][/color] Concretas la venta al precio actual que tengas establecido.\n\n" +
						 "• [color=e74c3c][b]X (Rechazar):[/b][/color] Cancelas la transacción si no te convence pero perderás algo de reputación.\n\n" +
						 "• [color=f1c40f][b]% (Descuento):[/b][/color] Aplicas una rebaja rápida para cerrar la venta (útil si el cliente es un tacaño).",
				"imagen": "res://sprite/ayuda/21.png"
			}
		]
	}
}

func _ready() -> void:
	if Engine.has_singleton("AnimUiManager") or get_node_or_null("/root/AnimUiManager"):
		AnimUiManager.animar_entrada_ui($PanelContenido)
		
	_conectar_senales()
	_cambiar_seccion("recepcion")

func _conectar_senales() -> void:
	btn_recepcion.pressed.connect(func(): _cambiar_seccion("recepcion"))
	btn_inventario.pressed.connect(func(): _cambiar_seccion("inventario"))
	btn_monitor.pressed.connect(func(): _cambiar_seccion("monitor"))
	btn_clientes.pressed.connect(func(): _cambiar_seccion("clientes"))
	
	btn_anterior.pressed.connect(_pagina_anterior)
	btn_siguiente.pressed.connect(_pagina_siguiente)
	boton_volver.pressed.connect(_on_btn_volver_pressed)

func _cambiar_seccion(nueva_seccion: String) -> void:
	seccion_actual = nueva_seccion
	pagina_actual = 0
	_actualizar_diapositiva()

func _pagina_anterior() -> void:
	if pagina_actual > 0:
		pagina_actual -= 1
		_actualizar_diapositiva()

func _pagina_siguiente() -> void:
	var total_paginas = manual_datos[seccion_actual]["diapositivas"].size()
	if pagina_actual < total_paginas - 1:
		pagina_actual += 1
		_actualizar_diapositiva()

func _actualizar_diapositiva() -> void:
	var datos = manual_datos[seccion_actual]
	var diapositiva_info = datos["diapositivas"][pagina_actual]
	var total_paginas = datos["diapositivas"].size()
	
	lbl_titulo_seccion.text = datos["titulo"]
	text_info.text = diapositiva_info["texto"]
	lbl_pagina.text = "Página %d / %d" % [pagina_actual + 1, total_paginas]
	
	var ruta_img: String = diapositiva_info.get("imagen", "")
	if not ruta_img.is_empty() and ResourceLoader.exists(ruta_img):
		img_diapositiva.texture = load(ruta_img)
		img_diapositiva.visible = true
	else:
		img_diapositiva.texture = null
		img_diapositiva.visible = false
	
	btn_anterior.disabled = (pagina_actual == 0)
	btn_siguiente.disabled = (pagina_actual == total_paginas - 1)

func _on_btn_volver_pressed() -> void:
	get_tree().change_scene_to_file("res://escena/menu_contenido.tscn")

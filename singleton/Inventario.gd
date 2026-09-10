extends Node

signal inventario_actualizado

const TEXTURAS_PRODUCTOS = {
	"Memoria RAM 8GB": "res://sprite/assets/productos/memory_ram_princeston.png",
	"Disco SSD 480GB": "res://sprite/assets/productos/disco_ssd_winxx.png",
	"Cargador Tipo C": "res://sprite/assets/productos/charger_earm.png",
	"Teléfono Gama Baja": "res://sprite/assets/productos/telefono_gamabaja_xamo.png"
}

const TEXTURA_DEFAULT = "res://sprite/iconos/imagen.svg"

var precios_venta_publico: Dictionary = {
	"Memoria RAM 8GB": 20.0,
	"Disco SSD 480GB": 25.0,
	"Cargador Tipo C": 7.0,
	"Teléfono Gama Baja": 80.0
}

var stock: Dictionary = {
	"Memoria RAM 8GB": 5,
	"Disco SSD 480GB": 3,
	"Cargador Tipo C": 10,
	"Teléfono Gama Baja": 2
}

func obtener_textura_producto(producto: String) -> Texture2D:
	var ruta = TEXTURAS_PRODUCTOS.get(producto, TEXTURA_DEFAULT)
	if ResourceLoader.exists(ruta):
		return load(ruta) as Texture2D
	return load(TEXTURA_DEFAULT) as Texture2D

func tiene_producto(producto: String, cantidad: int) -> bool:
	return stock.has(producto) and stock[producto] >= cantidad

func modificar_stock(producto: String, cantidad: int) -> void:
	if stock.has(producto):
		stock[producto] = max(0, stock[producto] + cantidad)
		inventario_actualizado.emit()
	elif cantidad > 0:
		stock[producto] = cantidad
		inventario_actualizado.emit()

func obtener_cantidad(producto: String) -> int:
	if stock.has(producto):
		return stock[producto]
	return 0

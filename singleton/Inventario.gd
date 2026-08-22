extends Node

signal inventario_actualizado

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

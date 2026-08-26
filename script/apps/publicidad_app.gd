extends Control

func _on_btn_campana_pressed() -> void:
	var costo = 50.0
	if EconomiaGlobal.restar_dinero(costo):
		EconomiaGlobal.reputacion += 20
		print("¡Campaña lanzada con éxito!")
	else:
		print("Fondos insuficientes.")

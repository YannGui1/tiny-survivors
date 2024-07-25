extends Node2D

@export var regeneration_amount: int = 10


func _ready():
	$Area2D.body_entered.connect(on_body_entered)  # Aqui eu uso um signal(body_entered) para detectar que um corpo entrou na Area2D da carne. A Função connect() ouve o sinal e conecta ele com algo. 


func on_body_entered(body: Node2D) ->void:
	if body.is_in_group("player"):
		var player: Player = body
		player.heal(regeneration_amount)
		player.meat_collected.emit(regeneration_amount) # emite o Signal(que está criado no player)
		queue_free()

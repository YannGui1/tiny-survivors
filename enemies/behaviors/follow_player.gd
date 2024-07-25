extends Node

@export var speed: float = 1.0

var enemy: Enemy
var sprite: AnimatedSprite2D #Aqui é o tipo AnimatedSprite2D.


#Essa função é chamada assim que esse node estiver pronto.
func _ready():
	enemy = get_parent() #Enemy irá herdar as informações do pai através do metodo get_parent()
	sprite = enemy.get_node("AnimatedSprite2D") #Aqui é o nome do node AnimatedSprite2D pra poder atribuir as animações que estão no AnimatedSprite

func _physics_process(delta: float) -> void:
	# Parar em caso de Game Over
	if GameManager.is_game_over: return
	
	#Calcular direção
	var player_position = GameManager.player_position  #Pegar a posição do player
	var difference = player_position - enemy.position #Calcular a distancia entre o inimigo e o player
	var input_vector = difference.normalized() 
	
	#Movimentar
	enemy.velocity = input_vector * speed * 100
	enemy.move_and_slide()

	#Girar Sprite
	if input_vector.x > 0:
		#Desmarcar flip_h do Sprite2D
		sprite.flip_h = false
	elif input_vector.x <0:
		#Marcar flip_h do Sprite2D
		sprite.flip_h = true

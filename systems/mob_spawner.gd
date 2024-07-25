class_name MobSpawner
extends Node2D

@export var creatures: Array[PackedScene]


#o uso do % ao inves de $ é porque o PathFollow2D foi recebeu acesso por nome unico. (Botão direito em cima de PathFollow2D e selecionar Acesso como nome único.)
@onready var path_follow_2d: PathFollow2D = %PathFollow2D

var cooldown: float = 0.0
var mobs_per_minute: float = 60.0

func _process(delta: float):
	# Parar em caso de Game Over
	if GameManager.is_game_over: return
	
	# Temporizador
	cooldown -= delta # Diminuir a cada quadro do jogo
	if cooldown > 0: return
	
	# Frequência
	var interval = 60.0 / mobs_per_minute
	cooldown = interval
	
	# Checar se o ponto é valido
	var point = get_point()
	var world_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = point
	parameters.collision_mask = 0b1001 # Essa notação se lê da direita pra esquerda. No canto direito está o Layer 1 e no canto esquerdo está o Layer 4. OBS: Abra o colission do world limit para entender melhor.
	var result: Array = world_state.intersect_point(parameters, 1)
	if not result.is_empty(): return
	
	# Instanciar uma criatura aleatória
	var index = randi_range(0, creatures.size() - 1)
	var creature_scene = creatures[index]
	var creature = creature_scene.instantiate()
	creature.global_position = point
	get_parent().add_child(creature)
	pass

# Pegar uma posição aleatória do pathfollow para depois spawnar um monstro.
func get_point() -> Vector2:
	path_follow_2d.progress_ratio = randf()
	return path_follow_2d.global_position # O position irá retornar a posição em relação ao pai. O global_position retorna a posição em relação a cena inteira.

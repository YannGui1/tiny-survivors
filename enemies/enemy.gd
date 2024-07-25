class_name Enemy  #Aqui eu nomeio a classe para que eu possa usar ela como tipo de variável
#e implementar os métodos e atributos daqui em qualquer objeto que herdar essa classe.
extends Node2D

#Um node só pode ter 1 script atrelado a ele. Para atrelar mais de um script você deve criar um node filho e colocar o script nele.
#Para herdar os atributos da classe pai o metodo get_parent é utilizado.

@export_category("Life")
@export var health: int = 10 #Obs: O @export aqui é apenas para fazer a variável aparecer no inspetor, não é relacionado a herança.
@export var death_prefeb: PackedScene #Essa varíavel que aparece no inspetor que irá receber a cena da morte(skull)

@export_category("Drops")
@export var drop_chance: float = 0.1
@export var drop_itens: Array[PackedScene]
@export var drop_chances: Array[float]

@onready var damage_digit_marker = $DamageDigitMarker

var damage_digit_prefeb: PackedScene

func _ready():
	damage_digit_prefeb = preload("res://Misc/damage_digit.tscn")

func damage(amount: int) -> void:
	health -= amount
	print("Inimigo recebeu dano de ", amount, ", a vida total é de ", health)
	
	# Piscar o inimigo quando toma dano. Procurar no site easings.net para tipos de easing
	modulate = Color.RED # Aqui é a cor que eu quero que o personagem mude
	var tween = create_tween() # tween é basicamente "Between" ou seja, no caso do ataque, é o que vai acontecer enquanto o personagem toda o dano
	tween.set_ease(Tween.EASE_IN) #metodo de easing
	tween.set_trans(Tween.TRANS_QUINT) #tipo de transição
	tween.tween_property(self, "modulate", Color.WHITE, 0.3) # self significa que irá aplicar ao proprio node, modulate significa a propriedade que a gente quer mudar, Color:White é o valor final e 0.3 é a duração.
	
	# Criar DamageDigit
	
	var damage_digit = damage_digit_prefeb.instantiate()
	damage_digit.value = amount
	if damage_digit_marker:
		damage_digit.global_position = damage_digit_marker.global_position
	else:
		damage_digit.global_position = global_position	
	get_parent().add_child(damage_digit)
	# Processar morte
	if health <= 0:
		die()
		
func die() -> void:
	# Caveira
	if death_prefeb:
		var death_object = death_prefeb.instantiate()
		death_object.position = position
		get_parent().add_child(death_object) #Registra o objeto criado na cena, para que possa ser mostrado e processado.
	
	# Drop 
	if randf() <= drop_chance:
		drop_item()
	
	# Incrementar contador
	GameManager.monsters_defeated_counter += 1
	
	# Deletar node
	queue_free() #queue_free é como se deleta nodes no godot. Nesse contexto, apaga o inimigo no final.

func drop_item():
	var drop = get_random_drop_item().instantiate()
	drop.position = position
	get_parent().add_child(drop)
		
func get_random_drop_item() -> PackedScene:
	# Listas com 1 item
	if drop_itens.size() == 1:
		return drop_itens[0]
	
	# Calcular chance máxima(Chance de drop combinada de todos os itens)
	var max_chance: float = 0.0
	for drop_chance in drop_chances:
		max_chance += drop_chance
		
	# Jogar dado
	var random_value = randf() * max_chance
	
	# Gira a roleta 
	var needle: float = 0.0
	for i in drop_itens.size():
		var drop_item = drop_itens[i] 
		var drop_chance = drop_chances[i] if i < drop_chances.size() else 1 # Se o drop_chances for maior que I, drop_chance = drop_chances[i] se não, drop_chance = 1
		if random_value <= drop_chance + needle:
			return drop_item
		needle += drop_chance
		
	return drop_itens[0]

class_name Player
extends CharacterBody2D
@export_category("Movement")
@export var speed: float = 3

@export_category("Sword")
@export var sword_damage: int = 2

@export_category("Ritual")
@export var ritual_damage: int = 1
@export var ritual_interval: float = 30
@export var ritual_scene: PackedScene

@export_category("Life")
@export var health: int = 100
@export var max_health: int = 100
@export var death_prefeb: PackedScene


@onready  var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite:Sprite2D = $Sprite2D
@onready var sword_area: Area2D = $SwordArea
@onready var hitbox_area: Area2D = $HitBoxArea
@onready var health_progress_bar: ProgressBar = $HealthProgressBar



var input_vector: Vector2 = Vector2(0, 0)
var is_running: bool = false
var was_running: bool = false
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var hitbox_cooldown: float = 0.0
var ritual_cooldown: float = 0.0

signal meat_collected(value: int)

func _ready():
	GameManager.player = self
	meat_collected.connect(func(value: int): GameManager.meat_counter += 1) # Função anônima

# _process é recomendado pro resto.
func _process(delta: float) -> void:
	# Guarda a posição do jogador no GameManager(um singleton)
	GameManager.player_position = position
	
	# Ler Input
	read_input()
	
	# Processar Ataque
	update_attack_cooldown(delta)
	if Input.is_action_just_pressed("attack"):
		attack();

	# Processar animação e rotação do sprite
	play_run_idle_animation()
	
	if not is_attacking:
		rotate_sprite()
	
	# Processar Dano
	update_hitbox_detection(delta)
	
	# Ritual
	update_ritual(delta)
	
	# Atualizar Health bar
	health_progress_bar.max_value = max_health
	health_progress_bar.value = health

# _physics_process é mais recomendado para fisica
func _physics_process(delta: float) -> void:
	# Modificar velocidade
	var target_velocity = input_vector * speed * 100
	if is_attacking:
		target_velocity *= 0.25 
	velocity = lerp(velocity, target_velocity, 0.05)
	move_and_slide();

func update_attack_cooldown(delta: float) -> void:
	# Atualizar temporizador do ataque
	if is_attacking:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			is_attacking = false
			is_running = false
			animation_player.play("idle")

func update_ritual(delta: float) -> void:
	# Atualizar temporizador
	ritual_cooldown -= delta
	if ritual_cooldown > 0: return
	ritual_cooldown = ritual_interval
	
	# Criar o ritual
	var ritual = ritual_scene.instantiate()
	ritual.damage_amount = ritual_damage
	add_child(ritual)  # Aqui a cena do ritual é colocado dentro da cena do player

func read_input() -> void:
	# Obter o input_vector
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")#, 0.15) #o quinto valor é a deadzone do analógico
	
	# Apagar deadzone
	var deadzone = 0.15
	if abs(input_vector.x) < deadzone:
		input_vector.x = 0.0
	if abs(input_vector.y) < deadzone:
		input_vector.y = 0.0
	
	# Atualizar is_running
	was_running = is_running
	is_running = not input_vector.is_zero_approx(); #isso faz com que caso não seja zero, is_running é igual a true

func play_run_idle_animation() -> void:
	# Tocar animação
	if not is_attacking:
		if was_running != is_running:
			if is_running:
				animation_player.play("run")
			else:
				animation_player.play("idle")	

func rotate_sprite() -> void:
	# Girar Sprite
	if input_vector.x > 0:
		# Desmarcar flip_h do Sprite2D
		sprite.flip_h = false
	elif input_vector.x <0:
		# Marcar flip_h do Sprite2D
		sprite.flip_h = true

func attack() -> void:	
# attack_side_1
	
	if is_attacking:
		return
	# Tocar animação
	animation_player.play("attack_side_1")
	
	# Configurar temporizador
	attack_cooldown = 0.6
	
	# Marcar Ataque
	is_attacking = true 	
  

func deal_damage_to_enemies() -> void:
	var bodies = sword_area.get_overlapping_bodies() #Irá pegar os Body que estiverem dentro da SwordArea
	for body in bodies:
		if body.is_in_group("Enemies"):
			var enemy: Enemy = body
			
			var direction_to_enemy = (enemy.position - position).normalized()
			var attack_direction: Vector2
			# Descobrir a direção do ataque do personagem
			if sprite.flip_h:
				attack_direction = Vector2.LEFT
			else:
				attack_direction = Vector2.RIGHT
			# Causar dano em uma area específica
			var dot_product = direction_to_enemy.dot(attack_direction)
			if dot_product > 0.2:
				enemy.damage(sword_damage)

	#var enemies = get_tree().get_nodes_in_group("Enemies")  #get_tree pega uma árvore. Uma árvore são todos os nodes de uma cena.
	#get_nodes_in_group é autoexplicativo. Ele vai pegar os nodes de um grupo especificado. 
	
func update_hitbox_detection(delta: float) -> void:
	# Temporizador 
	hitbox_cooldown -= delta
	if hitbox_cooldown > 0: return 
	
	# Frequência (2x por segundo)
	hitbox_cooldown = 0.5
	
	# HitboxArea
	var bodies = hitbox_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("Enemies"):
			var enemy: Enemy = body
			var damage_amount = 1
			damage(damage_amount)

func damage(amount: int) -> void:
	if health <= 0: return # o return aqui é pra finalizar a função, caso o hp seja 0
	
	health -= amount
	print("Player recebeu dano de ", amount, ". A vida total é de ", health, "/", max_health)
	
	modulate = Color.RED
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN) 
	tween.set_trans(Tween.TRANS_QUINT) 
	tween.tween_property(self, "modulate", Color.WHITE, 0.3) 
	
	# Processar morte
	if health <= 0:
		die()
		
func die() -> void:
	GameManager.end_game()
	if death_prefeb:
		var death_object = death_prefeb.instantiate()
		death_object.position = position
		get_parent().add_child(death_object) 
	queue_free() 

func heal(amount: int) -> int:
	health += amount
	if health > max_health:
		health = max_health
	print("Player recebeu ", amount, " pontos de vida. A vida total é de  ", health, "/", max_health)	
	return health

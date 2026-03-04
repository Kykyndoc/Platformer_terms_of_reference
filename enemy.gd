extends CharacterBody2D

var speed = 100.0
var dir = 1
var Hero = null
var is_attacking = false
var attack_damage_enemy = 20
var HP = 100
signal died

enum State { PATROL, CHASE, ATTACK, HIT, DEATH }
var current_state = State.PATROL

var can_attack = true
@onready var timer_attack: Timer = $Timer_attack
@onready var detection_area = $Area2D
@onready var anim = $AnimatedSprite2D
@onready var exit_timer: Timer = $Exit_timer
@onready var death_timer: Timer = $Death_timer



func _ready():
	anim.play("run")
	timer_attack.wait_time = 1.0
	timer_attack.timeout.connect(_on_attack_timer_timeout)
	exit_timer.timeout.connect(_on_exit_timer_timeout)
	death_timer.timeout.connect(_on_death_timer_timeout)
	anim.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()
	move(delta)
	check_attack()
	
	
func move(delta):
	match current_state:
		State.PATROL:
			velocity.x = speed * dir
			if $Right.is_colliding() or !$Right_down.is_colliding():
				dir = -1
			if $Left.is_colliding() or !$Left_down.is_colliding():
				dir = 1
			
			if velocity.x > 0:
				anim.flip_h = false
			else:
				anim.flip_h = true
			
		State.CHASE:
			if Hero:
				var direction = (Hero.global_position - global_position).normalized()
				velocity.x = direction.x * speed
				
				if direction.x > 0:
					anim.flip_h = false
				else:
					anim.flip_h = true
			else:
				current_state = State.PATROL
				
		State.ATTACK:
			velocity.x = 0
			
		State.HIT:
			velocity.x = 0  
			
		State.DEATH:               
			velocity.x = 0


func check_attack():
	var hero_in_range = $Right_attack.is_colliding() or $Left_attack.is_colliding()
	match current_state:
		State.CHASE:
			if hero_in_range and can_attack:
				enter_attack_state()

			elif not Hero:
				current_state = State.PATROL
				anim.play("run")
		
		State.ATTACK:
			if not hero_in_range and not is_attacking:
				if Hero:
					current_state = State.CHASE
					anim.play("run")
				else:
					current_state = State.PATROL
					anim.play("run")
			else:
				if can_attack and hero_in_range:
					perform_attack()
					
		State.HIT:
			pass
			
		State.DEATH:               
			pass


func enter_attack_state():
	current_state = State.ATTACK
	perform_attack() 


func perform_attack():
	can_attack = false
	timer_attack.start()  
	velocity = Vector2.ZERO
	if $Right_attack.is_colliding():
		anim.flip_h = false  
	else:  
		anim.flip_h = true  
		
	anim.play("attack")
	is_attacking = true
	

func _on_attack_timer_timeout():
	can_attack = true
	

func _on_animation_finished():
	if current_state == State.ATTACK and anim.animation == "attack":
		is_attacking = false
		var hero = null
		if $Right_attack.is_colliding():
			hero = $Right_attack.get_collider()
		elif $Left_attack.is_colliding():
			hero = $Left_attack.get_collider()
		
		if hero and hero.has_method("take_damage"):
			hero.take_damage(attack_damage_enemy)
			
		if Hero and ($Right_attack.is_colliding() or $Left_attack.is_colliding()):
			current_state = State.ATTACK
			anim.play("default")  
		elif Hero:
			current_state = State.CHASE
			anim.play("run")
		else:
			current_state = State.PATROL
			anim.play("run")
	
	elif anim.animation == "hit":
		current_state = State.CHASE if Hero else State.PATROL
		anim.play("run")
		
	elif anim.animation == "death":          
		death_timer.start(1.0)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("hero_group"): 
		Hero = body
		exit_timer.stop()
		if current_state == State.PATROL:
			current_state = State.CHASE


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == Hero: 
		exit_timer.start(0.2)
			
		
func _on_exit_timer_timeout():
	Hero = null
	if current_state != State.HIT and not is_attacking and current_state != State.DEATH:
		current_state = State.PATROL
		anim.play("run")
		
		
func _on_death_timer_timeout():
	queue_free()
			

func take_damage(damag):
	if current_state == State.DEATH:  
		return
	is_attacking = false
	HP -= damag
	velocity.x = 0
	if HP <= 0:
		current_state = State.DEATH
		anim.play("death")
		died.emit()
	else:
		current_state = State.HIT
		anim.play("hit")
	

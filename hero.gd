extends CharacterBody2D

const SPEED = 200.0
const JUMP_VELOCITY = -400.0

@onready var anim = $AnimatedSprite2D
@onready var attack_timer = $Attack_timer  
@onready var right_attack = $Right_attack  
@onready var left_attack = $Left_attack  
@onready var hp_hero: ProgressBar = $"../UI/HP_hero"

var can_attack = true
var is_attacking = false
var is_damag = false
var is_dead = false
var attack_damage_hero = 50
var HP = 100
signal died


func _ready():
	anim.animation_finished.connect(_on_animation_finished)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	

func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = 0
		move_and_slide()
		return
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_attacking and not is_damag:
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("left", "right")
	if direction and not is_attacking and not is_damag:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	animation()
	
	if Input.is_action_just_pressed("attack") and can_attack and not is_attacking and not is_damag:
		start_attack()


func start_attack():
	if is_on_floor():
		can_attack = false
		is_attacking = true
		anim.play("attack")  
		attack_timer.start(0.7)  


func _on_animation_finished():
	if anim.animation == "attack":
		is_attacking = false
		var enemy = null
		if not anim.flip_h:  
			if right_attack.is_colliding():
				enemy = right_attack.get_collider()
		else:  
			if left_attack.is_colliding():
				enemy = left_attack.get_collider()
		
		if enemy and enemy.has_method("take_damage"):
			enemy.take_damage(attack_damage_hero)
		
		if is_on_floor():
			if velocity.x != 0:
				anim.play("run")
			else:
				anim.play("default")
		else:
			anim.play("jump")
			
	elif anim.animation == "hit":
		is_damag = false
		
		if is_on_floor():
			if velocity.x != 0:
				anim.play("run")
			else:
				anim.play("default")
		else:
			anim.play("jump")
			
	elif anim.animation == "death":
		pass
		
		
func _on_attack_timer_timeout():
	can_attack = true


func animation():
	if is_attacking or is_damag or is_dead:
		return
		
	if not is_on_floor():
		anim.play("jump")
	elif velocity.x != 0:
		anim.play("run")	
	else:
		anim.play("default")
		
	if velocity.x < 0:
		anim.flip_h = true
	elif velocity.x > 0:
		anim.flip_h = false


func take_damage(damag):
	if is_dead:          
		return
	is_attacking = false
	is_damag = true
	HP -= damag
	hp_hero.value = HP
	if HP <= 0:
		die()
	else:
		anim.play("hit")
		

func die():
	is_dead = true
	is_attacking = false
	is_damag = false
	can_attack = false
	anim.play("death")   
	died.emit()
	
	

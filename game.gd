extends Node2D

@onready var game_over = $UI/GameOver
@onready var hero = $Hero
@onready var victory: Control = $UI/Victory
@onready var area_win: Area2D = $Area_Win
@onready var area_thorns: Area2D = $Area_thorns
@onready var thorns_timer: Timer = $ThornsTimer
@onready var kill_enemy: Label = $UI/Kill_enemy

var bodies_in_thorns = []
var kills = 0


func _ready() -> void:
	if hero and hero.has_signal("died"):
		hero.died.connect(_on_hero_died)
		
	if area_win:
		area_win.body_entered.connect(_on_area_win_body_entered)
		
	if area_thorns:
		area_thorns.body_entered.connect(_on_area_thorns_body_entered)
		area_thorns.body_exited.connect(_on_area_thorns_body_exited)
		
		
	var restart_button_defeat = game_over.get_node("Button_defeat") 
	if restart_button_defeat:
		restart_button_defeat.pressed.connect(_on_restart_pressed)
		
	var restart_button_victory = victory.get_node("Button_victory")
	if restart_button_victory:
		restart_button_victory.pressed.connect(_on_restart_pressed)
		
	connect_enemies()
	update_kill_label()
	

func connect_enemies():
	var enemies = get_tree().get_nodes_in_group("Bots")
	for enemy in enemies:
		if enemy.has_signal("died") and not enemy.died.is_connected(_on_enemy_died):
			enemy.died.connect(_on_enemy_died)
			

func _on_enemy_died():
	kills += 1
	update_kill_label()
	

func update_kill_label():
	kill_enemy.text = "Kills: " + str(kills)
		

func _physics_process(delta: float) -> void:
	$Map/bonfire.play("default")
	$Map/Portal.play("default")
	
	
func _on_hero_died():
	if hero in bodies_in_thorns:
		bodies_in_thorns.erase(hero)
	check_thorns_timer()
	show_screen(game_over)
	

func _on_area_win_body_entered(body):
	if body == hero:
		show_screen(victory)
		hero.anim.play("default")
		hero.collision_layer = 1
		
		
func _on_area_thorns_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage(20)
		if body not in bodies_in_thorns:
			bodies_in_thorns.append(body)
			if bodies_in_thorns.size() == 1:
				thorns_timer.start()
		

func _on_area_thorns_body_exited(body):
	if body in bodies_in_thorns:
		bodies_in_thorns.erase(body)
		check_thorns_timer()
		

func show_screen(screen: CanvasItem):
	screen.visible = true
	screen.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(screen, "modulate:a", 1.0, 1.0)
	await tween.finished
	get_tree().paused = true
	
	
func _on_restart_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_thorns_timer_timeout() -> void:
	var to_remove = []
	for body in bodies_in_thorns:
		if not is_instance_valid(body):
			to_remove.append(body)
			continue
		if body.has_method("take_damage"):
			body.take_damage(20)
	for body in to_remove:
		bodies_in_thorns.erase(body)
	check_thorns_timer()
	

func check_thorns_timer():
	if bodies_in_thorns.is_empty():
		thorns_timer.stop()

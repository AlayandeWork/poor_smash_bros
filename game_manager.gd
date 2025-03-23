extends Node
class_name GameManager

@export var player1_scene: PackedScene
@export var player2_scene: PackedScene
@export var player1_spawn_position: Vector2 = Vector2(300, 300)
@export var player2_spawn_position: Vector2 = Vector2(900, 300)

@onready var player1_waiting_label = $UI/Player1WaitingLabel
@onready var player2_waiting_label = $UI/Player2WaitingLabel
@onready var player1_ready_label = $UI/Player1ReadyLabel
@onready var player2_ready_label = $UI/Player2ReadyLabel

var player1_ready: bool = false
var player2_ready: bool = false
var player1_instance = null
var player2_instance = null

var player1_ready_action: String = "player1_ready"
var player2_ready_action: String = "player2_ready"

func _ready():
	if player1_waiting_label:
		player1_waiting_label.visible = true
		
	if player1_ready_label:
		player1_ready_label.visible = false
		
	if player2_waiting_label:
		player2_waiting_label.visible = true
		
	if player2_ready_label:
		player2_ready_label.visible = false
	
	if not InputMap.has_action(player1_ready_action):
		InputMap.add_action(player1_ready_action)
	
	if not InputMap.has_action(player2_ready_action):
		InputMap.add_action(player2_ready_action)
	
	if InputMap.action_get_events(player1_ready_action).size() == 0:
		var event = InputEventKey.new()
		event.keycode = KEY_ENTER
		InputMap.action_add_event(player1_ready_action, event)
	
	if InputMap.action_get_events(player2_ready_action).size() == 0:
		var event = InputEventKey.new()
		event.keycode = KEY_KP_ENTER
		InputMap.action_add_event(player2_ready_action, event)

func _process(_delta):
	if not player1_ready and Input.is_action_just_pressed(player1_ready_action):
		set_player1_ready()
	
	if not player2_ready and Input.is_action_just_pressed(player2_ready_action):
		set_player2_ready()

func set_player1_ready():
	if player1_ready:
		return
		
	player1_ready = true
	
	if player1_waiting_label:
		player1_waiting_label.visible = false
	if player1_ready_label:
		player1_ready_label.visible = true
	
	spawn_player1()
	check_both_players_ready()

func set_player2_ready():
	if player2_ready:
		return
		
	player2_ready = true
	
	if player2_waiting_label:
		player2_waiting_label.visible = false
	if player2_ready_label:
		player2_ready_label.visible = true
	
	spawn_player2()
	check_both_players_ready()

func spawn_player1():
	if not player1_scene:
		printerr("Player 1 scene not set in GameManager!")
		return
	
	player1_instance = player1_scene.instantiate()
	player1_instance.player_number = 1
	player1_instance.position = player1_spawn_position
	add_child(player1_instance)
	
	player1_instance.player_died.connect(_on_player_died)

func spawn_player2():
	if not player2_scene:
		printerr("Player 2 scene not set in GameManager!")
		return
	
	player2_instance = player2_scene.instantiate()
	player2_instance.player_number = 2
	player2_instance.position = player2_spawn_position
	add_child(player2_instance)
	
	player2_instance.player_died.connect(_on_player_died)

func check_both_players_ready():
	if player1_ready and player2_ready:
		start_game()

func start_game():
	hide_all_readiness_ui()
	print("Both players ready! Game starting!")

func hide_all_readiness_ui():
	if player1_waiting_label:
		player1_waiting_label.queue_free()
	if player1_ready_label:
		player1_ready_label.queue_free()
	if player2_waiting_label:
		player2_waiting_label.queue_free()
	if player2_ready_label:
		player2_ready_label.queue_free()

func _on_player_died(player_number: int):
	print("Player %d has been defeated!" % player_number)
	
	if player_number == 1:
		show_game_over("Player 2 Wins!")
	else:
		show_game_over("Player 1 Wins!")

func show_game_over(message: String):
	var game_over_label = Label.new()
	game_over_label.text = message
	game_over_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	game_over_label.size = Vector2(400, 100)
	game_over_label.position = Vector2(get_viewport().size / 2 - game_over_label.size / 2)
	game_over_label.add_theme_font_size_override("font_size", 36)
	add_child(game_over_label)
	
	var restart_button = Button.new()
	restart_button.text = "Play Again"
	restart_button.size = Vector2(200, 50)
	restart_button.position = Vector2(get_viewport().size / 2 - restart_button.size / 2 + Vector2(0, 80))
	restart_button.pressed.connect(restart_game)
	add_child(restart_button)

func restart_game():
	get_tree().reload_current_scene()

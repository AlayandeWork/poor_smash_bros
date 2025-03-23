extends CharacterBody2D
class_name Player

@export_category("Movement")
@export var speed: float = 300.0
@export var jump_force: float = 500.0
@export var gravity: float = 1000.0
@export var acceleration: float = 0.25
@export var deceleration: float = 0.1

@export_category("Combat")
@export var attack_damage: int = 10
@export var max_health: int = 100
@export var knockback_force: float = 300.0
@export var knockback_duration: float = 0.5
@export var attack_cooldown: float = 0.3

@export_category("Player")
@export var player_number: int = 1

@onready var health_bar = $HealthBar
@onready var attack_hitbox_right = $AttackHitboxRight
@onready var attack_hitbox_left = $AttackHitboxLeft
@onready var hurtbox = $Hurtbox
@onready var sprite = $Sprite2D
@onready var animation_player = $AnimationPlayer

var health: int
var is_attacking: bool = false
var is_knocked_back: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var attack_timer: float = 0.0
var can_attack: bool = true
var facing_direction: int = 1

var move_left_action: String
var move_right_action: String
var jump_action: String
var attack_action: String

signal player_damaged(current_health: int, max_health: int)
signal player_died(player_number: int)

func _ready():
	health = max_health
	setup_input_actions()
	setup_hitboxes()
	update_health_display()

func setup_input_actions():
	if player_number == 1:
		move_left_action = "move_left"
		move_right_action = "move_right"
		jump_action = "jump"
		attack_action = "attack"
	else:
		move_left_action = "p2_move_left"
		move_right_action = "p2_move_right"
		jump_action = "p2_jump"
		attack_action = "p2_attack"

func setup_hitboxes():
	if attack_hitbox_right:
		attack_hitbox_right.monitoring = false
		attack_hitbox_right.visible = false
		attack_hitbox_right.connect("area_entered", _on_attack_hitbox_area_entered)
		attack_hitbox_right.connect("body_entered", _on_attack_hitbox_body_entered)
	
	if attack_hitbox_left:
		attack_hitbox_left.monitoring = false
		attack_hitbox_left.visible = false
		attack_hitbox_left.connect("area_entered", _on_attack_hitbox_area_entered)
		attack_hitbox_left.connect("body_entered", _on_attack_hitbox_body_entered)

func _physics_process(delta):
	if is_knocked_back:
		handle_knockback(delta)
	else:
		handle_movement(delta)
		handle_attack(delta)
	
	move_and_slide()
	update_animations()

func handle_movement(delta):
	velocity.y += gravity * delta
	var input_direction = Vector2.ZERO
	if Input.is_action_pressed(move_left_action):
		input_direction.x = -1
		facing_direction = -1
	elif Input.is_action_pressed(move_right_action):
		input_direction.x = 1
		facing_direction = 1
	
	if input_direction.x != 0:
		velocity.x = lerp(velocity.x, input_direction.x * speed, acceleration)
	else:
		velocity.x = lerp(velocity.x, 0.0, deceleration)
	
	if Input.is_action_just_pressed(jump_action) and is_on_floor():
		velocity.y = -jump_force

func handle_attack(delta):
	if !can_attack:
		attack_timer += delta
		if attack_timer >= attack_cooldown:
			can_attack = true
			attack_timer = 0.0
	
	if Input.is_action_just_pressed(attack_action) and can_attack and !is_attacking:
		attack()

func handle_knockback(delta):
	velocity = knockback_velocity

func attack():
	if is_attacking:
		return
	
	is_attacking = true
	can_attack = false
	attack_timer = 0
	
	disable_hitboxes()
	
	if facing_direction < 0:
		attack_hitbox_left.monitoring = true
		attack_hitbox_left.visible = true
	else:
		attack_hitbox_right.monitoring = true
		attack_hitbox_right.visible = true
	
	if animation_player:
		animation_player.play("attack")
	
	get_tree().create_timer(0.2).timeout.connect(end_attack)

func end_attack():
	disable_hitboxes()
	is_attacking = false

func disable_hitboxes():
	if attack_hitbox_right:
		attack_hitbox_right.monitoring = false
		attack_hitbox_right.visible = false
	
	if attack_hitbox_left:
		attack_hitbox_left.monitoring = false
		attack_hitbox_left.visible = false

func take_damage(amount: int, direction: Vector2 = Vector2.ZERO):
	health -= amount
	health = max(health, 0)
	update_health_display()
	emit_signal("player_damaged", health, max_health)
	
	if direction != Vector2.ZERO:
		apply_knockback(direction)
	
	if animation_player:
		animation_player.play("hit")
	
	if health <= 0:
		die()

func update_health_display():
	if health_bar:
		health_bar.value = float(health) / max_health * 100.0

func apply_knockback(direction: Vector2):
	if is_knocked_back:
		return
	
	is_knocked_back = true
	knockback_velocity = direction.normalized() * knockback_force
	
	var timer = get_tree().create_timer(knockback_duration)
	timer.timeout.connect(end_knockback)

func end_knockback():
	is_knocked_back = false
	knockback_velocity = Vector2.ZERO

func die():
	emit_signal("player_died", player_number)
	
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	
	queue_free()

func _on_attack_hitbox_area_entered(area: Area2D) -> void:
	var opponent = area.get_parent()
	process_hit(opponent)

func _on_attack_hitbox_body_entered(body: Node2D) -> void:
	process_hit(body)

func process_hit(target):
	if target == self or not target.has_method("take_damage"):
		return
	
	if target is Player:
		print("Hit Player %d for %d damage!" % [target.player_number, attack_damage])
	
	var direction = (target.global_position - global_position).normalized()
	
	target.take_damage(attack_damage, direction)

func update_animations():
	if not animation_player:
		return
	
	if sprite:
		sprite.flip_h = facing_direction < 0
	
	if is_knocked_back:
		if not animation_player.current_animation == "hit":
			animation_player.play("hit")
	elif not is_on_floor():
		if velocity.y < 0:
			animation_player.play("jump")
		else:
			animation_player.play("fall")
	elif abs(velocity.x) > 10:
		animation_player.play("run")
	else:
		animation_player.play("idle")

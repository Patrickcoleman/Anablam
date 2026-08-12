extends CharacterBody2D
class_name Player

var peer_id: int = 1 
var local: bool = true

const CHARACTERS: Array[SpriteFrames] = [
	preload("res://objects/player/green_player.tres"),
	preload("res://objects/player/red_player.tres"),
	preload("res://objects/player/black_player.tres"),
	preload("res://objects/player/blue_player.tres"),
	preload("res://objects/player/beige_player.tres")
]

var character: int = 0 :
	set(value):
		character = clampi(value, 0, CHARACTERS.size() - 1)
		var sprite: AnimatedSprite2D = $Body
		sprite.sprite_frames = CHARACTERS[character]
		sprite.play(&"default")

# Lifecycle

func _enter_tree() -> void:
	peer_id = int(name)
	$ClientSynchronizer.set_multiplayer_authority(peer_id)
	local = (peer_id == multiplayer.get_unique_id())

func _ready() -> void:
	if (local):
		$Camera2D.make_current()

# RPC
@rpc("authority", "call_local", "reliable")
func teleport(new_pos: Vector2) -> void:
	velocity = Vector2.ZERO
	global_position = new_pos 


@export var acceleration: float = 400.0
@export var deceleration: float = 600.0
@export var max_speed: float = 120.0
@export var max_reverse_speed: float = 70.0
@export var turn_speed: float = 1.5 


@export var angular_damping: float = 100.0
@export var collision_torque_factor: float = 0.003

var speed: float = 0.0
var angular_velocity: float = 0.0

var last_received_position: Vector2 = Vector2.ZERO
var last_received_velocity: Vector2 = Vector2.ZERO
var last_received_rotation: float = 0.0
var time_since_last_update: float = 0.0

func on_state_received() -> void:
	last_received_position = global_position
	last_received_velocity = velocity
	last_received_rotation = rotation
	time_since_last_update = 0.0

func _physics_process(delta: float) -> void:
	# Only process physics if local
	if local:
		var turn_input: float = 0.0
		var move_input: float = 0.0

		if Input.is_action_pressed("turn_right"):
			turn_input += 1
		if Input.is_action_pressed("turn_left"):
			turn_input -= 1
		if Input.is_action_pressed("move_forward"):
			move_input += 1
		if Input.is_action_pressed("move_back"):
			move_input -= 1
		
		# Accelerate/decelerate toward target speed
		if !is_zero_approx(move_input):
			var target_speed: float = max_speed if (move_input > 0) else -max_reverse_speed
			speed = move_toward(speed, target_speed, acceleration * delta)
		else:
			speed = move_toward(speed, 0, deceleration * delta)
		
		var forward: Vector2 = Vector2.DOWN.rotated(rotation)
		var pre_velocity: Vector2 = forward * speed
		velocity = pre_velocity
		
		move_and_slide()
		
		speed = velocity.dot(forward)
		
		for i in get_slide_collision_count():
			var collision: KinematicCollision2D = get_slide_collision(i)
			var normal: Vector2 = collision.get_normal()
			var torque: float = pre_velocity.cross(normal)
			angular_velocity += torque * collision_torque_factor

		rotation += (turn_input * turn_speed + angular_velocity) * delta
		angular_velocity = move_toward(angular_velocity, 0, angular_damping * delta)
	
	#interpolate for other players
	else:
		time_since_last_update += delta
		if time_since_last_update > 0.02:
			var forward: Vector2 = Vector2.DOWN.rotated(last_received_rotation)
			global_position += forward * last_received_velocity.length() * delta

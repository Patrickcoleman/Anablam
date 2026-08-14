extends CharacterBody2D
class_name Player

var peer_id: int = 1 
var local: bool = true

const CHARACTERS: Array[SpriteFrames] = [
	preload("res://objects/player/bodies/green_player.tres"),
	preload("res://objects/player/bodies/red_player.tres"),
	preload("res://objects/player/bodies/black_player.tres"),
	preload("res://objects/player/bodies/blue_player.tres"),
	preload("res://objects/player/bodies/beige_player.tres")
]

const BARRELS: Array[Texture2D] = [
	preload("res://objects/player/barrels/barrelGreen_outline.png"),
	preload("res://objects/player/barrels/barrelRed_outline.png"),
	preload("res://objects/player/barrels/barrelBlack_outline.png"),
	preload("res://objects/player/barrels/barrelBlue_outline.png"),
	preload("res://objects/player/barrels/barrelBeige_outline.png"),
]

var character: int = 0 :
	set(value):
		character = clampi(value, 0, CHARACTERS.size() - 1)
		$Body.sprite_frames = CHARACTERS[character]
		$Body.play(&"default")
		$Barrel.texture = BARRELS[character]

var display_name: String = "Player" :
	set(value):
		display_name = value
		$InfoPanel/DisplayName.text = display_name

var kill_count: int = 0 :
	set(value):
		kill_count = value
		get_node("/root/Lobby/Scoreboard").update_row.rpc(peer_id, display_name, kill_count, character)

# Lifecycle

func _enter_tree() -> void:
	peer_id = int(name)
	$ClientSynchronizer.set_multiplayer_authority(peer_id)
	local = (peer_id == multiplayer.get_unique_id())

func _ready() -> void:
	if (local):
		$Camera2D.make_current()
		submit_display_name.rpc_id(1, get_node("/root/Lobby").display_name)
	else:
		$HUD.queue_free()

@rpc("any_peer", "call_local", "reliable")
func submit_display_name(name_value: String) -> void:
	if !multiplayer.is_server(): return
	if multiplayer.get_remote_sender_id() != peer_id: return
	display_name = name_value


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
var barrel_angle: float = 0.0
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
		if Input.is_action_pressed("fire"):
			fire_bullet()
		
		update_barrel_angle()
		
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
		
	
	else:
		time_since_last_update += delta
		if time_since_last_update > 0.02:
			var forward: Vector2 = Vector2.DOWN.rotated(last_received_rotation)
			global_position += forward * last_received_velocity.length() * delta
	
	$Barrel.rotation = barrel_angle - rotation

#bullet firing logic
const bullet_SCN: PackedScene = preload("res://objects/bullets/bullet.tscn")

func fire_bullet() -> void:
	if (!local): return
	if !$FireCooldown.is_stopped(): return
	if (!multiplayer.is_server()):
		_request_fire.rpc_id(1)
		$FireCooldown.start()
		return
	_spawn_bullet()
	$FireCooldown.start()

@rpc("any_peer", "call_remote", "reliable")
func _request_fire() -> void:
	if (!multiplayer.is_server()): return
	_spawn_bullet()

func _spawn_bullet() -> void:
	var bullet: Bullet = bullet_SCN.instantiate()
	bullet.position = global_position + Vector2.DOWN.rotated(barrel_angle) * 20.0
	bullet.rotation = barrel_angle
	bullet.owner_peer_id = peer_id
	get_node("/root/Lobby/Bullets").add_child(bullet, true)
	
func update_barrel_angle():
	barrel_angle = get_angle_to_mouse()
	
func get_angle_to_mouse() -> float:
		var mouse_pos: Vector2 = get_global_mouse_position()
		var direction: Vector2 = mouse_pos - global_position
		return direction.angle() - PI / 2

@rpc("authority", "call_local", "reliable")
func kill() -> void:
	set_hidden(true)
	if multiplayer.is_server():
		$RespawnTimer.start()

func _on_respawn_timer_timeout() -> void:
	if multiplayer.is_server():
		get_node("/root/Lobby").respawn_player(peer_id)

@rpc("authority", "call_local", "reliable")
func revive(new_pos: Vector2) -> void:
	global_position = new_pos
	set_hidden(false)

func set_hidden(hidden_bool: bool) -> void:
	visible = !hidden_bool
	$Hitbox.set_deferred("disabled", hidden_bool)
	set_physics_process(!hidden_bool)

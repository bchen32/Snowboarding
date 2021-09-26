extends KinematicBody

# Physical characteristics
export var gravity: float = 9.8
export var initial_vel: float = 2
export var min_vel: float = 0.5
export var max_angle_diff: float = 2 * PI / 5
export var max_turn_coeff: float = 3
export var min_friction: float = 0.0
export var max_friction: float = 0.1

export var turn_angle_coeff: float = 0.5
export var turn_vel_coeff: float = 0.01
export var rtc_angle_coeff: float = 0.5
export var angle_vel_coeff: float = 0.6
export var friction_vel_coeff: float = 0.000005

# Vel
var velocity: Vector3 = Globals.downhill * initial_vel
var downhill_vel: Vector3 = Globals.downhill * initial_vel
var lateral_vel: Vector3 = Vector3()

# Death
signal death
var move: bool = false

func reset() -> void:
	velocity = Globals.downhill * initial_vel
	downhill_vel = Globals.downhill * initial_vel
	lateral_vel = Vector3()

func _physics_process(delta: float) -> void:
	# Only move when allowed
	if !move:
		return
	# Check angle difference between current velocity and downhill
	var angle_diff: float = Globals.downhill.angle_to(velocity)
	# Get signed difference
	if Globals.downhill.cross(velocity).dot(Globals.normal) < 0:
		angle_diff = -angle_diff
	# Inverted angle difference
	var inv_angle_diff: float = PI / 2 - abs(angle_diff)
	# Turn player if angle difference doesn't exceed max
	if Input.is_action_pressed('move_left') and angle_diff < max_angle_diff:
		velocity = velocity.rotated(Globals.normal, PI * inv_angle_diff * turn_angle_coeff * clamp(velocity.length() * turn_vel_coeff, 1, max_turn_coeff) * delta)
	if Input.is_action_pressed('move_right') and angle_diff > -max_angle_diff:
		velocity = velocity.rotated(Globals.normal, -PI * inv_angle_diff * turn_angle_coeff * clamp(velocity.length() * turn_vel_coeff, 1, max_turn_coeff) * delta)
	# Return to center force
	velocity = velocity.rotated(Globals.normal, -PI * inv_angle_diff * turn_angle_coeff * angle_diff * rtc_angle_coeff * clamp(velocity.length() * turn_vel_coeff, 1, max_turn_coeff) * delta)
	# Give more forward velocity the more the player faces downhill
	var normalized_vel: Vector3 = velocity.normalized()
	velocity += normalized_vel * gravity * pow(inv_angle_diff, 2) * angle_vel_coeff * delta
	# Apply friction based on speed
	velocity *= 1 - clamp(velocity.length() * friction_vel_coeff, min_friction, max_friction)
	if velocity.length() < min_vel:
		velocity = normalized_vel * min_vel
	# Break velocity down into downhill and lateral components
	downhill_vel = velocity.project(Globals.downhill)
	lateral_vel = velocity - downhill_vel
	# Only move player along lateral velocity, downhill velocity will be simulated by moving obstacles uphill
	var move_collision: KinematicCollision = move_and_collide(lateral_vel * delta)
	if move_collision:
		emit_signal('death')

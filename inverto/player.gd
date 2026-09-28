extends CharacterBody2D

var speed = 300
var base_speed = 300
var boosted_speed = 550
var obstacles_node = null

var speed_boost_timer = 0.0
var rainbow_timer = 0.0
var effect_duration = 7.0
var blink_threshold = 2.0
var is_dead = false

func _ready():
	position = Vector2(240, 400)
	queue_redraw()
	obstacles_node = get_node("../Obstacles")

func _draw():
	if rainbow_timer > 0:
		var t = Time.get_ticks_msec() / 200.0
		var rcol = Color.from_hsv(fmod(t, 1.0), 1.0, 1.0)
		var alpha = 0.5
		if rainbow_timer < blink_threshold:
			alpha = 0.3 + 0.3 * sin(Time.get_ticks_msec() / 80.0)
		draw_circle(Vector2.ZERO, 26, Color(rcol.r, rcol.g, rcol.b, alpha))
	elif speed_boost_timer > 0:
		var alpha = 0.35
		if speed_boost_timer < blink_threshold:
			alpha = 0.15 + 0.25 * sin(Time.get_ticks_msec() / 80.0)
		draw_circle(Vector2.ZERO, 24, Color(0.3, 1, 0.5, alpha))
	else:
		draw_circle(Vector2.ZERO, 22, Color(0.3, 0.8, 1, 0.25))
		draw_circle(Vector2.ZERO, 17, Color(0.3, 0.8, 1, 0.4))

	var points = PackedVector2Array([
		Vector2(0, -14),
		Vector2(12, 0),
		Vector2(0, 14),
		Vector2(-12, 0)
	])
	var body_color = get_parent().get_selected_skin_color()
	if rainbow_timer > 0:
		var t2 = Time.get_ticks_msec() / 200.0
		body_color = Color.from_hsv(fmod(t2, 1.0), 0.8, 1.0)
	elif speed_boost_timer > 0:
		body_color = Color(0.3, 1, 0.5)
	draw_colored_polygon(points, body_color)

	var inner = PackedVector2Array([
		Vector2(0, -7),
		Vector2(6, 0),
		Vector2(0, 7),
		Vector2(-6, 0)
	])
	draw_colored_polygon(inner, Color(1, 1, 1, 0.6))

func _physics_process(delta):
	if not get_parent().game_started or get_parent().shop_open:
		return
	if is_dead:
		return

	if speed_boost_timer > 0:
		speed_boost_timer -= delta
		speed = boosted_speed
		if speed_boost_timer <= 0:
			speed = base_speed
	if rainbow_timer > 0:
		rainbow_timer -= delta

	queue_redraw()

	var direction = Vector2.ZERO
	if Input.is_action_pressed("ui_up"):
		direction.y += 1
	if Input.is_action_pressed("ui_down"):
		direction.y -= 1
	if Input.is_action_pressed("ui_left"):
		direction.x += 1
	if Input.is_action_pressed("ui_right"):
		direction.x -= 1

	velocity = direction.normalized() * speed
	move_and_slide()

	position.x = clamp(position.x, 20, 460)
	position.y = clamp(position.y, 20, 780)

	var powerup_type = obstacles_node.check_powerup_collision(position)
	if powerup_type == "speed":
		speed_boost_timer = effect_duration
	elif powerup_type == "rainbow":
		rainbow_timer = effect_duration

	if rainbow_timer <= 0 and not is_dead:
		if obstacles_node.check_collision(position):
			is_dead = true
			get_parent().play_blast_sound()
			await get_tree().create_timer(0.35).timeout
			get_tree().reload_current_scene()

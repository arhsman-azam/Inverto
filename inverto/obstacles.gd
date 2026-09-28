extends Node2D

var scroll_speed = 200
var spawn_timer = 0.0
var spawn_interval = 1.5
var elapsed_time = 0.0
var obstacles = []
var powerups = []
var pulse = 0.0

var last_speed_level = 0
var last_rainbow_level = 0

var level_colors = [
	[Color(0.95, 0.55, 0.25), Color(0.75, 0.25, 0.15)],
	[Color(0.85, 0.75, 0.25), Color(0.6, 0.45, 0.1)],
	[Color(0.3, 0.75, 0.55), Color(0.1, 0.45, 0.35)],
	[Color(0.35, 0.6, 0.85), Color(0.15, 0.3, 0.6)],
	[Color(0.6, 0.45, 0.8), Color(0.35, 0.2, 0.55)],
	[Color(0.8, 0.4, 0.5), Color(0.5, 0.2, 0.3)],
]

func _process(delta):
	if not get_parent().game_started:
		return

	elapsed_time += delta
	pulse = sin(elapsed_time * 4.0) * 0.5 + 0.5
	scroll_speed = 200 + elapsed_time * 5
	spawn_interval = max(0.5, 1.5 - elapsed_time * 0.02)

	var new_level = int(elapsed_time / 10) + 1
	if new_level != get_parent().current_level:
		get_parent().current_level = new_level
		get_parent().level_up_flash = 1.0

		if new_level % 2 == 0 and new_level != last_speed_level:
			last_speed_level = new_level
			spawn_powerup("speed")
		if new_level % 3 == 0 and new_level != last_rainbow_level:
			last_rainbow_level = new_level
			spawn_powerup("rainbow")

	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		spawn_obstacle()

	for obs in obstacles:
		obs.y += scroll_speed * delta
	obstacles = obstacles.filter(func(obs): return obs.y < 850)

	for p in powerups:
		p.y += scroll_speed * delta
	powerups = powerups.filter(func(p): return p.y < 850)

	queue_redraw()

func spawn_obstacle():
	var gap_x = randi_range(60, 420)
	obstacles.append({"y": -20, "gap_x": gap_x})

func spawn_powerup(type: String):
	var x = randi_range(60, 420)
	powerups.append({"y": -30, "x": x, "type": type})

func get_current_colors() -> Array:
	var lvl = get_parent().current_level
	var idx = min(lvl - 1, level_colors.size() - 1)
	return level_colors[idx]

func draw_bar(x: float, width: float, y: float, top_color: Color, bottom_color: Color, near_gap_right: bool):
	if width <= 0:
		return
	var style = get_parent().get_selected_bar_style()
	match style:
		0: draw_bar_classic(x, width, y, top_color, bottom_color, near_gap_right)
		1: draw_bar_neon(x, width, y, top_color, bottom_color)
		2: draw_bar_crystal(x, width, y, top_color, bottom_color)
		3: draw_bar_metal(x, width, y, top_color, bottom_color)

func draw_bar_classic(x, width, y, top_color, bottom_color, near_gap_right):
	var h = 30.0
	var glow_a = 0.2 + pulse * 0.2
	draw_rect(Rect2(x - 4, y - 4, width + 8, h + 8), Color(top_color.r, top_color.g, top_color.b, glow_a))
	draw_rect(Rect2(x, y, width, h), Color(0.08, 0.08, 0.1))
	var inset = 3.0
	var steps = 6
	for i in range(steps):
		var t = i / float(steps)
		var col = top_color.lerp(bottom_color, t)
		draw_rect(Rect2(x + inset, y + inset + t * (h - inset * 2), width - inset * 2, (h - inset * 2) / steps + 1), col)
	var seg_width = 22.0
	var num_segs = int(width / seg_width)
	for s in range(1, num_segs + 1):
		var sx = x + s * seg_width
		if sx < x + width - inset:
			draw_rect(Rect2(sx, y + inset, 1.5, h - inset * 2), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(x + inset, y + inset, width - inset * 2, 3), Color(1, 1, 1, 0.7))

func draw_bar_neon(x, width, y, top_color, bottom_color):
	var h = 30.0
	var cy = y + h / 2.0
	var glow_a = 0.3 + pulse * 0.25
	draw_rect(Rect2(x - 6, y - 6, width + 12, h + 12), Color(top_color.r, top_color.g, top_color.b, glow_a * 0.5))
	draw_rect(Rect2(x, y + 4, width, h - 8), top_color.lerp(bottom_color, 0.5))
	draw_circle(Vector2(x, cy), (h - 8) / 2.0, top_color.lerp(bottom_color, 0.5))
	draw_circle(Vector2(x + width, cy), (h - 8) / 2.0, top_color.lerp(bottom_color, 0.5))
	draw_rect(Rect2(x, y + 8, width, 3), Color(1, 1, 1, 0.8))

func draw_bar_crystal(x, width, y, top_color, bottom_color):
	var h = 30.0
	draw_rect(Rect2(x - 3, y - 3, width + 6, h + 6), Color(top_color.r, top_color.g, top_color.b, 0.25))
	var facet_w = 16.0
	var num_facets = int(width / facet_w) + 1
	for i in range(num_facets):
		var fx = x + i * facet_w
		var fw = min(facet_w, x + width - fx)
		if fw <= 0:
			break
		var shade = 0.15 if i % 2 == 0 else -0.1
		var col = top_color.lerp(bottom_color, 0.5)
		col = Color(clamp(col.r + shade, 0, 1), clamp(col.g + shade, 0, 1), clamp(col.b + shade, 0, 1))
		var pts = PackedVector2Array([
			Vector2(fx, y),
			Vector2(fx + fw, y),
			Vector2(fx + fw * 0.5, y + h)
		])
		draw_colored_polygon(pts, col)
	draw_rect(Rect2(x, y, width, 2), Color(1, 1, 1, 0.6))

func draw_bar_metal(x, width, y, top_color, bottom_color):
	var h = 30.0
	draw_rect(Rect2(x - 3, y - 3, width + 6, h + 6), Color(0.05, 0.05, 0.06, 0.4))
	var steps = 5
	for i in range(steps):
		var t = i / float(steps)
		var col = top_color.lerp(bottom_color, t) * Color(0.85, 0.85, 0.85)
		draw_rect(Rect2(x, y + t * h, width, h / steps + 1), col)
	var grid = 14.0
	var gx = x
	while gx < x + width:
		draw_rect(Rect2(gx, y, 1, h), Color(0, 0, 0, 0.3))
		gx += grid
	var rivet_x = x + 6
	while rivet_x < x + width - 6:
		draw_circle(Vector2(rivet_x, y + 6), 1.5, Color(1, 1, 1, 0.5))
		draw_circle(Vector2(rivet_x, y + h - 6), 1.5, Color(1, 1, 1, 0.5))
		rivet_x += grid

func draw_style_preview(style_id: int, cx: float, cw: float, cy: float):
	var top_color = Color(0.4, 0.75, 1)
	var bottom_color = Color(0.15, 0.35, 0.7)
	match style_id:
		0: draw_bar_classic(cx, cw, cy, top_color, bottom_color, false)
		1: draw_bar_neon(cx, cw, cy, top_color, bottom_color)
		2: draw_bar_crystal(cx, cw, cy, top_color, bottom_color)
		3: draw_bar_metal(cx, cw, cy, top_color, bottom_color)

func draw_powerup(p):
	var x = p.x
	var y = p.y
	if p.type == "speed":
		draw_circle(Vector2(x, y), 22, Color(0.3, 1, 0.5, 0.25 + pulse * 0.15))
		draw_circle(Vector2(x, y), 16, Color(0.05, 0.15, 0.1))
		var arrow = PackedVector2Array([
			Vector2(x, y - 10),
			Vector2(x + 8, y),
			Vector2(x + 3, y),
			Vector2(x + 3, y + 8),
			Vector2(x - 3, y + 8),
			Vector2(x - 3, y),
			Vector2(x - 8, y)
		])
		draw_colored_polygon(arrow, Color(0.4, 1, 0.6))
	elif p.type == "rainbow":
		var t = Time.get_ticks_msec() / 200.0
		draw_circle(Vector2(x, y), 22, Color(1, 1, 1, 0.15 + pulse * 0.1))
		for i in range(6):
			var hue = fmod(t + i / 6.0, 1.0)
			var col = Color.from_hsv(hue, 1.0, 1.0)
			draw_arc(Vector2(x, y), 14 - i * 1.5, 0, TAU, 24, col, 3.0)

func _draw():
	var colors = get_current_colors()
	for obs in obstacles:
		var gap_x = obs.gap_x
		var y = obs.y
		draw_bar(0, gap_x - 60, y, colors[0], colors[1], true)
		draw_bar(gap_x + 60, 480 - (gap_x + 60), y, colors[0], colors[1], false)

	for p in powerups:
		draw_powerup(p)

func check_collision(player_pos: Vector2) -> bool:
	var r = 14.0
	for obs in obstacles:
		var gap_x = obs.gap_x
		var y = obs.y
		if y - r < player_pos.y and player_pos.y < y + 30 + r:
			if player_pos.x - r < gap_x - 60 or player_pos.x + r > gap_x + 60:
				return true
	return false

func check_powerup_collision(player_pos: Vector2) -> String:
	for i in range(powerups.size() - 1, -1, -1):
		var p = powerups[i]
		if abs(player_pos.x - p.x) < 28 and abs(player_pos.y - p.y) < 28:
			var t = p.type
			powerups.remove_at(i)
			return t
	return ""

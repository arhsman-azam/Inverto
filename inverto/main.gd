extends Node2D

var score = 0.0
var best_score = 0.0
var game_started = false
var current_level = 1
var level_up_flash = 0.0
var bg_scroll = 0.0

var coins = 0
var coin_timer = 0.0
var shop_open = false
var shop_tab = 0
var shop_cursor = 0

var owned_skins = [0]
var owned_bars = [0]
var selected_skin = 0
var selected_bar = 0

var skins = [
	{"name": "Sky Blue", "price": 0, "color": Color(0.3, 0.85, 1)},
	{"name": "Crimson", "price": 20, "color": Color(0.9, 0.2, 0.25)},
	{"name": "Emerald", "price": 20, "color": Color(0.2, 0.85, 0.5)},
	{"name": "Gold", "price": 35, "color": Color(1, 0.8, 0.2)},
	{"name": "Violet", "price": 35, "color": Color(0.7, 0.3, 0.9)},
	{"name": "Obsidian", "price": 50, "color": Color(0.12, 0.12, 0.16)},
]

var bar_styles = [
	{"name": "Classic", "price": 0},
	{"name": "Neon Tube", "price": 30},
	{"name": "Crystal", "price": 35},
	{"name": "Metal Mesh", "price": 40},
]

var bg_colors = [
	[Color(0.15, 0.08, 0.05), Color(0.35, 0.15, 0.08)],
	[Color(0.14, 0.12, 0.04), Color(0.32, 0.26, 0.08)],
	[Color(0.04, 0.12, 0.09), Color(0.08, 0.28, 0.2)],
	[Color(0.04, 0.08, 0.14), Color(0.08, 0.18, 0.32)],
	[Color(0.1, 0.06, 0.14), Color(0.22, 0.1, 0.3)],
	[Color(0.14, 0.05, 0.08), Color(0.3, 0.1, 0.16)],
]

func _ready():
	load_data()
	$ScoreLabel.visible = false
	if $MusicPlayer.stream:
		$MusicPlayer.stream.loop = true
	setup_custom_cursor()
	queue_redraw()

func setup_custom_cursor():
	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var center = Vector2(size / 2.0, size / 2.0)

	for y in range(size):
		for x in range(size):
			var dx = abs(x - center.x)
			var dy = abs(y - center.y)
			var diamond_dist = dx + dy

			if diamond_dist < 9:
				var t = diamond_dist / 9.0
				var col = Color(0.3, 0.9, 1.0).lerp(Color(1, 1, 1), 1.0 - t * 0.5)
				img.set_pixel(x, y, col)
			elif diamond_dist < 12:
				var alpha = 1.0 - ((diamond_dist - 9) / 3.0)
				img.set_pixel(x, y, Color(0.3, 0.85, 1, alpha * 0.6))

	var texture = ImageTexture.create_from_image(img)
	Input.set_custom_mouse_cursor(texture, Input.CURSOR_ARROW, Vector2(size / 2.0, size / 2.0))

func load_data():
	if FileAccess.file_exists("user://save_data.json"):
		var file = FileAccess.open("user://save_data.json", FileAccess.READ)
		var text = file.get_as_text()
		file.close()
		var data = JSON.parse_string(text)
		if data:
			best_score = data.get("best_score", 0.0)
			coins = data.get("coins", 0)
			owned_skins = data.get("owned_skins", [0])
			owned_bars = data.get("owned_bars", [0])
			selected_skin = data.get("selected_skin", 0)
			selected_bar = data.get("selected_bar", 0)

func save_data():
	var data = {
		"best_score": best_score,
		"coins": coins,
		"owned_skins": owned_skins,
		"owned_bars": owned_bars,
		"selected_skin": selected_skin,
		"selected_bar": selected_bar,
	}
	var file = FileAccess.open("user://save_data.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		handle_click(event.position)

func handle_click(pos: Vector2):
	if shop_open:
		if Rect2(430, 20, 30, 30).has_point(pos):
			shop_open = false
			queue_redraw()
			return
		if Rect2(140, 150, 110, 30).has_point(pos):
			shop_tab = 0
			shop_cursor = 0
			queue_redraw()
			return
		if Rect2(280, 150, 110, 30).has_point(pos):
			shop_tab = 1
			shop_cursor = 0
			queue_redraw()
			return
		var list_size = skins.size() if shop_tab == 0 else bar_styles.size()
		if Rect2(50, 340, 40, 40).has_point(pos):
			shop_cursor = (shop_cursor - 1 + list_size) % list_size
			queue_redraw()
			return
		if Rect2(390, 340, 40, 40).has_point(pos):
			shop_cursor = (shop_cursor + 1) % list_size
			queue_redraw()
			return
		if Rect2(140, 480, 200, 40).has_point(pos):
			buy_or_select()
			return
		return

	if not game_started:
		if Rect2(120, 430, 240, 50).has_point(pos):
			game_started = true
			score = 0.0
			coin_timer = 0.0
			$MusicPlayer.play()
			queue_redraw()
			return
		if Rect2(120, 495, 240, 40).has_point(pos):
			shop_open = true
			shop_cursor = 0
			queue_redraw()
			return

func _process(delta):
	$Player.visible = game_started and not shop_open
	$Obstacles.visible = game_started and not shop_open

	if shop_open:
		return

	if not game_started:
		bg_scroll += delta * 20
		queue_redraw()
		return

	score += delta
	bg_scroll += delta * 40

	coin_timer += delta
	if coin_timer >= 2.0:
		coin_timer -= 2.0
		coins += 1
		save_data()

	if score > best_score:
		best_score = score
		save_data()

	if level_up_flash > 0:
		level_up_flash -= delta * 2

	queue_redraw()

func buy_or_select():
	if shop_tab == 0:
		var item = skins[shop_cursor]
		if owned_skins.has(shop_cursor):
			selected_skin = shop_cursor
		elif coins >= item.price:
			coins -= item.price
			owned_skins.append(shop_cursor)
			selected_skin = shop_cursor
		save_data()
	else:
		var item = bar_styles[shop_cursor]
		if owned_bars.has(shop_cursor):
			selected_bar = shop_cursor
		elif coins >= item.price:
			coins -= item.price
			owned_bars.append(shop_cursor)
			selected_bar = shop_cursor
		save_data()
	queue_redraw()

func get_selected_skin_color() -> Color:
	return skins[selected_skin].color

func get_selected_bar_style() -> int:
	return selected_bar

func play_blast_sound():
	$CrashSound.play()
	var playback = $CrashSound.get_stream_playback()
	var sample_rate = 22050.0
	var duration = 0.35
	var total_samples = int(sample_rate * duration)
	for i in range(total_samples):
		var t = i / sample_rate
		var envelope = pow(1.0 - (i / float(total_samples)), 2.0)
		var noise = randf_range(-1.0, 1.0)
		var low_thump = sin(t * 60.0 * TAU) * 0.5
		var sample = (noise * 0.6 + low_thump * 0.4) * envelope
		playback.push_frame(Vector2(sample, sample))

func draw_moving_bg(top_color: Color, bottom_color: Color):
	for i in range(20):
		var t = i / 20.0
		var col = top_color.lerp(bottom_color, t)
		draw_rect(Rect2(0, i * 40, 480, 40), col)

	var stripe_color = Color(1, 1, 1, 0.05)
	var spacing = 60.0
	var offset = fmod(bg_scroll, spacing)
	var i = -2
	while i * spacing - offset < 480 + 800:
		var sx = i * spacing - offset
		var points = PackedVector2Array([
			Vector2(sx, 0),
			Vector2(sx + 30, 0),
			Vector2(sx + 30 - 800, 800),
			Vector2(sx - 800, 800)
		])
		draw_colored_polygon(points, stripe_color)
		i += 1

func draw_stat_box(x: float, label: String, value: String, accent: Color):
	var box_w = 145.0
	var box_h = 54.0
	var y = 16.0
	draw_rect(Rect2(x - 2, y - 2, box_w + 4, box_h + 4), Color(accent.r, accent.g, accent.b, 0.2))
	draw_rect(Rect2(x, y, box_w, box_h), Color(0.05, 0.05, 0.08, 0.85))
	draw_rect(Rect2(x, y, box_w, 3), accent)
	draw_string(ThemeDB.fallback_font, Vector2(x + 10, y + 20), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.6))
	draw_string(ThemeDB.fallback_font, Vector2(x + 10, y + 44), value, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, accent)

func draw_centered(text: String, y: float, size: int, color: Color):
	var w = ThemeDB.fallback_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(ThemeDB.fallback_font, Vector2((480 - w) / 2, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func draw_bar_style_preview(style_id: int, x: float, width: float, y: float):
	var top_color = Color(0.4, 0.75, 1)
	var bottom_color = Color(0.15, 0.35, 0.7)
	var h = 30.0

	if style_id == 0:
		draw_rect(Rect2(x, y, width, h), Color(0.08, 0.08, 0.1))
		var inset = 3.0
		var steps = 6
		for i in range(steps):
			var t = i / float(steps)
			var col = top_color.lerp(bottom_color, t)
			draw_rect(Rect2(x + inset, y + inset + t * (h - inset * 2), width - inset * 2, (h - inset * 2) / steps + 1), col)
		draw_rect(Rect2(x + inset, y + inset, width - inset * 2, 3), Color(1, 1, 1, 0.7))

	elif style_id == 1:
		var cy = y + h / 2.0
		draw_rect(Rect2(x, y + 4, width, h - 8), top_color.lerp(bottom_color, 0.5))
		draw_circle(Vector2(x, cy), (h - 8) / 2.0, top_color.lerp(bottom_color, 0.5))
		draw_circle(Vector2(x + width, cy), (h - 8) / 2.0, top_color.lerp(bottom_color, 0.5))
		draw_rect(Rect2(x, y + 8, width, 3), Color(1, 1, 1, 0.8))

	elif style_id == 2:
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

	elif style_id == 3:
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

func draw_shop():
	draw_rect(Rect2(0, 0, 480, 800), Color(0.03, 0.03, 0.06, 0.97))
	draw_centered("SHOP", 90, 40, Color(1, 0.85, 0.2))
	draw_centered("Coins: " + str(coins), 130, 18, Color(1, 0.9, 0.4))

	draw_rect(Rect2(430, 20, 30, 30), Color(1, 0.3, 0.3, 0.2))
	draw_rect(Rect2(430, 20, 30, 30), Color(1, 0.3, 0.3), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(440, 42), "X", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 0.5, 0.5))

	var skins_active = shop_tab == 0
	var bars_active = shop_tab == 1

	draw_rect(Rect2(140, 150, 110, 30), Color(1, 0.85, 0.2, 0.15) if skins_active else Color(1, 1, 1, 0.05))
	draw_rect(Rect2(140, 150, 110, 30), Color(1, 0.85, 0.2) if skins_active else Color(1, 1, 1, 0.15), false, 2)
	var s_col = Color(1, 0.85, 0.2) if skins_active else Color(0.7, 0.7, 0.7)
	var s_w = ThemeDB.fallback_font.get_string_size("SKINS", HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(ThemeDB.fallback_font, Vector2(140 + (110 - s_w) / 2, 170), "SKINS", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, s_col)

	draw_rect(Rect2(280, 150, 110, 30), Color(1, 0.85, 0.2, 0.15) if bars_active else Color(1, 1, 1, 0.05))
	draw_rect(Rect2(280, 150, 110, 30), Color(1, 0.85, 0.2) if bars_active else Color(1, 1, 1, 0.15), false, 2)
	var b_col = Color(1, 0.85, 0.2) if bars_active else Color(0.7, 0.7, 0.7)
	var b_w = ThemeDB.fallback_font.get_string_size("BARS", HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(ThemeDB.fallback_font, Vector2(280 + (110 - b_w) / 2, 170), "BARS", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, b_col)

	var list = skins if shop_tab == 0 else bar_styles
	var owned = owned_skins if shop_tab == 0 else owned_bars
	var selected = selected_skin if shop_tab == 0 else selected_bar
	var item = list[shop_cursor]

	draw_rect(Rect2(90, 260, 300, 220), Color(0.08, 0.08, 0.12))
	draw_rect(Rect2(90, 260, 300, 220), Color(1, 1, 1, 0.1), false, 2)

	if shop_tab == 0:
		draw_circle(Vector2(240, 350), 22, Color(item.color.r, item.color.g, item.color.b, 0.3))
		var pts = PackedVector2Array([Vector2(240, 336), Vector2(252, 350), Vector2(240, 364), Vector2(228, 350)])
		draw_colored_polygon(pts, item.color)
	else:
		draw_bar_style_preview(shop_cursor, 120, 220, 350)

	draw_centered(item.name, 420, 22, Color(1, 1, 1))

	draw_rect(Rect2(50, 340, 40, 40), Color(1, 1, 1, 0.08))
	draw_rect(Rect2(50, 340, 40, 40), Color(1, 1, 1, 0.25), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(63, 367), "<", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.8))

	draw_rect(Rect2(390, 340, 40, 40), Color(1, 1, 1, 0.08))
	draw_rect(Rect2(390, 340, 40, 40), Color(1, 1, 1, 0.25), false, 2)
	draw_string(ThemeDB.fallback_font, Vector2(403, 367), ">", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(1, 1, 1, 0.8))

	var btn_text = ""
	var btn_color = Color(1, 1, 1)
	if owned.has(shop_cursor):
		if selected == shop_cursor:
			btn_text = "EQUIPPED"
			btn_color = Color(0.4, 1, 0.5)
		else:
			btn_text = "EQUIP"
			btn_color = Color(0.7, 0.9, 1)
	else:
		var can_afford = coins >= item.price
		btn_text = "BUY - " + str(item.price) + " coins"
		btn_color = Color(1, 0.9, 0.4) if can_afford else Color(1, 0.4, 0.4)

	draw_rect(Rect2(140, 480, 200, 40), Color(btn_color.r, btn_color.g, btn_color.b, 0.15))
	draw_rect(Rect2(140, 480, 200, 40), btn_color, false, 2)
	var btn_w = ThemeDB.fallback_font.get_string_size(btn_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(ThemeDB.fallback_font, Vector2(140 + (200 - btn_w) / 2, 505), btn_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, btn_color)

func _draw():
	if shop_open:
		draw_shop()
		return

	var colors = bg_colors[min(current_level - 1, bg_colors.size() - 1)]
	draw_moving_bg(colors[0], colors[1])

	if game_started:
		draw_stat_box(10, "SCORE", str(int(score)), Color(1, 0.85, 0.3))
		draw_stat_box(167, "LEVEL", str(current_level), Color(0.4, 0.9, 1))
		draw_stat_box(325, "BEST", str(int(best_score)), Color(1, 0.4, 0.6))
		draw_centered("Coins: " + str(coins), 90, 14, Color(1, 0.9, 0.4))

		if level_up_flash > 0:
			var alpha = level_up_flash
			draw_rect(Rect2(0, 0, 480, 800), Color(1, 1, 0, alpha * 0.15))
			draw_centered("LEVEL " + str(current_level), 400, 40, Color(1, 1, 0, alpha))

	if not game_started:
		draw_rect(Rect2(90, 300, 300, 3), Color(1, 0.85, 0.2))
		draw_centered("INVERTO", 260, 56, Color(1, 0.85, 0.2))
		draw_centered("Controls are INVERTED", 340, 18, Color(1, 0.5, 0.5))

		draw_rect(Rect2(120, 430, 240, 50), Color(1, 0.85, 0.2, 0.15))
		draw_rect(Rect2(120, 430, 240, 50), Color(1, 0.85, 0.2), false, 2)
		draw_centered("PLAY", 462, 20, Color(1, 1, 1))

		draw_rect(Rect2(120, 495, 240, 40), Color(0.3, 0.8, 1, 0.12))
		draw_rect(Rect2(120, 495, 240, 40), Color(0.3, 0.8, 1), false, 2)
		draw_centered("SHOP", 519, 16, Color(0.4, 0.85, 1))

		draw_centered("Coins: " + str(coins), 555, 15, Color(1, 0.9, 0.4))

		if best_score > 0:
			draw_centered("Best: " + str(int(best_score)), 580, 16, Color(0.7, 0.7, 0.7))

		draw_rect(Rect2(180, 620, 120, 1), Color(1, 1, 1, 0.15))
		draw_centered("GAME BY", 645, 11, Color(1, 0.85, 0.2, 0.6))
		draw_centered("ARSHMAN AZAM", 665, 16, Color(1, 1, 1, 0.9))

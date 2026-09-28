extends Control

var coins: int = 0

var speed_upgrade: int = 0
var rainbow_upgrade: int = 0
var multiplier_upgrade: int = 0

var selected_skin: int = 0
var unlocked_skins = [true, false, false, false]

var store_open: bool = false

var title_label: Label
var coins_label: Label
var message_label: Label
var back_button: Button

var speed_button: Button
var rainbow_button: Button
var multiplier_button: Button

var skin_buttons: Array[Button] = []

func _ready():
	visible = false
	load_store()
	create_store_ui()


func create_store_ui():
	# Background
	var background = ColorRect.new()
	background.color = Color(0.025, 0.025, 0.05, 0.98)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	# Title
	title_label = Label.new()
	title_label.text = "INVERTO STORE"
	title_label.position = Vector2(0, 35)
	title_label.size = Vector2(480, 50)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(1, 0.85, 0.2))
	add_child(title_label)

	# Coins
	coins_label = Label.new()
	coins_label.position = Vector2(0, 90)
	coins_label.size = Vector2(480, 35)
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coins_label.add_theme_font_size_override("font_size", 22)
	coins_label.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	add_child(coins_label)

	# Speed
	speed_button = create_item_button(
		"⚡ SPEED BOOST",
		Vector2(50, 150)
	)
	speed_button.pressed.connect(buy_speed)
	add_child(speed_button)

	# Rainbow
	rainbow_button = create_item_button(
		"🌈 RAINBOW SHIELD",
		Vector2(50, 245)
	)
	rainbow_button.pressed.connect(buy_rainbow)
	add_child(rainbow_button)

	# Multiplier
	multiplier_button = create_item_button(
		"💰 COIN MULTIPLIER",
		Vector2(50, 340)
	)
	multiplier_button.pressed.connect(buy_multiplier)
	add_child(multiplier_button)

	# Skins title
	var skins_title = Label.new()
	skins_title.text = "PLAYER SKINS"
	skins_title.position = Vector2(0, 445)
	skins_title.size = Vector2(480, 35)
	skins_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skins_title.add_theme_font_size_override("font_size", 20)
	skins_title.add_theme_color_override("font_color", Color(0.4, 0.9, 1))
	add_child(skins_title)

	create_skin_button("BLUE", 0, Vector2(35, 495))
	create_skin_button("GREEN", 1, Vector2(145, 495))
	create_skin_button("PURPLE", 2, Vector2(255, 495))
	create_skin_button("GOLD", 3, Vector2(365, 495))

	# Message
	message_label = Label.new()
	message_label.text = ""
	message_label.position = Vector2(0, 610)
	message_label.size = Vector2(480, 35)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", 16)
	message_label.add_theme_color_override("font_color", Color(1, 1, 1))
	add_child(message_label)

	# Back
	back_button = Button.new()
	back_button.text = "BACK"
	back_button.position = Vector2(140, 680)
	back_button.size = Vector2(200, 55)
	back_button.add_theme_font_size_override("font_size", 20)
	back_button.pressed.connect(close_store)
	add_child(back_button)

	update_ui()


func create_item_button(text_value: String, pos: Vector2) -> Button:
	var button = Button.new()
	button.text = text_value
	button.position = pos
	button.size = Vector2(380, 75)
	button.add_theme_font_size_override("font_size", 19)
	return button


func create_skin_button(skin_name: String, skin_id: int, pos: Vector2):
	var button = Button.new()
	button.text = skin_name
	button.position = pos
	button.size = Vector2(95, 75)
	button.add_theme_font_size_override("font_size", 14)

	button.pressed.connect(func():
		select_skin(skin_id)
	)

	add_child(button)
	skin_buttons.append(button)


func update_ui():
	coins_label.text = "🪙 COINS: " + str(coins)

	speed_button.text = "⚡ SPEED BOOST  |  LEVEL " + str(speed_upgrade) + "\n" + get_price_text(speed_upgrade)

	rainbow_button.text = "🌈 RAINBOW SHIELD  |  LEVEL " + str(rainbow_upgrade) + "\n" + get_price_text(rainbow_upgrade)

	multiplier_button.text = "💰 COIN MULTIPLIER  |  LEVEL " + str(multiplier_upgrade) + "\n" + get_multiplier_price()

	for i in range(skin_buttons.size()):
		if unlocked_skins[i]:
			if selected_skin == i:
				skin_buttons[i].text = "✓ SELECTED"
			else:
				skin_buttons[i].text = ["BLUE", "GREEN", "PURPLE", "GOLD"][i]
		else:
			skin_buttons[i].text = "🔒 " + str(get_skin_price(i))

	save_store()


func get_price_text(level: int) -> String:
	var price = 50 + level * 50
	return "BUY  |  " + str(price) + " COINS"


func get_multiplier_price() -> String:
	var price = 100 + multiplier_upgrade * 100
	return "BUY  |  " + str(price) + " COINS"


func get_skin_price(id: int) -> int:
	return 150 + id * 100


func buy_speed():
	var price = 50 + speed_upgrade * 50

	if coins >= price:
		coins -= price
		speed_upgrade += 1
		message_label.text = "SPEED UPGRADED!"
	else:
		message_label.text = "NOT ENOUGH COINS!"

	update_ui()


func buy_rainbow():
	var price = 50 + rainbow_upgrade * 50

	if coins >= price:
		coins -= price
		rainbow_upgrade += 1
		message_label.text = "RAINBOW UPGRADED!"
	else:
		message_label.text = "NOT ENOUGH COINS!"

	update_ui()


func buy_multiplier():
	var price = 100 + multiplier_upgrade * 100

	if coins >= price:
		coins -= price
		multiplier_upgrade += 1
		message_label.text = "MULTIPLIER UPGRADED!"
	else:
		message_label.text = "NOT ENOUGH COINS!"

	update_ui()


func select_skin(id: int):
	if unlocked_skins[id]:
		selected_skin = id
		message_label.text = "SKIN SELECTED!"
	else:
		var price = get_skin_price(id)

		if coins >= price:
			coins -= price
			unlocked_skins[id] = true
			selected_skin = id
			message_label.text = "SKIN UNLOCKED!"
		else:
			message_label.text = "NOT ENOUGH COINS!"

	update_ui()


func open_store():
	store_open = true
	visible = true
	update_ui()


func close_store():
	store_open = false
	visible = false


func add_coins(amount: int):
	coins += amount
	save_store()
	update_ui()


func get_coin_multiplier() -> int:
	return 1 + multiplier_upgrade


func save_store():
	var data = {
		"coins": coins,
		"speed_upgrade": speed_upgrade,
		"rainbow_upgrade": rainbow_upgrade,
		"multiplier_upgrade": multiplier_upgrade,
		"selected_skin": selected_skin,
		"unlocked_skins": unlocked_skins
	}

	var file = FileAccess.open("user://store_data.json", FileAccess.WRITE)

	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func load_store():
	if not FileAccess.file_exists("user://store_data.json"):
		return

	var file = FileAccess.open("user://store_data.json", FileAccess.READ)

	if file:
		var text = file.get_as_text()
		file.close()

		var data = JSON.parse_string(text)

		if data:
			coins = int(data.get("coins", 0))
			speed_upgrade = int(data.get("speed_upgrade", 0))
			rainbow_upgrade = int(data.get("rainbow_upgrade", 0))
			multiplier_upgrade = int(data.get("multiplier_upgrade", 0))
			selected_skin = int(data.get("selected_skin", 0))
			unlocked_skins = data.get(
				"unlocked_skins",
				[true, false, false, false]
			)

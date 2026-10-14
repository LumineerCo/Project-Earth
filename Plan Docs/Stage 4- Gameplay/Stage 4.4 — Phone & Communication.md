# Stage 4.4 — Phone & Communication

The in-game phone is the player's central hub for communication, navigation, missions, and apps. It replaces traditional menus with a diegetic interface.

---

## Goal
Create a fully functional in-game smartphone with apps for contacts, messages, map, missions, banking, and settings.

---

## Step 1 — Phone Apps

| App | Icon | Function |
| :--- | :--- | :--- |
| **Contacts** | 👤 | View and call NPCs |
| **Messages** | ✉ | Read/send text messages |
| **Map** | 🗺 | View city map, set waypoints |
| **Missions** | 📋 | Track active and available missions |
| **Banking** | 🏦 | Check balance, transfer money |
| **Camera** | 📷 | Take screenshots (in-game photos) |
| **Settings** | ⚙ | Game options |
| **Internet** | 🌐 | Browse in-game websites (shops, news) |

---

## Step 2 — Phone System

### `PhoneSystem.gd` (Autoload)

```gdscript
extends Node

signal phone_opened
signal phone_closed
signal notification_received(app: String, title: String, body: String)
signal message_received(sender: String, text: String)

var is_open: bool = false
var contacts: Dictionary = {}  # contact_id -> {name, phone, relationship, photo}
var messages: Array[Dictionary] = []  # {sender, recipient, text, timestamp, read}
var notifications: Array[Dictionary] = []
var current_app: String = "home"

func open_phone() -> void:
    if is_open: return
    is_open = true
    phone_opened.emit()

func close_phone() -> void:
    is_open = false
    current_app = "home"
    phone_closed.emit()

func add_contact(contact_id: String, name: String, phone: String, photo: Texture2D = null) -> void:
    contacts[contact_id] = {
        "name": name,
        "phone": phone,
        "relationship": 0,  # -100 to 100
        "photo": photo,
    }

func send_message(recipient_id: String, text: String) -> void:
    var msg = {
        "sender": "player",
        "recipient": recipient_id,
        "text": text,
        "timestamp": TimeSystem.get_time_string(),
        "read": true,
    }
    messages.append(msg)

func receive_message(sender_id: String, text: String) -> void:
    var sender_name = "Unknown"
    if contacts.has(sender_id):
        sender_name = contacts[sender_id]["name"]
    var msg = {
        "sender": sender_id,
        "recipient": "player",
        "text": text,
        "timestamp": TimeSystem.get_time_string(),
        "read": false,
    }
    messages.append(msg)
    message_received.emit(sender_name, text)
    add_notification("Messages", sender_name, text)

func add_notification(app: String, title: String, body: String) -> void:
    var notif = {
        "app": app,
        "title": title,
        "body": body,
        "timestamp": TimeSystem.get_time_string(),
        "read": false,
    }
    notifications.append(notif)
    notification_received.emit(app, title, body)

func get_unread_count() -> int:
    var count = 0
    for n in notifications:
        if not n["read"]:
            count += 1
    return count

func mark_all_read() -> void:
    for n in notifications:
        n["read"] = true
```

---

## Step 3 — Phone UI

### `PhoneUI.gd`

```gdscript
extends Control

@onready var home_screen: Control = $HomeScreen
@onready var app_container: Control = $AppContainer
@onready var status_bar: Label = $StatusBar
@onready var notification_badge: Label = $HomeScreen/NotificationBadge

var apps: Dictionary = {}

func _ready() -> void:
    visible = false
    PhoneSystem.phone_opened.connect(_on_opened)
    PhoneSystem.phone_closed.connect(_on_closed)
    PhoneSystem.notification_received.connect(_on_notification)
    _register_apps()
    _update_status_bar()

func _register_apps() -> void:
    apps["contacts"] = $AppContainer/ContactsApp
    apps["messages"] = $AppContainer/MessagesApp
    apps["map"] = $AppContainer/MapApp
    apps["missions"] = $AppContainer/MissionsApp
    apps["banking"] = $AppContainer/BankingApp
    apps["settings"] = $AppContainer/SettingsApp
    for app in apps.values():
        app.visible = false

func _process(_delta: float) -> void:
    if Input.is_action_just_pressed("toggle_phone"):
        if PhoneSystem.is_open:
            PhoneSystem.close_phone()
        else:
            PhoneSystem.open_phone()

func _on_opened() -> void:
    visible = true
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    _show_home()

func _on_closed() -> void:
    visible = false
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
    _show_home()

func _show_home() -> void:
    home_screen.visible = true
    for app in apps.values():
        app.visible = false
    notification_badge.text = str(PhoneSystem.get_unread_count())
    notification_badge.visible = PhoneSystem.get_unread_count() > 0

func open_app(app_name: String) -> void:
    home_screen.visible = false
    for key in apps:
        apps[key].visible = (key == app_name)
    if apps.has(app_name):
        apps[app_name].on_opened()

func _on_notification(app: String, title: String, body: String) -> void:
    notification_badge.text = str(PhoneSystem.get_unread_count())
    notification_badge.visible = true
    # Show toast notification
    _show_toast(title, body)

func _show_toast(title: String, body: String) -> void:
    # Display a brief notification at top of screen
    pass

func _update_status_bar() -> void:
    var time = TimeSystem.get_time_string()
    var money = "%d Cr" % MoneySystem.cash
    status_bar.text = "%s  |  %s" % [time, money]
```

---

## Step 4 — Map App

### `MapApp.gd`

```gdscript
extends Control

@onready var map_texture: TextureRect = $MapTexture
@onready var player_marker: Sprite2D = $PlayerMarker
@onready var waypoint_marker: Sprite2D = $WaypointMarker

var waypoint: Vector2 = Vector2.ZERO  # Map coordinates
var has_waypoint: bool = false

func on_opened() -> void:
    _update_player_marker()

func _process(_delta: float) -> void:
    if visible:
        _update_player_marker()

func _update_player_marker() -> void:
    var player_pos = GlobalWorldState.player_global_position
    # Convert world position to map coordinates
    var map_pos = _world_to_map(player_pos)
    player_marker.position = map_pos

func _world_to_map(world_pos: Vector3) -> Vector2:
    # Nova City is 2000x2000, map texture is 512x512
    var map_size = map_texture.size
    var world_size = Vector2(2000, 2000)
    var origin = world_size / 2  # Center of city is origin
    var relative = Vector2(world_pos.x, world_pos.z) + origin
    return relative / world_size * map_size

func _on_map_clicked(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.pressed:
        waypoint = event.position
        waypoint_marker.position = waypoint
        waypoint_marker.visible = true
        has_waypoint = true
        # Set navigation waypoint in HUD
        var world_pos = _map_to_world(waypoint)
        HUDManager.set_waypoint(world_pos)

func _map_to_world(map_pos: Vector2) -> Vector3:
    var map_size = map_texture.size
    var world_size = Vector2(2000, 2000)
    var origin = world_size / 2
    var relative = map_pos / map_size * world_size
    return Vector3(relative.x - origin.x, 0, relative.y - origin.y)
```

---

## Step 5 — Messages App

### `MessagesApp.gd`

```gdscript
extends Control

@onready var contact_list: ItemList = $ContactList
@onready var message_display: RichTextLabel = $MessageDisplay
@onready var input_field: LineEdit = $InputField

var selected_contact: String = ""

func on_opened() -> void:
    _refresh_contacts()

func _refresh_contacts() -> void:
    contact_list.clear()
    for contact_id in PhoneSystem.contacts:
        var contact = PhoneSystem.contacts[contact_id]
        contact_list.add_item(contact["name"])
        contact_list.set_item_metadata(contact_list.item_count - 1, contact_id)

func _on_contact_selected(index: int) -> void:
    selected_contact = contact_list.get_item_metadata(index)
    _display_messages()

func _display_messages() -> void:
    message_display.text = ""
    for msg in PhoneSystem.messages:
        if msg["sender"] == selected_contact or msg["recipient"] == selected_contact:
            var sender = "You" if msg["sender"] == "player" else PhoneSystem.contacts[selected_contact]["name"]
            message_display.text += "[b]%s[/b] (%s): %s\n" % [sender, msg["timestamp"], msg["text"]]

func _on_send_pressed() -> void:
    if selected_contact == "" or input_field.text == "": return
    PhoneSystem.send_message(selected_contact, input_field.text)
    input_field.text = ""
    _display_messages()
```

---

## Step 6 — Phone as Physical Object

The phone is also visible in the player's hand when held.

```gdscript
# In PlayerController.gd
func _input(event: InputEvent) -> void:
    if event.is_action_pressed("toggle_phone"):
        if PhoneSystem.is_open:
            PhoneSystem.close_phone()
            _lower_phone()
        else:
            PhoneSystem.open_phone()
            _raise_phone()

func _raise_phone(self) -> void:
    $Camera3D/PhoneModel.visible = true
    # Play raise animation

func _lower_phone(self) -> void:
    $Camera3D/PhoneModel.visible = false
    # Play lower animation
```

The phone provides a diegetic interface that keeps the player immersed while giving access to all meta-game systems.

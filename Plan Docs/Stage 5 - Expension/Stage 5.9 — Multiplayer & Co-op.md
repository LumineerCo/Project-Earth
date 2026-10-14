# Stage 5.9 — Multiplayer & Co-op

Online co-op allows 2–4 players to share the same world, build together, run businesses jointly, and explore Project Earth as a team. Multiplayer is built on top of the single-player foundation — all core systems are designed to be network-aware from the start.

---

## Goal
Implement a peer-to-peer co-op multiplayer layer supporting 2–4 players per session, with synchronized world state, shared economies, joint business ownership, and seamless drop-in/drop-out gameplay.

---

## Step 1 — Network Architecture

### Topology Overview

```text
┌─────────────────────────────────────────────────────────────────┐
│                    Co-op Session (2-4 Players)                   │
│                                                                  │
│   ┌──────────┐      ┌──────────────┐      ┌──────────┐         │
│   │ Player 1 │◄────►│   Host Peer  │◄────►│ Player 2 │         │
│   │ (Host)   │      │  Authority    │      │ (Client) │         │
│   └──────────┘      └──────┬───────┘      └──────────┘         │
│                            │                                     │
│                            ▼                                     │
│   ┌──────────┐      ┌──────────────┐      ┌──────────┐         │
│   │ Player 3 │◄────►│  World State  │◄────►│ Player 4 │         │
│   │ (Client) │      │  Sync Manager │      │ (Client) │         │
│   └──────────┘      └──────────────┘      └──────────┘         │
│                                                                  │
│   • Host = authoritative server                                  │
│   • Clients send inputs, receive state                           │
│   • ENet peer-to-peer (no dedicated server needed)               │
│   • Steam integration for lobby/matchmaking                      │
└─────────────────────────────────────────────────────────────────┘
```

### Network Modes

| Mode | Players | Description | Use Case |
| :--- | :--- | :--- | :--- |
| **Single Player** | 1 | Offline, all systems local | Default mode |
| **Co-op Private** | 2–4 | Invite-only via Steam friends | Playing with friends |
| **Co-op Public** | 2–4 | Open lobby, anyone can join | Meeting new players |
| **LAN** | 2–4 | Local network, no internet | Offline gatherings |

### `NetworkManager.gd`

```gdscript
extends Node
class_name NetworkManager

enum NetworkMode { SINGLEPLAYER, COOP_HOST, COOP_CLIENT, LAN }

const MAX_PLAYERS = 4
const DEFAULT_PORT = 24856
const NETWORK_TICK_RATE = 30  # Hz

var network_mode: NetworkMode = NetworkMode.SINGLEPLAYER
var peer: ENetMultiplayerPeer = null
var local_player_id: int = 1
var connected_players: Dictionary = {}  # peer_id -> PlayerData

signal player_connected(peer_id: int, player_data: Dictionary)
signal player_disconnected(peer_id: int)
signal session_started()
signal session_ended()

func host_game(port: int = DEFAULT_PORT) -> bool:
    network_mode = NetworkMode.COOP_HOST
    peer = ENetMultiplayerPeer.new()
    var err = peer.create_server(MAX_PLAYERS, port)
    if err != OK:
        push_error("Failed to create server: %d" % err)
        return false
    
    multiplayer.multiplayer_peer = peer
    local_player_id = 1
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    
    session_started.emit()
    print("Hosting game on port %d" % port)
    return true

func join_game(ip: String, port: int = DEFAULT_PORT) -> bool:
    network_mode = NetworkMode.COOP_CLIENT
    peer = ENetMultiplayerPeer.new()
    var err = peer.create_client(ip, port)
    if err != OK:
        push_error("Failed to connect to %s:%d — error %d" % [ip, port, err])
        return false
    
    multiplayer.multiplayer_peer = peer
    local_player_id = peer.get_unique_id()
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    
    print("Connecting to %s:%d..." % [ip, port])
    return true

func leave_game() -> void:
    if peer:
        peer.close()
        peer = null
    multiplayer.multiplayer_peer = null
    connected_players.clear()
    network_mode = NetworkMode.SINGLEPLAYER
    session_ended.emit()

func _on_peer_connected(peer_id: int) -> void:
    print("Player %d connected" % peer_id)
    # Send world state to new client
    rpc_id(peer_id, "_receive_world_state", WorldState.get_serialized_state())

func _on_peer_disconnected(peer_id: int) -> void:
    print("Player %d disconnected" % peer_id)
    connected_players.erase(peer_id)
    player_disconnected.emit(peer_id)
    # Save player data before removing
    if has_node("/root/World/Players/%d" % peer_id):
        var player = get_node("/root/World/Players/%d" % peer_id)
        PlayerSaveSystem.save_player(peer_id, player)
        player.queue_free()

func _on_connected_to_server() -> void:
    print("Connected to host!")
    rpc_id(1, "_register_player", SteamManager.get_steam_name(), local_player_id)

func _on_connection_failed() -> void:
    push_error("Connection failed")
    leave_game()

@rpc("any_peer", "call_local", "reliable")
func _register_player(player_name: String, peer_id: int) -> void:
    var player_data = {
        "name": player_name,
        "peer_id": peer_id,
        "position": Vector3.ZERO,
        "joined_at": Time.get_ticks_msec(),
    }
    connected_players[peer_id] = player_data
    player_connected.emit(peer_id, player_data)
    
    # Spawn player avatar for all clients
    rpc("_spawn_player_avatar", peer_id, player_data)

@rpc("authority", "call_local", "reliable")
func _receive_world_state(state: Dictionary) -> void:
    WorldState.load_serialized_state(state)
    print("World state received and loaded")

@rpc("any_peer", "call_local", "reliable")
func _spawn_player_avatar(peer_id: int, data: Dictionary) -> void:
    var avatar = preload("res://scenes/player/PlayerAvatar.tscn").instantiate()
    avatar.name = str(peer_id)
    avatar.set_multiplayer_authority(peer_id)
    $"/root/World/Players".add_child(avatar)
    avatar.global_position = data.get("position", Vector3.ZERO)
```

---

## Step 2 — Player Synchronization

### What Gets Synced

| Data Type | Sync Rate | Method | Authority |
| :--- | :--- | :--- | :--- |
| **Player Position** | 30 Hz | Unreliable RPC | Each player owns their avatar |
| **Player Rotation** | 30 Hz | Unreliable RPC | Each player |
| **Player Animation** | 15 Hz | Unreliable RPC | Each player |
| **Vehicle Position** | 30 Hz | Unreliable RPC | Current driver |
| **Inventory Changes** | On event | Reliable RPC | Each player |
| **Money Transactions** | On event | Reliable RPC | Host validates |
| **World Interactions** | On event | Reliable RPC | Host validates |
| **NPC State** | 10 Hz | State sync | Host only |
| **Time/Weather** | 5 Hz | State sync | Host only |

### `PlayerSync.gd`

```gdscript
extends Node
class_name PlayerSync

const SYNC_INTERVAL = 1.0 / 30.0  # 30 Hz
const ANIM_SYNC_INTERVAL = 1.0 / 15.0

var sync_timer: float = 0.0
var anim_timer: float = 0.0

func _process(delta: float) -> void:
    if NetworkManager.network_mode == NetworkManager.NetworkMode.SINGLEPLAYER:
        return
    
    sync_timer += delta
    anim_timer += delta
    
    if sync_timer >= SYNC_INTERVAL:
        sync_timer = 0.0
        _sync_transform()
    
    if anim_timer >= ANIM_SYNC_INTERVAL:
        anim_timer = 0.0
        _sync_animation()

func _sync_transform() -> void:
    var player = get_parent()
    if player.get_multiplayer_authority() != multiplayer.get_unique_id():
        return
    
    rpc_unreliable("_receive_transform", player.global_position, player.global_rotation)

@rpc("any_peer", "unreliable")
func _receive_transform(pos: Vector3, rot: Vector3) -> void:
    var player = get_parent()
    if player.get_multiplayer_authority() == multiplayer.get_unique_id():
        return  # Don't override our own position
    
    # Smooth interpolation
    player.global_position = player.global_position.lerp(pos, 0.3)
    player.global_rotation = rot

func _sync_animation() -> void:
    var player = get_parent()
    if player.get_multiplayer_authority() != multiplayer.get_unique_id():
        return
    
    var anim_tree = player.get_node("AnimationTree")
    var state = anim_tree.get("parameters/state/current")
    var speed = anim_tree.get("parameters/speed/scale")
    
    rpc_unreliable("_receive_animation", state, speed)

@rpc("any_peer", "unreliable")
func _receive_animation(state: int, speed: float) -> void:
    var player = get_parent()
    if player.get_multiplayer_authority() == multiplayer.get_unique_id():
        return
    
    var anim_tree = player.get_node("AnimationTree")
    anim_tree.set("parameters/state/current", state)
    anim_tree.set("parameters/speed/scale", speed)
```

### Interpolation & Prediction

```text
┌─────────────────────────────────────────────────────────────┐
│              Client-Side Movement Pipeline                   │
│                                                              │
│  Input ──► Local Prediction ──► Render Position              │
│               │                    ▲                        │
│               ▼                    │                        │
│          Send to Host         Reconcile with                 │
│               │              Server Snapshot                 │
│               ▼                    │                        │
│          Server Validates ──► Send Corrected Pos             │
│                                                              │
│  • Client predicts movement immediately (no lag feel)        │
│  • Server validates and corrects if needed                   │
│  • Interpolation smooths remote player movement              │
│  • Buffer of 100ms for remote positions                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Step 3 — Shared World State

### `WorldState.gd`

```gdscript
extends Node
class_name WorldState

# Only the host writes to world state; clients receive snapshots
var world_time: float = 0.0
var world_day: int = 1
var current_weather: int = 0
var current_season: int = 0
var shared_money_pool: float = 0.0  # Community fund for joint projects

# Per-player data (synced)
var player_states: Dictionary = {}  # peer_id -> {money, health, position, inventory_hash}

# World objects that can be modified by any player
var world_objects: Dictionary = {}  # object_id -> {type, position, owner, state}

signal world_state_snapshot(snapshot: Dictionary)

const SNAPSHOT_INTERVAL = 0.2  # 5 Hz

func _process(delta: float) -> void:
    if not multiplayer.is_server():
        return
    
    world_time += delta
    if Engine.get_physics_frames() % int(SNAPSHOT_INTERVAL / delta) == 0:
        _send_snapshot()

func _send_snapshot() -> void:
    var snapshot = {
        "time": world_time,
        "day": world_day,
        "weather": WeatherManager.current_weather,
        "season": SeasonSystem.current_season,
        "players": _serialize_players(),
        "objects": _serialize_objects(),
    }
    rpc_unreliable("_receive_snapshot", snapshot)

@rpc("authority", "unreliable")
func _receive_snapshot(snapshot: Dictionary) -> void:
    world_time = snapshot["time"]
    world_day = snapshot["day"]
    # Apply weather/season if changed
    if snapshot["weather"] != WeatherManager.current_weather:
        WeatherManager.set_weather(snapshot["weather"])
    # Update remote player states
    for peer_id in snapshot["players"]:
        if peer_id != multiplayer.get_unique_id():
            _apply_remote_player(peer_id, snapshot["players"][peer_id])
    # Update world objects
    for obj_id in snapshot["objects"]:
        _apply_world_object(obj_id, snapshot["objects"][obj_id])
    
    world_state_snapshot.emit(snapshot)

func get_serialized_state() -> Dictionary:
    return {
        "time": world_time,
        "day": world_day,
        "weather": WeatherManager.current_weather,
        "season": SeasonSystem.current_season,
        "players": _serialize_players(),
        "objects": _serialize_objects(),
    }

func load_serialized_state(state: Dictionary) -> void:
    world_time = state["time"]
    world_day = state["day"]
    WeatherManager.set_weather(state["weather"])
    for obj_id in state["objects"]:
        _apply_world_object(obj_id, state["objects"][obj_id])

func _serialize_players() -> Dictionary:
    var data = {}
    for peer_id in NetworkManager.connected_players:
        var player = get_node_or_null("/root/World/Players/%d" % peer_id)
        if player:
            data[peer_id] = {
                "money": PlayerStats.money,
                "health": PlayerStats.health,
                "position": player.global_position,
            }
    return data

func _serialize_objects() -> Dictionary:
    var data = {}
    for obj_id in world_objects:
        data[obj_id] = world_objects[obj_id]
    return data

func _apply_remote_player(peer_id: int, data: Dictionary) -> void:
    var player = get_node_or_null("/root/World/Players/%d" % peer_id)
    if player:
        player.global_position = data.get("position", player.global_position)

func _apply_world_object(obj_id: String, data: Dictionary) -> void:
    if obj_id in world_objects:
        world_objects[obj_id].merge(data, true)
    else:
        world_objects[obj_id] = data
        # Spawn the object visually
        WorldObjectSpawner.spawn(obj_id, data)
```

---

## Step 4 — Shared Economy & Joint Businesses

### Co-op Money System

| Feature | Single Player | Co-op |
| :--- | :--- | :--- |
| **Personal Money** | ✅ | ✅ Each player has own wallet |
| **Shared Bank Account** | N/A | ✅ Joint account for co-owners |
| **Business Ownership** | Solo | Solo or Joint (2–4 owners) |
| **Profit Split** | 100% to player | Configurable split % |
| **Shared Expenses** | N/A | Auto-split or assigned payer |
| **Community Fund** | N/A | ✅ Voluntary donations for world projects |

### `SharedEconomy.gd`

```gdscript
extends Node
class_name SharedEconomy

# Joint bank accounts: account_id -> {owners: [peer_ids], balance: float, split: {peer_id: percent}}
var joint_accounts: Dictionary = {}
var next_account_id: int = 1

signal joint_transaction(account_id: int, type: String, amount: float, by_peer: int)

func create_joint_account(owners: Array[int], initial_deposit: float = 0.0) -> int:
    var account_id = next_account_id
    next_account_id += 1
    
    var split = {}
    var equal_share = 100.0 / owners.size()
    for peer_id in owners:
        split[peer_id] = equal_share
    
    joint_accounts[account_id] = {
        "owners": owners,
        "balance": initial_deposit,
        "split": split,
        "transactions": [],
    }
    
    rpc("_sync_joint_account", account_id, joint_accounts[account_id])
    return account_id

func deposit_to_joint(account_id: int, amount: float, by_peer: int) -> bool:
    if not joint_accounts.has(account_id):
        return false
    if by_peer not in joint_accounts[account_id]["owners"]:
        return false
    
    # Withdraw from personal account
    if not PlayerStats.spend_money(amount):
        return false
    
    joint_accounts[account_id]["balance"] += amount
    joint_accounts[account_id]["transactions"].append({
        "type": "deposit",
        "amount": amount,
        "by": by_peer,
        "time": TimeSystem.get_game_time(),
    })
    
    joint_transaction.emit(account_id, "deposit", amount, by_peer)
    rpc("_sync_joint_account", account_id, joint_accounts[account_id])
    return true

func withdraw_from_joint(account_id: int, amount: float, by_peer: int) -> bool:
    if not joint_accounts.has(account_id):
        return false
    if by_peer not in joint_accounts[account_id]["owners"]:
        return false
    if joint_accounts[account_id]["balance"] < amount:
        return false
    
    joint_accounts[account_id]["balance"] -= amount
    PlayerStats.add_money(amount)
    
    joint_accounts[account_id]["transactions"].append({
        "type": "withdrawal",
        "amount": amount,
        "by": by_peer,
        "time": TimeSystem.get_game_time(),
    })
    
    joint_transaction.emit(account_id, "withdrawal", amount, by_peer)
    rpc("_sync_joint_account", account_id, joint_accounts[account_id])
    return true

func distribute_profits(account_id: int, profit: float) -> void:
    if not joint_accounts.has(account_id):
        return
    
    var split = joint_accounts[account_id]["split"]
    for peer_id in split:
        var share = profit * (split[peer_id] / 100.0)
        # Add to each owner's personal account
        rpc_id(peer_id, "_receive_profit_share", share)

@rpc("authority", "call_local", "reliable")
func _sync_joint_account(account_id: int, data: Dictionary) -> void:
    joint_accounts[account_id] = data

@rpc("any_peer", "reliable")
func _receive_profit_share(amount: float) -> void:
    PlayerStats.add_money(amount)
    UI.show_notification("Received profit share: $%.2f" % amount)
```

### Joint Business Registration

```gdscript
# Example: Two players co-own a restaurant
func register_joint_business(business_id: String, owners: Array[int], split: Dictionary) -> void:
    var account_id = SharedEconomy.create_joint_account(owners)
    BusinessRegistry.register(business_id, {
        "type": "restaurant",
        "owners": owners,
        "account_id": account_id,
        "split": split,
    })
    
    # Both players can manage the business
    for peer_id in owners:
        rpc_id(peer_id, "_grant_business_access", business_id)
```

---

## Step 5 — Lobby & Matchmaking

### `LobbyManager.gd`

```gdscript
extends Node
class_name LobbyManager

var lobby_data: Dictionary = {
    "host_name": "",
    "host_steam_id": 0,
    "max_players": 4,
    "current_players": 1,
    "password": "",
    "region": "default",
    "game_mode": "coop",
    "world_seed": 0,
}

signal lobby_updated(data: Dictionary)
signal lobby_joined()
signal lobby_left()

func create_lobby(max_players: int = 4, password: String = "") -> void:
    lobby_data["host_name"] = SteamManager.get_steam_name()
    lobby_data["host_steam_id"] = SteamManager.get_steam_id()
    lobby_data["max_players"] = max_players
    lobby_data["password"] = password
    lobby_data["world_seed"] = randi()
    
    Steam.create_lobby(Steam.LOBBY_TYPE_PUBLIC, max_players)
    NetworkManager.host_game()

func join_lobby(lobby_id: int, password: String = "") -> bool:
    if lobby_data["password"] != "" and lobby_data["password"] != password:
        return false
    
    Steam.join_lobby(lobby_id)
    var host_ip = Steam.get_lobby_member_data(lobby_id, lobby_data["host_steam_id"], "ip")
    NetworkManager.join_game(host_ip)
    lobby_joined.emit()
    return true

func leave_lobby() -> void:
    Steam.leave_lobby()
    NetworkManager.leave_game()
    lobby_data.clear()
    lobby_left.emit()

func get_lobby_list() -> Array:
    var lobbies = Steam.get_lobby_list()
    var result = []
    for lobby in lobbies:
        result.append({
            "id": lobby["id"],
            "name": lobby["name"],
            "players": lobby["members"],
            "max": lobby["max_members"],
            "has_password": lobby["password"] != "",
        })
    return result

func _on_lobby_data_updated() -> void:
    lobby_data["current_players"] = Steam.get_lobby_members().size()
    lobby_updated.emit(lobby_data)
```

### Lobby UI Flow

```text
┌─────────────────────────────────────────────────────────────┐
│                    Multiplayer Menu                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│   │  Host Game   │  │  Join Game   │  │  Invite Only │    │
│   └──────┬───────┘  └──────┬───────┘  └──────┬───────┘    │
│          │                 │                 │              │
│          ▼                 ▼                 ▼              │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│   │ Max Players  │  │ Lobby Browser │  │ Steam Friends│    │
│   │ [2] [3] [4]  │  │ ┌───────────┐ │  │ ┌──────────┐│    │
│   │              │  │ │ Lobby 1   │ │  │ │ Friend 1 ││    │
│   │ Password:    │  │ │ 2/4 players│ │  │ │ Online   ││    │
│   │ [________]   │  │ │ Open      │ │  │ └──────────┘│    │
│   │              │  │ ├───────────┤ │  │ ┌──────────┐│    │
│   │ [Start]      │  │ │ Lobby 2   │ │  │ │ Friend 2 ││    │
│   └──────────────┘  │ │ 3/4 players│ │  │ │ In Game  ││    │
│                     │ │ Locked    │ │  │ └──────────┘│    │
│                     │ └───────────┘ │  └──────────────┘    │
│                     └──────────────┘                        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Step 6 — Anti-Cheat & Validation

Since the host is the authority, all critical actions must be validated server-side.

### Validated Actions

| Action | Client Request | Host Validation |
| :--- | :--- | :--- |
| **Buy Item** | "I want to buy X for $Y" | Check money ≥ Y, item exists, stock available |
| **Sell Item** | "I sold X for $Y" | Check item in inventory, price within market range |
| **Start Job** | "I started job X" | Check requirements met, job slot available |
| **Drive Vehicle** | Input sent | Speed limit check, collision validation |
| **Modify World** | "I placed object X at Y" | Check ownership, placement rules, distance |
| **Attack NPC** | "I attacked NPC X" | Check weapon equipped, range, cooldown |

### `AntiCheatValidator.gd`

```gdscript
extends Node
class_name AntiCheatValidator

const MAX_MONEY_PER_TRANSACTION = 1000000.0
const MAX_ITEMS_PER_TRANSACTION = 100
const TELEPORT_THRESHOLD = 50.0  # meters per second

var player_last_positions: Dictionary = {}  # peer_id -> {pos, time}

func validate_purchase(peer_id: int, item_id: String, price: float, quantity: int) -> bool:
    # Check price sanity
    if price > MAX_MONEY_PER_TRANSACTION:
        push_warning("Player %d: suspicious purchase price %f" % [peer_id, price])
        return false
    if quantity > MAX_ITEMS_PER_TRANSACTION:
        return false
    # Check item exists and price matches
    var item = ItemDatabase.get_item(item_id)
    if not item:
        return false
    if abs(item.base_price - price) > item.base_price * 0.5:
        push_warning("Player %d: price mismatch for %s" % [peer_id, item_id])
        return false
    return true

func validate_movement(peer_id: int, new_pos: Vector3) -> bool:
    if not player_last_positions.has(peer_id):
        player_last_positions[peer_id] = {"pos": new_pos, "time": Time.get_ticks_msec()}
        return true
    
    var last = player_last_positions[peer_id]
    var elapsed = (Time.get_ticks_msec() - last["time"]) / 1000.0
    var distance = new_pos.distance_to(last["pos"])
    var speed = distance / elapsed if elapsed > 0 else 0
    
    if speed > TELEPORT_THRESHOLD:
        push_warning("Player %d: speed hack detected (%.1f m/s)" % [peer_id, speed])
        return false
    
    player_last_positions[peer_id] = {"pos": new_pos, "time": Time.get_ticks_msec()}
    return true

func validate_world_edit(peer_id: int, action: String, data: Dictionary) -> bool:
    match action:
        "place_object":
            # Check player is near the placement location
            var player = get_node_or_null("/root/World/Players/%d" % peer_id)
            if not player:
                return false
            var distance = player.global_position.distance_to(data["position"])
            if distance > 10.0:
                push_warning("Player %d: placing object too far away" % peer_id)
                return false
            return true
        "delete_object":
            # Check ownership
            if data.get("owner", -1) != peer_id:
                return false
            return true
    return false
```

---

## Step 7 — Voice Chat (Optional)

### `VoiceChatManager.gd`

```gdscript
extends Node
class_name VoiceChatManager

var is_transmitting: bool = false
var voice_enabled: bool = true
var push_to_talk: bool = true
var input_key: int = KEY_V

var player_volumes: Dictionary = {}  # peer_id -> volume (0.0 to 1.0)
var spatial_voice: bool = true  # 3D positional audio

func _process(_delta: float) -> void:
    if not voice_enabled:
        return
    
    if push_to_talk:
        var transmitting = Input.is_key_pressed(input_key)
        if transmitting != is_transmitting:
            is_transmitting = transmitting
            if is_transmitting:
                _start_transmission()
            else:
                _stop_transmission()
    else:
        # Open mic mode
        if not is_transmitting:
            _start_transmission()

func _start_transmission() -> void:
    var capture = AudioServer.get_input_device()
    AudioServer.capture_start()
    Steam.start_voice_recording()

func _stop_transmission() -> void:
    AudioServer.capture_stop()
    Steam.stop_voice_recording()

func _on_voice_data_received(peer_id: int, data: PackedByteArray) -> void:
    if not voice_enabled:
        return
    
    var stream = AudioStreamGenerator.new()
    var playback = AudioStreamPlayback.new()
    # Decode and play voice data
    var audio_player = get_node_or_null("VoicePlayers/%d" % peer_id)
    if not audio_player:
        audio_player = AudioStreamPlayer3D.new()
        audio_player.name = str(peer_id)
        $VoicePlayers.add_child(audio_player)
    
    if spatial_voice:
        # Attach to player position for 3D voice
        var player = get_node_or_null("/root/World/Players/%d" % peer_id)
        if player:
            audio_player.global_position = player.global_position
    
    audio_player.play_stream(stream)

func set_player_volume(peer_id: int, volume: float) -> void:
    player_volumes[peer_id] = clamp(volume, 0.0, 1.0)
    var audio_player = get_node_or_null("VoicePlayers/%d" % peer_id)
    if audio_player:
        audio_player.volume_db = linear_to_db(volume)
```

---

## Step 8 — Disconnect Handling

### Drop-In / Drop-Out Flow

```text
┌─────────────────────────────────────────────────────────────┐
│              Drop-In / Drop-Out Lifecycle                    │
│                                                              │
│  Player Joins:                                               │
│  1. Connect to host via Steam/ENet                           │
│  2. Receive world state snapshot                             │
│  3. Load player save data (or create new)                    │
│  4. Spawn avatar at last saved position                      │
│  5. Sync inventory, money, stats                             │
│  6. Show "Player X joined" notification                     │
│                                                              │
│  Player Leaves:                                              │
│  1. Detect disconnect (timeout or manual leave)              │
│  2. Save player state to host's save file                    │
│  3. Remove avatar from world                                 │
│  4. Transfer business ownership to remaining players         │
│  5. Show "Player X left" notification                        │
│  6. If host leaves → migrate host or end session             │
│                                                              │
│  Host Migration:                                              │
│  1. Select next-best peer (lowest latency)                  │
│  2. Transfer world state authority                           │
│  3. All clients reconnect to new host                        │
│  4. Resume game with minimal interruption                   │
└─────────────────────────────────────────────────────────────┘
```

### `DisconnectHandler.gd`

```gdscript
extends Node
class_name DisconnectHandler

const RECONNECT_TIMEOUT = 10.0  # seconds before giving up

func _on_player_disconnected(peer_id: int) -> void:
    print("Handling disconnect for player %d" % peer_id)
    
    # Save player data
    var player = get_node_or_null("/root/World/Players/%d" % peer_id)
    if player:
        PlayerSaveSystem.save_player(peer_id, player)
    
    # Handle business ownership
    _transfer_business_ownership(peer_id)
    
    # Show notification
    UI.show_notification("%s has left the game" % NetworkManager.connected_players.get(peer_id, {}).get("name", "Player"))
    
    # Remove avatar
    if player:
        player.queue_free()

func _transfer_business_ownership(leaving_peer: int) -> void:
    for business_id in BusinessRegistry.businesses:
        var business = BusinessRegistry.businesses[business_id]
        if leaving_peer in business.get("owners", []):
            business["owners"].erase(leaving_peer)
            if business["owners"].is_empty():
                # No owners left — business becomes inactive
                business["active"] = false
                UI.show_notification("Business '%s' is now inactive" % business.get("name", "Unknown"))
            else:
                # Redistribute shares equally
                var new_split = 100.0 / business["owners"].size()
                business["split"] = {}
                for owner in business["owners"]:
                    business["split"][owner] = new_split
                UI.show_notification("Business '%s' ownership transferred" % business.get("name", "Unknown"))

func handle_host_migration() -> void:
    if NetworkManager.network_mode != NetworkManager.NetworkMode.COOP_HOST:
        return
    
    # Find the client with the best connection
    var best_peer = -1
    var best_ping = 9999
    for peer_id in NetworkManager.connected_players:
        var ping = multiplayer.get_peer(peer_id).get_stat(ENetMultiplayerPeer.PEER_ROUND_TRIP_TIME)
        if ping < best_ping:
            best_ping = ping
            best_peer = peer_id
    
    if best_peer != -1:
        rpc("_migrate_host", best_peer, WorldState.get_serialized_state())
        print("Migrating host to peer %d" % best_peer)

@rpc("authority", "reliable")
func _migrate_host(new_host: int, world_state: Dictionary) -> void:
    if multiplayer.get_unique_id() == new_host:
        # This client becomes the new host
        NetworkManager.network_mode = NetworkManager.NetworkMode.COOP_HOST
        peer.create_server(NetworkManager.MAX_PLAYERS, NetworkManager.DEFAULT_PORT)
        WorldState.load_serialized_state(world_state)
        print("You are now the host!")
```

---

## Step 9 — Co-op Activities

### Shared Activities Table

| Activity | Players | Description | Reward Split |
| :--- | :--- | :--- | :--- |
| **Joint Mission** | 2–4 | Complete a mission together | Equal split |
| **Business Partners** | 2–4 | Co-own and run a business | Configurable % |
| **Convoy Driving** | 2–4 | Drive in a group to a destination | Per player |
| **Fishing Trip** | 2–4 | Group fishing at a lake/coast | Keep own catch |
| **Farm Co-op** | 2–4 | Work on a shared farm | Profit split |
| **House Building** | 2–4 | Build a shared house | Shared ownership |
| **Exploration** | 2–4 | Discover new locations together | Discovery XP shared |
| **Trading** | 2 | Buy low in one city, sell in another | Negotiated split |

### Co-op Mission Example

```gdscript
extends Mission
class_name CoopMission

@export var min_players: int = 2
@export var max_players: int = 4
@export var reward_per_player: float = 500.0

var participants: Array[int] = []

func start_mission(players: Array[int]) -> bool:
    if players.size() < min_players:
        UI.show_notification("Need at least %d players for this mission" % min_players)
        return false
    if players.size() > max_players:
        UI.show_notification("Maximum %d players for this mission" % max_players)
        return false
    
    participants = players
    _activate_objectives()
    rpc("_sync_mission_start", participants)
    return true

@rpc("authority", "call_local", "reliable")
func _sync_mission_start(player_list: Array) -> void:
    participants = player_list
    for peer_id in participants:
        UI.show_mission_tracker(mission_id, mission_title)

func complete_mission() -> void:
    for peer_id in participants:
        rpc_id(peer_id, "_receive_mission_reward", reward_per_player, mission_id)
    rpc("_sync_mission_complete", mission_id)

@rpc("any_peer", "reliable")
func _receive_mission_reward(amount: float, mission_id: String) -> void:
    PlayerStats.add_money(amount)
    PlayerStats.add_xp(100)
    UI.show_notification("Mission complete! +$%.2f and 100 XP" % amount)
```

---

## Step 10 — Performance & Bandwidth

### Bandwidth Budget

| Data | Per-Player Cost | 4-Player Total | Notes |
| :--- | :--- | :--- | :--- |
| **Player Transforms** | 2 KB/s | 8 KB/s | 30 Hz, unreliable |
| **Animations** | 0.5 KB/s | 2 KB/s | 15 Hz |
| **World Snapshot** | 5 KB/s | 5 KB/s | 5 Hz, host → all |
| **Voice Chat** | 4 KB/s | 16 KB/s | Opus codec, 32kbps |
| **Events (RPCs)** | 1 KB/s | 4 KB/s | Variable |
| **Total** | ~12.5 KB/s | ~35 KB/s | Well within broadband |

### Optimization Techniques

```gdscript
# Interest management — only sync entities near players
func _get_relevant_entities(peer_id: int) -> Array:
    var player = get_node_or_null("/root/World/Players/%d" % peer_id)
    if not player:
        return []
    
    var relevant = []
    var radius = 200.0  # 200m sync radius
    for entity in WorldEntities.get_children():
        if player.global_position.distance_to(entity.global_position) < radius:
            relevant.append(entity)
    return relevant

# Delta compression — only send changed fields
func _serialize_entity_delta(entity, last_state: Dictionary) -> Dictionary:
    var current = entity.get_network_state()
    var delta = {}
    for key in current:
        if key not in last_state or current[key] != last_state[key]:
            delta[key] = current[key]
    return delta
```

---

## Step 11 — Save System for Co-op

### `CoopSaveSystem.gd`

```gdscript
extends Node
class_name CoopSaveSystem

const SAVE_DIR = "user://coop_saves/"

func save_coop_session(session_name: String) -> void:
    var save_data = {
        "session_name": session_name,
        "world_state": WorldState.get_serialized_state(),
        "players": {},
        "timestamp": Time.get_unix_time_from_system(),
    }
    
    for peer_id in NetworkManager.connected_players:
        var player = get_node_or_null("/root/World/Players/%d" % peer_id)
        if player:
            save_data["players"][peer_id] = {
                "name": NetworkManager.connected_players[peer_id]["name"],
                "money": PlayerStats.money,
                "health": PlayerStats.health,
                "position": player.global_position,
                "inventory": InventorySystem.serialize(),
            }
    
    var dir = DirAccess.open("user://")
    if not dir.dir_exists(SAVE_DIR):
        dir.make_dir_recursive(SAVE_DIR)
    
    var file = FileAccess.open(SAVE_DIR + session_name + ".save", FileAccess.WRITE)
    file.store_var(save_data)
    file.close()
    
    print("Co-op session saved: %s" % session_name)

func load_coop_session(session_name: String) -> bool:
    var file = FileAccess.open(SAVE_DIR + session_name + ".save", FileAccess.READ)
    if not file:
        return false
    
    var save_data = file.get_var()
    file.close()
    
    WorldState.load_serialized_state(save_data["world_state"])
    
    for peer_id in save_data["players"]:
        var data = save_data["players"][peer_id]
        # Restore player state
        if peer_id == multiplayer.get_unique_id():
            PlayerStats.money = data["money"]
            PlayerStats.health = data["health"]
            InventorySystem.deserialize(data["inventory"])
            var player = get_node("/root/World/Players/%d" % peer_id)
            player.global_position = data["position"]
    
    print("Co-op session loaded: %s" % session_name)
    return true
```

---

## Step 12 — Implementation Checklist

| Task | Priority | Status |
| :--- | :--- | :--- |
| NetworkManager (host/join/leave) | Critical | Pending |
| PlayerSync (transform/animation) | Critical | Pending |
| WorldState snapshots | Critical | Pending |
| LobbyManager (Steam integration) | High | Pending |
| SharedEconomy (joint accounts) | High | Pending |
| AntiCheatValidator | High | Pending |
| DisconnectHandler (host migration) | High | Pending |
| CoopMission system | Medium | Pending |
| VoiceChatManager | Low | Pending |
| CoopSaveSystem | Medium | Pending |
| Interest management | Medium | Pending |
| Bandwidth optimization | Low | Pending |

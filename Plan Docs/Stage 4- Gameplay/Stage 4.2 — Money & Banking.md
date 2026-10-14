# Stage 4.2 — Money & Banking

Money is the lifeblood of any life simulation. The player needs to earn it, spend it, save it, and track it. This stage defines the currency, banking system, ATMs, and transaction framework.

---

## Goal
Create a complete money and banking system with cash, bank accounts, ATMs, and transaction logging.

---

## Step 1 — Currency System

Nova City uses a single currency called **Credits (Cr)**.

| Denomination | Symbol | Example |
| :--- | :--- | :--- |
| Credits | Cr | 1,500 Cr |

### Starting Economy Values

| Item | Price |
| :--- | :--- |
| **Coffee** | 5 Cr |
| **Fast food meal** | 15 Cr |
| **Restaurant meal** | 50 Cr |
| **Groceries (weekly)** | 80 Cr |
| **Bus fare** | 2 Cr |
| **Taxi ride** | 20–50 Cr |
| **Fuel (full tank)** | 60 Cr |
| **Apartment rent (monthly)** | 800–2,000 Cr |
| **House purchase** | 50,000–200,000 Cr |
| **Economy car** | 15,000 Cr |
| **Sports car** | 80,000 Cr |

---

## Step 2 — Money Storage

The player has two money stores:

| Store | Description | Access |
| :--- | :--- | :--- |
| **Cash** | Physical money on person | Always available, can be lost on death |
| **Bank Account** | Digital money | Access via ATM or phone app |

### `MoneySystem.gd` (Autoload)

```gdscript
extends Node

signal cash_changed(amount: int)
signal bank_changed(amount: int)
signal transaction_logged(entry: Dictionary)

var cash: int = 500
var bank_balance: int = 0
var transaction_history: Array[Dictionary] = []

const MAX_CASH: int = 999999
const MAX_BANK: int = 99999999

func add_cash(amount: int) -> bool:
    if amount < 0: return false
    cash = min(cash + amount, MAX_CASH)
    cash_changed.emit(cash)
    _log_transaction("cash_in", amount, "Cash received")
    return true

func spend_cash(amount: int) -> bool:
    if amount > cash: return false
    cash -= amount
    cash_changed.emit(cash)
    _log_transaction("cash_out", -amount, "Cash spent")
    return true

func deposit(amount: int) -> bool:
    if amount > cash: return false
    cash -= amount
    bank_balance += amount
    cash_changed.emit(cash)
    bank_changed.emit(bank_balance)
    _log_transaction("deposit", amount, "ATM deposit")
    return true

func withdraw(amount: int) -> bool:
    if amount > bank_balance: return false
    bank_balance -= amount
    cash += amount
    bank_changed.emit(bank_balance)
    cash_changed.emit(cash)
    _log_transaction("withdraw", -amount, "ATM withdraw")
    return true

func bank_transfer(amount: int, recipient: String) -> bool:
    if amount > bank_balance: return false
    bank_balance -= amount
    bank_changed.emit(bank_balance)
    _log_transaction("transfer", -amount, "Transfer to " + recipient)
    return true

func bank_payment(amount: int, description: String) -> bool:
    if amount > bank_balance: return false
    bank_balance -= amount
    bank_changed.emit(bank_balance)
    _log_transaction("payment", -amount, description)
    return true

func receive_bank_payment(amount: int, source: String) -> void:
    bank_balance = min(bank_balance + amount, MAX_BANK)
    bank_changed.emit(bank_balance)
    _log_transaction("income", amount, "Payment from " + source)

func _log_transaction(type: String, amount: int, description: String) -> void:
    var entry = {
        "type": type,
        "amount": amount,
        "description": description,
        "timestamp": TimeSystem.get_time_string(),
        "date": TimeSystem.get_date_string(),
        "balance_after": bank_balance,
    }
    transaction_history.append(entry)
    transaction_logged.emit(entry)
```

---

## Step 3 — ATM System

ATMs are placed throughout the city, allowing the player to deposit, withdraw, and check their balance.

### `ATMInteractable.gd`

```gdscript
extends Area3D
class_name ATMInteractable

@export var atm_id: String = ""
@onready var interaction_label: Label3D = $InteractionLabel

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)
    interaction_label.visible = false

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("Player"):
        interaction_label.visible = true
        body.set_nearby_interactable(self)

func _on_body_exited(body: Node3D) -> void:
    if body.is_in_group("Player"):
        interaction_label.visible = false
        body.clear_nearby_interactable()

func interact(player: Node3D) -> void:
    ShopUIManager.open_atm_ui()

func get_interaction_text() -> String:
    return "Press E to use ATM"
```

### ATM UI

```gdscript
extends Control

@onready var balance_label: Label = $Panel/BalanceLabel
@onready var cash_label: Label = $Panel/CashLabel
@onready var amount_input: LineEdit = $Panel/AmountInput

func _ready() -> void:
    _update_display()
    MoneySystem.bank_changed.connect(_on_bank_changed)
    MoneySystem.cash_changed.connect(_on_cash_changed)

func _update_display() -> void:
    balance_label.text = "Bank: %d Cr" % MoneySystem.bank_balance
    cash_label.text = "Cash: %d Cr" % MoneySystem.cash

func _on_deposit_pressed() -> void:
    var amount = int(amount_input.text)
    if MoneySystem.deposit(amount):
        _update_display()
    else:
        _show_error("Insufficient cash")

func _on_withdraw_pressed() -> void:
    var amount = int(amount_input.text)
    if MoneySystem.withdraw(amount):
        _update_display()
    else:
        _show_error("Insufficient bank balance")

func _on_close_pressed() -> void:
    ShopUIManager.close_atm_ui()
```

---

## Step 4 — ATM Placement

| District | ATM Count | Locations |
| :--- | :--- | :--- |
| **Central Plaza** | 3 | City Hall, Bus Terminal, Central Park entrance |
| **Financial** | 5 | Bank Tower lobby, Stock Exchange, 3 street ATMs |
| **Suburban** | 2 | Shopping center, Community center |
| **Industrial** | 1 | Truck depot |
| **Coastal** | 2 | Marina pier, Boardwalk |
| **Highway** | 2 | Gas station, Motel |

---

## Step 5 — Paycheck System

Jobs (defined in Stage 4.5) deposit paychecks directly into the player's bank account.

```gdscript
# Called by JobManager on payday
func receive_paycheck(amount: int, job_name: String) -> void:
    MoneySystem.receive_bank_payment(amount, job_name)
    PhoneSystem.add_notification(
        "Bank",
        "Paycheck received: +%d Cr from %s" % [amount, job_name]
    )
```

---

## Step 6 — Death Penalty

When the player dies, they lose a percentage of carried cash (hospital fees).

```gdscript
func on_player_death() -> void:
    var penalty = int(MoneySystem.cash * 0.1)  # 10% of cash
    MoneySystem.spend_cash(penalty)
    # Respawn at nearest hospital
    PlayerStats.stats["health"] = PlayerStats.max_stats["health"]
    PlayerStats.stats["stamina"] = PlayerStats.max_stats["stamina"]
```

This money system provides the economic foundation that jobs, shops, property, and vehicles all build upon.

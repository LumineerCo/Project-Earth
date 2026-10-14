## MoneySystem.gd
## Tracks cash, bank balance, and transaction history.
## Stage 4.2 — Money & Banking
extends Node
class_name MoneySystem

signal cash_changed(amount: int)
signal bank_changed(amount: int)
signal transaction_logged(entry: Dictionary)

const MAX_CASH := 999999
const MAX_BANK := 99999999

var cash: int = 500
var bank_balance: int = 0
var transaction_history: Array = []

func _ready() -> void:
	reset_to_default()
	DebugManager.log_info("MoneySystem", "Money system initialized")

func reset_to_default() -> void:
	cash = 500
	bank_balance = 0
	transaction_history = []
	cash_changed.emit(cash)
	bank_changed.emit(bank_balance)

func add_cash(amount: int) -> bool:
	if amount <= 0:
		return false
	cash = min(cash + amount, MAX_CASH)
	cash_changed.emit(cash)
	_log_transaction("cash_in", amount, "Cash received")
	return true

func spend_cash(amount: int) -> bool:
	if amount <= 0 or amount > cash:
		return false
	cash -= amount
	cash_changed.emit(cash)
	_log_transaction("cash_out", -amount, "Cash spent")
	return true

func deposit(amount: int) -> bool:
	if amount <= 0 or amount > cash:
		return false
	cash -= amount
	bank_balance = min(bank_balance + amount, MAX_BANK)
	cash_changed.emit(cash)
	bank_changed.emit(bank_balance)
	_log_transaction("deposit", amount, "ATM deposit")
	return true

func withdraw(amount: int) -> bool:
	if amount <= 0 or amount > bank_balance:
		return false
	bank_balance -= amount
	cash = min(cash + amount, MAX_CASH)
	bank_changed.emit(bank_balance)
	cash_changed.emit(cash)
	_log_transaction("withdraw", -amount, "ATM withdraw")
	return true

func bank_transfer(amount: int, recipient: String) -> bool:
	if amount <= 0 or amount > bank_balance:
		return false
	bank_balance -= amount
	bank_changed.emit(bank_balance)
	_log_transaction("transfer", -amount, "Transfer to %s" % recipient)
	return true

func receive_bank_payment(amount: int, source: String) -> void:
	if amount <= 0:
		return
	bank_balance = min(bank_balance + amount, MAX_BANK)
	bank_changed.emit(bank_balance)
	_log_transaction("income", amount, "Payment from %s" % source)

func _log_transaction(type: String, amount: int, description: String) -> void:
	var entry := {
		"type": type,
		"amount": amount,
		"description": description,
		"timestamp": Time.get_unix_time_from_system(),
		"bank_balance": bank_balance,
		"cash": cash,
	}
	transaction_history.append(entry)
	transaction_logged.emit(entry)

func serialize() -> Dictionary:
	return {
		"cash": cash,
		"bank_balance": bank_balance,
		"transaction_history": transaction_history,
	}

func deserialize(data: Dictionary) -> void:
	cash = data.get("cash", cash)
	bank_balance = data.get("bank_balance", bank_balance)
	transaction_history = data.get("transaction_history", transaction_history)
	cash_changed.emit(cash)
	bank_changed.emit(bank_balance)

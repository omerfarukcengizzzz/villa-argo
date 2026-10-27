extends Node
## Autoload "GameState": host-authoritative world state shared by both twins
## (flags, the twins' shared inventory, journal entries). Only the host writes;
## every change is broadcast, and a (re)joining client gets a full snapshot.
## Levels rebuild their visuals from this, so state survives level changes and
## rejoins.

signal changed(key: String)
signal journal_added(entry: Dictionary)

var flags := {}
## item id -> display name
var inventory := {}
## Each entry: {"id", "title", "body", "who"}; who is "both", "jason" or "julia".
var journal: Array = []


func reset() -> void:
	flags.clear()
	inventory.clear()
	journal.clear()


func get_flag(key: String, default: Variant = null) -> Variant:
	return flags.get(key, default)


func has_item(id: String) -> bool:
	return inventory.has(id)


func has_journal(id: String) -> bool:
	return journal.any(func(e: Dictionary) -> bool: return e["id"] == id)


## Condition strings used by levels and interactables: "" is always true,
## "flag" means the flag is truthy, "item:id" means the twins hold that item,
## and a leading "!" negates either.
func check(cond: String) -> bool:
	if cond == "":
		return true
	if cond.begins_with("!"):
		return not check(cond.substr(1))
	if cond.begins_with("item:"):
		return has_item(cond.substr(5))
	return bool(get_flag(cond, false))


func journal_for(role: String) -> Array:
	return journal.filter(func(e: Dictionary) -> bool: return e["who"] == "both" or e["who"] == role)


# --- Host-only writes ---------------------------------------------------------

func set_flag(key: String, value: Variant = true) -> void:
	assert(multiplayer.is_server())
	if flags.has(key) and typeof(flags[key]) == typeof(value) and flags[key] == value:
		return
	_set_flag.rpc(key, value)


func give_item(id: String, display_name: String) -> void:
	assert(multiplayer.is_server())
	if not has_item(id):
		_give_item.rpc(id, display_name)


func add_journal(id: String, title: String, body: String, who := "both") -> void:
	assert(multiplayer.is_server())
	if not has_journal(id):
		_add_journal.rpc({"id": id, "title": title, "body": body, "who": who})


func send_snapshot(peer_id: int) -> void:
	_apply_snapshot.rpc_id(peer_id, {"flags": flags, "inventory": inventory, "journal": journal})


# --- Replicated -----------------------------------------------------------------

@rpc("authority", "call_local", "reliable")
func _set_flag(key: String, value: Variant) -> void:
	flags[key] = value
	changed.emit(key)


@rpc("authority", "call_local", "reliable")
func _give_item(id: String, display_name: String) -> void:
	inventory[id] = display_name
	changed.emit("inventory")


@rpc("authority", "call_local", "reliable")
func _add_journal(entry: Dictionary) -> void:
	journal.append(entry)
	changed.emit("journal")
	journal_added.emit(entry)


@rpc("authority", "call_remote", "reliable")
func _apply_snapshot(data: Dictionary) -> void:
	flags = data["flags"]
	inventory = data["inventory"]
	journal = data["journal"]
	changed.emit("")

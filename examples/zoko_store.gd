extends Node
## Minimal purchase flow (Godot 3.x). Attach to any Node. In the editor and on desktop the simulator answers with a
## three-item test catalogue; in a web export the portal's real checkout opens.


func _ready() -> void:
	yield(ZokoGames.init_async(), "completed")
	if not ZokoGames.is_store_available:
		return  # hide your shop button on hosts without purchases

	# warning-ignore:return_value_discarded
	ZokoGames.connect("purchase_completed", self, "_on_purchase_completed")
	# warning-ignore:return_value_discarded
	ZokoGames.connect("purchase_failed", self, "_on_purchase_failed")

	var catalog = yield(ZokoGames.store_get_catalog_items_async(20), "completed")
	if not catalog.ok or catalog.result.empty():
		return
	for item in catalog.result:
		print(item.sku, "  ", item.name, "  ", item.price)

	var first = catalog.result[0]
	yield(ZokoGames.store_buy_item_async(first.sku), "completed")  # signals report the outcome
	if first.consumable:
		yield(ZokoGames.store_consume_item_async(first.sku, 1), "completed")

	var token = yield(ZokoGames.store_get_purchase_token_async(), "completed")  # send to your server to verify what the player owns
	if token.ok:
		print("purchase token: ", token.result)

	var inventory = yield(ZokoGames.store_get_player_inventory_async(), "completed")
	if inventory.ok:
		for owned in inventory.result:
			print(owned.sku, " x", owned.quantity)


func _on_purchase_completed(item_id) -> void:
	print("paid for ", item_id, " (verify ownership on your server)")


func _on_purchase_failed(error) -> void:
	match error.code:
		"purchaseCancelled":
			print("player closed the checkout")
		"userNotAuthenticated":
			ZokoGames.show_auth_prompt()
		_:
			push_warning("purchase failed: %s" % error.message)

extends Node
## Demo scene script (Godot 3.x). Attach to any Node. Keys: A midgame ad, R rewarded ad, G gameplay start/stop,
## H happytime, U user, F friends, T token, S save, M room message and state, B buy the first store item.
## Press G (gameplay start) before the first A: since SDK 1.6.4 a web build refuses a midgame ad with adCooldown until the game has called gameplay start (or 30 s of visible time passed).
## Ads pause the game and mute the Master bus on their own (ZokoGames.pause_game_during_ads / mute_audio_during_ads),
## so this node must keep running while paused: it sets pause_mode to PAUSE_MODE_PROCESS.

var _playing = false


func _ready() -> void:
	pause_mode = PAUSE_MODE_PROCESS
	var res = yield(ZokoGames.init_async(), "completed")
	if not res.ok:
		push_warning("ZokoGames init failed: %s" % res.error.code)
		return
	print("ZokoGames ready in ", ZokoGames.environment, " (simulated: ", ZokoGames.is_simulated, ")")
	ZokoGames.connect("settings_changed", self, "_on_settings_changed")
	ZokoGames.connect("auth_changed", self, "_on_auth_changed")
	ZokoGames.connect("ad_started", self, "_on_ad_started")
	ZokoGames.connect("ad_finished", self, "_on_ad_finished")
	ZokoGames.connect("ad_error", self, "_on_ad_error")
	ZokoGames.connect("room_message", self, "_on_room_message")
	ZokoGames.connect("room_state", self, "_on_room_state")

	var plays = int(ZokoGames.data_get_item("plays", "0")) + 1
	ZokoGames.data_set_item("plays", str(plays))
	print("Cloud save says this is play #", plays)


func _on_settings_changed(s) -> void:
	AudioServer.set_bus_mute(0, bool(s.muteAudio))


func _on_auth_changed(user) -> void:
	print("signed in as ", user.get("username", "(signed out)"))


func _on_ad_started() -> void:
	print("ad started (game paused and muted by the addon)")


func _on_ad_finished() -> void:
	print("ad finished (game resumed)")


func _on_ad_error(error) -> void:
	print("ad error: ", error.code)


func _on_room_message(m) -> void:
	print("room message from ", m.from, ": ", m.data)


func _on_room_state(state, _change) -> void:
	print("room state: ", state)


func _unhandled_key_input(event) -> void:
	if not ZokoGames.is_initialized or not event.pressed:
		return
	match event.scancode:
		KEY_A:
			ZokoGames.request_ad("midgame")
		KEY_R:
			ZokoGames.request_ad("rewarded")
		KEY_G:
			_playing = not _playing
			if _playing:
				ZokoGames.gameplay_start()
			else:
				ZokoGames.gameplay_stop()
		KEY_H:
			ZokoGames.happytime()
		KEY_U:
			var user = yield(ZokoGames.get_user_async(), "completed")
			print(user.result.username if user.ok and user.result != null else "logged out")
		KEY_F:
			var page = yield(ZokoGames.list_friends_async(1, 10), "completed")
			print(page.result.total if page.ok else page.error.code, " friends")
		KEY_T:
			var token = yield(ZokoGames.get_user_token_async(), "completed")
			print(token.result if token.ok else token.error.code)
		KEY_S:
			ZokoGames.set_game_context({"level": 3, "hard": true})
			ZokoGames.track_order("xsolla", {"sku": "gems_100", "price": 0.99})
		KEY_M:
			# Room data channel: the simulator loops these back to this instance.
			ZokoGames.room_send({"type": "ping", "t": OS.get_ticks_msec()})
			if ZokoGames.room_is_host():
				ZokoGames.room_set_state({"lastPing": OS.get_ticks_msec()})
		KEY_B:
			if ZokoGames.is_store_available:
				var catalog = yield(ZokoGames.store_get_catalog_items_async(), "completed")
				if catalog.ok and catalog.result.size() > 0:
					var bought = yield(ZokoGames.store_buy_item_async(catalog.result[0].sku), "completed")
					print("purchase: ", bought, " (verify ownership on your server)")

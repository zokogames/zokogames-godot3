# ZokoGames SDK for Godot 3

Godot 3.x addon (`addons/zokogames`) for HTML5 exports of Godot **3.3 to 3.6** (3.5 and 3.6 LTS are the targets). It has the same public API as the Godot 4 addon in `../godot`, one to one, so a project can move between them: same autoload name `ZokoGames`, same method names, same signals. The browser SDK `window.ZokoGames.SDK` is called through the Godot 3 `JavaScript` singleton; in the editor and on desktop a built-in simulator answers. Written in GDScript 1: no `await`, no lambdas, no typed arrays, no `@export`.

Version 1.8.2 (written against the JavaScript SDK `@zoko/sdk` 1.8.1). Changes: [CHANGELOG.md](./CHANGELOG.md).
Status: run headless in the official Godot 3.6.3 editor on macOS: the addon imports with zero errors and zero warnings (warnings treated as errors), enabling the plugin registers the autoload, every public method and signal behaves as documented in simulator mode, and the HTML5 export contains the bridge. Older 3.x releases and a browser run against the live portal are not verified; if something fails, send the engine version and the exact error to developer support.

## Versions

| Wrapper | ZokoGames SDK |
|---|---|
| 1.8.2 | @zoko/sdk 1.8.1 |
| 1.8.1 | @zoko/sdk 1.8.0 |
| 1.8.0 | @zoko/sdk 1.8.0 |
| 1.7.1 | @zoko/sdk 1.7.0 |
| 1.7.0 | @zoko/sdk 1.7.0 |
| 1.6.2 | @zoko/sdk 1.6.1 |
| 1.6.1 | @zoko/sdk 1.6.0 |
| 1.6.0 | @zoko/sdk 1.6.0 |
| 1.5.0 | @zoko/sdk 1.5.0 |
| 1.4.1 | @zoko/sdk 1.4.1 |
| 1.4.0 | @zoko/sdk 1.4.0 |
| 1.3.1 | @zoko/sdk 1.3.1 |

| Godot | Support |
|---|---|
| 3.5 and 3.6 LTS | Targeted: HTML5 export through the `JavaScript` singleton. |
| 3.3 and 3.4 | Should work: the web export shell uses the `Engine` class with `$GODOT_CONFIG` since 3.3. |
| 3.0 to 3.2 | Not supported (older export shell). |
| 4.x | Not supported by this addon: use `../godot`. `init()` refuses to run on 4.x and says so (`unsupportedEngine`). |

## Install

1. Copy `addons/zokogames` into your project's `addons/` folder.
2. Project > Project Settings > Plugins: enable **ZokoGames** (this registers the `ZokoGames` autoload with `add_autoload_singleton` and the `zokogames/simulator/*` settings).
3. Project > Export > Add **HTML5**, then set **Custom HTML Shell** (Options tab > HTML > Custom HTML Shell) to `res://addons/zokogames/export/zokogames_shell.html`. The shell loads `https://sdk.zokogames.com/zokogames-sdk-v1.js` before the engine, hosts `window.ZokoBridge`, and reports the engine download to the portal's loading bar. If you keep your own shell, add `<script src="https://sdk.zokogames.com/zokogames-sdk-v1.js"></script>` to its head and copy the bridge block from the supplied shell.
4. Optional: add a `ZokoBanner` node (`zoko_banner.gd`) over the space you can spare for a banner.

### HTML5 export preset settings (Godot 3.x)

- **Custom HTML Shell**: the file above.
- **Threads**: Godot 3 has no threaded web export (3.x ships a single-threaded runtime), so there is nothing to untick; leave `Thread Support`/SharedArrayBuffer options off if your build exposes them, because game pages are not cross-origin isolated.
- **GDNative / Extensions**: off. `Export > HTML5 > Options > Export With Debug` off for the uploaded build. Native extensions do not run in web builds anyway; enable GDNative only if you ship a web-compatible library.
- **Canvas Resize Policy**: `Adaptive` (the shell fills the frame; `Project Settings > Display > Window > Stretch Mode` `2d` or `viewport` with aspect `expand` or `keep`). `None` leaves a fixed-size canvas, `Project` keeps the project size.
- **Focus Canvas on Start**: on. **Experimental Virtual Keyboard**: on if the game has text input on phones.
- **VRAM Texture Compression**: enable For Desktop (S3TC) and For Mobile (ETC2) so every browser has a format.
- Export as `index.html` so the files are `index.html`, `index.js`, `index.wasm`, `index.pck`; do not rename them to `.br` or `.gz`.

## Quick start

```gdscript
extends Node

func _ready() -> void:
	yield(ZokoGames.init_async(), "completed")
	print(ZokoGames.environment, " simulated: ", ZokoGames.is_simulated)

	ZokoGames.connect("settings_changed", self, "_on_settings")
	ZokoGames.loading_stop()
	ZokoGames.gameplay_start()

	# Ads: the addon pauses the tree and mutes Master while the ad plays and restores both afterwards.
	# This node keeps running meanwhile because it is not pausable:
	pause_mode = PAUSE_MODE_PROCESS
	var ad = yield(ZokoGames.request_ad_async("rewarded"), "completed")
	if ad.ok:
		print("grant the reward")   # only after the ad finished

	# Cloud save: synchronous strings
	ZokoGames.data_set_item("level", "4")
	print(ZokoGames.data_get_item("level", "1"))

	# Store: see examples/zoko_store.gd for the full flow
	ZokoGames.connect("purchase_completed", self, "_on_paid")   # verify on your server
	if ZokoGames.is_store_available:
		var catalog = yield(ZokoGames.store_get_catalog_items_async(), "completed")
		if catalog.ok and catalog.result.size() > 0:
			var bought = yield(ZokoGames.store_buy_item_async(catalog.result[0].sku), "completed")
			if ZokoGames.has_error_code(bought, "purchaseCancelled"):
				print("closed the checkout")


func _on_settings(s) -> void:
	AudioServer.set_bus_mute(0, bool(s.muteAudio))


func _on_paid(item_id) -> void:
	print("paid: ", item_id)
```

A runnable demo scene script is `examples/zoko_demo.gd` (attach it to any Node); `examples/zoko_store.gd` is the purchase flow. In the editor and on desktop the simulator provides the test catalogue.

## Differences from the Godot 4 addon

The names are identical. Only the language mechanics differ:

| Godot 4 addon | Godot 3 addon |
|---|---|
| `JavaScriptBridge` | `JavaScript` singleton (`JavaScript.get_interface`, `JavaScript.create_callback(self, "_on_sink")`); the callback object is kept in a member (`_sink`) or Godot frees it |
| `await ZokoGames.get_user_async()` returns the Dictionary | `yield(ZokoGames.get_user_async(), "completed")` returns the Dictionary. `get_user_async()` returns a request object (`id`, `done`, `result`, signal `completed(result)`); the autoload keeps it alive until it completes, and every request completes on a later frame so the `yield` can never miss it |
| `callback: Callable` (lambda or `Callable(self, "m")`) | `callback`: a `FuncRef`, `funcref(self, "_on_done")`; `request_ad` callbacks are FuncRefs under `"ad_started"`, `"ad_finished"`, `"ad_error"` |
| `ZokoGames.ad_started.connect(fn)` | `ZokoGames.connect("ad_started", self, "_on_ad_started")` |
| `pause_game_during_ads`, `mute_audio_during_ads`, `follow_portal_mute` (all `true`; nodes that run during an ad need `process_mode = PROCESS_MODE_ALWAYS`) | Same properties and defaults: `get_tree().paused` and the Master bus (bus 0) are set on `ad_started` and restored on `ad_finished` / `ad_error`; the portal's mute setting is applied to Master. Your own nodes that must react during an ad need `pause_mode = PAUSE_MODE_PROCESS` (the autoload already has it) |
| Typed signals, `Array[String]`, `-> Dictionary` on async calls | Untyped signals and values; `_async` calls return a request object, not a Dictionary |
| `@export`, `ZokoBanner` with `size` / `queue_redraw()` | `export var`, `rect_size` / `update()` |
| Web feature tag `web` | Feature tag `JavaScript` (`OS.has_feature("JavaScript")`) |
| Extra: none | Extra error code `unsupportedEngine` |

`init_async()` in the Godot 3 addon sets up the bridge itself, so `yield(ZokoGames.init_async(), "completed")` is all you need at startup.

## API coverage

Every member of the JavaScript SDK is available. Names follow GDScript snake_case: `SDK.game.gameplayStart()` is `ZokoGames.gameplay_start()`. Every asynchronous method has a callback form `name(..., callback = null)` (`callback` is a `FuncRef`) and a request form `name_async(...)` that returns a request object: `var res = yield(ZokoGames.get_user_async(), "completed")`. Both give `{"ok": true, "result": value}` or `{"ok": false, "error": {"code", "message"}}`. The names match the Godot 4 addon one to one.

| JS SDK member | GDScript (`ZokoGames` autoload) | Notes |
|---|---|---|
| `init` | `init(callback)` / `init_async()` | Signal `initialized(ok)` also fires. |
| `environment` | `ZokoGames.environment` | `"local"`, `"zokogames"` or `"disabled"`. |
| `isQaTool` | `ZokoGames.is_qa_tool` |  |
| `ad.requestAd` | `request_ad(type, callbacks)` / `request_ad_async(type)` | Signals `ad_started`, `ad_finished`, `ad_error(error)`; or pass `{"ad_started", "ad_finished", "ad_error"}` FuncRefs. The addon pauses the tree and mutes Master while the ad plays. |
| `ad.requestAd.adStarted` | `ad_started` signal; `"ad_started"` callable in `request_ad(type, callbacks)` | The addon pauses the tree and mutes Master (`pause_game_during_ads`, `mute_audio_during_ads`, Godot 3 names, both default true). |
| `ad.requestAd.adFinished` | `ad_finished` signal; `"ad_finished"` callable; `request_ad_async` returns `{"ok": true}` | Pause and mute are restored first, and focus returns to the canvas. Grant the reward here. |
| `ad.requestAd.adError` | `ad_error(error)` signal; `"ad_error"` callable; `request_ad_async` returns `{"ok": false, "error": ...}` | Fires instead of `ad_finished`, also for failures before the ad started. |
| `ad.hasAdblock` | `has_adblock(callback)` / `has_adblock_async()` |  |
| `banner.requestBanner` | `request_banner(id, width, height, window_rect, cb)` / `..._async` | Or the `ZokoBanner` node. |
| `banner.requestResponsiveBanner` | `request_responsive_banner(id, window_rect, cb)` / `..._async` |  |
| `banner.clearBanner` | `clear_banner(id, cb)` / `..._async` |  |
| `banner.clearAllBanners` | `clear_all_banners(cb)` / `..._async` |  |
| `banner.hideAllBanners` | `hide_all_banners(cb)` / `..._async` | Added in SDK 1.8.0. Hides every banner without clearing it. |
| `banner.showAllBanners` | `show_all_banners(cb)` / `..._async` | Added in SDK 1.8.0. Shows the banners hidden by `hide_all_banners`. |
| `game.settings` | `ZokoGames.settings` | Dictionary `{muteAudio, disableChat, kidsMode}`. `kidsMode` (1.5.0) is absent on older portals: `settings.get("kidsMode", false)`. |
| `game.addSettingsChangeListener` | `settings_changed` signal | `ZokoGames.connect("settings_changed", self, "_on_settings")`. |
| `game.removeSettingsChangeListener` | `ZokoGames.disconnect("settings_changed", self, "_on_settings")` | Standard signal API. |
| `game.gameplayStart` | `gameplay_start(cb)` / `..._async` |  |
| `game.gameplayStop` | `gameplay_stop(cb)` / `..._async` |  |
| `game.loadingStart` | `loading_start(cb)` / `..._async` | The shell already reports the engine download. |
| `game.loadingStop` | `loading_stop(cb)` / `..._async` |  |
| `game.loadingProgress` | `loading_progress(percentage, cb)` / `..._async` | 0 to 100; safe every frame. |
| `game.happytime` | `happytime(cb)` / `..._async` |  |
| `game.reportGameCompletedPercentage` | `report_game_completed_percentage(p, cb)` / `..._async` | 0 to 100. |
| `game.reportChat` | `report_chat(report, callback)` / `report_chat_async(report)` | Added in SDK 1.4.0. `report` Dictionary: `reportedName`, `message`, `reason`, optional `reportedUserId`, `roomId`, `context`. |
| `game.onScreenshotRequest` | `set_screenshot_provider(funcref)` / `clear_screenshot_provider()` | Added in SDK 1.4.0. A default PNG capture of the viewport after `frame_post_draw` is registered at init; your FuncRef replaces it. |
| `game.setGameContext` | `set_game_context(dict, cb)` / `..._async` | Values: String, int, float or bool. |
| `game.clearGameContext` | `clear_game_context(cb)` / `..._async` |  |
| `game.isInstantMultiplayer` | `ZokoGames.is_instant_multiplayer` |  |
| `game.isInstantJoin` | `ZokoGames.is_instant_join` | Deprecated alias. |
| `game.isOffline` | `ZokoGames.is_offline` | `bool`; false on older SDKs and portals. Simulator: `zokogames/simulator/offline`. |
| `game.gameId` | `ZokoGames.get_game_id()` / `ZokoGames.game_id` | Read-only id the portal sends at init (JS SDK 1.6.2); empty before init. The simulator returns `simulated-game`. |
| `data.mirrorIndexedDB` | HTML shell option `ZOKO_MIRROR_INDEXEDDB` (mirrors user:// before the engine starts); `stop_mirror_indexed_db()` stops it | Added in SDK 1.7.0. See "Cloud save for user:// (IndexedDB mirror)" below. |
| `game.addOfflineListener` | `offline_changed` signal | `ZokoGames.connect("offline_changed", self, "_on_x")`; `_on_x(offline)`. |
| `game.removeOfflineListener` | `ZokoGames.disconnect("offline_changed", self, "_on_x")` | Standard signal API. |
| `game.updateRoom` | `update_room(dict, cb)` / `..._async` | `{"roomId", "isJoinable", "inviteParams"}`. |
| `game.leftRoom` | `left_room(cb)` / `..._async` |  |
| `game.addJoinRoomListener` | `join_room` signal | `join_room(params)`. |
| `game.removeJoinRoomListener` | `ZokoGames.disconnect("join_room", self, "_on_x")` |  |
| `game.inviteParams` | `ZokoGames.invite_params` | Dictionary (empty when not launched from an invite). |
| `game.inviteLink` | `invite_link(params, cb)` / `..._async` | Result is the link String. |
| `game.getInviteParam` | `get_invite_param(key)` | Null when absent. |
| `game.showInviteButton` | `show_invite_button(params, cb)` / `..._async` | Deprecated: `update_room({"isJoinable": true, ...})`. |
| `game.hideInviteButton` | `hide_invite_button(cb)` / `..._async` | Deprecated: `update_room({"isJoinable": false})`. |
| `game.room` | `room_*` methods and signals | Room data channel (1.3.0): small JSON messages between the players of one room plus a host-written shared state. Game data, not text chat. See [Room data channel](#room-data-channel). Errors: `notInRoom`, `notHost`, `payloadTooLarge`, `stateTooLarge`, `unknownMember`, `roomUnavailable`. |
| `game.room.send` | `room_send(data, to, cb)` / `room_send_async(data, to)` / `room_send_to(id, data, cb)` | `data` is any JSON value; at most 8 KB, 20 calls per second. `to` = member id, empty for everyone else. |
| `game.room.onMessage` | `room_message` signal | `room_message(message)` with `from`, `data`, `direct`, `seq`, `ts`. Never emitted for your own messages on the portal. |
| `game.room.addMessageListener` | `ZokoGames.connect("room_message", self, "_on_x")` |  |
| `game.room.removeMessageListener` | `ZokoGames.disconnect("room_message", self, "_on_x")` |  |
| `game.room.setState` | `room_set_state(patch, cb)` / `room_set_state_async(patch)` | Host only; a `null` value removes the key. Applies when the platform confirms it. |
| `game.room.getState` | `room_get_state()` / `room_get_state_value(key, default)` | Copy of the shared state. |
| `game.room.onState` | `room_state` signal | `room_state(state, change)`; `change` has `by`, `keys`, `rev`. |
| `game.room.addStateListener` | `ZokoGames.connect("room_state", self, "_on_x")` |  |
| `game.room.removeStateListener` | `ZokoGames.disconnect("room_state", self, "_on_x")` |  |
| `game.room.members` | `room_get_members()` | Array of `{"id", "username", "profilePictureUrl"}`, including this player. |
| `game.room.onMembers` | `room_members` signal | `room_members(members)`. |
| `game.room.addMembersListener` | `ZokoGames.connect("room_members", self, "_on_x")` |  |
| `game.room.removeMembersListener` | `ZokoGames.disconnect("room_members", self, "_on_x")` |  |
| `game.room.isHost` | `room_is_host()` |  |
| `game.room.onHostChange` | `room_host_changed` signal | `room_host_changed(host_id, is_host)`; `host_id` is `""` when there is no host. |
| `game.room.addHostChangeListener` | `ZokoGames.connect("room_host_changed", self, "_on_x")` |  |
| `game.room.removeHostChangeListener` | `ZokoGames.disconnect("room_host_changed", self, "_on_x")` |  |
| `game.room.addLeftListener` | `ZokoGames.connect("room_left", self, "_on_x")` | `room_left(reason, room_id)`; `reason` is `"left"`, `"kicked"`, `"closed"` or `"disconnected"`; `room_id` is `""` when unknown. Added in SDK 1.7.0. |
| `game.room.removeLeftListener` | `ZokoGames.disconnect("room_left", self, "_on_x")` |  |
| `game.room.selfId` | `room_self_id()` | `""` when not in a room. |
| `game.room.onError` | `room_error` signal | `room_error(error)`, e.g. `rateLimited`, `notHost`. |
| `game.room.addErrorListener` | `ZokoGames.connect("room_error", self, "_on_x")` |  |
| `game.room.removeErrorListener` | `ZokoGames.disconnect("room_error", self, "_on_x")` |  |
| `user.isUserAccountAvailable` | `ZokoGames.is_user_account_available` |  |
| `user.systemInfo` | `ZokoGames.system_info` | Dictionary as in the JS SDK. |
| `user.getUser` | `get_user(cb)` / `get_user_async()` | Result is null when signed out. |
| `user.listFriends` | `list_friends(page, size, cb)` / `..._async` |  |
| `user.getUserToken` | `get_user_token(signing_key_type, cb)` / `..._async` | `""`, `"IN_GAME_AUTH"` or `"IN_GAME_AUTH_LEGACY"`. |
| `user.showAuthPrompt` | `show_auth_prompt(cb)` / `..._async` |  |
| `user.addAuthListener` | `auth_changed` signal | `auth_changed(user)`. |
| `user.removeAuthListener` | `ZokoGames.disconnect("auth_changed", self, "_on_x")` |  |
| `user.showAccountLinkPrompt` | `show_account_link_prompt(cb)` / `..._async` | Result `{"response": "yes"|"no"}`. |
| `user.submitScore` | `submit_score(encrypted_score, score, cb)` / `..._async` | For a board with a key, build the payload with `ZokoGames.encrypt_score(score, KEY, cb)` and pass its result here; keep any manual scheme only as a fallback. |
| `user.encryptScore` | `encrypt_score(score, key, cb, earned_at)` / `encrypt_score_async(score, key, earned_at)` | Added in SDK 1.8.0. Result is the base64 payload String for `submit_score`; `userNotAuthenticated` for guests, `invalidArgument` for a bad score or key. `earned_at` (Unix ms, default 0 = live run) seals the delayed copy of a score. |
| `user.getXsollaUserToken` | `get_xsolla_user_token(cb)` / `..._async` | Deprecated alias of `store_get_purchase_token`. |
| `ERROR_CODES` | `ZokoGames.ERROR_CODES.<module>` | Dictionary of code Arrays per module (`ad`, `banner`, `user`, `data`, `store`, `achievements`, `room`, `general`); `has_error_code(res, code)`. |
| `ERROR_CODE_DESCRIPTIONS` | Error codes table below | Not shipped as runtime text. |
| `SDK_VERSION` | `ZokoGames.VERSION` | The JS SDK release this addon was written against. |
| `data.getItem` | `data_get_item(key, default)`, `data_has_key(key)` | Strings, like localStorage. |
| `data.setItem` | `data_set_item(key, value)` | Returns `{"ok": false, "error": ...}` on `dataLimitExceeded`. |
| `data.removeItem` | `data_remove_item(key)` |  |
| `data.clear` | `data_clear()` |  |
| `data.mirrorLocalStorage` | `mirror_local_storage(options)` / `stop_mirror_local_storage()`, signal `mirror_error` | Added in SDK 1.4.0. Only JavaScript-side `localStorage`; Godot `user://` files live in IndexedDB and are not mirrored (use `data_set_item`). |
| `analytics.trackOrder` | `track_order(provider, order, cb)` / `..._async` |  |
| `analytics.track` | `track(event_name, params, cb)` / `track_async(event_name, params)` | Added in SDK 1.7.0. Fire-and-forget. `name` matches `^[a-z][a-z0-9_]{0,39}$`; `params` is a flat Dictionary of String, int, float or bool values (max 10). Added in SDK 1.7.0. |
| `store.isAvailable` | `ZokoGames.is_store_available` |  |
| `store.getCatalogItems` | `store_get_catalog_items(cb, limit, offset)` / `..._async` | Result is an Array of Dictionaries. |
| `store.getPlayerInventory` | `store_get_player_inventory(cb, limit, offset)` / `..._async` | `quantity` is null when not counted. |
| `store.buyItem` | `store_buy_item(item_id, cb)` / `..._async` | Result `{"itemId": ...}`; also raises `purchase_completed(item_id)` / `purchase_failed(error)`. |
| `store.consumeItem` | `store_consume_item(sku, quantity, cb)` / `..._async` |  |
| `store.getPurchaseToken` | `store_get_purchase_token(cb)` / `..._async` | Result is the token String (`userNotAuthenticated` for guests); send it to your server. |
| `store.setSandbox` | `store_set_sandbox(bool)` | Returns `{"ok": ...}` immediately. |
| `achievements.list` | `achievements_list(cb)` / `..._async` | Result is an Array of achievement Dictionaries. |
| `achievements.unlock` | `achievements_unlock(key, cb)` / `..._async` | Result `{"ok": true, "unlocked": bool, "achievement": {...}}` or `{"ok": false, "reason": ...}`; guests and unknown keys resolve `ok: false`. |
| `achievements.onUnlock` | `achievement_unlocked(achievement)` signal |  |


## Cloud save for user:// (IndexedDB mirror)

The web export keeps `user://` files in the browser's IndexedDB (`/userfs`). To save them to the player's cloud save, add this line in Export > HTML > Head Include:

```html
<script>window.ZOKO_MIRROR_INDEXEDDB = true;</script>
```

The shell restores the cloud copy before the engine starts and uploads later writes within a few seconds. The mirrored data may not exceed 1 MiB, and the data module must be enabled for the game. `ZokoGames.stop_mirror_indexed_db()` stops mirroring.

## Room data channel

`ZokoGames.room_*` (SDK 1.3.0) lets the players of one room exchange small messages and share a tiny host-written state without your own server. It is for game data, not text chat. The channel exists after `update_room(...)` (or after joining from an invite) and ends with `left_room()`; it needs a signed-in player and a portal with realtime enabled, otherwise calls fail with `roomUnavailable`. Limits: 8 KB per message or patch, 20 messages per second, 64 KB of state, state keys of 1 to 40 characters of `A-Z a-z 0-9 _ . : -`. Payloads cross the bridge as JSON, so use Dictionary, Array, String, number, bool and null (numbers come back as `float`; convert with `int()`).

On desktop and in the editor the simulator provides one room with one member (`sim-player`, the host) and **loops your own messages and state changes back** to the signals, so one instance can run the whole flow. A real portal never echoes your own messages.

```gdscript
extends Node

func _ready() -> void:
	yield(ZokoGames.init_async(), "completed")
	ZokoGames.connect("room_message", self, "_on_message")
	ZokoGames.connect("room_host_changed", self, "_on_host")
	yield(ZokoGames.update_room_async({"roomId": "match-1", "isJoinable": true}), "completed")   # the first player is the host


func _on_host(host_id, is_host) -> void:
	if is_host:
		ZokoGames.room_set_state({"turn": "X"})       # only the host writes shared state


func play_cell(cell: int) -> void:
	var res = yield(ZokoGames.room_send_async({"cell": cell, "mark": "X"}), "completed")   # reaches the other player
	if not res.ok:
		push_warning(res.error.code)


func _on_message(message) -> void:
	print(message.from, " played cell ", int(message.data.cell))
```

## Error codes

Every failure carries a code and a message (`{"code": String, "message": String, "containerId"?: String}` under `error`). Banner errors also carry the container id.

| Code | Meaning |
|---|---|
| `adCooldown` | An ad was requested too soon after the previous one. |
| `adblock` | An ad blocker prevented the ad. |
| `adsDisabled` | Ads are switched off for this game or session. |
| `bannerCooldown` | The same banner container was refreshed within 30 seconds. |
| `bannersDisabled` | Banners are switched off for this game or session. |
| `catalogFetchFailed` | The store catalogue could not be loaded. |
| `consumeItemFailed` | The provider rejected the consume request. |
| `dataLimitExceeded` | Cloud save would exceed 1 MiB. |
| `dataModuleDisabled` | Cloud save is not enabled for this game. |
| `insufficientItemQuantity` | consumeItem asked for more than the player owns. |
| `inventoryFetchFailed` | The player inventory could not be loaded. |
| `invalidArgument` | An argument failed validation. |
| `invalidSize` | The banner size is not one of the supported sizes. |
| `itemNotConsumable` | consumeItem was used on a non-consumable item. |
| `itemNotInInventory` | consumeItem named an item the player does not own. |
| `maxRefreshReached` | The per-session banner refresh limit was reached. |
| `missingId` | A banner container id was empty. |
| `noAvailableSizes` | No responsive banner size fits the container. |
| `notCreated` | The banner container does not exist. |
| `notVisible` | The banner container is hidden or off screen. |
| `other` | Any other failure; read the message. |
| `purchaseCancelled` | The player closed the checkout. |
| `purchaseInProgress` | A purchase is already running. |
| `purchaseInitFailed` | The checkout could not be opened (for example an unknown item id). |
| `rateLimited` | Friends were requested more often than every 250 ms. |
| `requestInProgress` | A request of the same kind is already running. |
| `sdkDisabled` | The SDK is disabled where the game is embedded. |
| `sdkNotInitialized` | Init has not finished yet. |
| `sdkNotLoaded` | The SDK script did not load (offline, blocked or missing script tag). |
| `showAccountLinkPromptInProgress` | The account-link prompt is already open. |
| `showAuthPromptInProgress` | The login prompt is already open. |
| `timeout` | The portal did not answer in time. |
| `unexpectedError` | The portal failed unexpectedly. |
| `unfilled` | No ad or banner was available. |
| `unsupportedEngine` | Godot 3 addon only: `init()` ran on Godot 4. Use the Godot 4 addon there. |
| `unknownMethod` | The wrapper called a bridge method the page does not know (version mismatch). |
| `userAlreadySignedIn` | showAuthPrompt was called while signed in. |
| `userCancelled` | The player dismissed a prompt. |
| `userNotAuthenticated` | The call needs a signed-in player. |
| `videoAdPlaying` | A banner was requested while a video ad plays. |

## Local testing and mock mode

In the editor and in desktop runs `ZokoGames.is_simulated` is true (the `JavaScript` singleton is only used when `OS.has_feature("JavaScript")`). Tune it under Project Settings > `zokogames/simulator/*`: ad behaviour (`fill`, `no_fill`, `error`) and duration, ad blocker, disabled embed, login state, friend count, mute and chat flags, store availability. The room data channel is simulated with one member that receives its own messages and state changes. Cloud save is kept in `user://zoko_sim_data.json`, the simulated inventory in `user://zoko_sim_inventory.json`.

Serve the HTML5 export from `localhost` first: the SDK then runs in its in-page local mode (fake ads, a fake player, a `localStorage` cloud save). To see the real requirements checklist and event log, open `/preview` on the portal and enter your local address while you play.

## Checks that ship with the package

- `tests/godot3.test.ts` (in `packages/sdk-engines`) rejects GDScript 2 only syntax in every `.gd` file here (`await`, annotations, typed arrays, lambdas, `super.`, `.emit(`, `Callable`, ...) and compares the public methods, signals, properties and simulator settings with the Godot 4 addon so the two cannot drift.
- If a Godot 3 binary (`godot3`, or `godot` reporting 3.x) is on `PATH` the same test runs `--check-only` on each script. Without one it is skipped and the scripts are not parsed by a real engine.

## Troubleshooting

- `sdkNotLoaded`: the exported page has no SDK script tag; set the Custom HTML Shell.
- `ZokoGames` autoload missing: the plugin is not enabled.
- Calls fail with `sdkNotInitialized`: `yield(ZokoGames.init_async(), "completed")` first.
- `unsupportedEngine`: this is the Godot 3 addon running on Godot 4; use the Godot 4 addon.
- Everything works in the editor but not in the browser: open the browser console; `window.ZokoBridge` must exist (the shell defines it).
- The game stays muted or paused after an ad: something else changed `get_tree().paused` or the Master bus during the ad. Set `ZokoGames.pause_game_during_ads` / `mute_audio_during_ads` to `false` and handle `ad_started` / `ad_finished` / `ad_error` yourself.
- Banners never show: the `ZokoBanner` node must have a size and be visible.

## Upload

Export for HTML5 as `index.html`, zip the export folder contents so `index.html` is at the archive root, and upload it in the developer console. Documentation: `/docs/engines/godot` on the portal.

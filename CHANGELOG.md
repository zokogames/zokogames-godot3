# Changelog

## 1.8.0 (2026-11-25)

- Matches the JavaScript SDK 1.8.0 (additive). New `hide_all_banners(cb)` / `show_all_banners(cb)` (and `..._async`) for `banner.hideAllBanners` / `banner.showAllBanners`: hide or show every banner without clearing it.
- New `encrypt_score(score, key, cb, earned_at)` / `encrypt_score_async(score, key, earned_at)` for `user.encryptScore`: returns the base64 payload for `submit_score` (`userNotAuthenticated` for guests, `invalidArgument` for a bad score or key; `earned_at` in Unix ms seals the delayed copy, 0 is a live run). The simulator answers with a `simulated-score.` payload.
- New `ZokoGames.game_id` / `get_game_id() -> String` for `game.gameId` (empty before init; the simulator returns `simulated-game`).
- IndexedDB mirror for `user://`: the HTML shell option `ZOKO_MIRROR_INDEXEDDB` (`<script>window.ZOKO_MIRROR_INDEXEDDB = true;</script>` in Export > HTML > Head Include) restores the cloud copy before the engine starts and mirrors later writes (`data.mirrorIndexedDB`); new `stop_mirror_indexed_db()` stops it (no-op in the simulator).
- The plugin now targets SDK 1.8.0; the wrapper constant `ZokoGames.VERSION` now reads `"1.8.0"`.

## 1.7.1 (2026-11-23)

- Patch release, still targets the JavaScript SDK 1.7.0.
- Fix: the simulator's `submit_score` accepts an empty encrypted score (like the SDK and the Godot 4 addon) and rejects a non-string encrypted score or a non-finite score.

## 1.7.0 (2026-11-23)

- Room left event: new signal `room_left(reason, room_id)` (`game.room.addLeftListener` / `removeLeftListener`); `reason` is `"left"`, `"kicked"`, `"closed"` or `"disconnected"`.
- Analytics: new `track(name, params)` (`analytics.track`, fire-and-forget); the simulator accepts it.
- The plugin now targets the JavaScript SDK 1.7.0; the wrapper constant (`ZokoGames.VERSION`) now reads `"1.7.0"`.
- `data.mirrorIndexedDB` is not bound yet: it must run in the page before the engine boots.
- `game.gameId` is still not bound.

## 1.6.4 of the JavaScript SDK (source only, 2026-11-23)

- No plugin change: targets SDK 1.6.4 (delayed scores are not wrapped). The only SDK change a plugin can notice: in local mode the mock now refuses a midgame ad with `adCooldown` until the game has called gameplay start (or 30 seconds of visible page time have passed), so call `gameplayStart` when play begins, before the first midgame ad. The wrapper constant that reports the SDK version now reads `"1.6.4"` in this source; the published zips keep reporting the version they were built with until the next plugin release. Nothing to do for games already built with the plugin.

## 1.6.3 of the JavaScript SDK (source only, 2026-11-22)

- Targets the JavaScript SDK 1.6.3 (messages and console warnings only, plus one fix: `ad.requestAd` resolves when the callbacks object cannot be read; no wrapper API change and no wrapper change is needed). The wrapper constant that reports the SDK version now reads `"1.6.3"` in this source; the published zips keep reporting the version they were built with until the next plugin release. Nothing to do for games already built with the plugin.

## Unreleased

- Targets the JavaScript SDK 1.6.2 (additive: one-time console notices, reserved host labels at any depth, read-only `SDK.game.gameId`, which the wrapper does not expose yet; no wrapper change is needed). The wrapper constant that reports the SDK version now reads `"1.6.2"` in this source; the published zips report `"1.6.1"` until the next plugin release. Nothing to do for games already built with this plugin.

## 1.6.2 (2026-11-21)

- Targets the JavaScript SDK 1.6.1 (a security hardening of the SDK itself: init is answered only by portal pages, a local page counts only for a local game; no wrapper API change). The constant that reports the SDK release now reads `"1.6.1"` (`ZokoGames.VERSION`). Nothing to do for games already built with this plugin.
- The shared bridge core (`export/zokogames_shell.html`) validates like the SDK: store page `limit` / `offset` reach the SDK unchanged (an invalid one is now `invalidArgument` instead of the default page), the user-token call passes the key type on (`""` keeps the default), a room send target must be a member id, a room state change refuses a `remove` that is not a list of keys and a `patch` that is not an object, and the store sandbox flag must be a boolean (the wrapper converts its own argument).
- Fix: a second ad request while an ad plays is refused by the SDK with an ad error ("Another ad request is already in progress"). That refused request released the wrapper's pause and Master mute, so the game resumed and was heard under the ad still on screen. Only the request whose ad started releases it now; the refused request still reports its error.

## 1.6.1 (2026-11-20)

- Released with the other engine plugins so every download carries the same version; still targets the JavaScript SDK 1.6.0. Run headless in the official Godot 3.6.3 editor (import, plugin enable, every public method in simulator mode, HTML5 export).
- Fix: a null `auth` payload (signed out) reached `auth_changed` as `null`, and a null `joinRoom` payload set `invite_params` to `null`, so `get_invite_param()` failed. Both now fall back to an empty Dictionary, as in the Godot 4 addon.
- Fix: `examples/zoko_demo.gd` read `user.username` in its `auth_changed` handler, a runtime error for a signed-out player; it uses `user.get("username", ...)` now.
- `invite_link`, `invite_link_async`, `show_invite_button` and `show_invite_button_async` name their first parameter `params`, like the Godot 4 addon (positional, so calls are unchanged).

## 1.6.0 (2026-11-19)

- Matches the JavaScript SDK 1.6.0 (additive): `update_room` passes `isPublic` (bool) through like every other key (doc comment only, no code change).

## 1.5.0 (2026-11-19)

- Matches the JavaScript SDK 1.5.0 (additive): `game.settings` carries `kidsMode` (true when the game runs in kids mode: no chat, rooms, sign-in prompts or personalised ads). A portal that predates it does not send the field; keep honouring `disableChat`. The simulator/editor mock reports `kidsMode: false` unless kids mode is switched on, and then also turns chat off, like the portal. The SDK's new `LeaderboardEntry` type (leaderboard rows: `isYou`, opaque per-game `userId`) is type only and has no wrapper binding, as the SDK has no leaderboard read call. No existing API changes.
- `ZokoGames.settings` holds `kidsMode` (read it with `settings.get("kidsMode", false)`). Simulator project setting `zokogames/simulator/kids_mode`.

## 1.4.1 (2026-11-19)

- Matches the JavaScript SDK 1.4.1 (a fix release with no API change: inside the portal the handshake waits up to 15 s instead of 1.5 s, per-key user tokens, game calls that resolve with a warning when the portal does not answer, cheaper cloud-save writes with retried syncs). No wrapper API change from the SDK side.

- After an ad, the sign-in or account-link prompt or a checkout, keyboard focus is handed back to the game frame and its canvas (shared bridge core), so keys work without a click.
- New `follow_portal_mute` (default true): the portal's mute setting is applied to the Master bus after init and on every change. `pause_game_during_ads` / `mute_audio_during_ads` are no longer Godot 3 extras: the Godot 4 addon has them too.
- README: rows for the ad callbacks, `ERROR_CODE_DESCRIPTIONS`, `SDK_VERSION`. New `TESTING.md`.

## 1.4.0

- Matches the JavaScript SDK 1.4.0 (`game.reportChat`, `game.onScreenshotRequest`, `data.mirrorLocalStorage`, all additive). Real engine bindings for all three: chat reports, a screenshot provider (with a default end-of-frame capture) and the localStorage mirror, each with editor/mock behaviour and tests. The mirror only sees browser localStorage, not the IndexedDB saves most engines use. No existing API changes.

## 1.3.1

- First release of the Godot 3.x addon. Same public API as the Godot 4 addon 1.3.1 (every method, signal and property name), written in GDScript 1 on the `JavaScript` singleton: `FuncRef` callbacks, `name_async()` request objects you `yield` on, and the same simulator and export shell.
- Matches the JavaScript SDK 1.3.1: the ad request times out after 30 s when the host never answers, malformed host messages are ignored, `SDK.init()` is safe without `window`, and `ERROR_CODE_DESCRIPTIONS` is exported. Includes the room data channel (`game.room`), achievements, offline awareness and the store module.
- Godot 3 only: `pause_game_during_ads` and `mute_audio_during_ads` (on by default) pause the tree and mute the Master bus while an ad plays and restore both afterwards; `init()` refuses to run on Godot 4 with the error code `unsupportedEngine`.
- Not run in a real Godot 3 editor yet (see the README).

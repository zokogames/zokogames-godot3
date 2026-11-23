extends Control
class_name ZokoBanner
## Place this Control where the banner should appear. It reports its on-screen rectangle (window
## pixels) to the portal, which draws the banner over the game canvas. Resize it to the space you can
## spare; with `size_mode = "responsive"` the largest supported size that fits is chosen.

signal completed(error)

export var container_id = "zoko-banner"
export(String, "responsive", "728x90", "300x250", "320x50", "468x60", "320x100") var size_mode = "responsive"
export var request_on_ready = true
## Draws a hatched placeholder while a banner is shown in the simulator.
export var show_simulator_placeholder = true

var is_shown = false
## Last rectangle (window pixels) that was reported to the portal.
var reported_rect = Rect2()


func _ready() -> void:
	if request_on_ready:
		request()


func _exit_tree() -> void:
	if is_shown:
		clear()


## Window-pixel rectangle of this Control (accounts for stretch modes and canvas transforms).
func get_window_rect() -> Rect2:
	var xf = get_viewport().get_final_transform() * get_global_transform_with_canvas()
	var a = xf.xform(Vector2.ZERO)
	var b = xf.xform(rect_size)
	return Rect2(a, b - a).abs()


func request() -> void:
	yield(ZokoGames.init_async(), "completed")
	if not is_inside_tree():
		return
	reported_rect = get_window_rect()
	var res
	if size_mode == "responsive":
		res = yield(ZokoGames.request_responsive_banner_async(container_id, reported_rect), "completed")
	else:
		var parts = size_mode.split("x")
		res = yield(ZokoGames.request_banner_async(container_id, int(parts[0]), int(parts[1]), reported_rect), "completed")
	is_shown = res.ok
	if not res.ok:
		push_warning("ZokoBanner '%s': %s" % [container_id, res.error.get("message", "failed")])
	update()
	emit_signal("completed", {} if res.ok else res.error)


func clear() -> void:
	is_shown = false
	update()
	ZokoGames.clear_banner(container_id)


func _draw() -> void:
	if is_shown and show_simulator_placeholder and ZokoGames.is_simulated:
		draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.2, 0.7, 0.55, 0.35))
		draw_rect(Rect2(Vector2.ZERO, rect_size), Color(0.2, 0.7, 0.55), false, 2.0)

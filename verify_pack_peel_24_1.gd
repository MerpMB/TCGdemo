extends SceneTree
## Issue 24.1 — Left→right progressive peel + held full-attached pose.


func _initialize() -> void:
	var packed := load("res://scenes/Pack.tscn") as PackedScene
	var pack := packed.instantiate() as PackScene
	pack.custom_minimum_size = Vector2(180, 250)
	pack.size = Vector2(180, 250)
	root.add_child(pack)
	await process_frame
	await process_frame

	var sprite := pack.get_node("PackSprite") as Control
	sprite.size = Vector2(180, 240)

	var art := load("res://assets/packs/knightpack.png") as Texture2D
	pack.setup_profile("knight_pack", Color(0.25, 0.38, 0.75), Color(0.91, 0.78, 0.42), art)
	pack.set("_manual_tear_enabled", false)
	await process_frame

	var pack_art := pack.get_node("PackSprite/PackArt") as TextureRect
	var flap_pivot := pack.get_node("PackSprite/TopFlapPivot") as Control
	var flap := pack.get_node("PackSprite/TopFlapPivot/PackFlap") as TextureRect
	var seal := pack.get_node("PackSprite/TopSeal") as TextureRect

	## Frame 1 — closed / unopened.
	pack.call("_apply_physical_peel", 0.0)
	await process_frame
	if pack_art.texture != art:
		push_error("24.1 FAIL Frame1: pack not intact full art.")
		quit(1)
		return
	if flap_pivot.visible or seal.visible:
		push_error("24.1 FAIL Frame1: strip/seal visible while closed.")
		quit(1)
		return
	if pack.get_wrapper_stage() != PackScene.WrapperStage.CLOSED:
		push_error("24.1 FAIL Frame1: stage not CLOSED.")
		quit(1)
		return

	for path in ["PackSprite/OpeningEmitter", "PackSprite/BackWrapper", "Glow", "EnergyAura"]:
		var node := pack.get_node_or_null(path)
		if node != null and node.visible:
			push_error("24.1 FAIL: out-of-scope node visible: %s" % path)
			quit(1)
			return
	if pack_art.material != null or flap.material != null or seal.material != null:
		push_error("24.1 FAIL: wrapper must not use shader materials.")
		quit(1)
		return

	## Early peel — left corner only; right seal still flush; hinge at tear tip.
	pack.call("_apply_physical_peel", 0.22)
	await process_frame
	var early_w: float = flap_pivot.size.x
	if pack.get_wrapper_stage() != PackScene.WrapperStage.PEELING:
		push_error("24.1 FAIL early: stage not PEELING.")
		quit(1)
		return
	if not flap.visible or not flap.is_visible_in_tree():
		push_error("24.1 FAIL early: peeled corner not visible.")
		quit(1)
		return
	if not seal.visible:
		push_error("24.1 FAIL early: unpeeled right seal must stay flush.")
		quit(1)
		return
	if early_w > sprite.size.x * 0.45:
		push_error("24.1 FAIL early: peel too wide for left-corner start (w=%s)." % early_w)
		quit(1)
		return
	if absf(flap_pivot.pivot_offset.x - early_w) > 1.0:
		push_error("24.1 FAIL early: hinge must be at tear tip (pivot=%s)." % flap_pivot.pivot_offset)
		quit(1)
		return
	if absf(flap_pivot.pivot_offset.x - sprite.size.x) < 1.0:
		push_error("24.1 FAIL early: must not hinge at far right yet.")
		quit(1)
		return
	if flap_pivot.position.length() > 0.5:
		push_error("24.1 FAIL early: strip detached while peeling.")
		quit(1)
		return

	## Mid peel — tear progressed left → right (wider peel, seal still remains).
	pack.call("_apply_physical_peel", 0.55)
	await process_frame
	var mid_w: float = flap_pivot.size.x
	if pack.get_wrapper_stage() != PackScene.WrapperStage.PEELING:
		push_error("24.1 FAIL mid: stage not PEELING.")
		quit(1)
		return
	if not seal.visible:
		push_error("24.1 FAIL mid: right seal must remain until peel completes.")
		quit(1)
		return
	if mid_w <= early_w + 8.0:
		push_error("24.1 FAIL mid: peel did not advance left→right (early=%s mid=%s)." % [early_w, mid_w])
		quit(1)
		return
	if mid_w >= sprite.size.x - 1.0:
		push_error("24.1 FAIL mid: already full-width before complete.")
		quit(1)
		return
	if absf(flap_pivot.pivot_offset.x - mid_w) > 1.0:
		push_error("24.1 FAIL mid: hinge not following tear tip.")
		quit(1)
		return
	if flap_pivot.position.length() > 0.5 or flap.modulate.a < 0.99:
		push_error("24.1 FAIL mid: early detach/fade.")
		quit(1)
		return

	## Frame 3 — fully peeled, still attached on the right (no drift/fade yet).
	pack.call("_apply_physical_peel", 0.97)
	await process_frame
	if pack.get_wrapper_stage() != PackScene.WrapperStage.FULL_PEEL:
		push_error("24.1 FAIL Frame3: stage not FULL_PEEL.")
		quit(1)
		return
	if seal.visible:
		push_error("24.1 FAIL Frame3: flush remainder must be gone.")
		quit(1)
		return
	if absf(flap_pivot.size.x - sprite.size.x) > 1.0:
		push_error("24.1 FAIL Frame3: strip should be full width.")
		quit(1)
		return
	if absf(flap_pivot.pivot_offset.x - sprite.size.x) > 1.0:
		push_error("24.1 FAIL Frame3: must be attached at far right (pivot=%s)." % flap_pivot.pivot_offset)
		quit(1)
		return
	if absf(flap_pivot.rotation) < 1.0:
		push_error("24.1 FAIL Frame3: full peel not lifted enough (rot=%s)." % flap_pivot.rotation)
		quit(1)
		return
	if flap_pivot.position.length() > 0.5:
		push_error("24.1 FAIL Frame3: strip must stay attached (pos=%s)." % flap_pivot.position)
		quit(1)
		return
	if flap.modulate.a < 0.99:
		push_error("24.1 FAIL Frame3: attached strip must be fully opaque.")
		quit(1)
		return
	if not flap.visible:
		push_error("24.1 FAIL Frame3: peeled strip not visible.")
		quit(1)
		return

	## Hold then detach — must NOT detach immediately.
	var completed := {"done": false}
	pack.tear_completed.connect(func() -> void: completed.done = true)
	pack.force_complete_tear()
	await process_frame
	if pack.get_wrapper_stage() != PackScene.WrapperStage.FULL_PEEL:
		push_error("24.1 FAIL hold: expected FULL_PEEL hold before detach (got %s)." % pack.get_wrapper_stage())
		quit(1)
		return
	if flap_pivot.position.length() > 0.5:
		push_error("24.1 FAIL hold: detached during attached hold.")
		quit(1)
		return

	var waited := 0.0
	while pack.get_wrapper_stage() == PackScene.WrapperStage.FULL_PEEL and waited < 1.2:
		await process_frame
		waited += 0.016
	if waited < 0.35:
		push_error("24.1 FAIL hold: full-peel attached pose was not held (%.2fs)." % waited)
		quit(1)
		return

	## Frame 4 — flying detach.
	while pack.get_wrapper_stage() != PackScene.WrapperStage.DETACHING and waited < 1.5:
		await process_frame
		waited += 0.016
	if pack.get_wrapper_stage() != PackScene.WrapperStage.DETACHING:
		push_error("24.1 FAIL Frame4: never entered DETACHING.")
		quit(1)
		return
	var flight_wait := 0.0
	while flight_wait < 0.18 and not completed.done:
		await process_frame
		flight_wait += 0.016
		waited += 0.016
	if flap_pivot.position.length() < 8.0:
		push_error("24.1 FAIL Frame4: detached strip did not drift (pos=%s)." % flap_pivot.position)
		quit(1)
		return
	if flap.modulate.a >= 0.99:
		push_error("24.1 FAIL Frame4: strip should fade while flying.")
		quit(1)
		return

	## Frame 5 — finished.
	while not completed.done and waited < 3.0:
		await process_frame
		waited += 0.016
	if not completed.done:
		push_error("24.1 FAIL Frame5: tear_completed never emitted.")
		quit(1)
		return
	if pack.get_wrapper_stage() != PackScene.WrapperStage.FINISHED:
		push_error("24.1 FAIL Frame5: stage not FINISHED.")
		quit(1)
		return
	if flap_pivot.visible:
		push_error("24.1 FAIL Frame5: strip still visible.")
		quit(1)
		return
	if not pack_art.visible or pack_art.texture == null or pack_art.texture == art:
		push_error("24.1 FAIL Frame5: open body missing/incorrect.")
		quit(1)
		return

	var opening_source := FileAccess.get_file_as_string("res://scripts/ui/pack_opening.gd")
	if opening_source.contains("_release_cards_storyboard") or opening_source.contains("play_arrival"):
		push_error("24.1 FAIL: pack_opening releases cards (out of scope).")
		quit(1)
		return

	## Foundation reset must restore approved defaults after slider edits.
	pack.peel_rot_end = 1.55
	pack.detach_drift = Vector2(10.0, 20.0)
	pack.reset_peel_tuning_to_foundation()
	if absf(pack.peel_rot_end - PackScene.FOUNDATION_PEEL_ROT_END) > 0.001:
		push_error("24.1 FAIL: reset_peel_tuning_to_foundation did not restore rot.")
		quit(1)
		return
	if pack.detach_drift != PackScene.FOUNDATION_DETACH_DRIFT:
		push_error("24.1 FAIL: reset_peel_tuning_to_foundation did not restore drift.")
		quit(1)
		return

	print("VERIFY_PACK_PEEL_24_1: PASS")
	quit(0)

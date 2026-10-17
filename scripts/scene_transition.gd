
extends CanvasLayer


func change_scene_to_file(target: String) -> void:
	$AnimationPlayer.play("dissolve")
	await $AnimationPlayer.animation_finished

	get_tree().change_scene_to_file(target)

	$AnimationPlayer.play_backwards("dissolve")
	await $AnimationPlayer.animation_finished


func change_menu_scene_to_file(target: String) -> void:
	get_tree().change_scene_to_file(target)


func change_game_over_scene_to_file(target: String) -> void:
	var new_scene = load(target).instantiate()
	add_child(new_scene)

	var screen_size = get_viewport().size
	new_scene.position = Vector2(0, screen_size.y)

	var tween = create_tween()
	tween.tween_property(new_scene, "position", Vector2.ZERO, 0.6)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	await tween.finished

	var current = get_tree().current_scene
	if current and current != new_scene:
		current.queue_free()

	get_tree().current_scene = new_scene


func change_newspaper_scene_to_file(target: String) -> void:
	# Fade out the current scene.
	$AnimationPlayer.play("dissolve")
	await $AnimationPlayer.animation_finished

	# Change scene.
	get_tree().change_scene_to_file(target)

	# Fade back in.
	$AnimationPlayer.play_backwards("dissolve")
	await $AnimationPlayer.animation_finished

	# Allow the new scene to settle.
	await get_tree().create_timer(0.5).timeout

	# Slide newspaper into view.
	$AnimationPlayer.play("newspaper_enter")
	await $AnimationPlayer.animation_finished

	# Wait for the player to press a button.
	await get_tree().create_timer(0.1).timeout
	await _wait_for_newspaper_continue()

	# Slide newspaper away.
	$AnimationPlayer.play("newspaper_exit")
	await $AnimationPlayer.animation_finished


func _wait_for_newspaper_continue() -> void:
	await get_tree().process_frame

	while true:
		if Input.is_action_just_pressed("ui_accept"):
			return

		await get_tree().process_frame

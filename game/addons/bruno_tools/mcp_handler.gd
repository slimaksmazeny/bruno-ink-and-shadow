## Handler vlastního nástroje Godot AI „bruno_sync“ (git pull + obnovení editoru).
@tool
extends RefCounted

const GitSync := preload("res://addons/bruno_tools/git_sync.gd")

var _thread: Thread


func sync(_params: Dictionary, ctx: Object) -> Dictionary:
	if _thread != null and _thread.is_alive():
		return {"data": {"ok": false, "message": "Synchronizace už běží."}}
	if _thread != null:
		_thread.wait_to_finish()
	_thread = Thread.new()
	_thread.start(_work.bind(ctx))
	return {"_deferred": true}


func _work(ctx: Object) -> void:
	var r: Dictionary = GitSync.pull_blocking()
	_finish.call_deferred(ctx, r)


func _finish(ctx: Object, r: Dictionary) -> void:
	GitSync.apply_in_editor(r)
	ctx.call("send_deferred", {"data": r})


func quiesce_for_script_swap() -> Dictionary:
	return {"ok": _thread == null or not _thread.is_alive()}

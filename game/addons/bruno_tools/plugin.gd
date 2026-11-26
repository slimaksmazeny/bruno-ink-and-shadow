## Bruno Tools: tlačítko „⬇ GitHub“ v liště editoru + nástroj bruno_sync pro Godot AI.
@tool
extends EditorPlugin

const GitSync := preload("res://addons/bruno_tools/git_sync.gd")
const SOURCE_CFG := "res://addons/bruno_tools/plugin.cfg"
const REGISTRY := "res://addons/godot_ai/custom_tools/mcp_tool_registry.gd"
const SPEC := "res://addons/godot_ai/custom_tools/mcp_custom_tool_spec.gd"

var _button: Button
var _thread: Thread


func _enter_tree() -> void:
	_button = Button.new()
	_button.text = "⬇ GitHub"
	_button.tooltip_text = "Stáhnout nejnovější verzi hry z GitHubu (git pull) a obnovit soubory."
	_button.pressed.connect(_on_pressed)
	add_control_to_container(CONTAINER_TOOLBAR, _button)
	_register_tool.call_deferred()


func _exit_tree() -> void:
	if _thread != null:
		_thread.wait_to_finish()
	if _button != null:
		remove_control_from_container(CONTAINER_TOOLBAR, _button)
		_button.queue_free()
	var reg: Object = _registry()
	if reg != null:
		reg.call("unregister_source", SOURCE_CFG)


func _registry() -> Object:
	if not ResourceLoader.exists(REGISTRY):
		return null
	var script: Script = load(REGISTRY)
	return script.call("get_instance") if script != null else null


## Volitelné: když je nainstalovaný Godot AI, přidá nástroj „bruno_sync“.
func _register_tool() -> void:
	var reg: Object = _registry()
	if reg == null:
		return
	if reg.has_signal("registry_ready") and not reg.is_connected("registry_ready", _register_tool):
		reg.connect("registry_ready", _register_tool)
	var spec: Object = (load(SPEC) as Script).call("new")
	spec.set("name", "bruno_sync")
	spec.set("description", "Bruno: Ink & Shadow – stáhne nejnovější verzi z GitHubu (git pull --rebase --autostash), obnoví souborový systém editoru a znovu načte změněné otevřené scény. Vrací změněné soubory a výstup gitu.")
	spec.set("params_schema", {"type": "object", "properties": {}})
	spec.set("script_path", "res://addons/bruno_tools/mcp_handler.gd")
	spec.set("method", &"sync")
	spec.set("source_path", SOURCE_CFG)
	spec.set("deferred", true)
	spec.set("timeout_ms", 90000)
	spec.set("promoted", true)
	reg.call("register", spec)


func _on_pressed() -> void:
	if _thread != null and _thread.is_alive():
		return
	if _thread != null:
		_thread.wait_to_finish()
	_button.disabled = true
	_button.text = "⏳ Stahuji…"
	_thread = Thread.new()
	_thread.start(func() -> void:
		var r: Dictionary = GitSync.pull_blocking()
		_done.call_deferred(r))


func _done(r: Dictionary) -> void:
	GitSync.apply_in_editor(r)
	_button.disabled = false
	if not bool(r.get("ok", false)):
		_button.text = "⚠ GitHub"
		push_warning("Bruno Tools: stažení selhalo – " + String(r.get("message", r.get("git_output", ""))))
	elif bool(r.get("updated", false)):
		_button.text = "✔ GitHub (%d)" % (r.get("changed_files", PackedStringArray()) as PackedStringArray).size()
		print("Bruno Tools: staženo %s → %s" % [r["before"], r["after"]])
	else:
		_button.text = "✔ GitHub"
		print("Bruno Tools: už máš nejnovější verzi.")

## Stažení nejnovější verze projektu z GitHubu (git pull) a obnovení souborů v editoru.
## Používá git z PATH, jinak ten, který přibaluje GitHub Desktop.
@tool
extends RefCounted


## Kořen repozitáře (project.godot je ve složce game/).
static func repo_dir() -> String:
	return ProjectSettings.globalize_path("res://").path_join("..").simplify_path()


static func find_git() -> String:
	var out: Array = []
	if OS.execute("git", ["--version"], out, true) == 0:
		return "git"
	var local: String = OS.get_environment("LOCALAPPDATA").replace("\\", "/")
	var gh_root: String = local.path_join("GitHubDesktop")
	var dir := DirAccess.open(gh_root)
	if dir != null:
		var apps: PackedStringArray = []
		for d: String in dir.get_directories():
			if d.begins_with("app-"):
				apps.append(d)
		apps.sort()
		for i: int in range(apps.size() - 1, -1, -1):
			var p: String = gh_root.path_join(apps[i]).path_join("resources/app/git/cmd/git.exe")
			if FileAccess.file_exists(p):
				return p
	for p: String in ["C:/Program Files/Git/cmd/git.exe", "C:/Program Files (x86)/Git/cmd/git.exe"]:
		if FileAccess.file_exists(p):
			return p
	return ""


static func _git(git: String, args: PackedStringArray) -> Dictionary:
	var out: Array = []
	var full: PackedStringArray = ["-C", repo_dir()]
	full.append_array(args)
	var code: int = OS.execute(git, full, out, true)
	return {"code": code, "text": "\n".join(out).strip_edges()}


## Blokující část (běží ve vlákně): pull s automatickým odložením lokálních změn.
static func pull_blocking() -> Dictionary:
	var git: String = find_git()
	if git.is_empty():
		return {"ok": false, "message": "Git nenalezen (nainstaluj GitHub Desktop nebo Git)."}
	var before: String = String(_git(git, ["rev-parse", "HEAD"]).text)
	var r: Dictionary = _git(git, ["pull", "--rebase", "--autostash"])
	var after: String = String(_git(git, ["rev-parse", "HEAD"]).text)
	var changed: PackedStringArray = []
	if before != after and int(r.code) == 0:
		var d: Dictionary = _git(git, ["diff", "--name-only", before, after])
		changed = String(d.text).split("\n", false)
	return {
		"ok": int(r.code) == 0,
		"updated": before != after,
		"before": before.left(7),
		"after": after.left(7),
		"changed_files": changed,
		"git_output": String(r.text).right(1500),
	}


## Hlavní vlákno: obnovit souborový systém a znovu načíst otevřené scény, které se změnily.
static func apply_in_editor(result: Dictionary) -> void:
	if not Engine.is_editor_hint():
		return
	EditorInterface.get_resource_filesystem().scan()
	if not bool(result.get("updated", false)):
		return
	var open: PackedStringArray = EditorInterface.get_open_scenes()
	for f: String in result.get("changed_files", PackedStringArray()):
		if not f.begins_with("game/"):
			continue
		var res_path: String = "res://" + f.trim_prefix("game/")
		if res_path in open:
			EditorInterface.reload_scene_from_path(res_path)

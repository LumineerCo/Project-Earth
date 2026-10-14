## plan_coverage_audit.gd
## Plan document coverage automation tool.
## Stage 2.11 — Development Automation
##
## Scans Plan Docs for expected `.gd` and `.tscn` references and compares them
## against the actual files in the Godot project. Intended to help identify
## missing implementation files and plan-to-code gaps.
##
## Usage (from editor console):
##   var auditor = load("res://tools/plan_coverage_audit.gd").new()
##   auditor.scan()
##   auditor.print_summary()
extends Node
class_name PlanCoverageAudit

const PLAN_DOCS_RELATIVE := "../Plan Docs/"
const PROJECT_ROOT := "res://"
const PROJECT_FILE_EXTENSIONS := ["gd", "tscn"]

var _results := {
    "plan_references": [],
    "actual_files": [],
    "matched": [],
    "missing": [],
    "total_references": 0,
    "unique_plan_references": 0,
    "actual_file_count": 0
}

func scan() -> void:
    _results.clear()
    _results = {
        "plan_references": [],
        "actual_files": [],
        "matched": [],
        "missing": [],
        "total_references": 0,
        "unique_plan_references": 0,
        "actual_file_count": 0
    }

    var project_path := ProjectSettings.globalize_path(PROJECT_ROOT)
    var plan_path := project_path.plus_file(PLAN_DOCS_RELATIVE)
    var plan_dir := DirAccess.open(plan_path)
    if plan_dir == null:
        push_error("PlanCoverageAudit: Cannot open plan docs path: %s" % plan_path)
        return

    var plan_file_names := _collect_plan_file_names(plan_dir, plan_path)
    var unique_plan_names := []
    var seen_names := {}
    for name in plan_file_names:
        var lower_name := name.to_lower()
        if not seen_names.has(lower_name):
            seen_names[lower_name] = true
            unique_plan_names.append(name)

    _results["plan_references"] = plan_file_names
    _results["unique_plan_references"] = unique_plan_names
    _results["total_references"] = plan_file_names.size()

    var actual_files := _collect_project_files(project_path)
    _results["actual_files"] = actual_files
    _results["actual_file_count"] = actual_files.size()

    var actual_name_map := {}
    for actual in actual_files:
        actual_name_map[actual.to_lower()] = actual

    for plan_name in _results["unique_plan_references"]:
        var lower_name := plan_name.to_lower()
        if actual_name_map.has(lower_name):
            _results["matched"].append({"plan": plan_name, "actual": actual_name_map[lower_name]})
        else:
            _results["missing"].append(plan_name)

func print_summary() -> void:
    print("\n" + "=".repeat(60))
    print("PLAN COVERAGE AUDIT REPORT")
    print("=".repeat(60))
    print("Project files: %d" % _results["actual_file_count"])
    print("Plan document references: %d" % _results["unique_plan_references"].size())
    print("Matched references: %d" % _results["matched"].size())
    print("Missing files: %d" % _results["missing"].size())
    print("")

    if _results["missing"].size() == 0:
        print("[OK] All referenced plan files currently exist in the project.")
    else:
        print("[WARN] The following referenced plan files appear missing:")
        for missing in _results["missing"].slice(0, 50):
            print("  - %s" % missing)
        if _results["missing"].size() > 50:
            print("  ... and %d more" % (_results["missing"].size() - 50))
    print("=".repeat(60))

func _collect_plan_file_names(dir: DirAccess, root_path: String) -> Array:
    var names := []
    dir.list_dir_begin()
    var entry := dir.get_next()
    while entry != "":
        if entry.begins_with("."):
            entry = dir.get_next()
            continue
        var entry_path := root_path.plus_file(entry)
        if dir.current_is_dir():
            var sub_dir := DirAccess.open(entry_path)
            if sub_dir != null:
                names += _collect_plan_file_names(sub_dir, entry_path)
        elif entry.ends_with(".md"):
            var text := FileAccess.get_file_as_string(entry_path)
            names += _extract_references_from_text(text)
        entry = dir.get_next()
    return names

func _extract_references_from_text(text: String) -> Array:
    var found := []
    var regex := RegEx.new()
    regex.compile("\\b([A-Za-z0-9_]+\\.(?:gd|tscn))\\b")
    var results := regex.search_all(text)
    for r in results:
        var name := r.get_string(1)
        if name != "":
            found.append(name)
    return found

func _collect_project_files(root_path: String) -> Array:
    var result := []
    var dir := DirAccess.open(root_path)
    if dir == null:
        return result
    dir.list_dir_begin()
    var entry := dir.get_next()
    while entry != "":
        if entry.begins_with("."):
            entry = dir.get_next()
            continue
        var entry_path := root_path.plus_file(entry)
        if dir.current_is_dir():
            result += _collect_project_files(entry_path)
        elif _is_project_file(entry):
            result.append(entry)
        entry = dir.get_next()
    return result

func _is_project_file(file_name: String) -> bool:
    var ext := file_name.get_extension().to_lower()
    return ext in PROJECT_FILE_EXTENSIONS

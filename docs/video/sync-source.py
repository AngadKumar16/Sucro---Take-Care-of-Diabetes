# Copies the Swift shown on screen from the app's source into scenes/source.js, so the code in the
# video is always the real code. Each snippet starts at the line whose text contains `anchor`
# (so it survives edits above it) and runs for `count` lines. Rerun after changing the app:
#   python3 sync-source.py
import json, os, textwrap

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.join(HERE, "..", "..")
SNIPPETS = {
    "careStage": ("DiabetesCare/Models/Domain/CareStage.swift", "enum CareStage: String", 56),
    "setup": ("DiabetesCare/Views/Growth/SetupView.swift", "ForEach(CareStage.allCases", 18),
    "kidToday": ("DiabetesCare/Views/Growth/KidHelpCard.swift", 'Text("Feeling off?")', 22),
    "kidSteps": ("DiabetesCare/Views/Growth/KidHelpCard.swift", 'step(1, String(localized: "Find a grown-up now.")', 20),
    "callButton": ("DiabetesCare/Views/Growth/KidHelpCard.swift", "private func callButton", 13),
    "lowTreatment": ("DiabetesCare/Services/LowTreatmentService.swift", "enum LowTreatmentService", 30),
    "liveActivity": ("DiabetesCare/Services/LowTreatmentService.swift", "static func start(grams: Double, recheckAt", 20),
    "parentLock": ("DiabetesCare/Services/ParentLock.swift", "/// Sets or replaces the passcode", 30),
    "scale": ("DiabetesCare/Views/Components/KitchenScale.swift", "struct KitchenScale: View", 18),
    "pen": ("DiabetesCare/Views/Components/InsulinPen.swift", "struct InsulinPen: View", 4),
    "penDraw": ("DiabetesCare/Views/Components/InsulinPen.swift", "context.draw(Text(units.formatted", 3),
    "bodyMap": ("DiabetesCare/Views/Components/BodyMap.swift", "/// The site that has rested longest", 5),
    "tubes": ("DiabetesCare/Views/Components/TimeInRangeTubes.swift", "struct TimeInRangeTubes: View", 5),
    "skillPath": ("DiabetesCare/Views/Growth/SkillPathView.swift", "let needed = settings.stage.skillsToMoveUp", 38),
    "sendHelp": ("DiabetesCare/Services/Family/FamilyService.swift", "func sendHelpRequest(mgdl: Double?)", 15),
    "reply": ("DiabetesCare/Services/Family/FamilyService.swift", "/// Follower: answers someone's help request.", 18),
    "replyMessage": ("DiabetesCare/Services/Family/FamilyModels.swift", "enum Message: String, Codable", 12),
    "codec": ("DiabetesCare/Services/Family/FamilyRecordCodec.swift", "private static func record<T: Encodable>", 7),
    "familyModels": ("DiabetesCare/Services/Family/FamilyModels.swift", "struct FamilyProfile: Codable", 28),
    "access": ("DiabetesCare/Models/Domain/CareStage.swift", "func access(to feature: Feature", 20),
    "healthImport": ("DiabetesCare/Services/HealthGlucoseImporter.swift", "private func registerObserver()", 17),
    "storyWriter": ("DiabetesCare/Services/StoryWriter.swift", "static func reword(_ template: String", 28),
    "isFaithful": ("DiabetesCare/Services/StoryWriter.swift", "nonisolated static func isFaithful", 11),
    "checkGlucose": ("DiabetesCare/App/Intents/AppIntents.swift", "struct CheckGlucoseIntent: AppIntent", 12),
}

out = {}
for name, (path, anchor, count) in SNIPPETS.items():
    lines = open(os.path.join(APP, path)).read().split("\n")
    i = next(n for n, l in enumerate(lines) if anchor in l)
    body = textwrap.dedent("\n".join(lines[i:i + count])).split("\n")
    out[name] = {"file": os.path.basename(path), "start": i + 1, "lines": body}
with open(os.path.join(HERE, "scenes", "source.js"), "w") as f:
    f.write("// The app's real Swift, copied by `python3 sync-source.py`; don't edit by hand.\n")
    f.write("export const SRC = " + json.dumps(out, indent=1, ensure_ascii=False) + ";\n")
print("wrote scenes/source.js:", ", ".join(f"{k} {v['file']}:{v['start']}" for k, v in out.items()))

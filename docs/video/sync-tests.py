# The test wall in shot 11 shows every test from a real run. Run the suite with a result bundle,
# then point this at it:
#   xcodebuild test -project DiabetesCare.xcodeproj -scheme DiabetesCare \
#     -destination 'platform=iOS Simulator,name=iPhone 17' -parallel-testing-enabled NO -resultBundlePath /tmp/tests.xcresult
#   python3 docs/video/sync-tests.py /tmp/tests.xcresult [/tmp/rerun.xcresult ...]
# Writes scenes/tests.js with the passed tests' names and the count. Skipped tests and Xcode's empty
# template tests are left out; a test that passed in a later bundle (a rerun) counts as passed.
import json, os, subprocess, sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = {"testExample()", "testLaunchPerformance()", "testLaunch()"}
passed, other = [], []

def walk(node):
    if node.get("nodeType") == "Test Case":
        (passed if node.get("result") == "Passed" else other).append((node.get("name", ""), node.get("result")))
    for child in node.get("children", []):
        walk(child)

for bundle in sys.argv[1:]:
    for root in json.loads(subprocess.check_output(["xcrun", "xcresulttool", "get", "test-results", "tests", "--path", bundle])).get("testNodes", []):
        walk(root)
names = list(dict.fromkeys(n for n, _ in passed if n not in TEMPLATE))
other = [(n, r) for n, r in other if n not in names and n not in TEMPLATE]
with open(os.path.join(HERE, "scenes", "tests.js"), "w") as f:
    f.write("// Every test that passed in the last full run, from `python3 sync-tests.py <xcresult>`; don't edit.\n")
    f.write("export const TESTS = " + json.dumps({"count": len(names), "names": names}, indent=0) + ";\n")
print(f"{len(names)} passed; not passed: {len(other)}", sorted(set(r for _, r in other)), [n for n, r in other if r != "Skipped"][:20])

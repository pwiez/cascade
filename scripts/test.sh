#!/bin/bash
set -euo pipefail

usage() {
    cat <<'USAGE'
Usage: scripts/test.sh [unit|ui|all] [IPAD_SIMULATOR_UDID]

The default mode is all. Supply a simulator UDID as the last argument or set
DESTINATION_ID. The simulator must be an available iPad running iPadOS 26 or later.
Logs, result bundles, and build products are retained in a temporary run directory.
USAGE
}

mode=all
case "${1:-}" in
    unit|ui|all) mode=$1; shift ;;
    -h|--help) usage; exit 0 ;;
esac
if [[ $# -gt 1 ]]; then
    usage >&2
    exit 2
fi
destination_id=${1:-${DESTINATION_ID:-}}
if [[ ! "$destination_id" =~ ^[[:xdigit:]]{8}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{4}-[[:xdigit:]]{12}$ ]]; then
    printf 'Supply an explicit iPad simulator UDID, or set DESTINATION_ID.\n' >&2
    usage >&2
    exit 2
fi
for tool in xcodebuild xcrun python3; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        printf 'Required tool not found: %s\n' "$tool" >&2
        exit 1
    fi
done

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
run_directory=$(mktemp -d /tmp/cascade-tests.XXXXXX)
package_directory="$repository_root/Cascade.swiftpm"
package_data="$run_directory/package-derived"
app_bundle_id=pwiez.cascade
started_simulator=0
installed_app=0
started_ui_tests=0
active_pid=

cleanup() {
    local status=$?
    trap - EXIT INT TERM
    if [[ -n "$active_pid" ]]; then
        kill -TERM "$active_pid" 2>/dev/null || true
        wait "$active_pid" 2>/dev/null || true
    fi
    if [[ "$started_ui_tests" -eq 1 ]]; then
        xcrun simctl terminate "$destination_id" pwiez.cascade.uitests.xctrunner >>"$run_directory/cleanup.log" 2>&1 || true
    fi
    if [[ "$installed_app" -eq 1 ]]; then
        # XCTest normally terminates the app; this also covers an interrupted run.
        xcrun simctl terminate "$destination_id" "$app_bundle_id" >>"$run_directory/cleanup.log" 2>&1 || true
    fi
    if [[ "$started_simulator" -eq 1 ]]; then
        if ! xcrun simctl shutdown "$destination_id" >>"$run_directory/cleanup.log" 2>&1; then
            printf 'Could not shut down the simulator started by this run; see cleanup.log.\n' >&2
            if [[ "$status" -eq 0 ]]; then status=1; fi
        fi
    fi
    printf 'Artifacts: %s\n' "$run_directory"
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

run_logged() {
    local label=$1
    local working_directory=$2
    shift 2
    local log="$run_directory/$label.log"
    local status=0
    printf '%s...\n' "$label"
    (
        cd "$working_directory"
        exec "$@"
    ) >"$log" 2>&1 &
    active_pid=$!
    wait "$active_pid" || status=$?
    active_pid=
    if [[ "$status" -ne 0 ]]; then
        printf '%s failed (exit %s). Log: %s\n' "$label" "$status" "$log" >&2
        tail -n 25 "$log" | awk '
            length($0) > 400 { print substr($0, 1, 400) " ... [line truncated]"; next }
            { print }
        ' >&2
    fi
    return "$status"
}

summarize_tests() {
    local label=$1
    local result="$run_directory/$label.xcresult"
    local summary="$run_directory/$label-summary.json"
    if [[ ! -d "$result" ]]; then
        printf '%s: no result bundle was produced; see %s.log.\n' "$label" "$label" >&2
        return 1
    fi
    if ! xcrun xcresulttool get test-results summary --path "$result" >"$summary" 2>"$run_directory/$label-summary.log"; then
        printf '%s: could not read the result summary; see %s-summary.log.\n' "$label" "$label" >&2
        return 1
    fi
    python3 - "$label" "$summary" <<'PY'
import json
import sys

label, path = sys.argv[1:]
try:
    with open(path, encoding="utf-8") as source:
        summary = json.load(source)
    passed = int(summary.get("passedTests", 0))
    failed = int(summary.get("failedTests", 0))
    skipped = int(summary.get("skippedTests", 0))
except (OSError, ValueError, TypeError) as error:
    print(f"{label}: invalid result summary: {error}", file=sys.stderr)
    sys.exit(1)
print(f"{label}: {summary.get('result', 'Unknown')} ({passed} passed, {failed} failed, {skipped} skipped)")
if summary.get("result") != "Passed" or passed == 0 or failed != 0:
    sys.exit(1)
PY
}

# Inspect only the chosen device; never pick a different simulator implicitly.
if ! xcrun simctl list devices available --json >"$run_directory/devices.json" 2>"$run_directory/devices.log"; then
    printf 'Could not list simulators; see %s/devices.log.\n' "$run_directory" >&2
    exit 1
fi
device_state=$(python3 - "$destination_id" "$run_directory/devices.json" <<'PY'
import json
import sys

identifier, path = sys.argv[1:]
with open(path, encoding="utf-8") as source:
    devices = json.load(source)["devices"]
for runtime, entries in devices.items():
    for device in entries:
        if device.get("udid", "").upper() != identifier.upper():
            continue
        device_type = device.get("deviceTypeIdentifier", "")
        is_ipad = "iPad" in device_type if device_type else device.get("name", "").startswith("iPad")
        version = runtime.rsplit(".iOS-", 1)
        if not is_ipad or len(version) != 2 or int(version[1].split("-")[0]) < 26:
            sys.exit("Choose an iPad simulator running iPadOS 26 or later.")
        if not device.get("isAvailable", True):
            sys.exit("The selected simulator is unavailable.")
        state = device.get("state")
        if state not in ("Booted", "Shutdown"):
            sys.exit(f"The selected simulator is {state}; wait for it to finish transitioning.")
        print(state)
        sys.exit(0)
sys.exit("The selected simulator was not found among available devices.")
PY
)

if [[ "$device_state" == Shutdown ]]; then
    run_logged boot "$repository_root" xcrun simctl boot "$destination_id"
    started_simulator=1
fi
run_logged boot-status "$repository_root" xcrun simctl bootstatus "$destination_id" -b

run_unit_tests() {
    local status=0
    run_logged unit "$package_directory" xcodebuild test -scheme Cascade \
        -destination "platform=iOS Simulator,id=$destination_id" \
        -derivedDataPath "$package_data" \
        -resultBundlePath "$run_directory/unit.xcresult" \
        -enableCodeCoverage YES -parallel-testing-enabled NO -quiet \
        CODE_SIGNING_ALLOWED=NO || status=$?
    summarize_tests unit || { if [[ "$status" -eq 0 ]]; then status=1; fi; }
    return "$status"
}

run_ui_tests() {
    local status=0
    local app="$package_data/Build/Products/Debug-iphonesimulator/Cascade.app"
    run_logged app-build "$package_directory" xcodebuild build -scheme Cascade \
        -configuration Debug -destination "platform=iOS Simulator,id=$destination_id" \
        -derivedDataPath "$package_data" -quiet CODE_SIGNING_ALLOWED=NO || return $?
    if [[ ! -d "$app" ]]; then
        printf 'The app build did not produce %s.\n' "$app" >&2
        return 1
    fi
    run_logged app-install "$repository_root" xcrun simctl install "$destination_id" "$app" || return $?
    installed_app=1
    started_ui_tests=1
    run_logged ui "$repository_root" xcodebuild test \
        -project "$repository_root/Tests/CascadeUITests.xcodeproj" -scheme CascadeUITests \
        -destination "platform=iOS Simulator,id=$destination_id" \
        -derivedDataPath "$run_directory/ui-derived" \
        -resultBundlePath "$run_directory/ui.xcresult" \
        -test-timeouts-enabled YES -default-test-execution-time-allowance 180 \
        -maximum-test-execution-time-allowance 240 \
        -parallel-testing-enabled NO -collect-test-diagnostics never \
        -quiet CODE_SIGNING_ALLOWED=NO || status=$?
    summarize_tests ui || { if [[ "$status" -eq 0 ]]; then status=1; fi; }
    return "$status"
}

overall_status=0
if [[ "$mode" == unit || "$mode" == all ]]; then
    run_unit_tests || overall_status=$?
fi
if [[ "$mode" == ui || "$mode" == all ]]; then
    run_ui_tests || overall_status=$?
fi
exit "$overall_status"

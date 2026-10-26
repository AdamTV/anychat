#!/usr/bin/env bash
# Times a CI step and records the result for build-performance tracking.
#
# Usage: time_step.sh <label> <command> [args...]
#
# Runs the command, then appends one Markdown table row to
# $GITHUB_STEP_SUMMARY and one JSON line to build-metrics/timings.jsonl.
# The command's exit code is preserved so failing steps still fail the job.
set -uo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: time_step.sh <label> <command> [args...]" >&2
  exit 2
fi

label="$1"
shift

start=$(date +%s)
"$@"
status=$?
seconds=$(( $(date +%s) - start ))

repo_root=$(git rev-parse --show-toplevel)
mkdir -p "$repo_root/build-metrics"
printf '{"step":"%s","seconds":%s,"status":%s,"commit":"%s","run":"%s"}\n' \
  "$label" "$seconds" "$status" "${GITHUB_SHA:-local}" "${GITHUB_RUN_ID:-local}" \
  >> "$repo_root/build-metrics/timings.jsonl"

if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  if ! grep -q '^| Step |' "$GITHUB_STEP_SUMMARY" 2>/dev/null; then
    printf '### Build performance\n\n| Step | Duration | Status |\n| --- | --- | --- |\n' \
      >> "$GITHUB_STEP_SUMMARY"
  fi
  if [ "$status" -eq 0 ]; then
    result="pass"
  else
    result="FAIL"
  fi
  printf '| %s | %ss | %s |\n' "$label" "$seconds" "$result" \
    >> "$GITHUB_STEP_SUMMARY"
fi

exit "$status"

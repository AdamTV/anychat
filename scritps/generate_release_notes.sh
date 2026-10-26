#!/usr/bin/env bash
# Generates Keep a Changelog-style release notes for a git ref range.
#
# Usage: generate_release_notes.sh <from_ref> <to_ref> [output_file]
#
# Commits are grouped by conventional-commit type (feat, fix, docs, chore,
# build, ci, refactor, test, perf). With no output file, notes go to stdout.
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "usage: generate_release_notes.sh <from_ref> <to_ref> [output_file]" >&2
  exit 2
fi

from="$1"
to="$2"
out="${3:-/dev/stdout}"
range="${from}..${to}"

remote=$(git remote get-url origin 2>/dev/null || true)
slug=$(printf '%s' "$remote" | sed -nE 's#.*github\.com[:/]([^/]+/[^/]+?)(\.git)?$#\1#p')
slug="${slug%.git}"
compare_url=""
if [ -n "$slug" ]; then
  compare_url="https://github.com/${slug}/compare/${from}...${to}"
fi

release_date=$(git log -1 --format=%cd --date=short "$to")

emit_section() {
  local title="$1"
  local pattern="$2"
  local entries
  entries=$(git log --format='- %s (%h)' "$range" | grep -iE "$pattern" || true)
  if [ -n "$entries" ]; then
    printf '\n### %s\n\n%s\n' "$title" "$entries"
  fi
}

{
  printf '# Release %s (%s)\n' "$to" "$release_date"
  emit_section 'Features' '^feat(\(.+\))?!?:'
  emit_section 'Bug fixes' '^fix(\(.+\))?!?:'
  emit_section 'Documentation' '^docs(\(.+\))?!?:'
  emit_section 'Chores and maintenance' \
    '^(chore|build|ci|refactor|test|perf)(\(.+\))?!?:'
  other=$(git log --format='- %s (%h)' "$range" |
    grep -ivE '^(feat|fix|docs|chore|build|ci|refactor|test|perf)(\(.+\))?!?:' ||
    true)
  if [ -n "$other" ]; then
    printf '\n### Other changes\n\n%s\n' "$other"
  fi
  if [ -n "$compare_url" ]; then
    printf '\n**Full changelog**: %s\n' "$compare_url"
  fi
} > "$out"

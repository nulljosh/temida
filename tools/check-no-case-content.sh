#!/usr/bin/env bash
# Fails if any identifying case content appears in source.
#
# The web-only curl acceptance test passed green for a month while native source
# hardcoded party names and litigation strategy. This is the source-side half.
#
# Terms live in .leakterms (gitignored) — committing them would reintroduce the
# exact names we're keeping out of the repo. One term per line, blank/# ignored.
set -uo pipefail
cd "$(dirname "$0")/.."

if [[ ! -f .leakterms ]]; then
  cat >&2 <<'MSG'
error: .leakterms not found.

Create it (gitignored) with one identifying term per line — party surnames,
defendant names, place names tied to a case, counsel emails. Example:

  echo 'Surname1' >> .leakterms
  echo 'Surname2' >> .leakterms

Pull the current set from the brief_data table, key='fragments', if unsure.
MSG
  exit 2
fi

PATTERN=$(grep -vE '^\s*(#|$)' .leakterms | paste -sd'|' -)
[[ -z "$PATTERN" ]] && { echo "error: .leakterms has no usable terms" >&2; exit 2; }

scan() {
  grep -rniE "$PATTERN" "$@" \
        --binary-files=without-match \
        --exclude-dir=.build --exclude-dir=DerivedData --exclude-dir=.asc \
        --exclude-dir=*.xcodeproj --exclude-dir=node_modules \
        --exclude='*.png' --exclude='*.jpg' 2>/dev/null \
        | grep -viE 'MIT [0-9]{4}|Copyright|^\S+:[0-9]+:.*Joshua Trommel$' || true
}

# Fatal: the four shipping surfaces. These reach users — prose here is a leak.
# Excludes build output (.asc archives, DerivedData, kmp/*/build, kmp/*/.gradle):
# compiled artifacts, gitignored. Excludes the owner's own name on MIT/copyright
# lines — authorship, not case content.
HITS=$(scan ios/ macos/ web/ kmp/ --exclude-dir=build --exclude-dir=.gradle)

# Advisory: project notes and tooling. CLAUDE.md/roadmap.md legitimately discuss the
# cases (file numbers, incident dates) and always matched, which kept the gate red and
# made a real regression indistinguishable from the usual noise. Still reported, so
# drift stays visible — just not fatal. The repo is private; these files never ship.
NOTES=$(scan tools/ ./*.md)

if [[ -n "$HITS" ]]; then
  echo "FAIL — identifying case content found in shipping source (ios/ macos/ web/ kmp/):" >&2
  echo "$HITS" | sed 's/^/  /' >&2
  echo "" >&2
  echo "Move it to the brief_data table (key='fragments') and read it at runtime." >&2
  exit 1
fi

if [[ -n "$NOTES" ]]; then
  echo "note: case references in project notes (not fatal, these never ship):"
  echo "$NOTES" | sed 's/^/  /' | cut -c1-120
  echo ""
fi

echo "OK — no identifying case content in shipping source."

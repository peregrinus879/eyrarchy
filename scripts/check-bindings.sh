#!/bin/bash
# Assert the personal Hyprland bindings against the Omarchy defaults they load
# after: every hl.unbind target is a chord the defaults still bind (a retired
# default leaves a dead unbind behind), and every personal o.bind chord is
# either free in the defaults or unbound above its bind in the same file (a
# collision would shadow a default, or be shadowed by it, on reload). Chords
# compare with whitespace removed and case folded; commented-out lines count
# for nothing. Reads only o.bind and o.bind_toggle chords from the defaults,
# the registrations Omarchy makes at the top level.
# Usage: check-bindings.sh <bindings.lua> <omarchy-default-hypr-dir>
set -euo pipefail

personal=${1:?usage: check-bindings.sh <bindings.lua> <omarchy-default-hypr-dir>}
defaults_dir=${2:?usage: check-bindings.sh <bindings.lua> <omarchy-default-hypr-dir>}
[[ -f $personal ]] || { printf 'FAIL: personal bindings file is missing: %s\n' "$personal" >&2; exit 1; }
[[ -d $defaults_dir ]] || { printf 'FAIL: Omarchy default hypr directory is missing: %s\n' "$defaults_dir" >&2; exit 1; }

normalize() {
  local chord=${1//[[:space:]]/}
  printf '%s\n' "${chord^^}"
}

# grep -o keeps the match up to the closing quote of the chord, so a "--" later
# on the line (inside an exec string, say) never reaches the extraction.
chord_of() { sed -E 's/^[^"]*"//; s/"$//' <<<"$1"; }

declare -A default_chords=()
while IFS= read -r match; do
  default_chords[$(normalize "$(chord_of "$match")")]=1
done < <(grep -rhoE '^[^-]*\bo\.bind(_toggle)?\(\s*"[^"]+"' "$defaults_dir" || true)
((${#default_chords[@]})) || { printf 'FAIL: no default chords found under %s\n' "$defaults_dir" >&2; exit 1; }

fail=0
declare -A unbound_line=()
while IFS=: read -r line match; do
  chord=$(chord_of "$match")
  key=$(normalize "$chord")
  unbound_line[$key]=$line
  if [[ -n ${default_chords[$key]:-} ]]; then
    printf 'ok:   unbind target is a default chord: %s\n' "$chord"
  else
    printf 'FAIL: unbind target is not a default chord (line %s): %s\n' "$line" "$chord"
    fail=1
  fi
done < <(grep -noE '^\s*hl\.unbind\(\s*"[^"]+"' "$personal" || true)

while IFS=: read -r line match; do
  chord=$(chord_of "$match")
  key=$(normalize "$chord")
  if [[ -z ${default_chords[$key]:-} ]]; then
    printf 'ok:   personal chord is free in the defaults: %s\n' "$chord"
  elif [[ -n ${unbound_line[$key]:-} && ${unbound_line[$key]} -lt $line ]]; then
    printf 'ok:   personal chord replaces a default unbound above it: %s\n' "$chord"
  else
    printf 'FAIL: personal chord collides with a default that is not unbound above it (line %s): %s\n' "$line" "$chord"
    fail=1
  fi
done < <(grep -noE '^\s*o\.bind(_toggle)?\(\s*"[^"]+"' "$personal" || true)

exit "$fail"

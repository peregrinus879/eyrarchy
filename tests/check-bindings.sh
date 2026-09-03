#!/bin/bash
# Fixtures for scripts/check-bindings.sh against a fake Omarchy defaults tree:
# unbind targets must be default chords, personal chords must be free or
# unbound above their bind, spacing and case differences do not matter, and
# commented-out lines count for nothing.
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

check() { bash "$ROOT/scripts/check-bindings.sh" "$1" "$TMP/defaults"; }

expect_failure() {
  local label=$1
  shift
  if "$@" >/dev/null 2>&1; then fail "$label did not fail closed"; fi
}

mkdir -p "$TMP/defaults/bindings"
cat >"$TMP/defaults/bindings/applications.lua" <<'LUA'
if omarchy_preinstalled_bindings then
  o.bind("SUPER + SHIFT + A", "ChatGPT", { webapp = "https://chatgpt.com" })
  o.bind( "SUPER + SHIFT + CTRL + G", "Google Messages", { webapp = "https://messages.google.com/", focus = true })
end
-- o.bind("SUPER + SHIFT + Z", "Commented out", "true")
LUA
cat >"$TMP/defaults/bindings/utilities.lua" <<'LUA'
o.bind_toggle("SUPER + CTRL + N", "Toggle nightlight", "nightlight")
o.bind("SUPER + ALT + G", "Move window out of group", hl.dsp.moveoutofgroup)
LUA

cat >"$TMP/good.lua" <<'LUA'
hl.unbind("SUPER + SHIFT + A")        -- ChatGPT
hl.unbind("super+shift+ctrl+g")       -- spacing and case differ from the default
hl.unbind("SUPER + ALT + G")
o.bind("SUPER + SHIFT + A", "AppImages", "uwsm-app -- it.mijorus.gearlever")
o.bind("SUPER + ALT + G", "Gmail", { webapp = "https://mail.google.com" })
o.bind("SUPER + ALT + H", "GitHub", { webapp = "https://github.com/" })
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + CTRL + N", "commented out", "true")
LUA
check "$TMP/good.lua" >/dev/null || fail "valid personal bindings were rejected"

printf 'hl.unbind("SUPER + SHIFT + Q")\n' >"$TMP/bad-unbind.lua"
expect_failure "unbind of a chord the defaults do not bind" check "$TMP/bad-unbind.lua"

printf 'o.bind("SUPER + CTRL + N", "Nightlight", "true")\n' >"$TMP/bad-collision.lua"
expect_failure "collision with a default toggle chord" check "$TMP/bad-collision.lua"

printf 'o.bind("SUPER + SHIFT + Z", "Commented default", "true")\n' >"$TMP/free-commented.lua"
check "$TMP/free-commented.lua" >/dev/null || fail "a chord bound only in a commented-out default was treated as taken"

printf 'o.bind("SUPER + SHIFT + A", "AppImages", "true")\nhl.unbind("SUPER + SHIFT + A")\n' >"$TMP/bad-order.lua"
expect_failure "unbind placed after the personal bind" check "$TMP/bad-order.lua"

expect_failure "missing personal file" check "$TMP/absent.lua"
expect_failure "missing defaults directory" bash "$ROOT/scripts/check-bindings.sh" "$TMP/good.lua" "$TMP/no-defaults"
mkdir -p "$TMP/empty-defaults"
expect_failure "defaults without chords" bash "$ROOT/scripts/check-bindings.sh" "$TMP/good.lua" "$TMP/empty-defaults"

printf 'ok:   check-bindings asserts unbind targets and personal chords against the defaults\n'

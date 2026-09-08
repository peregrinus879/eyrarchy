#!/bin/bash
# The personal layer must preserve stock launch aliases without running tools.
set -euo pipefail
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
umask 077
TMP=$(mktemp -d "${TMPDIR:-/tmp}/eyr-bashrc.XXXXXXXXXX")
trap 'rm -rf -- "$TMP"' EXIT
mkdir -p "$TMP/omarchy/default/bash" "$TMP/.config/bash/functions"
cat >"$TMP/omarchy/default/bash/rc" <<'SH'
alias c='opencode --auto'
alias cx='claude --permission-mode auto'
alias cy='codex --approve-for-me'
alias ic='tdl c'
alias ix='tdl cx'
alias icx='tdl c cx'
SH
ln -s "$ROOT/bash/.config/bash/functions/hdw" "$TMP/.config/bash/functions/hdw"
# shellcheck disable=SC2016 # Variables expand in the isolated child shell.
env -i PATH="$PATH" HOME="$TMP" HISTFILE=/dev/null ROOT="$ROOT" OMARCHY_PATH="$TMP/omarchy" \
  bash --noprofile --norc -ic '
    set -euo pipefail
    # Do not import the installed bootstrap, host init or user configuration.
    source() {
      [[ $1 != /usr/share/omarchy/default/bash/env-bootstrap ]] || return 0
      builtin source "$@"
    }
    herdr() { return 99; }
    builtin source "$OMARCHY_PATH/default/bash/rc"
    expected=$(alias c cx cy ic ix icx)
    builtin source "$ROOT/bash/.bashrc"
    [[ $(alias c cx cy ic ix icx) == "$expected" ]]
    declare -F hdw >/dev/null
    declare -F y >/dev/null
    if declare -F tdw >/dev/null; then exit 1; fi
    for shortcut in cc oc; do
      if alias "$shortcut" >/dev/null 2>&1; then exit 1; fi
    done
    [[ $OPENCODE_DISABLE_CLAUDE_CODE_SKILLS == 1 && $OPENCODE_ENABLE_EXA == 1 ]]
  ' >"$TMP/result" 2>&1 || { cat "$TMP/result" >&2; exit 1; }
printf 'ok:   Bash preserves stock AI shortcuts, adds hdw without selector aliases, and retains personal exports/Yazi\n'

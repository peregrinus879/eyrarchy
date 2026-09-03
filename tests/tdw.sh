#!/bin/bash
# Fixtures for the tdw workspace launcher on an isolated tmux server: one
# window named after the project with the editor top-left, the agent top-right
# at half the width, a shell across the bottom 15%, and focus on the agent; the
# three agents and their continue forms; re-attach; the root-collision guard;
# and the usage and missing-agent refusals. Stub agents record their arguments;
# attaching is recorded instead of performed, since the fixture has no terminal.
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
SOCKET="tdw-test-$$"
trap 'command tmux -L "$SOCKET" kill-server >/dev/null 2>&1 || true; rm -rf -- "$TMP"' EXIT
unset TMUX

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

# Panes run bash without profiles so the stub PATH is what they see.
printf 'set -g default-command "bash --noprofile --norc"\nset -g default-size 120x40\n' >"$TMP/tmux.conf"
tmux() {
  case ${1:-} in
    attach-session | switch-client)
      printf '%s\n' "$*" >>"$TMP/attach.log"
      return 0
      ;;
  esac
  command tmux -L "$SOCKET" -f "$TMP/tmux.conf" "$@"
}

mkdir -p "$TMP/bin" "$TMP/bin-min"
for stub in claude codex opencode; do
  cat >"$TMP/bin/$stub" <<STUB
#!/bin/bash
printf '%s\\n' "\$(basename "\$0")\${*:+ \$*}" >>'$TMP/calls.log'
sleep 60
STUB
  chmod +x "$TMP/bin/$stub"
done
for tool in git tmux basename tr; do ln -s "$(command -v "$tool")" "$TMP/bin-min/$tool"; done
export PATH="$TMP/bin:$PATH" EDITOR=true
# shellcheck source=/dev/null
source "$ROOT/bash/.config/bash/functions/tdw"

project() {
  mkdir -p "$1"
  git -C "$1" init -q
}

wait_for_call() {
  local i
  for ((i = 0; i < 40; i++)); do
    [[ -f $TMP/calls.log ]] && grep -qxF "$1" "$TMP/calls.log" && return 0
    sleep 0.25
  done
  return 1
}

case_layout() {
  local dir="$TMP/proj/alpha.one" session="alpha-one" line
  local -a editor=() agent=() shell=() fields=()
  project "$dir"
  (cd "$dir" && tdw cc) || fail "tdw cc failed"
  [[ $(tmux list-windows -t "=$session" -F '#{window_name}:#{window_panes}') == "alpha.one:3" ]] ||
    fail "expected one window named after the project with three panes"
  # active left top width height window_width window_height
  while IFS= read -r line; do
    read -r -a fields <<<"$line"
    if ((fields[2] > 0)); then shell=("${fields[@]}"); elif ((fields[1] == 0)); then editor=("${fields[@]}"); else agent=("${fields[@]}"); fi
  done < <(tmux list-panes -t "=$session" -F '#{pane_active} #{pane_left} #{pane_top} #{pane_width} #{pane_height} #{window_width} #{window_height}')
  ((${#editor[@]} && ${#agent[@]} && ${#shell[@]})) || fail "could not classify the three panes"
  ((agent[0] == 1)) || fail "focus did not land on the agent pane"
  ((agent[1] == editor[3] + 1)) || fail "agent pane does not sit right of the editor"
  (( editor[3] - agent[3] <= 1 && agent[3] - editor[3] <= 1 )) || fail "editor and agent are not split 50/50 (${editor[3]} vs ${agent[3]})"
  ((shell[3] == shell[5])) || fail "shell does not span the window width"
  ((shell[4] * 100 <= 15 * shell[6] + 100 && shell[4] * 100 >= 15 * shell[6] - 100)) || fail "shell height is not 15% (${shell[4]} of ${shell[6]})"
  ((editor[4] + shell[4] + 1 == shell[6])) || fail "editor row and shell do not fill the window height"
  wait_for_call "claude" || fail "claude did not start in the agent pane"
  grep -qF -- "attach-session -t =$session" "$TMP/attach.log" || fail "creation did not attach"
  [[ $(tmux show-option -t "$session" -qv @dw_root) == "$dir" ]] || fail "session root was not recorded"
}

case_continue_forms() {
  project "$TMP/proj/beta"
  (cd "$TMP/proj/beta" && tdw cx -c) || fail "tdw cx -c failed"
  wait_for_call "codex resume --last" || fail "codex did not receive resume --last"
  project "$TMP/proj/gamma"
  (cd "$TMP/proj/gamma" && tdw oc -c) || fail "tdw oc -c failed"
  wait_for_call "opencode -c" || fail "opencode did not receive -c"
  project "$TMP/proj/delta"
  (cd "$TMP/proj/delta" && tdw -c cc) || fail "tdw -c cc failed"
  wait_for_call "claude -c" || fail "claude did not receive -c"
}

case_reattach_and_collision() {
  local dir="$TMP/proj/alpha.one" other="$TMP/elsewhere/alpha.one" out
  out=$(cd "$dir" && tdw cc 2>&1) || fail "re-attach with arguments failed"
  [[ $out == *"session exists, arguments ignored"* ]] || fail "re-attach did not report ignored arguments"
  (cd "$dir" && tdw) || fail "bare tdw did not re-attach"
  (($(grep -c -- "attach-session -t =alpha-one" "$TMP/attach.log") == 3)) || fail "expected three attaches to the project session"
  (($(grep -cx "claude" "$TMP/calls.log") == 1)) || fail "re-attach relaunched the agent"
  project "$other"
  if (cd "$other" && tdw cc) >/dev/null 2>&1; then fail "root collision did not refuse"; fi
  [[ $(tmux show-option -t "alpha-one" -qv @dw_root) == "$dir" ]] || fail "collision changed the session root"
}

case_refusals() {
  local dir="$TMP/proj/usage"
  project "$dir"
  if (cd "$dir" && tdw) >/dev/null 2>&1; then fail "bare tdw without a session did not fail"; fi
  if (cd "$dir" && tdw cc oc) >/dev/null 2>&1; then fail "two agents were accepted"; fi
  if (cd "$dir" && tdw foo) >/dev/null 2>&1; then fail "unknown argument was accepted"; fi
  if (cd "$dir" && PATH="$TMP/bin-min" tdw cx) >/dev/null 2>&1; then fail "missing agent was accepted"; fi
  if tmux has-session -t "=usage" 2>/dev/null; then fail "a refusal created a session"; fi
}

case_layout
case_continue_forms
case_reattach_and_collision
case_refusals
printf 'ok:   tdw builds the one-window layout with the agent focused, continues each agent, re-attaches, and refuses bad input\n'

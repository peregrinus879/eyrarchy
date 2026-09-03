# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
source "$OMARCHY_PATH/default/bash/rc"

# Personal overrides

# Keep OpenCode on managed skills and expose its configured web-search tool
export OPENCODE_DISABLE_EXTERNAL_SKILLS=1
export OPENCODE_ENABLE_EXA=1

# Launch Claude Code with maximum effort; interactive aliases (cx, tdl targets) inherit via alias expansion
alias claude='claude --effort max'

# Yazi cd-on-exit (Yazi is not part of Omarchy)
y() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

# Tmux Dev Workspace launcher (twin file with EyrWSL)
[[ -f ~/.config/bash/functions/tdw ]] && source ~/.config/bash/functions/tdw

# Herdr Dev Workspace launcher (twin file with EyrWSL)
if command -v herdr > /dev/null && [[ -f ~/.config/bash/functions/hdw ]]; then
  source ~/.config/bash/functions/hdw
fi

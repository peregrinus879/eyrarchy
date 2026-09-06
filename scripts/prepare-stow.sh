#!/bin/bash
# Guarded stow preparation for EyrArcHy (make clean / make recover).
#
# Stow runs with --no-folding, so live deployments are real parent directories
# holding leaf links that Stow itself manages. This script removes only what
# Stow cannot reconcile. Owned paths are derived from the Git-visible package
# files (tracked plus untracked, minus ignored): each file maps to its stow
# target under $HOME, and every directory between $HOME and that target is a
# managed parent. Every owned path is classified before anything is removed,
# so an unrecognized entry aborts the run untouched:
#   - a managed parent that is a symlink resolving into this repo is removed:
#     a folded directory link left by a folding deployment
#   - a leaf link that resolves into this repo is left alone: Stow owns it
#   - a dangling link, parent or leaf, whose text names a package path this
#     repo has (a moved or deleted clone) is removed
#   - a regular file at an owned path aborts: its pathname does not prove it is
#     a disposable Omarchy clobber artifact; compare and move or merge it first
#   - an entry beneath a folded parent queued for removal is skipped: it is
#     repo working-tree content and disappears with the fold
#   - anything else (a symlink that resolves elsewhere, a directory or special
#     file at a leaf path) aborts the run
# EYRARCHY_PACKAGES carries the package list; the Makefile owns it.
# --require-host and --require-clone are read-only guards used by every
# host-writing Make target. The host fixture override requires both HOME and
# this script's clone below TMPDIR, never the login home.
set -euo pipefail

abort() {
  printf 'prepare-stow: %s\n' "$1" >&2
  exit 1
}

repo=$(realpath -e -- "$(dirname -- "${BASH_SOURCE[0]}")/..") || abort 'cannot resolve the repository root'
[[ -n ${HOME:-} && $HOME != / && -d $HOME ]] || abort 'HOME must name an existing non-root directory'
HOME=$(realpath -e -- "$HOME") || abort 'cannot resolve HOME'
[[ $HOME != / ]] || abort 'HOME must name an existing non-root directory'
[[ $# -le 1 && ( ${1:-} == '' || ${1:-} == --require-host || ${1:-} == --require-clone ) ]] || abort "unsupported arguments: $*"
if [[ ${1:-} != --require-clone ]]; then
  omarchy=/usr/share/omarchy
  if [[ -n ${PREPARE_STOW_OMARCHY_ROOT:-} ]]; then
    login_home=$(getent passwd "$(id -un)" | cut -d: -f6)
    temp_root=$(realpath -e -- "${TMPDIR:-/tmp}")
    [[ ( $temp_root == /tmp || $temp_root == /tmp/* || $temp_root == /var/tmp || $temp_root == /var/tmp/* ) &&
      -n $login_home && $(realpath -m -- "$HOME") != "$(realpath -m -- "$login_home")" &&
      $(realpath -e -- "$HOME") == "$temp_root"/* && $repo == "$temp_root"/* &&
      $(realpath -m -- "$PREPARE_STOW_OMARCHY_ROOT") == "$temp_root"/* ]] ||
      abort 'PREPARE_STOW_OMARCHY_ROOT requires a temporary clone and non-live HOME under TMPDIR'
    omarchy=$PREPARE_STOW_OMARCHY_ROOT
  fi
  [[ -d $omarchy ]] || abort 'the Omarchy host is required for this target'
fi
[[ ${1:-} != --require-host ]] || exit 0
[[ -n ${EYRARCHY_PACKAGES:-} ]] || abort 'EYRARCHY_PACKAGES is required'
read -r -a packages <<<"$EYRARCHY_PACKAGES"
((${#packages[@]})) || abort 'package list is empty'
command -v git >/dev/null || abort 'git is required'

resolves_into_repo() {
  local resolved
  resolved=$(readlink -f -- "$1") || return 1
  [[ $resolved == "$repo"/* ]]
}

# Link text that names a package entry this repo really has: the package name
# followed by a top-level entry of that package, whatever clone path precedes
# it. Only dangling links are ever judged by their text.
managed_link_text() {
  local text=$1 package tail
  for package in "${packages[@]}"; do
    [[ $text == *"/$package/"* ]] || continue
    tail=${text#*"/$package/"}
    [[ -n $tail && -e "$repo/$package/${tail%%/*}" ]] && return 0
  done
  return 1
}

declare -a remove_folds=() remove_links=()

# A dangling link is judged by its text alone; it aborts unless the text names
# a package path this repo has.
queue_dangling_link() {
  local path=$1 text
  text=$(readlink -- "$path")
  managed_link_text "$text" ||
    abort "$path is a dangling symlink to $text, which names no package path of this repo; refusing to remove it"
  remove_links+=("$path")
}

under_queued_fold() {
  local path=$1 fold
  for fold in "${remove_folds[@]}"; do
    [[ $path == "$fold"/* ]] && return 0
  done
  return 1
}

# Owned leaves and their parents, from the Git-visible package files.
declare -a leaves=() parents=() sources=()
mapfile -d '' -t sources < <(git -C "$repo" ls-files -z --cached --others --exclude-standard -- "${packages[@]}")
scan=$!; wait "$scan" || abort 'cannot enumerate package files'
for source in "${sources[@]}"; do
  rel=${source#*/}
  leaves+=("$HOME/$rel")
  dir=$rel
  while [[ $dir == */* ]]; do
    dir=${dir%/*}
    parents+=("$HOME/$dir")
  done
done
((${#leaves[@]})) || abort 'no Git-visible package files found'
if ((${#parents[@]})); then
  mapfile -d '' -t parents < <(printf '%s\0' "${parents[@]}" | sort -z -u)
fi

# Inspect parents too: a foreign folded directory can hide missing endpoints.
for path in "${parents[@]}" "${leaves[@]}"; do
  [[ -L $path ]] || continue
  resolves_into_repo "$path" && continue
  if [[ ! -e $path ]] && managed_link_text "$(readlink -- "$path")"; then continue; fi
  abort "$path is linked from another clone or an unmanaged location; run from the deployed clone"
done
[[ ${1:-} != --require-clone ]] || exit 0

# Parents shallowest first, so a fold is queued before anything beneath it is
# looked at; entries under a queued fold are repo content and are skipped.
for dir in "${parents[@]}"; do
  under_queued_fold "$dir" && continue
  if [[ -L $dir ]]; then
    if resolves_into_repo "$dir"; then
      remove_folds+=("$dir")
    elif [[ ! -e $dir ]]; then
      queue_dangling_link "$dir"
    else
      abort "$dir is a symlink that does not resolve into this repo; refusing to remove it"
    fi
  elif [[ -e $dir && ! -d $dir ]]; then
    abort "$dir is neither a directory nor a symlink; refusing to continue"
  fi
done

for leaf in "${leaves[@]}"; do
  under_queued_fold "$leaf" && continue
  [[ -e $leaf || -L $leaf ]] || continue
  if [[ -L $leaf ]]; then
    if resolves_into_repo "$leaf"; then
      continue
    elif [[ ! -e $leaf ]]; then
      queue_dangling_link "$leaf"
    else
      abort "$leaf is a symlink that does not resolve into this repo; refusing to remove it"
    fi
  elif [[ -f $leaf ]]; then
    abort "$leaf is a regular file; compare and move or merge it before retrying"
  else
    abort "$leaf is neither a symlink nor a regular file; refusing to remove it"
  fi
done

# Mutation begins only after every owned path is classified.
if ((${#remove_folds[@]} + ${#remove_links[@]} == 0)); then
  printf 'prepare-stow: nothing to remove\n'
  exit 0
fi
for path in "${remove_folds[@]}"; do
  rm -- "$path"
  printf 'removed: %s (folded directory link into this repo)\n' "$path"
done
for path in "${remove_links[@]}"; do
  rm -- "$path"
  printf 'removed: %s (dangling symlink into a former clone)\n' "$path"
done

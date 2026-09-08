#!/bin/bash
# Guarded stow preparation for EyrArcHy (make clean / make recover).
#
# Stow runs with --no-folding, so live deployments are real parent directories
# holding leaf links that Stow itself manages. This script removes only what
# Stow cannot reconcile. Owned paths are derived from the Git-visible package
# files (tracked plus untracked, minus ignored), plus the exact retired mapping
# below, which survives source deletion from Git: each file maps to its stow
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
# Retired endpoints accept only exact links to this clone's former source,
# never the moved-clone text heuristic. Their parents must be safe real
# directories or exact owned folds, which are not traversed. Real directories
# and user state are never removed. --check-retired is read-only and requires
# the retired source and endpoint to be absent, with no folded/unsafe parent.
# EYRARCHY_PACKAGES carries the package list; the Makefile owns it.
# --require-host and --require-clone are read-only guards used by every
# host-writing Make target. The host fixture override requires both HOME and
# this script's clone below TMPDIR, never the login home. Deployment roots
# containing control characters are unsupported and refuse unchanged, both
# before and after canonicalization; path records must never be newline-trimmed.
set -euo pipefail

abort() {
  printf 'prepare-stow: %s\n' "$1" >&2
  exit 1
}

reject_control_paths() {
  local path
  for path; do
    [[ $path != *[[:cntrl:]]* ]] || abort 'deployment roots contain unsupported control characters'
  done
}

reject_control_paths "${BASH_SOURCE[0]}" "${HOME:-}"
IFS= read -r -d '' script_dir < <(dirname -z -- "${BASH_SOURCE[0]}") || abort 'cannot determine the script directory'
IFS= read -r -d '' script_dir < <(realpath -ze -- "$script_dir") || abort 'cannot resolve the script directory'
reject_control_paths "$script_dir"
IFS= read -r -d '' repo < <(realpath -ze -- "$script_dir/..") || abort 'cannot resolve the repository root'
reject_control_paths "$repo"
[[ -n ${HOME:-} && $HOME != / && -d $HOME ]] || abort 'HOME must name an existing non-root directory'
IFS= read -r -d '' HOME < <(realpath -ze -- "$HOME") || abort 'cannot resolve HOME'
reject_control_paths "$HOME"
[[ $HOME != / ]] || abort 'HOME must name an existing non-root directory'
[[ $# -le 1 && ( ${1:-} == '' || ${1:-} == --require-host || ${1:-} == --require-clone || ${1:-} == --check-retired ) ]] || abort "unsupported arguments: $*"
if [[ ${1:-} != --require-clone ]]; then
  omarchy=/usr/share/omarchy
  if [[ -n ${PREPARE_STOW_OMARCHY_ROOT:-} ]]; then
    reject_control_paths "${TMPDIR:-/tmp}" "$PREPARE_STOW_OMARCHY_ROOT"
    mapfile -t login_homes < <(getent passwd "$(id -u)" | cut -d: -f6)
    scan=$!; wait "$scan" || abort 'cannot determine the login home'
    [[ ${#login_homes[@]} == 1 && -n ${login_homes[0]} ]] || abort 'cannot determine one login home'
    reject_control_paths "${login_homes[0]}"
    IFS= read -r -d '' login_home < <(realpath -zm -- "${login_homes[0]}") || abort 'cannot resolve the login home'
    IFS= read -r -d '' temp_root < <(realpath -ze -- "${TMPDIR:-/tmp}") || abort 'cannot resolve TMPDIR'
    IFS= read -r -d '' omarchy < <(realpath -zm -- "$PREPARE_STOW_OMARCHY_ROOT") || abort 'cannot resolve the Omarchy fixture root'
    reject_control_paths "$login_home" "$temp_root" "$omarchy"
    [[ ( $temp_root == /tmp || $temp_root == /tmp/* || $temp_root == /var/tmp || $temp_root == /var/tmp/* ) &&
      $HOME != "$login_home" && $HOME == "$temp_root"/* && $repo == "$temp_root"/* &&
      $omarchy == "$temp_root"/* ]] ||
      abort 'PREPARE_STOW_OMARCHY_ROOT requires a temporary clone and non-live HOME under TMPDIR'
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

declare -a remove_folds=() remove_links=() remove_retired=()

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

# This exact endpoint-to-source inventory is independent of Git and PACKAGES.
declare -A retired_sources=([.config/bash/functions/tdw]=bash/.config/bash/functions/tdw)
declare -a leaves=() parents=() sources=()

# NUL records retain trailing newlines, which are part of the link's identity.
exact_retired_link() {
  local path=$1 expected=$2 text lexical resolved
  IFS= read -r -d '' text < <(readlink -z -- "$path") || return 1
  [[ $text == /* ]] || text="${path%/*}/$text"
  IFS= read -r -d '' lexical < <(realpath -zms -- "$text") || return 1
  [[ $lexical == "$expected" ]] || return 1
  IFS= read -r -d '' resolved < <(realpath -zm -- "$path") || return 1
  [[ $resolved == "$expected" ]]
}

# Preflight shallowest first. An exact old fold is left for normal preparation
# below; never inspect a retired endpoint through that link into source content.
for rel in "${!retired_sources[@]}"; do
  source=${retired_sources[$rel]}
  [[ ! -e $repo/$source && ! -L $repo/$source ]] || abort "retired source still exists: $source"
  [[ -O $HOME && -r $HOME && -w $HOME && -x $HOME && $((8#$(stat -c %a -- "$HOME") & 0022)) == 0 ]] || abort 'HOME must be accessible, owner-controlled and not group/world-writable'
  dir=$HOME
  folded=0
  IFS=/ read -r -a components <<<"${rel%/*}"
  for component in "${components[@]}"; do
    dir+=/$component
    parents+=("$dir")
    ((folded)) && continue
    if [[ -L $dir ]]; then
      exact_retired_link "$dir" "$repo/${source%%/*}/${dir#"$HOME/"}" ||
        abort "$dir is an unsafe retired parent linked from another clone or an unmanaged location"
      [[ ${1:-} != --check-retired ]] || abort "retired parent is folded: $dir; run make clean then make restow"
      folded=1
    elif [[ -e $dir ]]; then
      [[ -d $dir && -O $dir && -r $dir && -w $dir && -x $dir && $((8#$(stat -c %a -- "$dir") & 0022)) == 0 ]] ||
        abort "$dir is an unsafe retired parent; preserve it and resolve ownership/type/permissions before retrying"
    fi
  done
  ((folded)) && continue
  path=$HOME/$rel
  if [[ -L $path ]]; then
    exact_retired_link "$path" "$repo/$source" ||
      abort "$path is a retired endpoint linked from another clone or an unmanaged location; refusing to remove it"
    remove_retired+=("$path")
  elif [[ -e $path ]]; then
    abort "$path is a regular file, directory or special entry at a retired endpoint; refusing to remove it"
  fi
done
if [[ ${1:-} == --check-retired ]]; then
  ((${#remove_retired[@]} == 0)) || abort "retired link remains: ${remove_retired[0]}; run make clean then make restow"
  printf 'ok:   retired endpoints are absent with safe real parents\n'
  exit 0
fi

# Owned live leaves and their parents, from the Git-visible package files.
mapfile -d '' -t sources < <(git -C "$repo" ls-files -z --cached --others --exclude-standard -- "${packages[@]}")
scan=$!; wait "$scan" || abort 'cannot enumerate package files'
for source in "${sources[@]}"; do
  rel=${source#*/}
  [[ ${retired_sources[$rel]:-} == "$source" ]] && continue
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

# Parents shallowest first, so a fold is queued before anything beneath it is
# looked at; the clone guard shares this preflight rather than inspecting
# source content through folds in a separate endpoint scan.
for dir in "${parents[@]}"; do
  under_queued_fold "$dir" && continue
  if [[ -L $dir ]]; then
    if resolves_into_repo "$dir"; then
      remove_folds+=("$dir")
    elif [[ ! -e $dir ]]; then
      queue_dangling_link "$dir"
    else
      abort "$dir is linked from another clone or an unmanaged location; run from the deployed clone"
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
      abort "$leaf is linked from another clone or an unmanaged location; run from the deployed clone"
    fi
  elif [[ -f $leaf ]]; then
    abort "$leaf is a regular file; compare and move or merge it before retrying"
  else
    abort "$leaf is neither a symlink nor a regular file; refusing to remove it"
  fi
done
[[ ${1:-} != --require-clone ]] || exit 0

# Mutation begins only after every owned path is classified.
if ((${#remove_folds[@]} + ${#remove_links[@]} + ${#remove_retired[@]} == 0)); then
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
for path in "${remove_retired[@]}"; do
  rm -- "$path"
  printf 'removed: %s (exact retired link into this clone)\n' "$path"
done

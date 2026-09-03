#!/bin/bash
# Fixtures for scripts/prepare-stow.sh: a fake HOME holding a fake clone with
# this repo's package shape, laid out as Stow links it. Leftover folded links,
# dangling links from a moved clone, and clobber artifacts are removed; live
# leaf links, repo content, and unowned entries are untouched; anything
# unrecognized aborts before any removal; a no-folding deployment keeps every
# managed parent real so host-local files never reach a package source.
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT
PACKAGES='bash hypr nvim yazi'

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

# A clone at $home/Projects/eyrarchy with the package shape that matters, so
# relative link text resolves the way Stow writes it under $HOME.
make_clone() {
  local repo=$1
  mkdir -p "$repo/bash/.config/bash/functions" "$repo/hypr/.config/hypr" \
    "$repo/nvim/.config/nvim/lua/plugins" "$repo/yazi/.config/yazi" "$repo/scripts"
  printf 'bashrc\n' >"$repo/bash/.bashrc"
  printf 'tdw\n' >"$repo/bash/.config/bash/functions/tdw"
  printf 'bindings\n' >"$repo/hypr/.config/hypr/bindings.lua"
  printf 'obsidian\n' >"$repo/nvim/.config/nvim/lua/plugins/obsidian.lua"
  printf 'yazi\n' >"$repo/yazi/.config/yazi/yazi.toml"
  cp -- "$ROOT/scripts/prepare-stow.sh" "$repo/scripts/prepare-stow.sh"
  git -C "$repo" init -q
  git -C "$repo" add -A
}

prepare() { HOME=$1 EYRARCHY_PACKAGES=$PACKAGES bash "$2/scripts/prepare-stow.sh"; }
# shellcheck disable=SC2086
deploy() { stow --no-folding -R -d "$2" -t "$1" $PACKAGES; }

snapshot() {
  (cd -- "$1" && find . -path ./.git -prune -o -type f -print0 | sort -z | xargs -0 sha256sum)
}

case_fresh_home() {
  local home="$TMP/fresh/home" repo="$TMP/fresh/home/Projects/eyrarchy"
  mkdir -p "$home"
  make_clone "$repo"
  prepare "$home" "$repo" >/dev/null || fail "fresh home did not succeed"
  [[ $(ls -A "$home") == Projects ]] || fail "fresh home was changed"
}

case_owned_entries() {
  local home="$TMP/owned/home" repo="$TMP/owned/home/Projects/eyrarchy" before after path
  mkdir -p "$home/.config/hypr" "$home/.config/nvim/lua/plugins"
  make_clone "$repo"
  printf 'monitors\n' >"$repo/hypr/.config/hypr/monitors.lua" # untracked package file
  ln -s Projects/eyrarchy/bash/.bashrc "$home/.bashrc"
  ln -s ../Projects/eyrarchy/bash/.config/bash "$home/.config/bash"
  ln -s ../Projects/eyrarchy/yazi/.config/yazi "$home/.config/yazi"
  ln -s ../../Projects/eyrarchy/hypr/.config/hypr/bindings.lua "$home/.config/hypr/bindings.lua"
  ln -s ../../Projects/eyrarchy/hypr/.config/hypr/monitors.lua "$home/.config/hypr/monitors.lua"
  ln -s ../../../../Projects/eyrarchy/nvim/.config/nvim/lua/plugins/obsidian.lua "$home/.config/nvim/lua/plugins/obsidian.lua"
  printf 'omarchy\n' >"$home/.config/hypr/hyprland.lua"
  ln -s /usr/share/nothing/theme.lua "$home/.config/hypr/theme.lua"
  before=$(snapshot "$repo")
  prepare "$home" "$repo" >/dev/null || fail "owned entries did not succeed"
  after=$(snapshot "$repo")
  [[ $before == "$after" ]] || fail "owned-entry cleanup changed repo content"
  for path in .config/bash .config/yazi; do
    [[ ! -e $home/$path && ! -L $home/$path ]] || fail "leftover folded link remains: $path"
  done
  for path in .bashrc .config/hypr/bindings.lua .config/hypr/monitors.lua .config/nvim/lua/plugins/obsidian.lua; do
    [[ -L $home/$path ]] || fail "live leaf link was removed: $path"
  done
  [[ -d $home/.config/hypr && ! -L $home/.config/hypr ]] || fail "Omarchy-owned hypr directory was touched"
  [[ -d $home/.config/nvim/lua/plugins && ! -L $home/.config/nvim/lua/plugins ]] || fail "real nvim parent was touched"
  [[ $(<"$home/.config/hypr/hyprland.lua") == omarchy ]] || fail "unowned regular file was changed"
  [[ -L $home/.config/hypr/theme.lua ]] || fail "unowned link was removed"
  [[ -f $repo/bash/.config/bash/functions/tdw ]] || fail "content under a folded parent was removed from the repo"
}

case_no_folding() {
  local home="$TMP/nofold/home" repo="$TMP/nofold/home/Projects/eyrarchy" path
  mkdir -p "$home/.config/hypr" "$home/.config/nvim/lua/plugins"
  make_clone "$repo"
  # Folded links as a folding deployment created them: relative, so Stow still
  # recognizes them as its own.
  ln -s ../Projects/eyrarchy/bash/.config/bash "$home/.config/bash"
  ln -s ../Projects/eyrarchy/yazi/.config/yazi "$home/.config/yazi"
  prepare "$home" "$repo" >/dev/null || fail "leftover folds did not succeed"
  deploy "$home" "$repo" >/dev/null 2>&1 || fail "no-folding stow failed after cleanup"
  for path in .config/bash .config/bash/functions .config/yazi .config/hypr .config/nvim/lua/plugins; do
    [[ -d $home/$path && ! -L $home/$path ]] || fail "$path is not a real directory after no-folding stow"
  done
  [[ $(readlink -f -- "$home/.config/bash/functions/tdw") == "$repo/bash/.config/bash/functions/tdw" ]] ||
    fail "leaf link does not resolve into the clone"
  printf 'host-local\n' >"$home/.config/yazi/package.toml"
  prepare "$home" "$repo" >/dev/null || fail "cleanup with live links failed"
  [[ -L $home/.bashrc && -L $home/.config/yazi/yazi.toml ]] || fail "cleanup removed a live leaf link"
  deploy "$home" "$repo" >/dev/null 2>&1 || fail "restow failed with host-local state present"
  [[ ! -L $home/.config/yazi/package.toml && $(<"$home/.config/yazi/package.toml") == host-local ]] ||
    fail "restow changed host-local state"
  [[ ! -e $repo/yazi/.config/yazi/package.toml ]] || fail "host-local state reached the package source"
}

case_clobber_artifacts() {
  local home="$TMP/clobber/home" repo="$TMP/clobber/home/Projects/eyrarchy" path
  mkdir -p "$home/.config/hypr" "$home/.config/yazi"
  make_clone "$repo"
  printf 'clobbered\n' >"$home/.bashrc"
  printf 'clobbered\n' >"$home/.config/hypr/bindings.lua"
  printf 'clobbered\n' >"$home/.config/yazi/yazi.toml"
  printf 'omarchy\n' >"$home/.config/hypr/hyprland.lua"
  prepare "$home" "$repo" >/dev/null || fail "clobber artifacts did not succeed"
  for path in .bashrc .config/hypr/bindings.lua .config/yazi/yazi.toml; do
    [[ ! -e $home/$path ]] || fail "clobber artifact remains: $path"
  done
  [[ -d $home/.config/yazi && ! -L $home/.config/yazi ]] || fail "real yazi directory was removed"
  [[ $(<"$home/.config/hypr/hyprland.lua") == omarchy ]] || fail "unowned regular file was changed"
}

case_moved_clone() {
  local home="$TMP/moved/home" repo="$TMP/moved/home/Projects/eyrarchy" path
  mkdir -p "$home/.config/hypr"
  make_clone "$repo"
  ln -s Projects/old/eyrarchy/bash/.bashrc "$home/.bashrc"
  ln -s ../Projects/old/eyrarchy/yazi/.config/yazi "$home/.config/yazi"
  ln -s "$TMP/moved/elsewhere/eyrarchy/hypr/.config/hypr/bindings.lua" "$home/.config/hypr/bindings.lua"
  prepare "$home" "$repo" >/dev/null || fail "moved-clone links did not succeed"
  for path in .bashrc .config/yazi .config/hypr/bindings.lua; do
    [[ ! -L $home/$path ]] || fail "dangling link from a moved clone remains: $path"
  done
}

case_dangling_unrelated() {
  local home="$TMP/dangling/home" repo="$TMP/dangling/home/Projects/eyrarchy"
  mkdir -p "$home/.config/hypr"
  make_clone "$repo"
  ln -s Projects/old/eyrarchy/bash/.bashrc "$home/.bashrc"
  ln -s /usr/share/hypr/bindings.lua "$home/.config/hypr/bindings.lua"
  if prepare "$home" "$repo" >/dev/null 2>&1; then fail "dangling link outside the package layout did not abort"; fi
  [[ -L $home/.config/hypr/bindings.lua ]] || fail "dangling unrelated link was removed"
  [[ -L $home/.bashrc ]] || fail "abort was not atomic: a dangling clone link was removed first"
}

case_foreign_link() {
  local home="$TMP/foreign/home" repo="$TMP/foreign/home/Projects/eyrarchy" foreign="$TMP/foreign/user-bindings.lua"
  mkdir -p "$home/.config/hypr"
  make_clone "$repo"
  printf 'foreign\n' >"$foreign"
  ln -s Projects/old/eyrarchy/bash/.bashrc "$home/.bashrc"
  ln -s "$foreign" "$home/.config/hypr/bindings.lua"
  if prepare "$home" "$repo" >/dev/null 2>&1; then fail "foreign link did not abort"; fi
  [[ -L $home/.config/hypr/bindings.lua && $(<"$foreign") == foreign ]] || fail "foreign link or its target was changed"
  [[ -L $home/.bashrc ]] || fail "abort was not atomic: a dangling clone link was removed first"
}

case_foreign_fold() {
  local home="$TMP/fold/home" repo="$TMP/fold/home/Projects/eyrarchy" other="$TMP/fold/other-yazi"
  mkdir -p "$home/.config" "$other"
  make_clone "$repo"
  printf 'other\n' >"$other/yazi.toml"
  ln -s ../Projects/eyrarchy/bash/.config/bash "$home/.config/bash"
  ln -s "$other" "$home/.config/yazi"
  if prepare "$home" "$repo" >/dev/null 2>&1; then fail "foreign directory link did not abort"; fi
  [[ -L $home/.config/yazi && $(<"$other/yazi.toml") == other ]] || fail "foreign directory link or its content was changed"
  [[ -L $home/.config/bash ]] || fail "abort was not atomic: a folded link was removed first"
}

case_special_file() {
  local home="$TMP/special/home" repo="$TMP/special/home/Projects/eyrarchy"
  mkdir -p "$home"
  make_clone "$repo"
  mkfifo "$home/.bashrc"
  if prepare "$home" "$repo" >/dev/null 2>&1; then fail "special file did not abort"; fi
  [[ -p $home/.bashrc ]] || fail "special file was removed"
}

case_directory_at_leaf() {
  local home="$TMP/dirleaf/home" repo="$TMP/dirleaf/home/Projects/eyrarchy"
  mkdir -p "$home/.bashrc"
  make_clone "$repo"
  if prepare "$home" "$repo" >/dev/null 2>&1; then fail "directory at a leaf path did not abort"; fi
  [[ -d $home/.bashrc ]] || fail "directory at a leaf path was removed"
}

case_missing_packages() {
  local home="$TMP/nopkg/home" repo="$TMP/nopkg/home/Projects/eyrarchy"
  mkdir -p "$home"
  make_clone "$repo"
  if HOME=$home EYRARCHY_PACKAGES='' bash "$repo/scripts/prepare-stow.sh" >/dev/null 2>&1; then
    fail "empty EYRARCHY_PACKAGES did not abort"
  fi
}

case_fresh_home
case_owned_entries
case_no_folding
case_clobber_artifacts
case_moved_clone
case_dangling_unrelated
case_foreign_link
case_foreign_fold
case_special_file
case_directory_at_leaf
case_missing_packages
printf 'ok:   prepare-stow removes leftover folds, dangling clone links, and clobber artifacts, keeps live links, and aborts untouched otherwise\n'

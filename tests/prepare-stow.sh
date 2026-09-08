#!/bin/bash
# Fixtures for scripts/prepare-stow.sh: a fake HOME holding a fake clone with
# this repo's package shape, laid out as Stow links it. Leftover folded links,
# dangling links from a moved clone are removed; regular files, live
# leaf links, repo content, and unowned entries are untouched; anything
# unrecognized aborts before any removal; a no-folding deployment keeps every
# managed parent real so host-local files never reach a package source. Exact
# tdw retirement is checked with both pending and post-pull Git inventories.
set -euo pipefail

IFS= read -r -d '' ROOT < <(dirname -z -- "${BASH_SOURCE[0]}") || exit 1
IFS= read -r -d '' ROOT < <(realpath -ze -- "$ROOT/..") || exit 1
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export HISTFILE=/dev/null HYPRLAND_INSTANCE_SIGNATURE=''
export PREPARE_STOW_OMARCHY_ROOT="$TMP/omarchy"
mkdir -p "$PREPARE_STOW_OMARCHY_ROOT"
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
  printf 'hdw\n' >"$repo/bash/.config/bash/functions/hdw"
  printf 'bindings\n' >"$repo/hypr/.config/hypr/bindings.lua"
  printf 'obsidian\n' >"$repo/nvim/.config/nvim/lua/plugins/obsidian.lua"
  printf 'yazi\n' >"$repo/yazi/.config/yazi/yazi.toml"
  cp -- "$ROOT/scripts/prepare-stow.sh" "$repo/scripts/prepare-stow.sh"
  cp -- "$ROOT/Makefile" "$repo/Makefile"
  git -C "$repo" init -q
  git -C "$repo" add -A
}

prepare() { HOME=$1 EYRARCHY_PACKAGES=$PACKAGES bash "$2/scripts/prepare-stow.sh"; }
check_retired() { HOME=$1 EYRARCHY_PACKAGES=$PACKAGES bash "$2/scripts/prepare-stow.sh" --check-retired; }
require_clone() { HOME=$1 EYRARCHY_PACKAGES=$PACKAGES bash "$2/scripts/prepare-stow.sh" --require-clone; }
# shellcheck disable=SC2086
deploy() { HOME=$1 stow --no-folding -R -d "$2" -t "$1" $PACKAGES; }

# Exercise the real verify recipe, not unrelated repository/runtime gates.
verify() {
  HOME=$1 GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=user.email GIT_CONFIG_VALUE_0=1000+fixture@users.noreply.github.com \
    make --no-print-directory -C "$2" -f Makefile -f "$TMP/verify.mk" verify
}
cat >"$TMP/verify.mk" <<'MAKE'
lint check twins:
	@:
MAKE

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
  [[ -f $repo/bash/.config/bash/functions/hdw ]] || fail "content under a folded parent was removed from the repo"
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
  [[ $(readlink -f -- "$home/.config/bash/functions/hdw") == "$repo/bash/.config/bash/functions/hdw" ]] ||
    fail "leaf link does not resolve into the clone"
  printf 'host-local\n' >"$home/.config/yazi/package.toml"
  prepare "$home" "$repo" >/dev/null || fail "cleanup with live links failed"
  [[ -L $home/.bashrc && -L $home/.config/yazi/yazi.toml ]] || fail "cleanup removed a live leaf link"
  deploy "$home" "$repo" >/dev/null 2>&1 || fail "restow failed with host-local state present"
  [[ ! -L $home/.config/yazi/package.toml && $(<"$home/.config/yazi/package.toml") == host-local ]] ||
    fail "restow changed host-local state"
  [[ ! -e $repo/yazi/.config/yazi/package.toml ]] || fail "host-local state reached the package source"
}

case_regular_files() {
  local home="$TMP/clobber/home" repo="$TMP/clobber/home/Projects/eyrarchy" path
  mkdir -p "$home/.config/hypr" "$home/.config/yazi"
  make_clone "$repo"
  printf 'clobbered\n' >"$home/.bashrc"
  printf 'clobbered\n' >"$home/.config/hypr/bindings.lua"
  printf 'clobbered\n' >"$home/.config/yazi/yazi.toml"
  printf 'omarchy\n' >"$home/.config/hypr/hyprland.lua"
  ln -s ../Projects/eyrarchy/bash/.config/bash "$home/.config/bash"
  if prepare "$home" "$repo" >/dev/null 2>&1; then fail "regular files at owned paths did not abort"; fi
  for path in .bashrc .config/hypr/bindings.lua .config/yazi/yazi.toml; do
    [[ $(<"$home/$path") == clobbered ]] || fail "unfamiliar regular file was changed: $path"
  done
  [[ -L $home/.config/bash ]] || fail "a fold was removed before the regular-file refusal"
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

case_make_guards() {
  local home="$TMP/make/home" repo="$TMP/make/eyrarchy" other="$TMP/make/deployed" bin="$TMP/make/bin" target out
  mkdir -p "$home/.config" "$bin"
  make_clone "$repo"
  make_clone "$other"
  ln -s "$other/bash/.bashrc" "$home/.bashrc"
  ln -s "$TMP/make/old/yazi/.config/yazi" "$home/.config/yazi"
  # Observe the actual Make recipes, delaying the clone guard to expose -j races.
  cat >"$bin/bash" <<'SH'
#!/bin/bash
if [[ ${1:-} == scripts/prepare-stow.sh ]]; then
  case ${2:-} in
    --require-clone) printf 'guard\n' >>"$EYR_TEST_EVENTS"; sleep 0.05 ;;
    --require-host) ;;
    *) printf 'write\n' >>"$EYR_TEST_EVENTS" ;;
  esac
fi
exec /bin/bash "$@"
SH
  chmod +x "$bin/bash"
  for target in stow unstow restow clean recover 'clean restow' 'restow clean'; do
    : >"$TMP/make/events"
    local -a goals=()
    read -r -a goals <<<"$target"
    if out=$(HOME=$home PATH="$bin:$PATH" EYR_TEST_EVENTS="$TMP/make/events" make --no-print-directory -C "$repo" -j8 "${goals[@]}" 2>&1); then
      fail "Make accepted a wrong deployed clone: $target"
    fi
    [[ $out == *'another clone'* ]] || fail "Make failed for the wrong reason ($target): $out"
    [[ $(<"$TMP/make/events") != *write* ]] || fail "cleanup started before the clone guard refused: $target"
    [[ -L $home/.config/yazi && $(readlink -- "$home/.bashrc") == "$other/bash/.bashrc" ]] || fail "Make changed links before refusal: $target"
  done
  rm -- "$home/.bashrc"
  ln -s "$repo/bash/.bashrc" "$home/.bashrc"
  : >"$TMP/make/events"
  HOME=$home PATH="$bin:$PATH" EYR_TEST_EVENTS="$TMP/make/events" make --no-print-directory -C "$repo" -j8 clean >/dev/null || fail "guarded Make clean failed in the deployed fixture"
  [[ $(<"$TMP/make/events") == $'guard\nwrite' && ! -L $home/.config/yazi ]] || fail "guard and cleanup were not ordered"
  # The same real target must also stop on the wrong host before cleanup.
  ln -s "$TMP/make/old/yazi/.config/yazi" "$home/.config/yazi"
  if HOME=$home PREPARE_STOW_OMARCHY_ROOT="$TMP/missing-omarchy" make --no-print-directory -C "$repo" -j8 clean restow >/dev/null 2>&1; then
    fail "Make accepted a non-Omarchy host"
  fi
  [[ -L $home/.config/yazi ]] || fail "host refusal happened after cleanup"
}

case_retired_owned() {
  local inventory=$1 spelling=$2 base="$TMP/retired-$1-$2" home repo endpoint source out path
  home=$base/home; repo=$home/Projects/eyrarchy
  endpoint=$home/.config/bash/functions/tdw; source=bash/.config/bash/functions/tdw
  mkdir -p "$home"
  make_clone "$repo"
  printf 'old tdw\n' >"$repo/$source"
  git -C "$repo" add -- "$source"
  # Start with an actual old Stow deployment, not just a fabricated stale link.
  deploy "$home" "$repo" >/dev/null 2>&1 || fail "old deployment failed: $inventory/$spelling"
  [[ -L $endpoint && $(readlink -f -- "$endpoint") == "$repo/$source" ]] || fail 'old tdw was not deployed'
  if [[ $spelling == absolute ]]; then
    rm -- "$endpoint"
    ln -s "$repo/$source" "$endpoint"
  else
    [[ $(readlink -- "$endpoint") != /* ]] || fail 'Stow did not create a relative old link'
  fi
  if prepare "$home" "$repo" >/dev/null 2>&1; then fail 'retirement accepted a source still present'; fi
  [[ -L $endpoint ]] || fail 'live retired source link was removed'
  if [[ $inventory == post-pull ]]; then
    git -C "$repo" rm -q --cached -- "$source"
  fi
  rm -- "$repo/$source"
  if [[ $inventory == post-pull ]]; then
    [[ -z $(git -C "$repo" ls-files -- "$source") ]] || fail 'post-pull source still appears in Git inventory'
  else
    [[ $(git -C "$repo" ls-files -- "$source") == "$source" ]] || fail 'pending deletion lost its Git inventory entry'
  fi
  printf 'user state\n' >"$home/.config/bash/functions/personal"
  printf '#!/bin/bash\nexit 0\n' >"$repo/scripts/check-bindings.sh"
  if out=$(check_retired "$home" "$repo" 2>&1); then fail 'read-only check accepted a remaining retired link'; fi
  [[ $out == *'retired link remains'* && -L $endpoint ]] || fail "retirement check mutated or failed incorrectly: $out"
  if out=$(verify "$home" "$repo" 2>&1); then fail 'Make verify accepted a remaining retired link'; fi
  [[ $out == *'retired link remains'* && -L $endpoint ]] || fail "Make did not use read-only retirement check: $out"
  # No reload/session access: HYPRLAND_INSTANCE_SIGNATURE is empty in fixtures.
  HOME=$home make --no-print-directory -C "$repo" clean restow >/dev/null 2>&1 || fail 'guarded cleanup/restow failed'
  [[ ! -e $endpoint && ! -L $endpoint ]] || fail 'retired endpoint survived cleanup/restow'
  check_retired "$home" "$repo" >/dev/null || fail 'clean retirement did not verify'
  if ! out=$(verify "$home" "$repo" 2>&1); then fail "Make verify rejected $inventory after retirement: $out"; fi
  prepare "$home" "$repo" >/dev/null || fail 'retirement was not idempotent'
  for path in .config .config/bash .config/bash/functions; do
    [[ -d $home/$path && ! -L $home/$path ]] || fail "retirement removed a real directory: $path"
  done
  [[ $(<"$home/.config/bash/functions/personal") == 'user state' ]] || fail 'retirement changed user state'
  [[ -L $home/.config/bash/functions/hdw ]] || fail 'retirement removed retained hdw'
  # Two matching dangling resolutions must not hide an unrelated source loss.
  rm -- "$repo/bash/.config/bash/functions/hdw"
  if out=$(verify "$home" "$repo" 2>&1); then fail 'Make verify accepted an unrelated missing live source'; fi
  [[ $out == *'FAIL: managed source is missing: bash/.config/bash/functions/hdw'* ]] || fail "wrong missing-source refusal: $out"
}

case_retired_refusal() {
  local kind=$1 base="$TMP/retired-refuse-$1" home repo endpoint target out before after
  home=$base/home; repo=$home/Projects/eyrarchy
  endpoint=$home/.config/bash/functions/tdw
  mkdir -p "$home/.config/bash/functions"
  make_clone "$repo"
  # This independently removable link must survive every refusal below.
  ln -s "$repo/yazi/.config/yazi" "$home/.config/yazi"
  case $kind in
    foreign)
      target=$base/other/bash/.config/bash/functions/tdw
      mkdir -p "${target%/*}"
      printf 'foreign\n' >"$target"
      ln -s "$target" "$endpoint" ;;
    dangling-foreign) ln -s "$base/other/bash/.config/bash/functions/tdw" "$endpoint" ;;
    clone-lookalike) ln -s "$repo-other/bash/.config/bash/functions/tdw" "$endpoint" ;;
    leaf-lookalike) ln -s "$repo/bash/.config/bash/functions/tdw.keep" "$endpoint" ;;
    newline-absolute) ln -s "$repo/bash/.config/bash/functions/tdw"$'\n' "$endpoint" ;;
    newline-relative) ln -s $'../../../Projects/eyrarchy/bash/.config/bash/functions/tdw\n' "$endpoint" ;;
    wrong-source) ln -s "$repo/bash/.config/bash/functions/hdw" "$endpoint" ;;
    regular) printf 'personal\n' >"$endpoint" ;;
    directory) mkdir "$endpoint"; printf 'personal\n' >"$endpoint/state" ;;
    fifo) mkfifo "$endpoint" ;;
  esac
  if [[ -L $endpoint ]]; then
    IFS= read -r -d '' before < <(readlink -z -- "$endpoint") || fail 'cannot snapshot retired link text'
  fi
  if prepare "$home" "$repo" >/dev/null 2>&1; then fail "retirement accepted $kind"; fi
  if check_retired "$home" "$repo" >/dev/null 2>&1; then fail "retirement check accepted $kind"; fi
  if require_clone "$home" "$repo" >/dev/null 2>&1; then fail "clone guard accepted retired $kind"; fi
  if out=$(HOME=$home make --no-print-directory -C "$repo" -j8 clean restow 2>&1); then fail "Make accepted retired $kind"; fi
  [[ $out == *'prepare-stow:'* && -L $home/.config/yazi ]] || fail "retirement $kind refused after mutation: $out"
  case $kind in
    regular) [[ $(<"$endpoint") == personal ]] || fail 'retired regular file changed' ;;
    directory) [[ $(<"$endpoint/state") == personal ]] || fail 'retired directory content changed' ;;
    fifo) [[ -p $endpoint ]] || fail 'retired FIFO changed' ;;
    *)
      IFS= read -r -d '' after < <(readlink -z -- "$endpoint") || fail "retired $kind link was removed"
      [[ $before == "$after" ]] || fail "retired $kind link text changed" ;;
  esac
  [[ $kind != foreign || $(<"$target") == foreign ]] || fail 'foreign retired link target changed'
}

case_retired_parent() {
  local kind=$1 base="$TMP/retired-parent-$1" home repo parent target before after
  home=$base/home; repo=$home/Projects/eyrarchy
  parent=$home/.config/bash/functions
  mkdir -p "${parent%/*}"
  make_clone "$repo"
  ln -s "$repo/yazi/.config/yazi" "$home/.config/yazi"
  case $kind in
    foreign|lookalike)
      target=$base/foreign
      [[ $kind != lookalike ]] || target=$repo/bash/.config/bash/functions-other
      mkdir -p "$target"
      printf 'personal\n' >"$target/state"
      ln -s "$repo/bash/.config/bash/functions/tdw" "$target/tdw"
      ln -s "$target" "$parent" ;;
    newline-absolute|newline-relative|newline-redirect)
      target=$repo/bash/.config/bash/functions$'\n'
      if [[ $kind == newline-redirect ]]; then
        # The lexical target is exact, but its physical target has a newline.
        mv -- "$repo/bash/.config/bash/functions" "$target"
        ln -s "$target" "$repo/bash/.config/bash/functions"
        ln -s "$repo/bash/.config/bash/functions" "$parent"
      else
        mkdir "$target"
        if [[ $kind == newline-relative ]]; then
          ln -s $'../../Projects/eyrarchy/bash/.config/bash/functions\n' "$parent"
        else
          ln -s "$target" "$parent"
        fi
      fi
      printf 'personal\n' >"$target/state" ;;
    regular) printf 'personal\n' >"$parent" ;;
    fifo) mkfifo "$parent" ;;
    writable) mkdir -m 0777 "$parent"; chmod 0777 "$parent" ;;
    inaccessible) mkdir "$parent"; chmod 0600 "$parent" ;;
  esac
  if [[ -L $parent ]]; then
    IFS= read -r -d '' before < <(readlink -z -- "$parent") || fail 'cannot snapshot retired parent link text'
  fi
  if prepare "$home" "$repo" >/dev/null 2>&1; then fail "retirement accepted unsafe $kind parent"; fi
  if check_retired "$home" "$repo" >/dev/null 2>&1; then fail "retirement check accepted unsafe $kind parent"; fi
  if require_clone "$home" "$repo" >/dev/null 2>&1; then fail "clone guard accepted unsafe $kind parent"; fi
  [[ -L $home/.config/yazi ]] || fail 'unsafe parent was detected after unlink'
  if [[ -v before ]]; then
    IFS= read -r -d '' after < <(readlink -z -- "$parent") || fail 'unsafe retired parent link was removed'
    [[ $before == "$after" ]] || fail 'unsafe retired parent link text changed'
  fi
  case $kind in
    foreign|lookalike) [[ -L $parent && -L $target/tdw && $(<"$target/state") == personal ]] || fail 'unsafe parent/contents changed' ;;
    newline-absolute|newline-relative|newline-redirect)
      [[ -d $target && $(<"$target/state") == personal ]] || fail 'newline parent content changed'
      if [[ $kind == newline-redirect ]]; then
        IFS= read -r -d '' after < <(readlink -z -- "$repo/bash/.config/bash/functions") || fail 'redirected source parent was removed'
        [[ $after == "$target" && $(<"$target/hdw") == hdw ]] || fail 'redirected source parent/content changed'
      fi ;;
    regular) [[ $(<"$parent") == personal ]] || fail 'regular parent changed' ;;
    fifo) [[ -p $parent ]] || fail 'FIFO parent changed' ;;
    writable) [[ -d $parent && $(stat -c %a -- "$parent") == 777 ]] || fail 'writable parent changed' ;;
    inaccessible) [[ -d $parent && $(stat -c %a -- "$parent") == 600 ]] || fail 'inaccessible parent changed'; chmod 0700 "$parent" ;;
  esac
}

case_owned_fold_guards() {
  local rel=$1 base="$TMP/fold-guard-${1##*/}" home repo parent source foreign out before after
  home=$base/home; repo=$home/Projects/eyrarchy
  parent=$home/$rel; source=$repo/bash/.config/bash/functions/hdw
  foreign=$base/foreign
  mkdir -p "${parent%/*}"
  make_clone "$repo"
  printf 'personal\n' >"$foreign"
  rm -- "$source"
  ln -s "$foreign" "$source"
  ln -s "$repo/bash/$rel" "$parent"
  before=$(snapshot "$repo")
  # A foreign child in package source is not a deployed endpoint while folded.
  # Neither read-only guard may inspect that child through the HOME fold.
  if ! out=$(require_clone "$home" "$repo" 2>&1); then fail "clone guard traversed an owned fold: $out"; fi
  if out=$(check_retired "$home" "$repo" 2>&1); then fail 'retirement check accepted an owned fold'; fi
  [[ $out == *'retired parent is folded:'* && -L $parent ]] || fail 'retirement check traversed or changed the fold'
  IFS= read -r -d '' after < <(readlink -z -- "$parent") || fail 'guard removed the fold'
  [[ $after == "$repo/bash/$rel" ]] || fail 'guard changed the fold target'
  prepare "$home" "$repo" >/dev/null || fail 'preparation traversed an owned fold'
  [[ ! -e $parent && ! -L $parent ]] || fail 'owned fold was not removed'
  IFS= read -r -d '' after < <(readlink -z -- "$source") || fail 'source child link was removed'
  [[ $after == "$foreign" && $(<"$foreign") == personal && $(snapshot "$repo") == "$before" ]] || fail 'fold handling changed source or foreign state'
}

case_retired_all_preflight() {
  local home="$TMP/retired-preflight/home" repo="$TMP/retired-preflight/home/Projects/eyrarchy" endpoint
  endpoint=$home/.config/bash/functions/tdw
  mkdir -p "${endpoint%/*}"
  make_clone "$repo"
  ln -s "$repo/bash/.config/bash/functions/tdw" "$endpoint"
  printf 'personal\n' >"$home/.bashrc"
  if prepare "$home" "$repo" >/dev/null 2>&1; then fail 'retirement ignored a live-path conflict'; fi
  [[ -L $endpoint && $(<"$home/.bashrc") == personal ]] || fail 'retirement happened before full live preflight'
  rm -- "$home/.bashrc"
  if HOME=$home PREPARE_STOW_OMARCHY_ROOT="$TMP/missing-omarchy" make --no-print-directory -C "$repo" clean restow >/dev/null 2>&1; then
    fail 'retirement accepted a wrong host'
  fi
  if HOME=$home PREPARE_STOW_OMARCHY_ROOT="$TMP/missing-omarchy" EYRARCHY_PACKAGES=$PACKAGES bash "$repo/scripts/prepare-stow.sh" --check-retired >/dev/null 2>&1; then
    fail 'retirement check accepted a wrong host'
  fi
  [[ -L $endpoint ]] || fail 'wrong-host retirement mutated the endpoint'
}

case_control_roots() {
  local kind=$1 base="$TMP/control-root-$1" home repo temp_root omarchy run_dir script mode out status tree text before metadata
  local -a args=()
  home=$base/home; repo=$base/clone
  temp_root=${TMPDIR:-/tmp}; omarchy=$PREPARE_STOW_OMARCHY_ROOT
  run_dir=$repo; script=scripts/prepare-stow.sh
  for tree in "$home" "$home"$'\n'; do
    mkdir -p "$tree/.config/bash/functions"
    printf 'personal\n' >"$tree/state"
  done
  make_clone "$repo"
  make_clone "$repo"$'\n'
  ln -s "$repo/bash/.config/bash/functions/tdw" "$home/.config/bash/functions/tdw"
  ln -s "$repo"$'\n'"/bash/.config/bash/functions/tdw" "$home"$'\n'"/.config/bash/functions/tdw"
  case $kind in
    home) home+=$'\n' ;;
    home-alias) ln -s "$home"$'\n' "$base/home-alias"; home=$base/home-alias ;;
    clone) script=$repo$'\n'/scripts/prepare-stow.sh ;;
    clone-relative) run_dir=$repo$'\n' ;;
    clone-alias) ln -s "$repo"$'\n' "$base/clone-alias"; script=$base/clone-alias/scripts/prepare-stow.sh ;;
    script-directory)
      mkdir "$repo/scripts"$'\n'
      cp -- "$repo/scripts/prepare-stow.sh" "$repo/scripts"$'\n'/prepare-stow.sh
      run_dir=$repo/scripts$'\n'; script=prepare-stow.sh ;;
    temp|temp-alias)
      mkdir "$base/temp" "$base/temp"$'\n'
      temp_root=$base/temp$'\n'
      if [[ $kind == temp-alias ]]; then ln -s "$temp_root" "$base/temp-alias"; temp_root=$base/temp-alias; fi ;;
    omarchy|omarchy-alias)
      mkdir "$base/omarchy" "$base/omarchy"$'\n'
      omarchy=$base/omarchy$'\n'
      if [[ $kind == omarchy-alias ]]; then ln -s "$omarchy" "$base/omarchy-alias"; omarchy=$base/omarchy-alias; fi ;;
  esac
  before=$(snapshot "$base")
  metadata=$(find "$base" -printf '%y %m %p -> %l\0' | sort -z | sha256sum)
  for mode in '' --require-host --require-clone --check-retired; do
    # The clone-only guard does not consume host-fixture paths.
    [[ $mode != --require-clone || ( $kind != temp* && $kind != omarchy* ) ]] || continue
    args=()
    [[ -z $mode ]] || args+=("$mode")
    if out=$(cd -- "$run_dir" && HOME=$home TMPDIR=$temp_root PREPARE_STOW_OMARCHY_ROOT=$omarchy EYRARCHY_PACKAGES=$PACKAGES \
      bash "$script" "${args[@]}" 2>&1); then status=0; else status=$?; fi
    [[ $(snapshot "$base") == "$before" && $(find "$base" -printf '%y %m %p -> %l\0' | sort -z | sha256sum) == "$metadata" ]] ||
      fail "$kind root handling changed paired trees: ${mode:-cleanup}"
    for tree in "$base/home" "$base/home"$'\n'; do
      IFS= read -r -d '' text < <(readlink -z -- "$tree/.config/bash/functions/tdw") || fail 'root refusal removed a paired retired link'
      if [[ $tree == "$base/home" ]]; then
        [[ $text == "$repo/bash/.config/bash/functions/tdw" ]] || fail 'root refusal changed the ordinary HOME link'
      else
        [[ $text == "$repo"$'\n'"/bash/.config/bash/functions/tdw" ]] || fail 'root refusal changed the newline HOME link'
      fi
    done
    [[ $status != 0 && $out == *'unsupported control characters'* ]] || fail "$kind root did not refuse explicitly: ${mode:-cleanup}: $out"
  done
}

case_fresh_home
case_owned_entries
case_no_folding
case_regular_files
case_moved_clone
case_dangling_unrelated
case_foreign_link
case_foreign_fold
case_special_file
case_directory_at_leaf
case_missing_packages
case_make_guards
for inventory in pending post-pull; do
  for spelling in relative absolute; do case_retired_owned "$inventory" "$spelling"; done
done
for kind in foreign dangling-foreign clone-lookalike leaf-lookalike newline-absolute newline-relative wrong-source regular directory fifo; do
  case_retired_refusal "$kind"
done
for kind in foreign lookalike newline-absolute newline-relative newline-redirect regular fifo writable inaccessible; do case_retired_parent "$kind"; done
for rel in .config/bash .config/bash/functions; do case_owned_fold_guards "$rel"; done
case_retired_all_preflight
for kind in home home-alias clone clone-relative clone-alias script-directory temp temp-alias omarchy omarchy-alias; do case_control_roots "$kind"; done
printf 'ok:   prepare-stow preserves regular files and foreign entries; actual Make deployment targets guard before cleanup, including -j\n'
printf 'ok:   tdw retirement handles pending/post-pull inventories, exact relative/absolute links, refusals, safe parents, idempotence and Make verification\n'
printf 'ok:   exact retirement preserves trailing newlines and guards skip owned-fold children without changing source or foreign state\n'
printf 'ok:   control-character HOME, clone, script-directory and fixture roots refuse without changing either lookalike tree\n'

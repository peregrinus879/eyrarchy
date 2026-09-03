#!/bin/bash
# Fixtures for scripts/update-references.sh against local bare upstreams: the
# family union of references.txt files defines the quarry, missing own
# references are cloned, listed clones fast-forward with moved tags, unlisted
# clean clones are removed, dirty or unpushed ones are refused, manifest
# conflicts stop the run before any change, and dry runs change nothing.
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

commit() { # work-dir message
  git -C "$1" -c user.name=fixture -c user.email=fixture@example.invalid commit -q --allow-empty -m "$2"
}

make_upstream() { # name -> bare repo at $TMP/upstream/<name>.git with one commit on main
  local bare="$TMP/upstream/$1.git" work="$TMP/work/$1"
  mkdir -p "$work" "$TMP/upstream"
  git init -q --bare -b main "$bare"
  git init -q -b main "$work"
  printf 'one\n' >"$work/file"
  git -C "$work" add file
  commit "$work" "one"
  git -C "$work" push -q "$bare" main
}

advance_upstream() { # name message [tag]
  local work="$TMP/work/$1"
  printf '%s\n' "$2" >>"$work/file"
  git -C "$work" add file
  commit "$work" "$2"
  git -C "$work" push -q "$TMP/upstream/$1.git" main
  if [[ -n ${3:-} ]]; then
    git -C "$work" tag -f "$3" >/dev/null
    git -C "$work" push -q -f "$TMP/upstream/$1.git" "refs/tags/$3"
  fi
}

upstream_head() { git -C "$TMP/upstream/$1.git" rev-parse main; }

make_family() { # writes $TMP/eyrie/{eyrarchy,eyrwsl} manifests and the script copy
  mkdir -p "$TMP/eyrie/eyrarchy/scripts" "$TMP/eyrie/eyrwsl"
  cp -- "$ROOT/scripts/update-references.sh" "$TMP/eyrie/eyrarchy/scripts/update-references.sh"
  cat >"$TMP/eyrie/eyrarchy/references.txt" <<MANIFEST
# own references
alpha $TMP/upstream/alpha.git
beta  $TMP/upstream/beta.git   # trailing comment
MANIFEST
  cat >"$TMP/eyrie/eyrwsl/references.txt" <<MANIFEST
beta $TMP/upstream/beta.git
gamma $TMP/upstream/gamma.git
MANIFEST
}

run() { QUARRY="$TMP/quarry" bash "$TMP/eyrie/eyrarchy/scripts/update-references.sh" "$@"; }

for name in alpha beta gamma stale unpushed; do make_upstream "$name"; done
make_family
mkdir -p "$TMP/quarry"
git clone -q -- "$TMP/upstream/beta.git" "$TMP/quarry/beta"
git -C "$TMP/work/beta" tag nightly >/dev/null
git -C "$TMP/work/beta" push -q "$TMP/upstream/beta.git" refs/tags/nightly
git -C "$TMP/quarry/beta" fetch -q --tags origin
advance_upstream beta two nightly
git clone -q -- "$TMP/upstream/stale.git" "$TMP/quarry/stale"
git clone -q -- "$TMP/upstream/unpushed.git" "$TMP/quarry/unpushed"
commit "$TMP/quarry/unpushed" "local only"
mkdir -p "$TMP/quarry/plain-dir"

# Dry run: plans everything, changes nothing; it still reports the unpushed
# stale clone, so its exit status is non-zero here.
out=$(run --dry-run 2>&1) && fail "dry run with an unpushed stale clone did not fail closed: $out"
[[ $out == *"plan: alpha: clone"* && $out == *"plan: stale: remove"* && $out == *"note: gamma: listed by eyrwsl only"* ]] ||
  fail "dry run did not plan clone, removal, and sibling note: $out"
[[ ! -e $TMP/quarry/alpha && -d $TMP/quarry/stale ]] || fail "dry run changed the quarry"

# Real run: alpha cloned, beta fast-forwarded with the moved tag, stale removed,
# unpushed refused, plain directory left alone, gamma not cloned; exit non-zero
# for the refusal.
if out=$(run 2>&1); then fail "run with an unpushed stale clone did not fail closed: $out"; fi
[[ -d $TMP/quarry/alpha && $(git -C "$TMP/quarry/alpha" rev-parse HEAD) == $(upstream_head alpha) ]] || fail "own reference was not cloned"
[[ $(git -C "$TMP/quarry/beta" rev-parse HEAD) == $(upstream_head beta) ]] || fail "listed clone did not fast-forward"
[[ $(git -C "$TMP/quarry/beta" rev-parse 'nightly^{commit}') == $(upstream_head beta) ]] || fail "moved rolling tag was not updated"
[[ ! -e $TMP/quarry/stale ]] || fail "clean unlisted clone was not removed"
[[ -d $TMP/quarry/unpushed && -d $TMP/quarry/plain-dir && ! -e $TMP/quarry/gamma ]] || fail "unpushed clone, plain directory, or sibling-only reference was mishandled"
[[ $out == *"unpushed"*"remove by hand"* ]] || fail "unpushed clone was not reported: $out"

# A dirty unlisted clone is refused; a clean one goes on the next run.
git -C "$TMP/quarry/unpushed" reset -q --hard origin/main
printf 'edit\n' >>"$TMP/quarry/unpushed/file"
if run >/dev/null 2>&1; then fail "dirty unlisted clone did not fail closed"; fi
[[ -d $TMP/quarry/unpushed ]] || fail "dirty unlisted clone was removed"
git -C "$TMP/quarry/unpushed" checkout -q -- file
run >/dev/null 2>&1 || fail "settled quarry did not succeed"
[[ ! -e $TMP/quarry/unpushed ]] || fail "clean unlisted clone was not removed on the next run"

# A listed clone with local changes is left alone and fails the run.
printf 'edit\n' >>"$TMP/quarry/beta/file"
if run >/dev/null 2>&1; then fail "dirty listed clone did not fail closed"; fi
[[ $(<"$TMP/quarry/beta/file") == *edit ]] || fail "dirty listed clone was changed"
git -C "$TMP/quarry/beta" checkout -q -- file

# Manifests that disagree stop the run before any change.
advance_upstream alpha three
printf 'alpha %s/upstream/other.git\n' "$TMP" >>"$TMP/eyrie/eyrwsl/references.txt"
if run >/dev/null 2>&1; then fail "conflicting manifests did not fail closed"; fi
[[ $(git -C "$TMP/quarry/alpha" rev-parse HEAD) != $(upstream_head alpha) ]] || fail "conflicting manifests still updated a clone"
sed -i '$d' "$TMP/eyrie/eyrwsl/references.txt"
run >/dev/null 2>&1 || fail "repaired manifests did not succeed"
[[ $(git -C "$TMP/quarry/alpha" rev-parse HEAD) == $(upstream_head alpha) ]] || fail "clone did not fast-forward after the repair"

# A missing quarry is created; a missing manifest and a bad flag fail.
rm -rf -- "$TMP/quarry"
run >/dev/null 2>&1 || fail "missing quarry was not created"
[[ -d $TMP/quarry/alpha && -d $TMP/quarry/beta ]] || fail "own references were not cloned into the new quarry"
if run --bogus >/dev/null 2>&1; then fail "unknown flag was accepted"; fi
mv -- "$TMP/eyrie/eyrarchy/references.txt" "$TMP/eyrie/eyrarchy/references.off"
if run >/dev/null 2>&1; then fail "missing manifest was accepted"; fi

printf 'ok:   update-references clones, fast-forwards, and prunes the quarry from the family manifests\n'

#!/bin/bash
# Fixtures for the DKMS override in system/etc/dkms: a patch that fits exactly
# is applied; a tree that already carries it, a fuzz-only or failed fit, a
# half-patched tree, a missing tree and a missing patch are left unchanged,
# and every one of those exits 0 so DKMS still builds stock. Each outcome
# reaches the journal tag. The override expands to the script with DKMS's
# build directory and kernel, and the tracked patch touches exactly the two
# files the script checks for.
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
SCRIPT=$ROOT/system/etc/dkms/nvidia/nvidia-difr-patch
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT
DIFR=src/nvidia-modeset/src/nvkms-difr.c
PUSH=src/common/unix/nvidia-push/src/nvidia-push.c

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

# The logger stub records each call instead of writing to the journal.
mkdir -p "$TMP/bin"
cat >"$TMP/bin/logger" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >>"$LOGGER_LOG"
SH
chmod +x "$TMP/bin/logger"
export PATH="$TMP/bin:$PATH" LOGGER_LOG="$TMP/journal"

# stock and patched trees, and the -p1 patch between them.
make_tree() {
  mkdir -p "$1/${DIFR%/*}" "$1/${PUSH%/*}"
  printf 'a%s\n' 1 2 3 4 5 6 7 8 9 >"$1/$DIFR"
  printf 'b%s\n' 1 2 3 4 5 6 7 8 9 >"$1/$PUSH"
}
make_tree "$TMP/stock"
make_tree "$TMP/patched"
sed -i 's/^a5$/a5\nadded difr/' "$TMP/patched/$DIFR"
sed -i 's/^b5$/changed push/' "$TMP/patched/$PUSH"
(cd "$TMP" && diff -ru stock patched >fixture.patch) || [[ $? -eq 1 ]] || fail "could not build the fixture patch"
export NVIDIA_DIFR_PATCH=$TMP/fixture.patch

# run <label> <tree> <expected tree> <expected journal message>
run() {
  local label=$1 tree=$2 expected=$3 message=$4
  : >"$LOGGER_LOG"
  bash "$SCRIPT" "$tree" 7.2.5-test >/dev/null 2>&1 || fail "$label exited non-zero"
  if [[ -n $expected ]]; then diff -r "$tree" "$expected" >/dev/null || fail "$label left the wrong tree"; fi
  grep -qF -- "-t nvidia-difr-patch -- $message" "$LOGGER_LOG" || fail "$label did not log: $message"
  [[ -z $(find "$TMP" -name '*.orig' -o -name '*.rej') ]] || fail "$label left patch leftovers"
}

cp -a "$TMP/stock" "$TMP/apply"
run "clean fit" "$TMP/apply" "$TMP/patched" "applied PR #1286 to $TMP/apply (kernel 7.2.5-test)"

cp -a "$TMP/patched" "$TMP/already"
run "already patched" "$TMP/already" "$TMP/patched" "$TMP/already already contains PR #1286"

cp -a "$TMP/stock" "$TMP/fuzz"
sed -i 's/^a3$/a3 edited/' "$TMP/fuzz/$DIFR"
cp -a "$TMP/fuzz" "$TMP/fuzz.before"
patch -p1 --dry-run -s -d "$TMP/fuzz" -i "$NVIDIA_DIFR_PATCH" >/dev/null || fail "fuzz fixture does not fit with default fuzz"
run "fuzz-only fit" "$TMP/fuzz" "$TMP/fuzz.before" "PR #1286 does not apply to $TMP/fuzz"

cp -a "$TMP/stock" "$TMP/moved"
sed -i 's/^a5$/a5 moved/' "$TMP/moved/$DIFR"
cp -a "$TMP/moved" "$TMP/moved.before"
run "failed fit" "$TMP/moved" "$TMP/moved.before" "PR #1286 does not apply to $TMP/moved"

cp -a "$TMP/stock" "$TMP/half"
cp "$TMP/patched/$PUSH" "$TMP/half/$PUSH"
cp -a "$TMP/half" "$TMP/half.before"
run "half-patched tree" "$TMP/half" "$TMP/half.before" "PR #1286 does not apply to $TMP/half"

run "missing tree" "$TMP/none" "" "no NVIDIA open-module source at '$TMP/none'"

cp -a "$TMP/stock" "$TMP/nopatch"
NVIDIA_DIFR_PATCH=$TMP/missing.patch run "missing patch" "$TMP/nopatch" "$TMP/stock" "$TMP/missing.patch or patch(1) is missing"

# The override as DKMS reads it: sourced with DKMS's variables in scope.
pre_build=$(dkms_tree=/var/lib/dkms PACKAGE_NAME=nvidia PACKAGE_VERSION=610.57.04 kernelver=7.2.5-test \
  bash -c 'source "$1" && printf "%s" "$PRE_BUILD"' _ "$ROOT/system/etc/dkms/nvidia.conf")
[[ $pre_build == "nvidia-difr-patch /var/lib/dkms/nvidia/610.57.04/build 7.2.5-test" ]] ||
  fail "override expands to: $pre_build"
[[ -x $ROOT/system/etc/dkms/nvidia/${pre_build%% *} ]] || fail "override names a script that is not executable"

[[ $(grep '^+++ ' "$ROOT/system/etc/dkms/nvidia/pr1286.patch" | cut -d' ' -f2 | sort) == "$(printf 'b/%s\n' "$PUSH" "$DIFR" | sort)" ]] ||
  fail "the tracked patch does not touch exactly the two checked files"

echo "ok:   nvidia-difr-patch fixtures"

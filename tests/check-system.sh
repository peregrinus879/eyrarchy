#!/bin/bash
# Fixtures for scripts/check-system.sh against a fake root holding copies of
# system/: matching owned copies pass; a link, a missing or edited copy, an
# executable bit that differs from the repo, or the wrong owner fails. With
# the DKMS override installed, a module without PR #1286, one whose build ID
# differs from the loaded note, or an unknown compression fails; without it,
# no module is read.
# The directory-owner check needs root to fixture and runs only on the host.
set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf -- "$TMP"' EXIT
cd "$ROOT"
mapfile -t FILES < <(find system -type f | sort)
((${#FILES[@]})) || { printf 'FAIL: no system files found\n' >&2; exit 1; }

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

check() {
  SYSTEM_ROOT=$TMP/root SYSTEM_OWNER=${OWNER:-$(id -un)} NVIDIA_MODESET_MODULE=$TMP/module.ko \
    NVIDIA_MODESET_NOTE=$TMP/note bash scripts/check-system.sh "$@"
}

expect_failure() {
  local label=$1
  shift
  if "$@" >/dev/null 2>&1; then fail "$label did not fail closed"; fi
}

install_root() {
  rm -rf -- "$TMP/root"
  local f
  for f in "${FILES[@]}"; do install -D -m "$(stat -c %a -- "$f")" -- "$f" "$TMP/root/${f#system/}"; done
}

# A 36-byte GNU build-ID note, a patched module that embeds it, and variants.
printf '\x04\x00\x00\x00\x14\x00\x00\x00\x03\x00\x00\x00GNU\x00%s' 'loaded-build-id-0001' >"$TMP/note"
printf '\x04\x00\x00\x00\x14\x00\x00\x00\x03\x00\x00\x00GNU\x00%s' 'other--build-id-0002' >"$TMP/other-note"
module() { { printf 'ELF head'; cat "$1"; printf '%s\0' "${@:2}"; } >"$TMP/module.ko"; }
MARKERS=('Timed out waiting for a free GPFIFO entry' 'Failed to reset the DIFR prefetch channel')

install_root
module "$TMP/note" "${MARKERS[@]}"
check "${FILES[@]}" >/dev/null || fail "matching copies and a patched loaded module were rejected"

module "$TMP/note" "${MARKERS[0]}"
expect_failure "module without PR #1286" check "${FILES[@]}"
module "$TMP/other-note" "${MARKERS[@]}"
expect_failure "installed module differing from the loaded one" check "${FILES[@]}"
module "$TMP/note" "${MARKERS[@]}"

cp "$TMP/module.ko" "$TMP/module.ko.xz"
expect_failure "unknown module compression" env SYSTEM_ROOT="$TMP/root" SYSTEM_OWNER="$(id -un)" \
  NVIDIA_MODESET_MODULE="$TMP/module.ko.xz" NVIDIA_MODESET_NOTE="$TMP/note" bash scripts/check-system.sh "${FILES[@]}"

zstd -q -o "$TMP/module.ko.zst" "$TMP/module.ko"
SYSTEM_ROOT=$TMP/root SYSTEM_OWNER=$(id -un) NVIDIA_MODESET_MODULE=$TMP/module.ko.zst NVIDIA_MODESET_NOTE=$TMP/note \
  bash scripts/check-system.sh "${FILES[@]}" >/dev/null || fail "a zstd-compressed patched module was rejected"

OWNER=nobody-else expect_failure "copies owned by another user" check "${FILES[@]}"

ln -sf "$ROOT/system/etc/sysctl.d/99-sysrq.conf" "$TMP/root/etc/sysctl.d/99-sysrq.conf"
expect_failure "a link into the clone" check "${FILES[@]}"
install_root
printf '# local edit\n' >>"$TMP/root/etc/sysctl.d/99-sysrq.conf"
expect_failure "an edited copy" check "${FILES[@]}"
install_root
chmod -x "$TMP/root/etc/dkms/nvidia/nvidia-difr-patch"
expect_failure "a non-executable script copy" check "${FILES[@]}"
install_root
chmod +x "$TMP/root/etc/dkms/nvidia/pr1286.patch"
expect_failure "an executable copy of a plain file" check "${FILES[@]}"
install_root
rm "$TMP/root/etc/dkms/nvidia/pr1286.patch"
expect_failure "a missing copy" check "${FILES[@]}"

rm -rf -- "$TMP/root"
install -D -m 644 system/etc/sysctl.d/99-sysrq.conf "$TMP/root/etc/sysctl.d/99-sysrq.conf"
rm "$TMP/module.ko" "$TMP/note"
check system/etc/sysctl.d/99-sysrq.conf >/dev/null || fail "module checks ran without the DKMS override"

printf 'ok:   system copies are owned, identical and unlinked, and the loaded nvidia-modeset carries PR #1286\n'

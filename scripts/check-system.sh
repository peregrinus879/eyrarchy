#!/bin/bash
# Host check for the files under system/, run by make verify. Each one must be
# installed at the same path under / as a regular copy owned by root, in a
# root-owned directory, identical to the repo and executable exactly when the
# repo file is: a link into this user-writable clone would let the clone change
# what root runs. While the DKMS override is installed, the running kernel's
# nvidia-modeset module must carry PR #1286 and must be the loaded module
# (the loaded build-ID note appears in the installed file). SYSTEM_ROOT,
# SYSTEM_OWNER, NVIDIA_MODESET_MODULE and NVIDIA_MODESET_NOTE exist for tests.
# Checking the scoped keyboard rule also requires retirement of 99-via.rules.
# Its missing source may remain in Git's index until the rename is staged;
# only that exact pending deletion is skipped when its replacement is checked.
# Usage: check-system.sh <system/...>...
set -euo pipefail

root=${SYSTEM_ROOT:-}
owner=${SYSTEM_OWNER:-root}
(($#)) || { printf 'FAIL: no system files given\n' >&2; exit 1; }

fail=0
keyboard_rule=system/etc/udev/rules.d/72-keyboard-config.rules
retired_rule=system/etc/udev/rules.d/99-via.rules
keyboard_in_scope=0
for src in "$@"; do
  if [[ $src == "$keyboard_rule" ]]; then keyboard_in_scope=1; fi
done
retired_target="$root/${retired_rule#system/}"
if ((keyboard_in_scope)) && [[ -e $retired_target || -L $retired_target ]]; then
  printf 'FAIL: %s is retired; preserve it outside rules.d per docs/setup.md\n' "$retired_target"
  fail=1
fi

for src in "$@"; do
  if ((keyboard_in_scope)) && [[ $src == "$retired_rule" && ! -e $src && ! -L $src ]]; then
    continue
  fi
  target="$root/${src#system/}"
  if [[ -L $target ]]; then
    printf 'FAIL: %s is a link; install a root-owned copy\n' "$target"; fail=1
  elif [[ ! -f $target ]]; then
    printf 'FAIL: %s is not installed\n' "$target"; fail=1
  elif [[ $(stat -c %U -- "$target") != "$owner" || $(stat -c %U -- "${target%/*}") != "$owner" ]]; then
    printf 'FAIL: %s or its directory is not owned by %s\n' "$target" "$owner"; fail=1
  elif ! cmp -s -- "$src" "$target"; then
    printf 'FAIL: %s differs from %s\n' "$target" "$src"; fail=1
  elif [[ -x $src && ! -x $target || ! -x $src && -x $target ]]; then
    printf 'FAIL: %s executable bit differs from %s\n' "$target" "$src"; fail=1
  else
    printf 'ok:   %s matches the repo\n' "$target"
  fi
done

[[ -f $root/etc/dkms/nvidia.conf ]] || exit $fail
module=${NVIDIA_MODESET_MODULE:-$(modinfo -n nvidia_modeset 2>/dev/null || true)}
note=${NVIDIA_MODESET_NOTE:-/sys/module/nvidia_modeset/notes/.note.gnu.build-id}
if [[ ! -f $module ]]; then
  printf 'FAIL: no nvidia_modeset module is installed for the running kernel\n'; exit 1
elif [[ ! -r $note ]]; then
  printf 'FAIL: nvidia_modeset is not loaded\n'; exit 1
fi
case $module in
  *.ko.zst) read_module=(zstdcat -- "$module") ;;
  *.ko) read_module=(cat -- "$module") ;;
  *) printf 'FAIL: unsupported module compression: %s\n' "$module"; exit 1 ;;
esac
if ! read -r state loaded < <("${read_module[@]}" | python3 -c '
import sys
data = sys.stdin.buffer.read()
note = open(sys.argv[1], "rb").read()
markers = (b"Timed out waiting for a free GPFIFO entry", b"Failed to reset the DIFR prefetch channel")
print("patched" if all(m in data for m in markers) else "stock", "loaded" if len(note) >= 20 and note in data else "other")
' "$note"); then
  printf 'FAIL: could not read %s\n' "$module"; exit 1
fi
if [[ $state == patched ]]; then
  printf 'ok:   %s carries PR #1286\n' "$module"
else
  printf 'FAIL: %s lacks PR #1286; see journalctl -t nvidia-difr-patch\n' "$module"; fail=1
fi
if [[ $loaded == loaded ]]; then
  printf 'ok:   the loaded nvidia_modeset is the installed module\n'
else
  printf 'FAIL: the loaded nvidia_modeset is not the installed module; reboot, and if that does not load it, rebuild per docs/setup.md\n'; fail=1
fi
exit $fail

# Maintenance automation for EyrArcHy. Stow, clean, recover, and verify run
# from the repo root on the Omarchy machine; lint, check, twins, and refs run
# anywhere, including CI. The package list here is the single source of truth
# for the stow command sets and for scripts/prepare-stow.sh.
# Stow runs without directory folding so every managed parent under $HOME stays
# a real directory and only leaf files are links.

SHELL := /bin/bash
PACKAGES := bash hypr nvim yazi
STOW := stow --no-folding -t ~

# Twin files are byte-identical with EyrWSL and synced manually. When the
# sibling clone is present, twins fails on drift; otherwise it reports a
# skipped check. Paths are repo-relative and identical in both repos.
ifeq ($(origin SIBLING),undefined)
SIBLING := $(HOME)/Projects/eyrie/eyrwsl
endif
# Freeze caller input without expanding Make functions, then pass it only via
# the environment. Exporting a recursively expanded variable is not sufficient.
override export SIBLING := $(value SIBLING)
override export SELF_COMMIT := $(value SELF_COMMIT)
override export PEER_COMMIT := $(value PEER_COMMIT)
TWIN_SPECS := nvim/.config/nvim/lua/plugins/obsidian.lua \
  nvim/.config/nvim/lua/plugins/render-markdown.lua \
  nvim/.config/nvim/lua/plugins/git-review.lua \
  bash/.config/bash/functions/hdw \
  yazi/.config/yazi/yazi.toml \
  scripts/update-references.sh \
  tests/update-references.sh \
  tests/git-review.sh \
  tests/hdw.sh \
  tests/fixtures/herdr \
  docs/cheatsheet/build.py \
  docs/cheatsheet/reference.json \
  docs/cheatsheet/template.html \
  docs/cheatsheet/README.md

BASH_FILES := bash/.bashrc $(wildcard bash/.config/bash/functions/*)
LUA_FILES := $(wildcard hypr/.config/hypr/*.lua nvim/.config/nvim/lua/plugins/*.lua)
TOML_FILES := yazi/.config/yazi/yazi.toml
OMARCHY_HYPR := /usr/share/omarchy/default/hypr

.PHONY: help require-host require-clone stow unstow dry-run restow lint check test twins twins-pair verify clean recover refs cheatsheet

# Deployment goals and their guards must never race, including `make -j clean restow`.
.NOTPARALLEL:

# Hyprland auto-reloads on config changes and caches an error if a reload
# lands while a sourced file is mid-swap (as during a restow). Force a clean
# reload after any stow operation that ends in a linked state, but only when
# running inside a Hyprland session.
define hypr_reload
@if command -v hyprctl > /dev/null && [[ -n "$${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then \
  hyprctl reload > /dev/null; sleep 1; errs="$$(hyprctl configerrors)"; \
  if [[ -z "$$errs" || "$$errs" == *"no errors"* ]]; then \
    echo "ok:   hyprland reloaded, no config errors"; \
  else \
    echo "$$errs"; exit 1; \
  fi; \
else \
  echo "note: hyprland session not detected, skipped hyprctl reload"; \
fi
endef

help:
	@echo "Targets:"
	@echo "  stow      Stow all packages into ~"
	@echo "  unstow    Remove all package symlinks"
	@echo "  dry-run   Preview stow actions without making changes"
	@echo "  restow    Re-stow after repo content changes (Omarchy host, deployed clone only)"
	@echo "  lint      ShellCheck over the bash package, scripts/, and tests/ (.shellcheckrc holds the disable list)"
	@echo "  check     Repository-only checks: bash, Lua, and TOML syntax, then test (runs in CI)"
	@echo "  test      Run the tests/ fixtures in fake homes"
	@echo "  twins     Twin-file sync against the EyrWSL clone at SIBLING (skipped when absent)"
	@echo "  twins-pair  Read-only committed twin check: full SELF_COMMIT and PEER_COMMIT, with the peer objects at SIBLING"
	@echo "  verify    lint, check, and twins, then host checks: retired absence, sources/links, real parents, Git identity, Hyprland chords/errors"
	@echo "  clean     Guarded stow preparation: owned folds, dangling clone links and exact retired links; regular files are preserved"
	@echo "  recover   Re-apply after omarchy-reinstall-configs (clean + restow)"
	@echo "  refs      Clone and fast-forward listed references to exact upstream parity; report and keep stale clones"
	@echo "  cheatsheet  Rebuild the offline hdw workflow guide in docs/hdw.html"

# Host-bound targets refuse elsewhere, and a managed endpoint that is a link
# must resolve into this clone so a reference clone never redeploys the
# packages from itself.
require-host:
	@bash scripts/prepare-stow.sh --require-host

require-clone: require-host
	@EYRARCHY_PACKAGES='$(PACKAGES)' bash scripts/prepare-stow.sh --require-clone

stow: require-clone
	$(STOW) -v $(PACKAGES)
	$(hypr_reload)

unstow: require-clone
	$(STOW) -D -v $(PACKAGES)

dry-run:
	$(STOW) -n -v $(PACKAGES)

restow: require-clone
	$(STOW) -R -v $(PACKAGES)
	$(hypr_reload)

lint:
	shellcheck -s bash $(BASH_FILES) scripts/*.sh tests/*.sh
	@echo "ok:   shellcheck clean"

# Repository-only checks: syntax and format of every owned file, then the
# fixture suites. Needs no Omarchy host, stowed links, or Hyprland session.
# Fail closed: a missing verifier binary must fail the run, not skip a check.
check:
	python3 docs/cheatsheet/build.py --profile eyrarchy --check
	@for tool in luac python3 git stow; do \
	  command -v "$$tool" > /dev/null || { echo "FAIL: required verifier '$$tool' is missing"; exit 1; }; \
	done
	@fail=0; \
	for f in $(BASH_FILES); do \
	  if bash -n "$$f"; then echo "ok:   bash -n $$f"; else echo "FAIL: bash -n $$f"; fail=1; fi; \
	done; \
	for f in $(LUA_FILES); do \
	  if luac -p "$$f" > /dev/null; then echo "ok:   luac -p $$f"; else echo "FAIL: luac -p $$f"; fail=1; fi; \
	done; \
	for f in $(TOML_FILES); do \
	  if python3 -c 'import tomllib,sys; tomllib.load(open(sys.argv[1],"rb"))' "$$f" 2> /dev/null; then \
	    echo "ok:   $$f parses as TOML"; \
	  else \
	    echo "FAIL: $$f is not valid TOML"; fail=1; \
	  fi; \
	done; \
	exit $$fail
	@$(MAKE) --no-print-directory test
	@echo "ok:   check"

test:
	@set -e; for t in tests/*.sh; do bash "$$t"; done

twins:
	@command -v cmp > /dev/null || { echo "FAIL: required verifier 'cmp' is missing"; exit 1; }
	@if [[ ! -d "$$SIBLING" ]]; then \
	  echo "note: EyrWSL clone not found at $$SIBLING, skipped twin checks"; exit 0; \
	fi; \
	fail=0; \
	for f in $(TWIN_SPECS); do \
	  twin="$$SIBLING/$$f"; \
	  if [[ ! -e "$$twin" ]]; then echo "FAIL: twin missing in EyrWSL: $$f"; fail=1; \
	  elif cmp -s "$$f" "$$twin"; then echo "ok:   $$f matches the EyrWSL twin"; \
	  else echo "FAIL: $$f drifted from the EyrWSL twin"; fail=1; fi; \
	done; \
	exit $$fail

# Exact final-pair validation, with no peer checkout or execution of peer code.
# Unlike twins, a missing peer or revision is a failure, never a skipped check.
twins-pair:
	@set -euo pipefail; \
	export GIT_NO_REPLACE_OBJECTS=1; \
	self="$$SELF_COMMIT"; peer="$$PEER_COMMIT"; \
	[[ $$self =~ ^[0-9a-f]{40}$$ && $$peer =~ ^[0-9a-f]{40}$$ ]] || { echo "FAIL: SELF_COMMIT and PEER_COMMIT must be full 40-character commit IDs"; exit 1; }; \
	[[ $$(git rev-parse --verify "$$self^{commit}") == "$$self" && $$(git -C "$$SIBLING" rev-parse --verify "$$peer^{commit}") == "$$peer" ]] || { echo "FAIL: exact pair commits are unavailable"; exit 1; }; \
	echo "pair: self=$$self peer=$$peer"; \
	fail=0; \
	for f in $(TWIN_SPECS); do \
	  if ! left=$$(git rev-parse --verify "$$self:$$f") || ! right=$$(git -C "$$SIBLING" rev-parse --verify "$$peer:$$f"); then \
	    echo "FAIL: committed twin missing: $$f"; fail=1; \
	  elif [[ $$(git cat-file -t "$$left") != blob || $$(git -C "$$SIBLING" cat-file -t "$$right") != blob ]]; then \
	    echo "FAIL: committed twin is not a file: $$f"; fail=1; \
	  elif [[ $$left == "$$right" ]]; then echo "ok:   $$f matches in the exact commit pair"; \
	  else echo "FAIL: $$f drifted in the exact commit pair"; fail=1; fi; \
	done; \
	exit $$fail

# Host checks after stowing. Symlink pairs are derived from the package files
# git sees (tracked plus untracked): stripping the leading package name maps
# each file to its stow target, so every package file is checked, including
# one being added in the working tree; resolved paths are compared so a link
# to the wrong file fails too. Every managed parent must be a real directory:
# a folded one means a folding deployment that make restow has not replaced.
# The Git identity check prints no value. The unbind chord check reads the
# installed Omarchy defaults, so it fails closed off-host.
# Explicit retired endpoints are checked even after their sources leave Git;
# only those known deletions are excluded from the live inventory below.
verify: require-host lint check twins
	@command -v readlink > /dev/null || { echo "FAIL: required verifier 'readlink' is missing"; exit 1; }
	@EYRARCHY_PACKAGES='$(PACKAGES)' bash scripts/prepare-stow.sh --check-retired
	@fail=0; \
	for src in $$(git ls-files --cached --others --exclude-standard -- $(PACKAGES)); do \
	  [[ $$src == bash/.config/bash/functions/tdw ]] && continue; \
	  target="$$HOME/$${src#*/}"; \
	  if [[ ! -e $$src ]]; then \
	    echo "FAIL: managed source is missing: $$src"; fail=1; \
	  elif [[ "$$(readlink -f "$$target")" == "$$(readlink -f "$$src")" ]]; then \
	    echo "ok:   $$target resolves into the repo"; \
	  else \
	    echo "FAIL: $$target does not resolve into the repo"; fail=1; \
	  fi; \
	done; \
	while IFS= read -r rel; do \
	  target="$$HOME/$$rel"; \
	  if [[ -d $$target && ! -L $$target ]]; then echo "ok:   $$target is a real directory"; \
	  else echo "FAIL: managed directory is folded or missing: $$target"; fail=1; fi; \
	done < <(git ls-files --cached --others --exclude-standard -- $(PACKAGES) | \
	  while IFS= read -r src; do [[ $$src == bash/.config/bash/functions/tdw ]] && continue; rel=$${src#*/}; \
	  while [[ $$rel == */* ]]; do rel=$${rel%/*}; echo "$$rel"; done; done | sort -u); \
	if [[ "$$(git config user.email)" == *@users.noreply.github.com ]]; then \
	  echo "ok:   git identity resolves to a GitHub no-reply address"; \
	else \
	  echo "FAIL: git identity does not resolve to a GitHub no-reply address"; fail=1; \
	fi; \
	bash scripts/check-bindings.sh hypr/.config/hypr/bindings.lua $(OMARCHY_HYPR) || fail=1; \
	if command -v hyprctl > /dev/null && [[ -n "$${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then \
	  errs="$$(hyprctl configerrors)"; \
	  if [[ -z "$$errs" || "$$errs" == *"no errors"* ]]; then echo "ok:   no hyprland config errors"; \
	  else echo "FAIL: $$errs"; fail=1; fi; \
	fi; \
	exit $$fail
	@echo "ok:   verify"

clean: require-clone
	@EYRARCHY_PACKAGES='$(PACKAGES)' bash scripts/prepare-stow.sh

recover: require-clone clean restow

# omasync step 1. Clones what references.txt lists and the quarry lacks,
# repoints moved GitHub remotes, fast-forwards listed clones to exact upstream
# parity, and reports unlisted clones without deleting them.
refs:
	@bash scripts/update-references.sh

cheatsheet:
	python3 docs/cheatsheet/build.py --profile eyrarchy

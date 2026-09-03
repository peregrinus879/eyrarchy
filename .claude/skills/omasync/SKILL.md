---
name: omasync
description: Sync personal Omarchy customizations against upstream references, installed defaults, and official docs.
---

# Omasync

Source configs from the installed Omarchy defaults, the reference repos, and official docs, compare against EyrArcHy, and apply changes only where they belong in the personal customizations.

## Sources

Local reference clones live under `~/Projects/quarry/`; `references.txt` at the repo root names the ones this repo needs, and the family union of every sibling's file defines the quarry (`make refs` clones, updates, and prunes to it):

- `omarchy/` - main repo for bash, tmux, and general Omarchy defaults; `make refs` keeps it on the upstream default branch, which upstream moves between releases, so pin release comparisons to the installed version's tag (`git show <installed-tag>:<path>`)
- `omarchy-pkgs/` - Omarchy's package build recipes, for package version and dependency questions
- `obsidian.nvim/` - obsidian.nvim upstream for the vault plugin spec

The installed defaults the machine actually runs live under `/usr/share/omarchy` (package-backed). The shipped `omarchy` agent skill (auto-discovered via `~/.claude/skills/omarchy`; package copy at `/usr/share/omarchy/default/agents/skills/omarchy`) is upstream-owned, refreshed with Omarchy updates, and authoritative for desktop-config editing; never fork it into this repo. Upstream URLs, official docs, and descriptions live in `DEVIATIONS.md` (Reference Sources). Unresolved decisions, deferred work, and dated evidence live in `docs/maintenance.md`; sibling coordination lives at `~/Projects/eyrie/eyragents/docs/maintenance.md` and `~/Projects/eyrie/eyrwsl/AGENTS.md`.

## When To Use

- Use this skill when Omarchy or a reference repo changed materially, including after an Omarchy update or a config refresh ran.
- Use this skill when personal customization scope or behavior changed materially.
- Use this skill when you suspect undocumented drift between this repo and its references.
- Use this skill before broad sync-oriented doc updates.

## Workflow

1. Run `make refs` first, every time: `scripts/update-references.sh` clones what `references.txt` lists and the quarry lacks, resolves each listed clone to its current GitHub location and repoints a moved remote, checks out the upstream default branch and fast-forwards it, and removes clean clones no family repository lists. Fix anything it reports before comparing, and when it reports a repointed origin, update that URL in `references.txt` and `DEVIATIONS.md` (Reference Sources). When this repo starts or stops using a reference, change `references.txt`; the clones follow. Updating the quarry is this skill's job, never H's preparation.
2. Compare `bash/.bashrc` against the current Omarchy Bash defaults, in the reference clone under `omarchy/default/` and installed under `/usr/share/omarchy/default/`:
   - the upstream preamble (everything above `# Personal overrides`) against `default/bashrc`, the seed Omarchy installs as `/etc/skel/.bashrc`; it is kept verbatim, so adopt upstream changes to it
   - the `unalias` line against `default/bash/aliases`: it must name exactly Omarchy's AI launch aliases (`c`, `cx`, `cy`, `ic`, `ix`, and `icx` today); a new upstream launch alias joins the line and a renamed one leaves it
   - the `OPENCODE_DISABLE_EXTERNAL_SKILLS` and `OPENCODE_ENABLE_EXA` exports stay additive unless Omarchy starts setting `OPENCODE_*` variables
   - `y()` is additive (Yazi is not in Omarchy)
   - the sourced `tdw` and `hdw` twins against `default/bash/fns/tmux` and `default/bash/fns/herdr`: they stay additive alongside `tdl`/`tds` and `hdl`/`hds`, and a change to either lands in EyrWSL in the same session (`make twins`)
3. Compare `hypr/bindings.lua` against the installed defaults at `/usr/share/omarchy/default/hypr/bindings/` (`applications.lua` carries the app and web-app set) and the user seed at `/usr/share/omarchy/config/hypr/bindings.lua`; the shipped `omarchy` skill owns the binding API, inspection commands, and validation loop:
   - every `hl.unbind` target must still match a default chord, and personal chords must not collide with new defaults
   - verify live registration by description and modmask via `hyprctl binds`; Omarchy registers Lua bindings as opaque `__lua` dispatchers, so exec strings never appear there
   - the file stays personal overrides only; defaults are never replicated
   - `make verify` runs `scripts/check-bindings.sh` for the unbind-target and collision assertions; run it after every change here
4. Compare `yazi/yazi.toml` against official Yazi docs, and the `nvim/` plugin specs against `obsidian.nvim/` and the render-markdown.nvim README
5. App parity sweep: diff `pacman -Qe` against the installed default manifest (`/usr/share/omarchy/install/omarchy-base.packages` plus hardware conditionals) and the optional installers (`omarchy-install-*`); classify each extra as personal, optional-installed, or retired survivor, and account for provider resolution (`extra/neovim` satisfies the `nvim` entry)
6. Tool-path integrity: every managed CLI in `~/.local/bin` (the `omarchy-mise-install` lines in `/usr/share/omarchy/install/user/mise.sh`: claude, codex, opencode, gemini, copilot, gh, and the rest) must be the Omarchy mise wrapper; `omarchy-refresh-applications` deletes and rewrites them through `omarchy-mise-install`, so verify with `head -3` on each and `mise ls --current`. Hand-installed scripts and the EyrAgents spar links are unmanaged and survive. Native install stores are removable only after confirming the running binary path via `/proc/<pid>/exe`
7. Webapp entries: compare the webapp launchers in `~/.local/share/applications` against the current Omarchy default set and remove stale ones with `omarchy-webapp-remove`; personal bindings launch by URL and do not depend on desktop entries
8. Cross-repo coordination: read the sibling ledgers for items assigned to this repo and for stale entries describing this host's environment
9. For each difference, classify it:
   - **Intentional personal customization**: documented in `DEVIATIONS.md`, should stay different
   - **New upstream addition**: added upstream after the last sync, should be reviewed for inclusion
   - **Upstream change to existing config**: modified upstream, needs review
10. Check `git log --format="%h %ad %s" --date=short -- <file>` on the relevant reference repo when you need to determine when a difference was introduced
11. Cross-check differences against `DEVIATIONS.md`. If a difference is not documented there, treat it as a likely upstream change that needs review
12. Apply new upstream additions and changes where they belong in the personal customizations
13. Update `README.md`, `AGENTS.md`, and `DEVIATIONS.md` when package ownership, setup steps, or documented deviations change
14. Summarize which changes were adopted, rejected, or intentionally kept different

## Completion Checks

- `README.md`, `AGENTS.md`, and `DEVIATIONS.md` reflect any ownership, setup, or workflow changes
- Every retained difference is still documented in `DEVIATIONS.md`
- The final summary distinguishes adopted changes, rejected changes, and intentional retained differences

## Rules

- Present proposed changes to the user before editing; a deliberate exception to shared guidance, because a sync pass touches many files on judgment calls and each adopted upstream change is a deviation decision
- Omarchy, official docs, official package docs, and `DEVIATIONS.md` are the source of truth for default behavior and intentional differences
- Always check all relevant sources, not just one
- Never assume a difference is intentional without verifying it is documented in `DEVIATIONS.md`
- Fetch changeable upstream and package facts at maintenance time instead of caching versions in this skill
- Do not copy Omarchy default behavior into this repo if Omarchy already manages it; the deviation policy extends to skills, so defer to the shipped `omarchy` skill rather than duplicating its content here
- Load the shipped `omarchy` skill before editing any Hyprland or desktop config; keep only repo-specific rules in this file
- Keep the Bash overrides minimal: source Omarchy defaults, only override what needs to change; the AI alias removals, the OpenCode exports, `y()`, and the sourced `tdw` and `hdw` twins are the whole override set, and the twins change only together with EyrWSL
- Keep Yazi config standalone since Yazi is not part of Omarchy
- Package removals: the pacman dependency graph is necessary but not sufficient; also check runtime plugin loading (`qt5-wayland`/`qt6-wayland` style), tools exec'd by Omarchy scripts (`grep -r` the `/usr/share/omarchy` tree), and .NET framework targets (`*.runtimeconfig.json` against installed runtimes)
- `qt6-wayland` reads as a pacman orphan but carries Quickshell and every Qt6 app at runtime; never remove `pacman -Qdtq` output as a batch

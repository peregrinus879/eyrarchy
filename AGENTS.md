# AGENTS.md - EyrArcHy

Personal [Omarchy](https://github.com/omacom/omarchy) dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/): targeted personal deviations stowed on top of the Omarchy desktop (Bash overrides and workspace launchers in `bash/`, Hyprland personal overrides in `hypr/`, additive Neovim vault-workflow plugin specs in `nvim/`, Yazi config in `yazi/`). Omarchy, official docs, official package docs, and `DEVIATIONS.md` are the source of truth for default behavior and intentional differences; ownership boundaries live in `DEVIATIONS.md` (Deviation Policy and Out Of Scope).

## Load Map

- Claude Code loads this file through the root `CLAUDE.md` `@AGENTS.md` import; skills load on invocation only.
- The `Makefile` is the single source of the package list (`scripts/prepare-stow.sh` consumes it); `references.txt` lists the reference clones `/omasync` needs, and the family union of those files owns `~/Projects/quarry`; `README.md` carries the human-facing setup, verification, and maintenance detail; script headers own local constraints.
- `docs/maintenance.md` owns unresolved decisions, deferred work, active limitations, and dated revalidation evidence; read it before package removals, Omarchy updates or refreshes, or work on a deferred item. Prose describes current behavior; Git history owns provenance.
- EyrAgents' canonical [Workstream Checkpoints](https://github.com/peregrinus879/eyragents/blob/main/agents/.agents/shared-guidance.md#workstream-checkpoints) rule owns local continuity for substantial work. The primary owns the gitignored `.eyr-plans/<workstream>.md` milestone summary and reads it on resume, compaction, and handoff; no extra skill is needed. It is not authorization or cross-machine transport. Retain completed local checkpoints; remove session scratch.

## Invariants

- Target machine: Omarchy. `stow`, `unstow`, `restow`, `clean`, `recover`, and `verify` refuse elsewhere, and `restow` refuses from a clone whose links are not the deployed ones; `lint`, `check`, `test`, `twins`, and `refs` run anywhere.
- Because the packages are live configuration on the stowed host, an edit to a stowed file here is active for the next shell, Hyprland reload (Hyprland reloads on save), Neovim session, or Yazi launch before any commit; work on this repository only in a session H is watching.
- Stow runs with `--no-folding`, so every managed parent under `$HOME` is a real directory and only leaf files are links; generated host state therefore never reaches a package source. `make clean` removes only leftover folded links, dangling links whose text names a package entry this repository has, and regular files at owned paths (Omarchy clobber artifacts); `make verify` fails on a folded managed directory.
- When editing sibling dotfiles repos, use identical wording for shared concepts; only repo-specific values (scope, package lists, invariants) differ.
- The Makefile `TWIN_SPECS` files (nvim vault plugin specs, the `tdw` and `hdw` workspace functions, `yazi.toml`, and `scripts/update-references.sh`) are byte-identical twins with EyrWSL; `make twins` (and `make verify` through it) fails on drift when the sibling clone is present and reports a skipped check when it is absent, and CI runs the same comparison against a fresh EyrWSL clone.
- Omarchy must be installed and functional before applying these dotfiles; Yazi is installed separately (`sudo pacman -S yazi`).
- The vault is expected at `~/Projects/vault` (override with `OBSIDIAN_VAULT`) for the obsidian.nvim workflow.
- Git identity lives in the untracked per-host `~/.config/git/config.local`; `make verify` asserts that it resolves to a GitHub no-reply address without printing it.
- Interactive Bash exports `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1` and `OPENCODE_ENABLE_EXA=1` so terminal-launched OpenCode skips the Claude Code skill copies, reads `.agents/skills` natively, and exposes web search. EyrAgents owns OpenCode configuration; this repo owns the Omarchy host environment. Non-interactive launchers supply the same variables explicitly.
- The `hypr` package carries personal Hyprland overrides only, loaded after the Omarchy defaults through the Omarchy-owned `~/.config/hypr/hyprland.lua` require chain: `bindings.lua` (the twelve default web-app bindings retired via `hl.unbind`, the personal `SUPER ALT` set and AppImages added), `monitors.lua` (display values), `input.lua` (us/ara layouts, natural scrolling), and `looknfeel.lua` (rounded corners, reduced gaps); no defaults are replicated (deviations documented in `DEVIATIONS.md`). `make verify` asserts every `hl.unbind` target against the installed defaults and fails on a personal chord that collides with a default not unbound above it.
- Keep every intentional difference documented in `DEVIATIONS.md`; update `README.md`, `AGENTS.md`, and `DEVIATIONS.md` together when ownership, setup, or sync assumptions change.

## Post-Change Verification

- Start a fresh shell and Neovim session after structural changes.
- The full human checklist lives in `README.md` (Verify and Maintenance).

## Skills

- `/omasync` - sync personal customizations against Omarchy references, installed defaults, and official docs; its source is `.agents/skills/omasync/SKILL.md`, the Agent Skills standard's home, with a tracked symlink under `.claude/skills` for Claude Code; Codex and OpenCode read `.agents/skills` natively

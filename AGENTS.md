# AGENTS.md - EyrArcHy

EyrArcHy is a set of personal overrides for an installed [Omarchy](https://github.com/omacom/omarchy) desktop, deployed with [GNU Stow](https://www.gnu.org/software/stow/): Bash additions and the `hdw` workspace helper in `bash/`, Hyprland overrides in `hypr/`, additive Neovim plugin specs in `nvim/`, Yazi configuration in `yazi/`, and root-owned host files in `system/`. Omarchy, its official documentation and [DEVIATIONS.md](DEVIATIONS.md) are the source of truth for default behavior and every intentional difference.

## Loading

Claude Code (2.1.277 or later) and OpenCode read this file natively as the project's `AGENTS.md`; the repository has no `CLAUDE.md`, which would take precedence. The `omasync` skill lives in `.agents/skills`, with a tracked directory link under `.claude/skills` for Claude Code.

## Ownership

| Owner | Holds |
| --- | --- |
| This file | Invariants for agents changing the repository |
| [README](README.md) | Overview and navigation |
| [DEVIATIONS.md](DEVIATIONS.md) | Every intentional difference from Omarchy, its reason, and the behavior contracts of `hdw` and Git review |
| [Setup](docs/setup.md) | Installation, deployment, moves and recovery after Omarchy resets |
| [Operations](docs/operations.md) | Daily use, verification and Make targets |
| [Maintenance ledger](docs/maintenance.md) | Open work only; read it before package removals, Omarchy updates or work on a listed item |
| [`omasync`](.agents/skills/omasync/SKILL.md) | Reconciliation with upstream Omarchy |
| `Makefile`, script headers, tests | The package list, twin list, local constraints and checked contracts |

State each fact once, at its owner, and link to it. Git history holds provenance. [EyrAgents](https://github.com/peregrinus879/eyragents) owns the offline workspace guide; a change to a key or command here includes reconciling its `host-reference.json` there, or recording the pending reconciliation in this ledger when that repository is out of scope.

## Invariants

- **Target host.** Host-writing targets (`stow`, `unstow`, `restow`, `clean`, `recover`, `verify`) refuse anywhere but an Omarchy host, and each checks that the deployed links belong to this clone before changing anything. `lint`, `check`, `test`, `twins`, `twins-pair` and `refs` run anywhere.
- **Live configuration.** An edit to a stowed file takes effect at the next shell, Hyprland reload (Hyprland reloads on save), Neovim session or Yazi launch, before any commit. Work on this repository only in a session H is watching.
- **Layer on Omarchy.** Load Omarchy's defaults first and override only what needs to differ; never copy its defaults, themes, AI launch aliases, Herdr recipes or tmux setup. Every intentional difference is documented in DEVIATIONS.md, and the overview, this file and the affected guides change together with it.
- **Twins with EyrWSL.** The files in the Makefile's `TWIN_SPECS` (Neovim plugin specs, `hdw`, Yazi configuration, the reference updater and their tests) are byte-identical across EyrArcHy and [EyrWSL](https://github.com/peregrinus879/eyrwsl); shared concepts use identical wording in both repositories, with only repository-specific values differing.
- **Host system files.** `system/` mirrors paths under `/` and is never stowed or linked: H installs root-owned copies with the commands in [setup](docs/setup.md#5-host-system-files), so a change to one includes those commands for H. `make verify` fails while a copy differs.
- **Host-local state.** Git identity and GitHub helper settings live in the untracked `~/.config/git/config.local`, never in a package; credentials never enter the repository.
- **Preservation.** Cleanup, reference refreshes and recovery never delete or overwrite what they cannot prove they own; they refuse and report instead. The script headers and [setup](docs/setup.md) state each rule.

## Checks

`make lint check` are the repository checks; on Omarchy, `make verify` adds deployment checks and `make twins` compares the twin files with EyrWSL. After a structural change, start a fresh shell and Neovim session. [Operations](docs/operations.md#verify) holds the full checklist.

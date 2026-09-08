# EyrArcHy

Personal [Omarchy](https://github.com/omacom/omarchy) dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

EyrArcHy carries standalone personal customizations for the Omarchy desktop. Omarchy manages its own defaults, themes, and desktop configs. This repo tracks only targeted personal deviations applied via GNU Stow.

The display name shares its capital `H` between Arch and Hyprland, preserving Omarchy's naming lineage; the repository slug remains lowercase `eyrarchy`.

Eyrie is the shared project habitat, reflected locally in `~/Projects/eyrie/`. `Eyr` is its shortened family prefix, used by EyrAgents, EyrArcHy, and EyrWSL.

## Repo Family

Derivation model for this repo family:

```text
AI agent harness                → EyrAgents
Omarchy + personal deviations   → EyrArcHy
Omarchy + WSL deviations        → EyrWSL
```

- [`eyragents`](https://github.com/peregrinus879/eyragents) - AI agent harness: Claude Code, Codex, and OpenCode settings, shared guidance, and commit workflow
- [`eyrarchy`](https://github.com/peregrinus879/eyrarchy) - Personal Omarchy customizations: Bash overrides, Hyprland bindings, Neovim plugins, and Yazi
- [`eyrwsl`](https://github.com/peregrinus879/eyrwsl) - Self-contained WSL Arch environment: terminal baseline plus Windows Terminal and clipboard integration

Local clones live side by side under `~/Projects/eyrie/`.

## Stack

- **Base**: [Omarchy](https://github.com/omacom/omarchy)
- **Bash**: Personal alias, function, and OpenCode host-environment overrides on top of Omarchy defaults
- **Editor**: [obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim), [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim), and contextual Snacks Git-review mappings on the `omarchy-nvim` base
- **File Manager**: [Yazi](https://github.com/sxyazi/yazi) (not part of Omarchy)
- **Desktop**: [Hyprland](https://github.com/hyprwm/Hyprland) personal keybindings, display, input, and look-and-feel config

## Package Layout

Each top-level directory is a GNU Stow package that symlinks into `$HOME`:

```text
bash/   Bash overrides (.bashrc with Omarchy defaults sourced + personal additions, tdw and hdw workspace functions)
hypr/   Hyprland personal overrides (bindings.lua, monitors.lua, input.lua, looknfeel.lua)
nvim/   Additive Neovim plugin specs for vault workflows and contextual Git review
yazi/   Yazi file manager config (yazi.toml, no theme)
```

Key ownership rules:

- Omarchy manages all defaults, themes, and desktop configs
- `bash/` owns `~/.bashrc`, sources Omarchy defaults, and adds personal overrides below, including the interactive OpenCode skill-isolation and search environment; EyrAgents owns the OpenCode configuration itself. The AI tools run as EyrAgents configures them; Omarchy's launch aliases are unaliased. `tdw` and `hdw` are byte-identical twins with EyrWSL.
- `yazi/` is purely additive since Yazi is not part of Omarchy
- `nvim/` is purely additive plugin specs on top of the `omarchy-nvim` base; the vault is expected at `~/Projects/vault` (override with `OBSIDIAN_VAULT`)
- `hypr/` owns `~/.config/hypr/bindings.lua`, `~/.config/hypr/monitors.lua`, `~/.config/hypr/input.lua`, and `~/.config/hypr/looknfeel.lua`: personal overrides only, loaded after the Omarchy defaults; all other Hyprland config is Omarchy-owned and untracked
- no theme files are tracked; Omarchy manages themes

## Setup

### 1. Prerequisites

Omarchy must be installed and functional.

Install Yazi (not part of Omarchy):

```bash
sudo pacman -S yazi
```

### 2. Clone

Recommended local layout for this repo family:

```text
~/Projects/eyrie/eyrarchy
```

Stow can work from any clone location, but the related docs and cross-repo maintenance workflows assume this layout.

```bash
git clone https://github.com/peregrinus879/eyrarchy.git ~/Projects/eyrie/eyrarchy
```

### 3. Prepare

Checklist before stowing:

- Omarchy is installed and functional
- Yazi is installed
- The vault is synced to `~/Projects/vault` (or `OBSIDIAN_VAULT` is set) if you use the Obsidian workflow
- Reported conflicts were compared and any needed content preserved at explicitly reviewed backup paths

Preview before cleanup. The guarded preparation script derives owned paths from package files and preflights the complete layout. It removes only owned folded links and recognized dangling clone links; live leaf links stay for Stow. Every regular file is preserved and causes refusal, even at an owned path: the pathname does not prove it is an Omarchy clobber artifact. Compare each reported file and deliberately move or merge its needed content before retrying; foreign links and special files also refuse unchanged.

```bash
cd ~/Projects/eyrie/eyrarchy
make dry-run
make clean
make dry-run
```

### 4. Stow

Create symlinks for all packages (the Makefile owns the package list):

```bash
cd ~/Projects/eyrie/eyrarchy
make stow
```

Stow runs without directory folding, so `~/.config/bash`, `~/.config/yazi`, and the other managed parents stay real directories that tools may write into; Stow reports any conflicting regular file without changing it. Inside a Hyprland session, `make stow` finishes with a forced reload and a config-error check. Start a new terminal session, or run `source ~/.bashrc`, for the shell config to take effect.

### Unstow

```bash
cd ~/Projects/eyrie/eyrarchy
make unstow
```

### Dry Run

Preview what stow would do without making changes:

```bash
cd ~/Projects/eyrie/eyrarchy
make dry-run
```

### Re-stow

To update symlinks after the repo content changes (same clone path):

```bash
cd ~/Projects/eyrie/eyrarchy
make restow
```

To migrate from a different clone path, unstow from the old location first:

```bash
make -C /old/clone/path unstow
cd ~/Projects/eyrie/eyrarchy
make stow
```

If the old clone is no longer available, `make clean` (section 3) removes its dangling links; then run `make stow`.

### Recovery After Omarchy Config Resets

`omarchy-reinstall-configs` overwrites `~/.bashrc` and `~/.config/` from Omarchy defaults (via `cp -af /etc/skel/. ~/`). Inspect `git status` and the exact affected diff before restoring anything; preserve unrelated or pre-existing edits. Restore only H-approved clobbered paths/hunks, then run `make recover` from the deployed clone (guarded cleanup plus restow). A replacement regular file is a preservation/refusal case, not automatic cleanup: compare and back it up deliberately first.

`omarchy-refresh-hyprland` (and `omarchy-refresh-config` generally) copies shipped defaults over existing files with `cp -f`, which writes through a Stow symlink into the repo working tree; the link survives and a timestamped `.bak` of the personal content is left beside it. Compare the backup, current diff, and intended source before an exact-path/hunk restoration. Do not restore the whole Hyprland directory blindly; keep unrelated work and verify the result.

## Git Review

After stowing, start a fresh Neovim session once to load `git-review.lua`. `Space g d` shows staged and unstaged hunks, `Space g D` compares against origin, and `Space g s` shows status including untracked files. Each invocation uses the current file/directory's Git repository or the selected Neo-tree item, falling back to the displayed tree root when no item path exists. Symlink targets and linked worktrees are supported; switching files between repositories switches the review target without changing any editor directory.

Empty or special non-explorer buffers use the current window's directory. A known non-Git file or explorer target warns instead of silently reviewing another repository. No recurring `:cd`/`:lcd` is needed for repository files or selected repository folders. Keep the ordinary picker review controls; do not use its stage/restore actions unless intended.

## Verify

Workspace fixtures exercise isolated tmux servers with fake agents and a Python-backed Herdr model. They cover creation, ownership, failure recovery and concurrency without using running user workspaces or real agents; rendered UI and actual-host activation remain separate checks.

After stowing or changing owned packages:

- Run `make lint` and `make check` after any change; both are repository-only (ShellCheck; bash, Lua, and TOML syntax; the `tests/` fixtures). GitHub Actions runs them on pushes to `main` and pull requests, plus an exact committed twin-pair check against EyrWSL's fetched default branch.
- Run `make verify` from the repo root on the Omarchy host after stowing or changing owned packages: `lint`, `check`, and `twins`, then the stowed symlinks (compared by resolved path), every managed parent being a real directory, the Git identity (it must resolve to a GitHub no-reply address; the value is not printed), every `hl.unbind` target and personal chord in `bindings.lua` against the installed Omarchy defaults, and Hyprland config errors.
- Start a fresh shell and confirm `printenv OPENCODE_DISABLE_CLAUDE_CODE_SKILLS` and `printenv OPENCODE_ENABLE_EXA` each print `1`; non-interactive OpenCode launchers must supply both variables themselves.
- Start a fresh shell and confirm `type y` shows the Yazi cd-on-exit function.
- Start a fresh shell and confirm `alias claude c cx cy ic ix icx` reports no alias for any of them: the AI tools run as EyrAgents configures them.
- Confirm `type tdw` and `type hdw` show the workspace functions. From a project directory, `<tdw|hdw> <cc|cx|oc> [-c]` creates a project-named session/workspace with a new window/tab named `claude`, `codex`, or `opencode`; `-c` continues that agent's last conversation. AI stays full-height left, editor/shell equally stacked right, with equal columns and agent focus. Bare invocation preserves existing workspace names/layouts while attaching or focusing. New tmux titles retain host, project session, and agent window as `#h:#S:#W`.
- Workspace creation is serialized and validates the full layout before sending input; failures stop clearly and cleanup targets only that invocation's creation. Herdr starts headless when needed; failed startup returns failure with manual-start guidance, not a plain-attach success. If rollback is unverified, inspect the reported pending identity and any retained `hdw` roots snapshot before retrying; do not delete unfamiliar workspaces or recovery files.
- `hl.env` values in the tracked hypr files reach the compositor on reload but reach uwsm-launched clients only at session start; after first adopting the hypr package on a running session, log out and back in once.
- Run `yazi` and confirm the layout ratio and sort order match the config.
- Open a vault note in Neovim and confirm obsidian.nvim loads (`<leader>oo` opens the note switcher).
- Check Git review from files in two repositories and from a selected Neo-tree repository folder while the editor was launched in their non-Git parent; `Space g d` and `Space g s` must target the selection without changing `:pwd`.

## Maintenance

A repo-root `Makefile` keeps the package list in one place and wraps the routine commands. Run targets from the repo root on the Omarchy machine:

- `make stow` / `make unstow` / `make dry-run` / `make restow` - the stow command sets over the package list
- `make lint` - ShellCheck 0.11.0 or newer over the bash package, `scripts/`, and `tests/`; `.shellcheckrc` disables the upstream-derived warnings so new issues stand out
- `make check` - repository-only checks: bash, Lua, and TOML syntax, then the `tests/` fixtures (`prepare-stow.sh` in a fake home, `check-bindings.sh` against fake defaults)
- `make twins` - twin-file sync against the EyrWSL clone (`SIBLING`, default `~/Projects/eyrie/eyrwsl`); a missing sibling is reported as a skipped check
- `make twins-pair SELF_COMMIT=<full-sha> PEER_COMMIT=<full-sha> SIBLING=<peer-object-repo>` - read-only twin comparison of two exact full 40-character commit IDs; all three inputs remain literal data, missing objects/files fail, and no peer code executes. Replace the placeholders and quote the peer path; do not type angle brackets
- `make test` - the `tests/` fixtures alone, in fake homes
- `make verify` - `lint`, `check`, and `twins`, then the host checks listed under Verify; refuses off the Omarchy host
- `make clean` - guarded Stow preparation (`scripts/prepare-stow.sh`); owned folded links and recognized dangling clone links only, with every regular file preserved and complete preflight refusal on foreign entries
- `make recover` - the Recovery steps after `omarchy-reinstall-configs` (clean + restow)
- `make refs` - clone and fast-forward listed references to exact fetched upstream parity, repointing moved GitHub remotes; report and keep stale clones, never auto-delete them (`/omasync` step 1)

Every host-writing Make target checks host and deployed-clone ownership before mutation. Deployment goals are serialized within one Make invocation, including `make -j`; this is not rollback against I/O failure or independent concurrent deployments.

Before running `make refs`, preview with `bash scripts/update-references.sh --dry-run` and approve any new clone or remote repointing separately. The preview can query GitHub but does not fetch or establish conflict-free upstream parity. Routine authorized refreshes remain the sync skill's work; atomic fetch does not make the whole family update transactional.

`make refs` refuses ahead-only/divergent listed default branches instead of calling them current. Its atomic, non-forced fetch preserves existing local tags and annotations, imports new tags, and prunes only origin tracking branches. Checkout and merge use `--no-overwrite-ignore`, preserving ignored files in listed clones. Tag/file conflicts refuse that update and require separate review; do not force a tag replacement or delete local files to make it pass. Stale references are informational and require separate review of all refs, stashes, and ignored/untracked files before any manual removal.

`make stow`, `make restow`, and `make recover` finish with a forced Hyprland reload and config-error check when run inside a Hyprland session (rationale in the Makefile header); `make verify` runs the same check read-only.

CI runs `make lint`, `make check`, and `twins-pair` on pushes to `main` and pull requests, using the peer default branch for normal runs. Manual workflow dispatch accepts an explicit full `peer_commit` only with `peer_reviewed=true`; it fetches peer objects without executing peer code and records both actual commits. This attestation is not publication authorization. For coordinated changes, verify the final published pair explicitly after both commits are available; a green check against an earlier peer is not final-pair evidence. Local `make twins` remains a worktree convenience check that can skip a missing sibling.

CI uses the official `archlinux:base` container with a full signed-package upgrade, matching the Arch userspace of both supported hosts. `ubuntu-latest` supplies only GitHub's VM. Checks run as an unprivileged `ci` user with explicit Bash, a private temporary directory and container process reaping; checkout credentials are not persisted. CI does not perform or attest deployment to Omarchy or WSL.

Periodically, review the local reference repos and official docs for upstream changes to overridden items, sync with `/omasync` or a manual comparison, and confirm every intentional difference is still documented in `DEVIATIONS.md`. Unresolved decisions, deferred work, active limitations, and dated evidence live in [docs/maintenance.md](docs/maintenance.md).

## Related Repos

Upstream comparison runs through the `/omasync` skill; `make refs` keeps the reference clones listed in `references.txt` current. Upstream URLs and official docs live in [DEVIATIONS.md](DEVIATIONS.md) (Reference Sources).

## Credits

Personal customizations on top of [Omarchy](https://github.com/omacom/omarchy). See [DEVIATIONS.md](DEVIATIONS.md) for intentional differences and boundary definitions.

## License

[MIT](LICENSE)

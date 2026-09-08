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
bash/   Bash overrides (.bashrc with Omarchy defaults sourced + personal additions, hdw new-workspace layout helper)
hypr/   Hyprland personal overrides (bindings.lua, monitors.lua, input.lua, looknfeel.lua)
nvim/   Additive Neovim plugin specs for vault workflows and contextual Git review
yazi/   Yazi file manager config (yazi.toml, no theme)
```

Key ownership rules:

- Omarchy manages all defaults, themes, and desktop configs
- `bash/` owns `~/.bashrc`, sources Omarchy defaults, and adds personal overrides below, including the interactive OpenCode skill-discovery and search environment; EyrAgents owns the OpenCode configuration itself. Omarchy's six AI launch aliases load unchanged; both stock shortcuts and `hdw` load applicable EyrAgents settings, with stock shortcut flags applied only on that launch path. `hdw` is a byte-identical twin with EyrWSL. Omarchy retains ownership of its Herdr recipes and installed tmux, including native configuration, functions and launch bindings.
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

Preview before cleanup. The guarded preparation script derives owned paths from package files plus its exact retired-endpoint inventory, and preflights the complete layout before mutation. It removes only owned folded links, recognized dangling clone links and exact retired links; live leaf links stay for Stow. Every regular file is preserved and causes refusal, even at an owned path: the pathname does not prove it is an Omarchy clobber artifact. Compare each reported file and deliberately move or merge its needed content before retrying; foreign links, unsafe parents and special files also refuse unchanged. Real directories and user state are retained.

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

Stow runs without directory folding, so `~/.config/bash`, `~/.config/yazi`, and the other managed parents stay real directories that tools may write into; Stow reports any conflicting regular file without changing it. Inside a Hyprland session, `make stow` finishes with a forced reload and a config-error check. Start a fresh shell to load the current helper and stock AI aliases without retaining retired function definitions; preserve existing sessions.

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

After pulling the custom `tdw` removal, run guarded cleanup before restowing:

```bash
make clean
make restow
make verify
```

The retirement inventory explicitly maps `~/.config/bash/functions/tdw` to this clone's old `bash/.config/bash/functions/tdw`, even when that source no longer appears in Git. Only an exact relative or absolute owned link is removed; foreign or lookalike links (including dangling links into another clone), regular files and special entries refuse unchanged. Safe real parents stay; exact old owned folds can be removed without traversing them. `make verify` includes preparation's read-only `--check-retired` route and requires the retired endpoint to be absent, whether the source deletion is pending or already pulled. Unrelated missing sources still fail. `make restow` keeps its ordinary Stow semantics and does not run cleanup implicitly. No Omarchy refresh, tmux package/configuration change or session termination is part of this retirement. Start a fresh shell to drop an already-loaded `tdw` function.

To migrate from a different clone path, unstow from the old location first:

```bash
make -C /old/clone/path unstow
cd ~/Projects/eyrie/eyrarchy
make stow
```

If the old clone is no longer available, `make clean` (section 3) removes recognized dangling links for active packages; then run `make stow`. Retired `tdw` ownership is stricter: a link into another clone requires exact-path review instead of automatic cleanup.

### Recovery After Omarchy Config Resets

`omarchy-reinstall-configs` overwrites `~/.bashrc` and `~/.config/` from Omarchy defaults (via `cp -af /etc/skel/. ~/`). Inspect `git status` and the exact affected diff before restoring anything; preserve unrelated or pre-existing edits. Restore only H-approved clobbered paths/hunks, then run `make recover` from the deployed clone (guarded cleanup plus restow). A replacement regular file is a preservation/refusal case, not automatic cleanup: compare and back it up deliberately first.

`omarchy-refresh-hyprland` (and `omarchy-refresh-config` generally) copies shipped defaults over existing files with `cp -f`, which writes through a Stow symlink into the repo working tree; the link survives and a timestamped `.bak` of the personal content is left beside it. Compare the backup, current diff, and intended source before an exact-path/hunk restoration. Do not restore the whole Hyprland directory blindly; keep unrelated work and verify the result.

## Native Herdr

Launch Herdr independently with `herdr` or Omarchy's native `SUPER CTRL RETURN` binding. In a shell inside that session, navigate to the desired directory, then run `hdw <cc|cx|oc> [-c]` to create and focus a new workspace:

- `cc` sends `claude`; `-c` uses `claude -c`.
- `cx` sends `codex`; `-c` uses `codex resume --last`.
- `oc` sends `opencode`; `-c` uses `opencode -c`.

`hdw` uses the current physical directory, not an inferred Git root. AI occupies the full-height left column, Neovim the top-right and a shell the bottom-right, with equal columns, equally stacked right panes and AI focus. The caller may be in a populated tab or an inactive workspace, but its pane identity and selected-tab context must be valid. Every call creates a separate workspace, even in the same directory; change directory in a generated bottom-right shell and call again to open the next workspace. Bare `hdw` prints usage; outside-Herdr or invalid-context calls refuse.

Existing workspace/tab names and layouts stay intact, apart from normal global workspace focus moving to the new workspace. New names are Herdr's defaults, with no `--label` or rename/metadata writes; the new default tab displays positional `1` ([Herdr 0.8.2 display-name implementation](https://github.com/herdrdev/herdr/blob/v0.8.2/src/workspace.rs)). There is no workspace reuse, roots registry, server startup or client attachment. Old `hdw` state and recovery files remain unused and untouched. Native controls still own navigation: the shipped `Ctrl+Space` prefix followed by `c` opens a tab and `Shift+C` opens a workspace; in-app help is authoritative for personal keymap changes.

Cooperating calls are serialized. Caller identity, the pre-creation workspace inventory, the new root's opaque terminal identity, exact membership and complete geometry are checked before tool input. Cleanup may close only proven new split panes before input, never any workspace, tab, root or original caller. A newly created workspace/root always remains for inspection on failure; possible input or uncertain ownership preserves remaining state. Inspect the reported original/new recovery context before manual action. This is not an atomic multi-RPC transaction.

The `cc`/`cx`/`oc` selectors are arguments, not shell aliases. Stock Omarchy `c`/`cx`/`cy` select OpenCode/Claude Code/Codex respectively, so stock `cx` is Claude Code while `hdw cx` is Codex; `ic`/`ix`/`icx` retain their stock `tdl` recipes. These aliases also remain available in `hdw`-created shells. `hdw` sends full commands without stock shortcut flags, but it is not an isolated profile: both launch paths load applicable EyrAgents settings. Stock Herdr/tmux functions, bindings and packages remain unchanged.

## Git Review

After stowing, start a fresh Neovim session once to load `git-review.lua`. `Space g d` shows staged and unstaged hunks, `Space g D` compares against origin, and `Space g s` shows status including untracked files. Each invocation uses the current file/directory's Git repository or the selected Neo-tree item, falling back to the displayed tree root when no item path exists. Symlink targets and linked worktrees are supported; switching files between repositories switches the review target without changing any editor directory.

Empty or special non-explorer buffers use the current window's directory. A known non-Git file or explorer target warns instead of silently reviewing another repository. No recurring `:cd`/`:lcd` is needed for repository files or selected repository folders. Keep the ordinary picker review controls; do not use its stage/restore actions unless intended.

## Verify

Layout fixtures use fake agents and a Python-backed Herdr model. They cover new-workspace creation, populated/inactive callers, repeated calls and generated-shell chaining, ownership, failure recovery and concurrency without using running user workspaces or real agents. Real-Herdr, rendered UI and actual-host evidence remain separate; see [active limitations](docs/maintenance.md#active-limitations). Preparation fixtures cover real old Stow deployments followed by pending/post-pull retirement, exact ownership, refusal and read-only verification. Repository checks do not require or invoke tmux.

After stowing or changing owned packages:

- Run `make lint` and `make check` after any change; both are repository-only (ShellCheck; bash, Lua, and TOML syntax; the `tests/` fixtures). GitHub Actions runs them on pushes to `main` and pull requests, plus an exact committed twin-pair check against EyrWSL's fetched default branch.
- Run `make verify` from the repo root on the Omarchy host after stowing or changing owned packages: `lint`, `check`, and `twins`, then retired-endpoint absence, live source existence, the stowed symlinks (compared by resolved path), every managed parent being a real directory, the Git identity (it must resolve to a GitHub no-reply address; the value is not printed), every `hl.unbind` target and personal chord in `bindings.lua` against the installed Omarchy defaults, and Hyprland config errors.
- Start a fresh shell and confirm `printenv OPENCODE_DISABLE_CLAUDE_CODE_SKILLS` and `printenv OPENCODE_ENABLE_EXA` each print `1`; non-interactive OpenCode launchers must supply both variables themselves.
- Start a fresh shell and confirm `type y` shows the Yazi cd-on-exit function.
- Start a fresh shell and confirm `alias c cx cy ic ix icx` matches Omarchy's installed defaults; `alias claude` should still report no alias. Stock shortcuts keep their own launch flags and applicable EyrAgents settings; do not confuse stock `cx` with the `hdw cx` argument.
- Confirm `type hdw` shows the new-workspace helper and a fresh shell no longer loads custom `tdw`. In a disposable Herdr session/project, check the [Native Herdr](#native-herdr) layout, full agent/continuation commands, native names and AI focus. Repeated calls, including from a populated caller, a valid inactive source workspace and a generated bottom-right shell, must each create a new workspace; existing names/layouts must stay intact apart from global focus. Bare invocation shows usage; outside-Herdr and invalid-context calls refuse. Do not experiment in an existing working session.
- On helper failure, inspect the original/new pane/tab/workspace context before manual cleanup. The new workspace/root must remain; only verified new split panes may be removed before possible input, never any workspace/tab/root/caller. Never delete unfamiliar panes or retained state/recovery files. Omarchy's stock Herdr/tmux functions, configuration and launch bindings remain upstream-owned and unchanged.
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
- `make clean` - guarded Stow preparation (`scripts/prepare-stow.sh`); owned folded links, recognized dangling clone links and exact retired links only, with real directories/user state preserved and complete preflight refusal on unsafe parents, foreign entries, regular files and special files
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

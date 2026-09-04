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
- **Editor**: [obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim) and [render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) plugin specs on the `omarchy-nvim` base
- **File Manager**: [Yazi](https://github.com/sxyazi/yazi) (not part of Omarchy)
- **Desktop**: [Hyprland](https://github.com/hyprwm/Hyprland) personal keybindings, display, input, and look-and-feel config

## Package Layout

Each top-level directory is a GNU Stow package that symlinks into `$HOME`:

```text
bash/   Bash overrides (.bashrc with Omarchy defaults sourced + personal additions, tdw and hdw workspace functions)
hypr/   Hyprland personal overrides (bindings.lua, monitors.lua, input.lua, looknfeel.lua)
nvim/   Additive Neovim plugin specs for the vault workflow (obsidian.lua, render-markdown.lua)
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
- Any existing conflicting files were removed

Remove existing files that would conflict with stow. The guarded preparation script derives the owned paths from the package files and removes only folded directory links left by a folding deployment, dangling symlinks left by a moved or deleted clone, and regular files at owned paths (Omarchy clobber artifacts); live leaf links stay for Stow to manage, and anything unrecognized aborts the run before anything is removed:

```bash
cd ~/Projects/eyrie/eyrarchy
make clean
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

`omarchy-reinstall-configs` overwrites `~/.bashrc` and `~/.config/` from Omarchy defaults (via `cp -af /etc/skel/. ~/`). After running it, `git restore` any repo files it clobbered through stow symlinks, then run `make recover` from the repo root (the Prepare cleanup plus a re-stow).

`omarchy-refresh-hyprland` (and `omarchy-refresh-config` generally) copies shipped defaults over existing files with `cp -f`, which writes through a stow symlink into the repo working tree; the symlink itself survives and a timestamped `.bak` of the personal content is left beside it. After it runs, `git restore hypr/.config/hypr/` is the whole recovery.

## Verify

After stowing or changing owned packages:

- Run `make lint` and `make check` after any change; both are repository-only (ShellCheck; bash, Lua, and TOML syntax; the `tests/` fixtures), and GitHub Actions runs them on every push to `main` and every pull request, plus `make twins` against a fresh EyrWSL clone.
- Run `make verify` from the repo root on the Omarchy host after stowing or changing owned packages: `lint`, `check`, and `twins`, then the stowed symlinks (compared by resolved path), every managed parent being a real directory, the Git identity (it must resolve to a GitHub no-reply address; the value is not printed), every `hl.unbind` target and personal chord in `bindings.lua` against the installed Omarchy defaults, and Hyprland config errors.
- Start a fresh shell and confirm `printenv OPENCODE_DISABLE_EXTERNAL_SKILLS` and `printenv OPENCODE_ENABLE_EXA` each print `1`; non-interactive OpenCode launchers must supply both variables themselves.
- Start a fresh shell and confirm `type y` shows the Yazi cd-on-exit function.
- Start a fresh shell and confirm `alias claude c cx cy ic ix icx` reports no alias for any of them: the AI tools run as EyrAgents configures them.
- Confirm `type tdw` shows the tmux workspace function; from a project directory, `tdw cc`, `tdw cx`, or `tdw oc` opens its session in one window with the agent focused (`-c` continues that agent's last conversation; bare `tdw` re-attaches an existing session). Creating a session fails before changing tmux state when the selected agent is unavailable.
- Confirm `type hdw` shows the herdr workspace function; from a project directory, `hdw cc`, `hdw cx`, or `hdw oc` opens its workspace with the agent focused (bare `hdw` refocuses; the herdr server is started headless when down, and if that start fails `hdw` attaches plain herdr, rerun it inside).
- `hl.env` values in the tracked hypr files reach the compositor on reload but reach uwsm-launched clients only at session start; after first adopting the hypr package on a running session, log out and back in once.
- Run `yazi` and confirm the layout ratio and sort order match the config.
- Open a vault note in Neovim and confirm obsidian.nvim loads (`<leader>oo` opens the note switcher).

## Maintenance

A repo-root `Makefile` keeps the package list in one place and wraps the routine commands. Run targets from the repo root on the Omarchy machine:

- `make stow` / `make unstow` / `make dry-run` / `make restow` - the stow command sets over the package list
- `make lint` - ShellCheck over the bash package, `scripts/`, and `tests/`; `.shellcheckrc` disables the upstream-derived warnings so new issues stand out
- `make check` - repository-only checks: bash, Lua, and TOML syntax, then the `tests/` fixtures (`prepare-stow.sh` in a fake home, `check-bindings.sh` against fake defaults)
- `make twins` - twin-file sync against the EyrWSL clone (`SIBLING`, default `~/Projects/eyrie/eyrwsl`); a missing sibling is reported as a skipped check
- `make test` - the `tests/` fixtures alone, in fake homes
- `make verify` - `lint`, `check`, and `twins`, then the host checks listed under Verify; refuses off the Omarchy host
- `make clean` - guarded stow preparation (`scripts/prepare-stow.sh`); leftover folded links, dangling clone links, and clobber artifacts only, aborts before removing anything otherwise
- `make recover` - the Recovery steps after `omarchy-reinstall-configs` (clean + restow)
- `make refs` - clone, fast-forward, and prune the reference clones under `~/Projects/quarry` to the family's `references.txt` files, repointing moved GitHub remotes (`/omasync` step 1)

`make stow`, `make restow`, and `make recover` finish with a forced Hyprland reload and config-error check when run inside a Hyprland session (rationale in the Makefile header); `make verify` runs the same check read-only. `.github/workflows/test.yml` runs `make lint`, `make check`, and `make twins` on every push to `main` and every pull request.

Periodically, review the local reference repos and official docs for upstream changes to overridden items, sync with `/omasync` or a manual comparison, and confirm every intentional difference is still documented in `DEVIATIONS.md`. Unresolved decisions, deferred work, active limitations, and dated evidence live in [docs/maintenance.md](docs/maintenance.md).

## Related Repos

Upstream comparison runs through the `/omasync` skill; `make refs` keeps the reference clones listed in `references.txt` current. Upstream URLs and official docs live in [DEVIATIONS.md](DEVIATIONS.md) (Reference Sources).

## Credits

Personal customizations on top of [Omarchy](https://github.com/omacom/omarchy). See [DEVIATIONS.md](DEVIATIONS.md) for intentional differences and boundary definitions.

## License

[MIT](LICENSE)

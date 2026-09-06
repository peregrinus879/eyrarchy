# Deviations

## Purpose

This document records the intentional differences carried by EyrArcHy relative to [Omarchy](https://github.com/omacom/omarchy) defaults, and defines the boundary between personal desktop customizations and Omarchy-managed behavior.

Omarchy is the upstream reference. This repo carries only targeted personal deviations applied via GNU Stow.

## Deviation Policy

Omarchy manages its own defaults, themes, and desktop configs. This repo sources those defaults and adds personal customizations on top.

**Guiding principles:**

1. **Source Omarchy defaults first.** Personal overrides come after Omarchy defaults are loaded, not instead of them.
2. **Keep customizations minimal and targeted.** Only override what needs personal customization. Do not replicate Omarchy behavior.
3. **Keep scope to personal desktop customizations.** Shared Linux baseline behavior and headless adaptations are out of scope.
4. **No theme customizations.** Omarchy manages themes. This repo does not track theme files.
5. **Additive Neovim plugin specs only.** `omarchy-nvim` owns the base Neovim config; this repo adds vault-workflow plugin specs on top without touching base options.

## Reference Sources

- [omacom/omarchy](https://github.com/omacom/omarchy) - main Omarchy repo for defaults, themes, and desktop configs
- [The Omarchy Manual](https://learn.omacom.io/2/the-omarchy-manual) - setup guides, keybindings, workflows
- [obsidian-nvim/obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim) - upstream for the vault plugin spec
- [MeanderingProgrammer/render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) - upstream for the markdown rendering spec
- [sxyazi/yazi](https://github.com/sxyazi/yazi) and the [Yazi docs](https://yazi-rs.github.io/docs/) - file manager upstream and configuration reference
- [GNU Stow manual](https://www.gnu.org/software/stow/manual/stow.html) - symlink management and package structure

## Intentional Deviations

### Dotfile Management

- GNU Stow with `--no-folding` keeps managed parents real and leaf ownership explicit. Every host-writing Make target checks host and deployed-clone ownership before mutation. Cleanup preflights the complete owned layout, removing only owned folds and recognized dangling clone links; regular files, foreign links, and special files refuse unchanged. `.NOTPARALLEL` serializes one Make invocation, not independent deployments or disk failures.

### Bash

- `.bashrc` opens with the upstream seed preamble (`/usr/share/omarchy/default/bashrc`), kept verbatim, then adds personal overrides below; Omarchy writes to `.bashrc` reach the repo file through the stow symlink.
- Interactive Bash exports `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1` and `OPENCODE_ENABLE_EXA=1` so terminal-launched OpenCode skips the Claude Code skill copies, reads `.agents/skills` natively, and exposes its configured web-search tool. EyrAgents owns OpenCode configuration; this repo owns the Omarchy host environment. Non-interactive launchers supply both variables explicitly.
- The AI tools run as EyrAgents configures them: `claude`, `codex`, and `opencode` are launched plain and inherit EyrAgents' effort pin and permission rules. Omarchy's launch aliases `c`, `cx`, `cy`, `ic`, `ix`, and `icx` set permission modes, approval flags, and `tdl` targets that EyrAgents and the workspace launchers own, so `.bashrc` unaliases them after the Omarchy defaults load.
- `y()` is added for Yazi cd-on-exit support. Yazi is not part of Omarchy.
- `tdw` is added: one tmux session per project (Git root, else current directory) holding a dev layout in one window named after the project: the AI agent on the left at full height, and `$EDITOR` above a shell on the right, split 50/50 by height; the columns also split 50/50 instead of Omarchy's 70/30 with its full-width 15% shell strip, and focus lands on the agent, not the editor. Inside tmux, creation uses the full window size, not the calling pane's size. `tdw cc` runs Claude Code, `tdw cx` Codex, `tdw oc` OpenCode; the choice is mandatory at creation so a single agent owns the working tree, and `-c` continues that agent's last conversation in the project (`claude -c`, `codex resume --last`, `opencode -c`). Bare `tdw` re-attaches an existing session without changing its layout; creation checks the selected agent before changing tmux state. Additive alongside Omarchy's `tdl`/`tds` pane layouts. The `t`/`h` prefix follows Omarchy's multiplexer lettering (`tdl`/`hdl`).
- `hdw` is added: the herdr counterpart of `tdw`, one herdr workspace per project with the same one-tab layout, agent choice, `-c` flag, and agent focus, plus a root-collision guard backed by a label-to-root record under `~/.local/state/hdw/roots` (workspace ids recycle across server restarts, so the record keys on the label). Bare `hdw` refocuses; when the herdr server is down, `hdw` starts it headless and attaches, so one invocation works from a cold boot, and if the headless start fails it attaches plain herdr with a hint to rerun `hdw` inside. Additive alongside Omarchy's `hdl`/`hds` pane layouts. `tdw` and `hdw` are byte-identical twins with EyrWSL.

### Hyprland

- `bindings.lua` carries the personal keybinding overrides, loaded after the Omarchy defaults through the Omarchy-owned `~/.config/hypr/hyprland.lua` require chain. No defaults are replicated.
- `monitors.lua` is tracked: the GU605C panel at `2560x1600@240`, scale 1.6, and `GDK_SCALE=2`. `hl.env` values reach the compositor and its direct spawns on reload; uwsm-launched clients pick them up at session start.
- The twelve default web-app bindings (ChatGPT, Grok, Calendar, Email, New email, YouTube, WhatsApp, Google Messages, Google Photos, Google Maps, X, X Post) are retired via `hl.unbind`; the personal `SUPER ALT` web-app set replaces them (Claude, Gmail, GitHub, LinkedIn, CFI, M365 Copilot, Proton, Teams, WhatsApp, X, YouTube).
- `SUPER SHIFT A` launches the AppImages manager, taking the key from the default ChatGPT web app.
- `SUPER SHIFT C` launches the ChatGPT desktop app (`omarchy-install-ai-chatgpt`, launch-or-focus on class `chatgpt`), reusing the retired Calendar key; the default window-grouping toggle stays on `SUPER G`.
- `SUPER ALT G` launches Gmail, taking the key from the default "move window out of group" tiling binding; that default is knowingly sacrificed.
- The preinstalled app and TUI bindings (Music, Docker, Signal, Obsidian, Omawrite, Passwords, Herdr, Tmux) stay on Omarchy defaults.
- `input.lua` is tracked: `kb_layout = "us,ara"` with the Left Alt + Right Alt toggle (`grp:alts_toggle`; `kb_options` replaces the default string, so it restates the compose and caps settings), and touchpad `natural_scroll = true`.
- `looknfeel.lua` is tracked: `gaps_in = 3`, `gaps_out = 6` (Omarchy defaults are 5 and 10), and `rounding = 6` with `rounding_power = 3` (the solitude theme's values; the Omarchy default is 0). User `looknfeel.lua` loads after the active theme's Hyprland fragment, so these hold under any theme; the Quickshell shell mirrors `decoration:rounding` into its menu, bar-item, OSD, and notification radii. The bar body slab itself never rounds; the window-no-gaps toggle forces rounding 0 while active.
- All other Hyprland config (`hyprland.lua`, `autostart.lua`) is Omarchy-owned and untracked.

### Neovim

- `omarchy-nvim` owns the base Neovim config. This repo adds two additive plugin specs for the vault workflow.
- `obsidian.lua` configures obsidian.nvim against the vault at `~/Projects/vault` (override with `OBSIDIAN_VAULT`), including slug-rename and promote workflows that shell out to the vault's `normalize.py`, plus confirm-prompted delete workflows.
- `render-markdown.lua` adds visual markdown rendering; a companion, not required by obsidian.nvim.
- Runtime dependencies beyond the base install: `ripgrep`, `python3`, and `wl-clipboard`, all present on Omarchy.
- The spec carries a WSL-guarded `open.func` override that routes URIs through Windows interop; it is inert on Omarchy, where the default `vim.ui.open` applies. Both repos track byte-identical copies of the spec.
- `theme.lua` in `~/.config/nvim/lua/plugins/` stays Omarchy-managed by the theme system and is not tracked here.

### Yazi

- Added entirely. Yazi is not part of Omarchy.
- `yazi.toml` carries local layout and behavior choices: ratio `[2, 4, 4]`, hidden files shown, directories sorted first, `sort_by = "natural"`, and `linemode = "size"`. Tracked as a byte-identical twin with EyrWSL.
- No theme file is tracked; the Omarchy theme pipeline does not cover Yazi, which runs its built-in default theme over the terminal's themed palette.

## Out Of Scope

The following do **not** belong in EyrArcHy:

- Shared Linux baseline configs (out of scope)
- WSL or Windows-specific behavior (belong in EyrWSL)
- AI agent harness configuration (belongs in EyrAgents)
- The vault itself, its scripts, or its sync (belong to the vault project)
- Omarchy system bindings, window rules, or desktop defaults (belong in Omarchy)

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
6. **Host system files only where the desktop needs them.** `system/` carries the few root-owned files this laptop's desktop depends on, installed as copies, never stowed ([Host](#host-gu605)).

## Reference Sources

- [omacom/omarchy](https://github.com/omacom/omarchy) - main Omarchy repo for defaults, themes, and desktop configs
- [The Omarchy Manual](https://learn.omacom.io/2/the-omarchy-manual) - setup guides, keybindings, workflows
- [obsidian-nvim/obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim) - upstream for the vault plugin spec
- [MeanderingProgrammer/render-markdown.nvim](https://github.com/MeanderingProgrammer/render-markdown.nvim) - upstream for the markdown rendering spec
- [sxyazi/yazi](https://github.com/sxyazi/yazi) and the [Yazi docs](https://yazi-rs.github.io/docs/) - file manager upstream and configuration reference
- [GNU Stow manual](https://www.gnu.org/software/stow/manual/stow.html) - symlink management and package structure
- [dkms-project/dkms](https://github.com/dkms-project/dkms) and dkms(8) - DKMS, including its `/etc/dkms` overrides
- [NVIDIA/open-gpu-kernel-modules](https://github.com/NVIDIA/open-gpu-kernel-modules) - the open kernel modules behind `nvidia-open-dkms`, the DIFR issue and its pending fix
- [Linux Magic System Request Key Hacks](https://docs.kernel.org/admin-guide/sysrq.html) - SysRq keys and the `kernel.sysrq` bitmask

## Intentional Deviations

### Dotfile Management

- Omarchy has no dotfile manager; EyrArcHy deploys its packages with GNU Stow, using `--no-folding` so managed parents stay real directories and only files are links. Deployment, cleanup and recovery are guarded against taking over or deleting anything the clone cannot prove it owns ([setup](docs/setup.md)).
- Files shared with EyrWSL are byte-identical twins, checked locally and in CI ([operations](docs/operations.md#make-targets)). `/omasync` owns reference-clone maintenance and upstream comparison.

### Bash

- `.bashrc` opens with the upstream seed preamble (`/usr/share/omarchy/default/bashrc`), kept verbatim except for the seed's closing placeholder comment ("Add your own exports, aliases, and functions here" and its example alias), which the `# Personal overrides` section replaces; Omarchy writes to `.bashrc` reach the repo file through the stow symlink.
- Omarchy's six AI launch aliases `c`, `cx`, `cy`, `ic`, `ix`, and `icx` load unchanged, without an `unalias` override. Stock `c`/`cx`/`cy` select OpenCode/Claude Code/Codex respectively; `ic`/`ix`/`icx` keep their stock `tdl` recipes. The `cc`/`oc` selectors belong only to `hdw`, which starts the clients with their normal permission prompts, without the stock aliases' auto-approval flags (`opencode --auto`, `claude --permission-mode auto`); stock `cx` and `hdw cc` both start Claude Code. Both launch paths use normal client configuration, including inside generated shells; `hdw` is not an isolated profile.
- `y()` is added for Yazi cd-on-exit support. Yazi is not part of Omarchy.
- `hdw <cc|oc> [-c]` creates and focuses a new workspace inside an already-running Herdr using the caller's current physical directory, not an inferred Git root. A populated tab or inactive source workspace is allowed with valid pane identity and selected-tab context; repeated calls and generated bottom-right-shell chaining each create another workspace. AI stays full-height left, Neovim above a shell equally stacked right, with equal columns and AI focus. Commands are `claude` or `opencode`; `-c` uses `claude -c` or `opencode -c`. This geometry intentionally differs from Omarchy's `hdl` recipe.
- Existing names/layouts remain untouched apart from normal global workspace focus. New naming stays with Herdr, with no `--label` or rename/metadata writes; the new default tab displays positional `1`. Bare `hdw` is usage. There is no workspace reuse, server startup, client attachment or roots registry. Old state/recovery files, including `${XDG_STATE_HOME:-$HOME/.local/state}/hdw/roots`, remain untouched and unused. Native Herdr controls own workspace/tab navigation.
- Cooperating calls are serialized; caller identity, pre-creation workspace inventory, the new root's opaque terminal identity, exact membership and complete geometry are checked before input. Cleanup may close only proven new split panes before possible input, never any workspace/tab/root/caller. A new workspace/root always remains on failure; possible input or uncertain ownership preserves remaining state with original/new recovery context. These are failure-preserving multi-call workflows, not server-side atomic transactions.
- `hdw` is additive; it and its declared tests/fixture are byte-identical twins with EyrWSL. Omarchy's Herdr recipes, including `hdl`/`hdlm`, are neither copied nor overridden. Custom `tdw` is not loaded or shipped. Omarchy retains the installed tmux package, native configuration/functions and launch binding; no refresh or session change is needed for retirement. Repository tests and CI have no tmux prerequisite.

### Hyprland

- `bindings.lua` carries the personal keybinding overrides, loaded after the Omarchy defaults through the Omarchy-owned `~/.config/hypr/hyprland.lua` require chain. No defaults are replicated.
- `monitors.lua` is tracked: the GU605C panel at `2560x1600@240`, scale 1.6, and `GDK_SCALE=2`. `hl.env` values reach the compositor and its direct spawns on reload; uwsm-launched clients pick them up at session start.
- The twelve default web-app bindings (ChatGPT, Grok, Calendar, Email, New email, YouTube, WhatsApp, Google Messages, Google Photos, Google Maps, X, X Post) are retired via `hl.unbind`; the personal `SUPER ALT` web-app set replaces them (Claude, Basecamp, ChatGPT, GitHub, LinkedIn, CFI, Fastmail, Proton, Teams, WhatsApp, X, YouTube).
- `SUPER SHIFT A` launches the AppImages manager, taking the key from the default ChatGPT web app.
- `SUPER SHIFT C` launches the ChatGPT desktop app (`omarchy-install-ai-chatgpt`, launch-or-focus on class `chatgpt`), reusing the retired Calendar key and labeled `ChatGPT (app)` in the binding menu. `SUPER ALT C` opens `https://chatgpt.com` as a web app, labeled `ChatGPT (web)`.
- `SUPER ALT B` opens Basecamp at `https://launchpad.37signals.com`, the generic target used by the installed Basecamp desktop launcher; no account/project URL is embedded.
- The native grouping controls remain unshadowed: `SUPER G` toggles window grouping, and `SUPER ALT G` moves the active window out of its group. Gmail has no personal shortcut.
- The preinstalled app and TUI bindings (Music, Docker, Signal, Obsidian, Omawrite, Passwords, Herdr, Tmux) stay on Omarchy defaults.
- `input.lua` is tracked: `kb_layout = "us,ara"` with the Left Alt + Right Alt toggle (`grp:alts_toggle`; `kb_options` replaces the default string, so it restates the compose and caps settings), and touchpad `natural_scroll = true`.
- `looknfeel.lua` is tracked: `gaps_in = 3`, `gaps_out = 6` (Omarchy defaults are 5 and 10), and `rounding = 6` with `rounding_power = 3` (the solitude theme's values; the Omarchy default is 0). User `looknfeel.lua` loads after the active theme's Hyprland fragment, so these hold under any theme; the Quickshell shell mirrors `decoration:rounding` into its menu, bar-item, OSD, and notification radii. The bar body slab itself never rounds; the window-no-gaps toggle forces rounding 0 while active.
- All other Hyprland config (`hyprland.lua`, `autostart.lua`) is Omarchy-owned and untracked.

### Neovim

- `omarchy-nvim` owns the base Neovim config. This repo adds vault plugin specs and contextual Git-review mappings without editing the base or installed plugin caches.
- `obsidian.lua` configures obsidian.nvim against the vault at `~/Projects/vault` (override with `OBSIDIAN_VAULT`), including slug-rename and promote workflows that shell out to the vault's `normalize.py`, plus confirm-prompted delete workflows.
- `render-markdown.lua` adds visual markdown rendering; a companion, not required by obsidian.nvim.
- `git-review.lua` overrides only Snacks `gd`, `gD`, and `gs` review mappings, choosing the current file/directory or Neo-tree selection's Git root on each invocation, resolving symlink targets and supporting linked worktrees. Empty/special non-explorer buffers use window cwd; a known non-Git target warns without falling back to an unrelated repository. No global/window directory change is introduced. The spec and mocked regression suite are byte-identical twins with EyrWSL.
- Runtime dependencies beyond the base install: `ripgrep`, `python3`, and `wl-clipboard`, all present on Omarchy.
- The spec carries a WSL-guarded `open.func` override that routes URIs through Windows interop; it is inert on Omarchy, where the default `vim.ui.open` applies. Both repos track byte-identical copies of the spec.
- `theme.lua` in `~/.config/nvim/lua/plugins/` stays Omarchy-managed by the theme system and is not tracked here.

### Yazi

- Added entirely. Yazi is not part of Omarchy.
- `yazi.toml` carries local layout and behavior choices: ratio `[2, 4, 4]`, hidden files shown, directories sorted first, `sort_by = "natural"`, and `linemode = "size"`. Tracked as a byte-identical twin with EyrWSL.
- No theme file is tracked; the Omarchy theme pipeline does not cover Yazi, which runs its built-in default theme over the terminal's themed palette.

### Host (GU605)

`system/` mirrors paths under `/` for this laptop, an ASUS ROG Zephyrus G16 GU605CR whose RTX 5070 Ti Laptop GPU drives the internal panel directly (display MUX in dGPU mode, kept for gaming). Stow never links these files: H installs them as root-owned copies ([setup](docs/setup.md#5-host-system-files)), because DKMS runs the script as root and a link into the user-writable clone would let the clone change what root runs. `make verify` checks the installed copies.

- `etc/sysctl.d/99-sysrq.conf` sets `kernel.sysrq = 184`, enabling the task-dump, sync, read-only remount and reboot keys where systemd's default allows only sync; Omarchy sets none. A frozen desktop can then log its blocked tasks and reboot with filesystems synced and read-only, instead of a forced power-off. [Operations](docs/operations.md#desktop-freeze) holds the keys.
- `etc/dkms/nvidia.conf` is a DKMS override (dkms(8), DKMS.CONF OVERRIDES) whose `PRE_BUILD` runs `etc/dkms/nvidia/nvidia-difr-patch` on DKMS's fresh copy of the `nvidia-open-dkms` source at every build, for driver and kernel updates alike. The script applies `etc/dkms/nvidia/pr1286.patch`, the two commits of NVIDIA's open [PR #1286](https://github.com/NVIDIA/open-gpu-kernel-modules/pull/1286), only when the whole patch applies with exact context; otherwise the build stays stock. Each outcome is logged under the journal tag `nvidia-difr-patch`, `/usr/src` stays as packaged, and `make verify` fails while the loaded `nvidia-modeset` lacks the patch.
- Reason for the override: the driver's DIFR (Display Idle Frame Refresh) prefetch worker can wait without a timeout in `nvWriteGpEntry` while holding the NVKMS power-management lock, so Hyprland's next modeset blocks and the desktop stays frozen until a forced power-off ([#1289](https://github.com/NVIDIA/open-gpu-kernel-modules/issues/1289)). The driver has no switch to disable DIFR. The patch bounds the wait at 3 s and resets the prefetch channel after a copy-engine fault. [Maintenance](docs/maintenance.md) tracks its removal.

## Out Of Scope

The following do **not** belong in EyrArcHy:

- Shared Linux baseline configs (out of scope)
- WSL or Windows-specific behavior (belong in EyrWSL)
- AI-client configuration and agent workflow policy
- The vault itself, its scripts, or its sync (belong to the vault project)
- Omarchy system bindings, window rules, or desktop defaults (belong in Omarchy)

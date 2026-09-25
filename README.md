# EyrArcHy

Personal overrides for an installed [Omarchy](https://github.com/omacom/omarchy) desktop, deployed with [GNU Stow](https://www.gnu.org/software/stow/). Omarchy keeps its defaults; EyrArcHy loads after them and changes only what needs to differ, with every difference and its reason in [DEVIATIONS.md](DEVIATIONS.md).

## What You Get

| Package | Adds |
| --- | --- |
| `bash/` | Personal Bash additions on top of Omarchy's, a Yazi cd-on-exit function, and `hdw`, which opens an AI client, Neovim and a shell as a new [Herdr](https://herdr.dev) workspace |
| `hypr/` | Hyprland keybindings, display, keyboard layout and appearance overrides |
| `nvim/` | Neovim plugin specs for an Obsidian-style vault and repository-aware Git review, on top of Omarchy's Neovim setup |
| `yazi/` | [Yazi](https://yazi-rs.github.io) file-manager configuration, using the terminal's theme |

## Requirements

A working Omarchy installation, plus Yazi (`sudo pacman -S yazi`). The vault workflow expects notes at `~/Projects/vault` (or `OBSIDIAN_VAULT`).

## Quick Start

```bash
git clone https://github.com/peregrinus879/eyrarchy.git ~/Projects/eyrie/eyrarchy
cd ~/Projects/eyrie/eyrarchy
make dry-run   # preview; resolve any conflict first
make stow      # deploy
make verify    # repository and deployment checks
```

The deployed clone is live configuration, so keep it in place; [setup](docs/setup.md) covers conflicts, Git identity, GitHub access, moves and recovery after Omarchy resets its configuration. Inside Herdr, `hdw cc` opens Claude Code, Neovim and a shell as a new workspace; [operations](docs/operations.md) covers daily use.

## Documentation

| Need | Read |
| --- | --- |
| Install, move or recover | [Setup](docs/setup.md) |
| Daily use, checks and Make targets | [Operations](docs/operations.md) |
| What differs from Omarchy, and why | [DEVIATIONS.md](DEVIATIONS.md) |
| Keys, commands and workflows, offline | [EyrAgents workspace guide](https://github.com/peregrinus879/eyragents/blob/main/docs/workspace-guide.html) (download the raw file) |
| Open work | [Maintenance ledger](docs/maintenance.md) |
| Reconcile with upstream Omarchy | [omasync](.agents/skills/omasync/SKILL.md) |
| Rules for agents changing this repository | [AGENTS.md](AGENTS.md) |

Companion repositories: [EyrWSL](https://github.com/peregrinus879/eyrwsl) brings the same Omarchy-derived terminal environment to Arch Linux on WSL 2, sharing several files byte for byte, and [EyrAgents](https://github.com/peregrinus879/eyragents) holds the shared AI harness.

## License

[MIT](LICENSE). Built on Omarchy.

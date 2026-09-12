# EyrArcHy

Personal shell, desktop, and editor customizations for an existing [Omarchy](https://github.com/omacom/omarchy) installation, deployed with [GNU Stow](https://www.gnu.org/software/stow/).

EyrArcHy layers targeted overrides onto Omarchy. It follows the installed defaults and keeps intentional differences in [DEVIATIONS.md](DEVIATIONS.md).

## What Is Included

- Bash additions and `hdw`, a three-pane native Herdr workspace helper.
- Personal Hyprland keybindings, display, input, and appearance overrides.
- Additive Neovim plugins for vault work and contextual Git review.
- Yazi configuration.

Omarchy owns the base desktop, themes, native launch recipes, and tmux. EyrAgents supplies the shared AI harness.

## Package Layout

These directories are Stow packages. `scripts/`, `tests/`, and `docs/` support the repository itself.

| Package | Contents |
| --- | --- |
| `bash/` | Bash configuration that sources Omarchy defaults, plus personal additions and `hdw`. |
| `hypr/` | Personal Hyprland overrides loaded after the defaults. |
| `nvim/` | Plugin specs added to the Omarchy-managed Neovim base. |
| `yazi/` | File-manager configuration using the terminal's theme. |

## Repository Family

The three repositories share the `Eyr` prefix and normally live under `~/Projects/eyrie/`.

| Repository | Purpose |
| --- | --- |
| [EyrAgents](https://github.com/peregrinus879/eyragents) | Shared guidance, skills, and reviewed Git workflows for Claude Code, Codex, OpenCode, and Hermes Agent. |
| [EyrArcHy](https://github.com/peregrinus879/eyrarchy) | Personal shell, desktop, and editor customizations for an existing Omarchy installation. |
| [EyrWSL](https://github.com/peregrinus879/eyrwsl) | A self-contained Arch WSL terminal environment with Windows integration and mise-managed AI tools. |

## Setup

Use the [setup and recovery guide](docs/setup.md) on a working Omarchy desktop. It covers prerequisites, clone ownership, conflict review, preview, deployment, and recovery after an upstream configuration refresh.

**Keep the deployed clone:** its files supply live configuration. Inspect conflicts and preserve local customizations before stowing.

## Usage

Inside an existing Herdr session, change to your project and run `hdw ha` to open Hermes, Neovim, and a shell in a new workspace. `hdw ha -c` continues Hermes; `cc`, `cx`, and `oc` select the other clients.

See [Native Herdr](docs/operations.md#native-herdr) for layout, selectors, continuation, and recovery behavior, and [Git review](docs/operations.md#git-review) for the contextual Neovim mappings.

Open the [Workspace Guide](docs/workspace-guide.html) in a browser for searchable keys, commands, launch recipes and host notes across the whole workspace. It is a self-contained offline file; on GitHub, download the raw HTML first.

[GitHub setup](docs/setup.md#github-access) uses Omarchy's GitHub CLI and HTTPS. [Operations](docs/operations.md#github-access) covers fresh-client and reboot checks. EyrAgents owns exact commit approval, Push selection, agent execution and verification.

## Verify

`make lint check` runs repository checks. On the Omarchy host, `make verify` also checks deployed configuration and `make twins` compares shared files with EyrWSL. The [operations guide](docs/operations.md#verify) covers fresh-session checks, CI, and exact committed twin pairs.

## Documentation

| Need | Read |
| --- | --- |
| Install, move, or recover the deployment | [Setup](docs/setup.md) |
| Use helpers, verify changes, or perform routine maintenance | [Operations](docs/operations.md) |
| Find workspace keys, commands and everyday workflows | [Offline workflow guide](docs/workspace-guide.html) |
| Understand ownership and intentional differences | [Deviations](DEVIATIONS.md) |
| Find unresolved issues and pending work | [Maintenance ledger](docs/maintenance.md) |
| Reconcile with upstream Omarchy | [omasync](.agents/skills/omasync/SKILL.md) |
| Change the repository with an agent | [AGENTS.md](AGENTS.md) |

## License

[MIT](LICENSE). Built on Omarchy.

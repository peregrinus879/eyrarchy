# Setup

[Overview](../README.md) · [Operations](operations.md)

Use this guide on the Omarchy desktop. For an existing deployment, start with [re-stowing or moving the clone](#re-stow); for upstream overwrites, see [recovery](#recovery-after-omarchy-config-resets).

## Installation

### 1. Prerequisites

Omarchy must be installed and functional.

Install Yazi (not part of Omarchy):

```bash
sudo pacman -Syu --needed yazi
```

### AI Clients

Omarchy owns the desktop client installers and mise wrappers. Hermes has a specialised CLI installer:

```bash
omarchy install hermes cli --now
```

It uses mise's pipx backend with Python 3.13. Hermes Desktop is a separate optional installation whose runtime supersedes the standalone mise CLI. EyrArcHy supplies the workspace selector; [EyrAgents setup](https://github.com/peregrinus879/eyragents/blob/main/docs/setup.md) owns the optional shared harness and sign-in guidance.

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

### Git Identity And Host-Local Settings

EyrArcHy does not deploy a Git package. Stock Omarchy's global Git config contains identity settings but does not create the family’s `config.local` include. Establish that include before configuring the GitHub helper.

As the normal user, create or update the untracked regular file `~/.config/git/config.local` in your editor, preserving any existing settings. It owns the host's `[user]` name and the GitHub no-reply address shown in your account's email settings:

```gitconfig
[user]
    name = YOUR_NAME
    email = YOUR_GITHUB_NOREPLY_ADDRESS
```

Replace the placeholders locally. Check the current include declarations:

```bash
git config --show-origin --get-all include.path
```

If no applicable include already points to this file, review the active host-owned global config and add it once:

```bash
git config --global --add include.path '~/.config/git/config.local'
```

Preserve other includes and settings; do not duplicate an existing equivalent absolute path. Check that ordinary Git actually reads the file, without printing identity values:

```bash
git config --show-origin --name-only --get-regexp '^user\.(name|email)$'
```

Expect both user keys from `config.local`. Review any conflicting repository, conditional or later identity settings locally; retain needed values before removing superseded definitions. `make verify` checks the effective GitHub no-reply identity without printing it. A declared include alone does not establish that its target exists or supplies the intended settings.

### GitHub Access

Omarchy's [development-tools guide](https://github.com/omacom/omarchy/blob/master/manual/18-development-tools.md#github-cli) documents GitHub CLI login. Use its installed `gh` launcher from a normal interactive terminal, after the [host-local Git identity/include setup](#git-identity-and-host-local-settings) above. This is one-time host authentication, separate from Stow and publication approval.

H checks existing login locally with `gh auth status --hostname github.com`. If login is needed, complete the browser flow in that terminal:

```bash
GIT_CONFIG_GLOBAL="$HOME/.config/git/config.local" GH_PATH=gh \
  gh auth login --hostname github.com --git-protocol https --web
```

Then configure Git to use that login:

```bash
GIT_CONFIG_GLOBAL="$HOME/.config/git/config.local" GH_PATH=gh \
  gh auth setup-git --hostname github.com
```

These command-scoped variables keep helper settings in the existing untracked include and store `!gh auth git-credential`, resolving the current executable through the normal trusted PATH instead of a versioned mise directory. Future Git/tool processes need that PATH; launch them from a fresh normal shell after mise updates. The setup command resets helper chains specifically for `github.com` and `gist.github.com`; review an existing custom/account-specific helper choice first. Other hosts retain their configuration.

GitHub CLI uses an OS credential store when available and can fall back to a host-local plaintext file. H checks its reported storage choice locally; credentials stay out of Git and agent reports. Follow Omarchy's native credential-storage model. Its stock default keyring has no separate password and relies on host disk protection; verify the actual host rather than assuming the installer proves encryption. Introducing an encrypted default/login collection affects browsers too, and automatic SDDM login cannot unlock it with a password it never receives. PAM or SSH-agent setup is not a GitHub CLI prerequisite. Preserve existing stores and entries during recovery.

For H's canonical clone, inspect the current fetch/push destinations, then select HTTPS only after confirming it is the intended origin:

```bash
git remote get-url --all origin
git remote get-url --push --all origin
git remote set-url origin https://github.com/peregrinus879/eyrarchy.git
git remote get-url --push --all origin
```

Preserve forks, custom remotes and separately configured push URLs for their own review. Repeat the corresponding exact URL change in H's EyrAgents and EyrWSL clones when intended; do not add broad URL rewrites. The `gh` protocol preference does not rewrite existing origins. Complete the [fresh-client/reboot checks](operations.md#github-access) before claiming routine readiness. References: [login/storage](https://cli.github.com/manual/gh_auth_login), [Git helper setup](https://cli.github.com/manual/gh_auth_setup-git), and [`GH_PATH`](https://cli.github.com/manual/gh_help_environment).

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

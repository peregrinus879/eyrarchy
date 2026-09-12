---
name: omasync
description: Sync personal Omarchy customizations against upstream references, installed defaults, and official docs.
---

# Omasync

Source configs from the installed Omarchy defaults, the reference repos, and official docs, compare against EyrArcHy, and apply changes only where they belong in the personal customizations.

## Sources

Local reference clones live under `~/Projects/quarry/`; `references.txt` names this repo's needs and the family union defines the maintained set. `make refs` creates missing entries only from this repo's manifest, updates existing family-listed clones to exact fetched-upstream parity, and reports but preserves unlisted clones:

- `omarchy/` - main repo for bash, tmux, and general Omarchy defaults; `make refs` keeps it on the upstream default branch, which upstream moves between releases, so pin release comparisons to the installed version's tag (`git show <installed-tag>:<path>`)
- `omarchy-pkgs/` - Omarchy's package build recipes, for package version and dependency questions
- `obsidian.nvim/` - obsidian.nvim upstream for the vault plugin spec

The installed defaults the machine actually runs live under `/usr/share/omarchy` (package-backed). The shipped `omarchy` agent skill (auto-discovered via `~/.claude/skills/omarchy`; package copy at `/usr/share/omarchy/default/agents/skills/omarchy`) is upstream-owned, refreshed with Omarchy updates, and authoritative for desktop-config editing; never fork it into this repo. Upstream URLs, official docs, and descriptions live in `DEVIATIONS.md` (Reference Sources). Unresolved decisions, deferred work, and dated evidence live in `docs/maintenance.md`; sibling coordination lives at `~/Projects/eyrie/eyragents/docs/maintenance.md` and `~/Projects/eyrie/eyrwsl/AGENTS.md`.

## When To Use

- Use this skill when Omarchy or a reference repo changed materially, including after an Omarchy update or a config refresh ran.
- Use this skill when personal customization scope or behavior changed materially.
- Use this skill when you suspect undocumented drift between this repo and its references.
- Review the affected workspace guide sections after a binding/command change or a relevant application/plugin update, including inherited defaults that changed without an owned keymap-file diff.
- Use this skill before broad sync-oriented doc updates.

## Workflow

1. Before reference mutation, run `bash scripts/update-references.sh --dry-run` and review its scope. The preview can query GitHub through `gh api`, but does not fetch or prove upstream parity or absence of incoming conflicts. Obtain H's explicit approval for each new clone or remote repointing, and for any separately proposed destructive resolution; routine preservation-safe refreshes of existing declared clones remain the skill's work within shared authorization. Then run `make refs`. Atomic, non-forced fetches preserve existing local tags and annotations, import new tags, and prune only origin tracking branches; this is not a transaction across clones. Checkout/merge use `--no-overwrite-ignore` to preserve ignored files. Ahead/divergent branches and tag/file conflicts refuse that update; do not force or delete to obtain a pass. Unlisted clones are reported and kept. Resolve failed updates before comparing, without assuming earlier successful updates rolled back. If an approved origin move occurs, align its URL in `references.txt` and `DEVIATIONS.md`. Manifest changes define maintenance scope, not permission to create, repoint or delete unreviewed targets.
2. Compare `bash/.bashrc` against the current Omarchy Bash defaults, in the reference clone under `omarchy/default/` and installed under `/usr/share/omarchy/default/`:
   - the upstream preamble (everything above `# Personal overrides`) against `default/bashrc`, the seed Omarchy installs as `/etc/skel/.bashrc`; it is kept verbatim, so adopt upstream changes to it
   - AI launch aliases (`c`, `cx`, `cy`, `ic`, `ix`, and `icx`) stay sourced unchanged from `default/bash/aliases`, with no `unalias` override. Stock `cx` selects Claude Code, unlike the Codex argument in `hdw cx`; both launch paths load applicable EyrAgents settings, with stock flags only on stock launches
   - the `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS` and `OPENCODE_ENABLE_EXA` exports stay additive unless Omarchy starts setting `OPENCODE_*` variables
   - `y()` is additive (Yazi is not in Omarchy)
   - the sourced `hdw` twin against `default/bash/fns/herdr`: it stays additive, creating/focusing a new workspace in the current physical directory inside an already-running Herdr, with AI-left/Neovim-top-right/shell-bottom-right geometry and AI focus. Valid populated/inactive callers, repeated new workspaces and generated-shell chaining are supported; preserve existing names/layouts apart from global focus. Naming stays native, without `--label`; `cc`/`cx`/`oc`/`ha` are arguments sending full commands, with optional `-c`, not an isolated EyrAgents profile. No reuse/registry/startup/attach behavior. A change lands in EyrWSL in the same session (`make twins`)
   - stock Herdr/tmux functions and bindings remain unchanged, including `hdl`/`hdlm`; tmux stays installed with upstream-owned configuration. Custom `tdw` retirement does not authorize refreshing defaults or resetting sessions
3. Compare `hypr/.config/hypr/bindings.lua` against the installed defaults at `/usr/share/omarchy/default/hypr/bindings/` (`applications.lua` carries the app and web-app set) and the user seed at `/usr/share/omarchy/config/hypr/bindings.lua`; the shipped `omarchy` skill owns the binding API, inspection commands, and validation loop:
   - every `hl.unbind` target must still match a default chord, and personal chords must not collide with new defaults
   - verify live registration by description and modmask via `hyprctl binds`; Omarchy registers Lua bindings as opaque `__lua` dispatchers, so exec strings never appear there
   - the file stays personal overrides only; defaults are never replicated
   - `make verify` runs `scripts/check-bindings.sh` for the unbind-target and collision assertions
4. Compare `yazi/.config/yazi/yazi.toml` against official Yazi docs, and the `nvim/` plugin specs against `obsidian.nvim/` and the render-markdown.nvim README
5. App parity sweep: diff `pacman -Qe` against the installed default manifest (`/usr/share/omarchy/install/omarchy-base.packages` plus hardware conditionals) and the optional installers (`omarchy-install-*`); classify each extra as personal, optional-installed, or retired survivor, and account for provider resolution (`extra/neovim` satisfies the `nvim` entry)
6. Tool-path integrity: compare Omarchy-owned launchers in `~/.local/bin` with the installed ordinary and specialised installer definitions, then check `mise ls --current` and actual command resolution. Hermes has its own CLI installer and optional Desktop takeover, so do not classify every launcher as the ordinary wrapper. EyrAgents workflow executables live under `~/.agents/skills/*/scripts`, separately from these launchers. Review any replacement or native-store removal against its actual owner and running executable; directory location alone is not disposal authority
7. Webapp entries: compare the webapp launchers in `~/.local/share/applications` against the current Omarchy default set and remove stale ones with `omarchy-webapp-remove`; personal bindings launch by URL and do not depend on desktop entries
8. Cross-repo coordination: read the sibling ledgers for items assigned to this repo and for stale entries describing this host's environment
9. For each difference, classify it:
   - **Intentional personal customization**: documented in `DEVIATIONS.md`, should stay different
   - **New upstream addition**: added upstream after the last sync, should be reviewed for inclusion
   - **Upstream change to existing config**: modified upstream, needs review
10. Check `git log --format="%h %ad %s" --date=short -- <file>` on the relevant reference repo when you need to determine when a difference was introduced
11. Cross-check differences against `DEVIATIONS.md`. If a difference is not documented there, treat it as a likely upstream change that needs review
12. Apply new upstream additions and changes where they belong in the personal customizations
13. Update each affected documentation owner: README overview, AGENTS invariants, DEVIATIONS rationale, `docs/setup.md` procedures, and `docs/operations.md` usage/verification. Reconcile the workspace guide through `docs/workspace-guide-src/README.md` (Change-coupled maintenance): review added, changed and removed bindings/commands in the affected host/default layers, including Herdr, the outer terminal, Neovim/Neo-tree/vault plugins, Bash and Yazi. Compare installed/version-matched defaults even when no personal mapping file changed; route AI-client interface changes through EyrAgents' `/eyrsync`. Update affected entries, recipes, routing notes and source evidence together, then regenerate both companion guides. A generator/twin pass does not establish semantic or live-keymap accuracy
14. Summarize which changes were adopted, rejected, or intentionally kept different

## Completion Checks

- The overview, invariants, deviations, and affected setup/operation guides reflect the change without duplicating detailed procedures
- Every affected workspace guide section has been reconciled with the owning configuration/source/help, including additions and removals. Both generated outputs are current and the shared authoring twins agree. Unchanged behavior is stated in the change review; unavailable/unauthorized sibling or actual-host checks remain explicit incomplete work at the maintenance owner, not a fabricated completed guide review
- Every retained difference is still documented in `DEVIATIONS.md`
- For custom `tdw` retirement, use guarded `make clean` then `make restow`; `make verify` checks the exact retired endpoint read-only even after its source leaves Git. Preserve/refuse foreign links, regular/special entries and unsafe parents; preserve real directories and user state. Do not broaden retirement into a home cleaner or change restow's ordinary semantics
- For twin changes, `make twins` checks local worktrees; after both commits exist, `twins-pair` checks the exact full `SELF_COMMIT`/`PEER_COMMIT` pair at `SIBLING`. Inputs remain literal data and peer code never executes. Hosted final-pair evidence must name the final published commits; earlier-peer CI is not a substitute or publication authorization
- The final summary distinguishes adopted changes, rejected changes, and intentional retained differences

## Rules

- Present proposed changes to the user before editing; a deliberate exception to shared guidance, because a sync pass touches many files on judgment calls and each adopted upstream change is a deviation decision
- Omarchy, official docs, official package docs, and `DEVIATIONS.md` are the source of truth for default behavior and intentional differences
- Always check all relevant sources, not just one
- Never assume a difference is intentional without verifying it is documented in `DEVIATIONS.md`
- Fetch changeable upstream and package facts at maintenance time instead of caching versions in this skill
- Do not copy Omarchy default behavior into this repo if Omarchy already manages it; the deviation policy extends to skills, so defer to the shipped `omarchy` skill rather than duplicating its content here
- Load the shipped `omarchy` skill before editing any Hyprland or desktop config; keep only repo-specific rules in this file
- Keep the Bash overrides minimal: source Omarchy defaults, only override what needs to change; the OpenCode exports, `y()`, and the sourced `hdw` twin are the whole override set, and the twin changes only together with EyrWSL. Keep stock AI aliases, Herdr recipes and upstream tmux ownership intact. Preserve `hdw`'s pre-input identity/membership/geometry checks: only proven new split panes may be cleaned before possible input, never a workspace/tab/root/caller; retain the new workspace/root on failure and report original/new context without claiming multi-RPC atomicity. Never remove old Herdr state/recovery files as part of helper or `tdw` retirement
- Keep Yazi config standalone since Yazi is not part of Omarchy
- Package removals: the pacman dependency graph is necessary but not sufficient; also check runtime plugin loading (`qt5-wayland`/`qt6-wayland` style), tools exec'd by Omarchy scripts (`grep -r` the `/usr/share/omarchy` tree), and .NET framework targets (`*.runtimeconfig.json` against installed runtimes)
- `qt6-wayland` reads as a pacman orphan but carries Quickshell and every Qt6 app at runtime; never remove `pacman -Qdtq` output as a batch

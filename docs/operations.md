# Operations

[Overview](../README.md) · [Setup](setup.md) · [Open work](maintenance.md)

Run Make targets from the repository root, on the host required by each target.

## Workspace Guide

Open the self-contained [Workspace Guide](workspace-guide.html) in a browser:

```bash
xdg-open docs/workspace-guide.html
```

Daily and All views cover Herdr, the four AI clients, Neovim/Neo-tree, Git review, vault notes, Bash tools and Yazi. The host profile selects outer-terminal controls and host-specific notes. Search, saved keys, copyable launcher commands and printing work offline; source links open online references when selected.

One keybinding is a shortcut; a keymap is the collection. Both belong in this single guide. Its shared source and [maintenance instructions](workspace-guide-src/README.md) live under `docs/workspace-guide-src/`; `make workspace-guide` rebuilds the HTML, `make check` rejects stale output, and `make twins` compares the shared authoring files. Update both companion guides when their shared configuration changes.

Guide reconciliation is part of every in-scope binding or command addition, change and removal. Follow [change-coupled maintenance](workspace-guide-src/README.md#change-coupled-maintenance), including inherited-default changes after application/plugin updates. `/omasync` owns host/default review; EyrAgents' `/eyrsync` owns AI-client review. The checks verify generated/twin consistency, not the accuracy of live keymaps.

## Native Herdr

Launch Herdr independently with `herdr` or Omarchy's native `SUPER CTRL RETURN` binding. In a shell inside that session, navigate to the desired directory, then run `hdw <cc|cx|oc|ha> [-c]` to create and focus a new workspace:

- `cc` sends `claude`; `-c` uses `claude -c`.
- `cx` sends `codex`; `-c` uses `codex resume --last`.
- `oc` sends `opencode`; `-c` uses `opencode -c`.
- `ha` sends `hermes`; `-c` uses `hermes -c`.

See [AI client setup](setup.md#ai-clients) for Omarchy's Hermes installer and Desktop runtime choice. EyrAgents owns the harness. `hdw` supplies no YOLO flag; Hermes continuation may restore its recorded cwd after launch.

`hdw` uses the current physical directory, not an inferred Git root. AI occupies the full-height left column, Neovim the top-right and a shell the bottom-right, with equal columns, equally stacked right panes and AI focus. The caller may be in a populated tab or an inactive workspace, but its pane identity and selected-tab context must be valid. Every call creates a separate workspace, even in the same directory; change directory in a generated bottom-right shell and call again to open the next workspace. Bare `hdw` prints usage; outside-Herdr or invalid-context calls refuse.

Existing workspace/tab names and layouts stay intact, apart from normal global workspace focus moving to the new workspace. New names are Herdr's defaults, with no `--label` or rename/metadata writes; the new default tab displays positional `1` ([Herdr 0.8.2 display-name implementation](https://github.com/herdrdev/herdr/blob/v0.8.2/src/workspace.rs)). There is no workspace reuse, roots registry, server startup or client attachment. Old `hdw` state and recovery files remain unused and untouched. Native controls still own navigation: the shipped `Ctrl+Space` prefix followed by `c` opens a tab and `Shift+C` opens a workspace; in-app help is authoritative for personal keymap changes.

Cooperating calls are serialized. Caller identity, the pre-creation workspace inventory, the new root's opaque terminal identity, exact membership and complete geometry are checked before tool input. Cleanup may close only proven new split panes before input, never any workspace, tab, root or original caller. A newly created workspace/root always remains for inspection on failure; possible input or uncertain ownership preserves remaining state. Inspect the reported original/new recovery context before manual action. This is not an atomic multi-RPC transaction.

The `cc`/`cx`/`oc`/`ha` selectors are arguments, not shell aliases. Stock Omarchy `c`/`cx`/`cy` select OpenCode/Claude Code/Codex respectively, so stock `cx` is Claude Code while `hdw cx` is Codex; `ic`/`ix`/`icx` retain their stock `tdl` recipes. These aliases also remain available in `hdw`-created shells. `hdw` sends full commands without stock shortcut flags, but it is not an isolated profile: both launch paths load applicable EyrAgents settings. Stock Herdr/tmux functions, bindings and packages remain unchanged.

## GitHub Access

After [host-local setup](setup.md#github-access), open a fresh normal terminal in this clone and check:

```bash
command -v gh
git remote get-url --push --all origin
gh repo view peregrinus879/eyrarchy --json nameWithOwner,viewerPermission
GIT_TERMINAL_PROMPT=0 GH_PROMPT_DISABLED=1 \
  git -c credential.interactive=false ls-remote --exit-code --refs origin refs/heads/main
```

Expect the canonical HTTPS origin, intended repository/access level, and a branch ID without another credential prompt. Public Git refs can be read anonymously; that result alone does not establish authenticated Git writes. H checks helper configuration locally, without displaying credentials, and the next independently approved publication supplies real write-path evidence.

At the next H-chosen reboot, repeat these checks after normal boot/login, before manually unlocking a keyring or refreshing credentials. Start new Claude Code, Codex, OpenCode and Hermes processes from that fresh shell. Confirm prompt absence explicitly, including normal browser startup; a check repaired in one terminal does not establish startup persistence. Keep missing evidence in [maintenance](maintenance.md#deferred-work).

Authentication readiness is separate from EyrAgents' exact commit approval, exact Push selection, agent execution and verification. Codex retains its restrictions and hands publication to a separately launched network-capable primary with fresh approval. Credential access carries the account's permissions, not read-only isolation. A locked store, expired login or wrong account requires H-local recovery through the standard CLI/native UI. Neither TLS/host-trust weakening nor dumping tokens is a recovery step. Follow the setup command's host-local configuration target when refreshing Git helper settings after an update.

## Git Review

After stowing, start a fresh Neovim session once to load `git-review.lua`. `Space g d` shows staged and unstaged hunks, `Space g D` compares against origin, and `Space g s` shows status including untracked files. Each invocation uses the current file/directory's Git repository or the selected Neo-tree item, falling back to the displayed tree root when no item path exists. Symlink targets and linked worktrees are supported; switching files between repositories switches the review target without changing any editor directory.

Empty or special non-explorer buffers use the current window's directory. A known non-Git file or explorer target warns instead of silently reviewing another repository. No recurring `:cd`/`:lcd` is needed for repository files or selected repository folders. Keep the ordinary picker review controls; do not use its stage/restore actions unless intended.

## Verify

Layout fixtures use fake agents and a Python-backed Herdr model. They cover new-workspace creation, populated/inactive callers, repeated calls and generated-shell chaining, ownership, failure recovery and concurrency without using running user workspaces or real agents. Real-Herdr, rendered UI and actual-host evidence remain separate; see [active limitations](maintenance.md#active-limitations). Preparation fixtures cover real old Stow deployments followed by pending/post-pull retirement, exact ownership, refusal and read-only verification. Repository checks do not require or invoke tmux.

After stowing or changing owned packages:

- Run `make lint` and `make check` after any change; both are repository-only (ShellCheck; bash, Lua, and TOML syntax; the `tests/` fixtures). GitHub Actions runs them on pushes to `main` and pull requests, plus an exact committed twin-pair check against EyrWSL's fetched default branch.
- Run `make verify` from the repo root on the Omarchy host after stowing or changing owned packages: `lint`, `check`, and `twins`, then retired-endpoint absence, live source existence, the stowed symlinks (compared by resolved path), every managed parent being a real directory, the Git identity (it must resolve to a GitHub no-reply address; the value is not printed), every `hl.unbind` target and personal chord in `bindings.lua` against the installed Omarchy defaults, and Hyprland config errors.
- Confirm `SUPER G` toggles window grouping and `SUPER ALT G` moves the active window out of its group. `SUPER ALT B` opens Basecamp, `SUPER ALT C` opens ChatGPT web, and `SUPER SHIFT C` launches or focuses the ChatGPT desktop app. Gmail has no replacement shortcut; [Hyprland deviations](../DEVIATIONS.md#hyprland) own the launch targets and default-key exceptions.
- Start a fresh shell and confirm `printenv OPENCODE_DISABLE_CLAUDE_CODE_SKILLS` and `printenv OPENCODE_ENABLE_EXA` each print `1`; non-interactive OpenCode launchers must supply both variables themselves.
- Start a fresh shell and confirm `type y` shows the Yazi cd-on-exit function.
- Start a fresh shell and confirm `alias c cx cy ic ix icx` matches Omarchy's installed defaults; `alias claude` should still report no alias. Stock shortcuts keep their own launch flags and applicable EyrAgents settings; do not confuse stock `cx` with the `hdw cx` argument.
- Confirm `type hdw` shows the new-workspace helper and a fresh shell no longer loads custom `tdw`. In a disposable Herdr session/project, check the [Native Herdr](#native-herdr) layout, full agent/continuation commands, native names and AI focus. Repeated calls, including from a populated caller, a valid inactive source workspace and a generated bottom-right shell, must each create a new workspace; existing names/layouts must stay intact apart from global focus. Bare invocation shows usage; outside-Herdr and invalid-context calls refuse. Do not experiment in an existing working session.
- On helper failure, inspect the original/new pane/tab/workspace context before manual cleanup. The new workspace/root must remain; only verified new split panes may be removed before possible input, never any workspace/tab/root/caller. Never delete unfamiliar panes or retained state/recovery files. Omarchy's stock Herdr/tmux functions, configuration and launch bindings remain upstream-owned and unchanged.
- `hl.env` values in the tracked hypr files reach the compositor on reload but reach uwsm-launched clients only at session start; after first adopting the hypr package on a running session, log out and back in once.
- Run `yazi` and confirm the layout ratio and sort order match the config.
- Open a vault note in Neovim and confirm obsidian.nvim loads (`<leader>oo` opens the note switcher).
- Check Git review from files in two repositories and from a selected Neo-tree repository folder while the editor was launched in their non-Git parent; `Space g d` and `Space g s` must target the selection without changing `:pwd`.

CI runs `make lint`, `make check`, and `twins-pair` on pushes to `main` and pull requests, using the peer default branch for normal runs. Manual workflow dispatch accepts an explicit full `peer_commit` only with `peer_reviewed=true`; it fetches peer objects without executing peer code and records both actual commits. This attestation is not publication authorization. For coordinated changes, verify the final published pair explicitly after both commits are available; a green check against an earlier peer is not final-pair evidence. Local `make twins` remains a worktree convenience check that can skip a missing sibling.

CI uses the official `archlinux:base` container with a full signed-package upgrade, matching the Arch userspace of both supported hosts. `ubuntu-latest` supplies only GitHub's VM. Checks run as an unprivileged `ci` user with explicit Bash, a private temporary directory and container process reaping; checkout credentials are not persisted. CI does not perform or attest deployment to Omarchy or WSL.

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

Periodically, review the local reference repos and official docs for upstream changes to overridden items, sync with `/omasync` or a manual comparison, and confirm every intentional difference is still documented in `DEVIATIONS.md`. Unresolved decisions, deferred work, active limitations, and dated evidence live in [docs/maintenance.md](maintenance.md).

# Operations

[Overview](../README.md) · [Setup](setup.md) · [Deviations](../DEVIATIONS.md) · [Open work](maintenance.md)

Run Make targets from the repository root, on the host each target requires.

## Workspace Guide

The [EyrAgents workspace guide](https://github.com/peregrinus879/eyragents/blob/main/docs/workspace-guide.html) is one offline page of Herdr, AI-client, Neovim, Git-review, vault, Bash and Yazi controls. Open it and select **Omarchy** (on GitHub, download the raw file first):

```bash
xdg-open "$HOME/Projects/eyrie/eyragents/docs/workspace-guide.html"
```

EyrAgents owns the guide and its [maintenance contract](https://github.com/peregrinus879/eyragents/blob/main/docs/workspace-guide-src/README.md). A key or command change here includes reconciling the guide's `host-reference.json` there; `/omasync` reviews host facts and `/eyrsync` client facts.

## Native Herdr

Start Herdr with `herdr` or Omarchy's `SUPER CTRL RETURN`. In a shell inside it, change to the project directory and run `hdw <cc|oc> [-c]`:

| Command | Opens |
| --- | --- |
| `hdw cc` | Claude Code (`claude`) |
| `hdw cc -c` | Claude Code, continuing the last session (`claude -c`) |
| `hdw oc` | OpenCode (`opencode`) |
| `hdw oc -c` | OpenCode, continuing the last session (`opencode -c`) |

Each call creates and focuses a new workspace in the current directory: the AI client full-height on the left, Neovim top-right and a shell bottom-right, with the AI client focused. Call it again from any shell, including the new bottom-right one, to open another workspace; existing workspaces keep their names and layouts. Herdr's own controls handle navigation (`Ctrl+Space`, then `c` for a tab or `Shift+C` for a workspace). [DEVIATIONS.md](../DEVIATIONS.md#bash) holds the full contract, including how a failed call preserves state for inspection.

**Claude Code background sessions.** A session sent to the background with `/bg`, or with *Move to background and exit*, keeps running under Claude Code's own daemon, independently of Herdr. While it runs, `claude -c` refuses with `Your most recent conversation is running in the background (session <uuid>)`. `claude agents` lists such sessions; `claude attach <id>` reopens one with its tasks intact, and `claude stop <id>` followed by `claude -c` continues it in the foreground.

Omarchy's own launch aliases (`c`, `cx`, `cy`, `ic`, `ix`, `icx`) are unchanged and remain available in `hdw` shells; `cc` and `oc` are `hdw` arguments, not aliases.

## Git Review

Start a fresh Neovim session once after stowing. `Space g d` shows staged and unstaged hunks, `Space g D` compares against origin, and `Space g s` shows status including untracked files. Each uses the Git repository of the current file or directory, or of the selected Neo-tree item, without changing Neovim's working directory; a file outside any repository warns instead of reviewing another one. [DEVIATIONS.md](../DEVIATIONS.md#neovim) holds the full contract.

## GitHub Access

After [setup](setup.md#github-access), confirm from a fresh terminal in this clone:

```bash
git remote get-url --push --all origin
gh repo view peregrinus879/eyrarchy --json nameWithOwner,viewerPermission
GIT_TERMINAL_PROMPT=0 GH_PROMPT_DISABLED=1 \
  git -c credential.interactive=false ls-remote --exit-code --refs origin refs/heads/main
```

Expect the HTTPS origin, the intended access level, and a branch ID with no credential prompt. Public refs can be read anonymously, so only an approved push proves write access. After a reboot, repeat the check before unlocking a keyring by hand, to confirm access survives a normal login. A locked store, expired login or wrong account is recovered locally through the GitHub CLI; never weaken TLS or dump tokens.

## Verify

After any change:

```bash
make lint check   # ShellCheck 0.11.0 or newer; Bash, Lua and TOML syntax; the fixture tests
```

On Omarchy, after stowing or changing a package, `make verify` runs `lint`, `check` and `twins`, then checks the deployment: retired links are gone, every managed parent is a real directory, each link resolves into this clone, the Git identity is a GitHub no-reply address (without printing it), every `hl.unbind` target exists in Omarchy's defaults and no personal chord collides with a default that is still bound, and Hyprland reports no configuration errors.

Then check by hand, in fresh sessions:

- `type y` shows the Yazi cd-on-exit function and `type hdw` the workspace helper;
- `alias c cx cy ic ix icx` matches Omarchy's defaults, and `alias claude` reports no alias;
- in a disposable Herdr session, `hdw` produces the layout above, repeated calls each create a new workspace, bare `hdw` prints usage, and calls outside Herdr refuse;
- `SUPER G` toggles window grouping, `SUPER ALT G` moves a window out of its group, `SUPER ALT B` opens Basecamp, `SUPER ALT C` opens ChatGPT on the web and `SUPER SHIFT C` the ChatGPT app;
- `yazi` shows the configured layout and sort order;
- a vault note loads obsidian.nvim (`<leader>oo` opens the note switcher);
- Git review targets the selected repository when Neovim was started in a non-Git parent directory, without changing `:pwd`.

After first adopting the `hypr` package on a running session, log out and back in once: `hl.env` values reach applications started by uwsm only at session start.

The fixture tests model Herdr, Stow and the Omarchy defaults in fake homes; they do not replace a check on the real host. GitHub Actions runs `make lint check` and an exact twin-pair check against EyrWSL's default branch on every push to `main` and every pull request, in an `archlinux:base` container as an unprivileged user; it does not deploy to a host.

## Make Targets

| Target | Does |
| --- | --- |
| `make dry-run` | Preview Stow's links |
| `make stow`, `make restow`, `make unstow` | Deploy, redeploy or remove the packages (Omarchy only) |
| `make clean` | Guarded preparation: remove only folded, dangling or retired links this clone owns; refuse on anything else (Omarchy only) |
| `make recover` | `clean` then `restow`, after an Omarchy configuration reset (Omarchy only; [setup](setup.md#recovery-after-omarchy-config-resets)) |
| `make lint`, `make check`, `make test` | Repository checks and the fixture tests |
| `make verify` | Repository and deployment checks (Omarchy only) |
| `make twins` | Compare the twin files with the EyrWSL clone (`SIBLING`, default `~/Projects/eyrie/eyrwsl`); a missing sibling is skipped |
| `make twins-pair SELF_COMMIT=<sha> PEER_COMMIT=<sha> SIBLING=<path>` | Compare the twin files at two exact full commit IDs, without running the peer's code |
| `make refs-plan`, `make refs` | Preview, then refresh the reference clones in [`references.txt`](../references.txt) |

`make stow`, `restow` and `recover` finish with a forced Hyprland reload and a configuration-error check when run inside Hyprland. Deployment goals in one Make invocation run serially, even under `make -j`; this is not a transaction against disk failure or a second concurrent deployment.

**Twin pairs in CI.** A manual workflow run accepts an explicit `peer_commit` only with `peer_reviewed=true`, fetches the peer's objects without executing its code, and records both commits. For a coordinated change, check the final published pair once both commits are available; a green check against an earlier peer is not evidence for the final pair.

**Reference clones.** Approve a new clone or a remote repointing that `make refs-plan` shows before running `make refs`. The refresh fast-forwards listed default branches to the fetched upstream and refuses branches that are ahead or diverged; its fetch keeps existing local tags, imports new ones and prunes only origin tracking branches, and checkout never overwrites ignored files. It may include the EyrWSL peer when selected, never arbitrary neighboring repositories. Conflicts refuse for separate review, and stale clones are reported and kept.

## Upstream Changes

At each Omarchy package update, run `/omasync` to compare the overridden files with the new defaults and official documentation, confirm every difference is still documented in DEVIATIONS.md, and run `make verify`.

# Maintenance Ledger - EyrArcHy

Unresolved decisions, deferred work, active limitations, and the dated evidence behind them. Durable rules live in `AGENTS.md`, `DEVIATIONS.md`, a skill, a script header, or a test; remove an item here once its rule has moved there.

## Active Limitations

- Git-review context (2026-09-06): source checked on Neovim 0.12.5, Snacks `882c996`, LazyVim `c10948c`, and installed Neo-tree `0bd0eea`; the WSL-pinned Neo-tree `5e076e5` has the same inspected state-manager API. The managed `gd`/`gD`/`gs` mappings use per-call file/explorer context, not a global directory change; direct picker API calls and other mappings retain upstream behavior. Omarchy deployment/verify passed; 39 mocked cases and an isolated installed-Neovim/Snacks/Git run with ten picker cases and five refusal cases passed. H then confirmed a fresh editor's diff/status work across repositories without manual directory changes. This is not WSL host evidence. Revalidate after picker cwd, root detection, Neo-tree state, or LazyVim mapping changes. Upstream context reports include [Snacks #1639](https://github.com/folke/snacks.nvim/issues/1639) and the distinct subdirectory-jump fix [#2483](https://github.com/folke/snacks.nvim/issues/2483); neither alone proves installed behavior.
- Omarchy's config refresh and reset scripts copy defaults with no symlink awareness (checked against the installed 4.0.2-1 scripts on 2026-09-03; recheck at each omarchy package update): `omarchy-refresh-config`, and `omarchy-refresh-hyprland` through it, `cp -f` the shipped default through each stowed link into the repo working tree, leaving the link in place and a timestamped `.bak` of the personal content beside it; `omarchy-reinstall-configs` replays `/etc/skel` over `$HOME` with `cp -af`. Follow README's exact-path/hunk review and preservation-first recovery, not blanket restoration or removal. Regular-file replacements now cause unchanged preparation refusal; a pathname alone cannot establish disposable clobber content.
- Native Herdr workspace limits (2026-09-08): `hdw` creates/focuses a new workspace from valid caller context, including populated tabs and inactive source workspaces. Identity/membership/geometry checks and serialization protect cooperating calls, not a server-side atomic transaction or a malicious server. Cleanup may close only verified new split panes before possible input, never any workspace/tab/root/caller; retain every newly created workspace/root on failure and report original/new context. Source/mock checks and 22 real Herdr 0.8.2 cases passed for the current helper in proved private namespaces with dummy tools and real pane PTYs. Coverage includes global-focus handling, generated-shell chaining, cooperating calls, physical cwd, native names, even/odd/offset/gapped geometry, and mutation-free refusals; forced-timeout cleanup left no survivors. This is not attached-UI, real-agent or WSL host evidence. Revalidate after launcher, Herdr CLI/schema, identity, focus or layout changes.
- Deployment preflight does not roll back disk I/O failure or serialize independent Make processes. `twins-pair` attests exact committed twin blobs, not deployment or publication authorization; CI must name the final published pair. Revalidate these limits before introducing concurrent deployments or changing the CI pair protocol.

## Open Decisions

- Whether `/omasync` keeps its "present proposed changes before editing" rule as a deliberate exception to shared guidance, under which an implementation request authorizes edits. Upstream sync is judgment-heavy and touches many files, which argues for keeping the rule with its reason stated in the skill.
- Whether to clean the inert leftovers on this host: the pre-quattro `~/.config/hypr/*.conf` set (including the orphaned NVIDIA `envs.conf`), the legacy `~/.local/share/omarchy` tree, the `*.omarchy-upgrade-to-quattro.*.bak` files, and the stale mise wrappers in `~/.local/bin` (`omarchy-refresh-applications` rewrites them in the current form). The active Lua chain reads none of the config leftovers, and the mise install directories precede `~/.local/bin` on `PATH`; cleanup is outside repo ownership.
- Deferred current decision, audit 8: explicit-target/completion-aware, reference-safe vault rename and promotion are not implemented. Keep current note operations and shared Obsidian plugin specs unchanged; revisit only on H's explicit note-workflow request, coordinating both twins and the vault project's own scripts.
- Deferred current decisions, audits 21 and 22: immutable approved deployments and new trust/disclosure tiers are not implemented. Continue live Stow and existing EyrAgents policy; the canonical [EyrAgents decisions](https://github.com/peregrinus879/eyragents/blob/main/docs/maintenance.md#open-decisions) own any future change. This repo remains the Omarchy desktop owner, not the harness or WSL owner.

## Deferred Work

- Reference maintenance host evidence: fixtures do not establish the state of the shared quarry. On the next authorized reference-dependent maintenance pass, preview with `bash scripts/update-references.sh --dry-run`, obtain approval for new clones/repointing, then run the preservation-first update. Confirm exact fetched parity and preservation of local tags and ignored/stale content without disclosing private values. Keep failures explicit; revalidate after updater or Git transport changes and remove this item when the host pass is complete.
- Watch omacom/omarchy#7327 (qt6-wayland install-reason gap from the quattro upgrade, filed from this account, open as of 2026-09-03); this host is repaired (`pacman -D --asexplicit qt6-wayland`), so drop this line when the issue closes.
- Upstream watches, rechecked at each omarchy package update (last 4.0.2-1, 2026-09-03): `tdl` still ends with `select-pane -t "$opencode_pane"` on a variable it never sets (cosmetic focus regression; no local guard is tracked); the planned "dots" user-config preservation feature (`022f6993`, plans only) could overlap this repo's stow approach when it ships.

### Desktop Keybindings

Queued by H on 2026-09-08; not applied. Verify the Omarchy host, current upstream bindings/unbinds, collisions and intended app targets before editing the live configuration.

- Remove the personal `SUPER ALT G` override and restore Omarchy's group-tiling default, including any corresponding unbind that would otherwise suppress it.
- Add `SUPER ALT B` for Basecamp; confirm the intended webapp target rather than invent a project/account URL.
- Add `SUPER ALT C` for the ChatGPT webapp and retain `SUPER SHIFT C` for the installed app. H's intended distinction is Alt for the webapp and Shift for the installed app.

## Revalidation Triggers

- Each omarchy package update (`pacman -Q omarchy`): rerun `/omasync`, recheck every item above that names a version, then run `make verify`.

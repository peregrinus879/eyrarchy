# Maintenance Ledger - EyrArcHy

Unresolved decisions, deferred work, active limitations, and the dated evidence behind them. Durable rules live in `AGENTS.md`, `DEVIATIONS.md`, a skill, a script header, or a test; remove an item here once its rule has moved there.

## Active Limitations

- Workspace recovery limits (2026-09-06): uncatchable termination or an unavailable server can leave a uniquely named pending workspace or roots snapshot. Locks and ownership checks protect cooperating launches, not a server-side atomic layout transaction. Installed Herdr 0.8.2 passed `hdw` cold-create/reuse twice with the actual CLI/server in proven private Bubblewrap mount/PID/network namespaces, network off and fake HOME/XDG/agents/editor; cleanup was verified. This is real isolated Herdr evidence, not attached-UI or real-agent verification, and not a WSL host pass. Check those remaining paths in disposable projects without disturbing existing work; inspect reported recovery identities/snapshots before manual cleanup. Revalidate on launcher or tmux/Herdr RPC/ID changes.
- Omarchy's config refresh and reset scripts copy defaults with no symlink awareness (checked against the installed 4.0.2-1 scripts on 2026-09-03; recheck at each omarchy package update): `omarchy-refresh-config`, and `omarchy-refresh-hyprland` through it, `cp -f` the shipped default through each stowed link into the repo working tree, leaving the link in place and a timestamped `.bak` of the personal content beside it; `omarchy-reinstall-configs` replays `/etc/skel` over `$HOME` with `cp -af`. Follow README's exact-path/hunk review and preservation-first recovery, not blanket restoration or removal. Regular-file replacements now cause unchanged preparation refusal; a pathname alone cannot establish disposable clobber content.
- Deployment preflight does not roll back disk I/O failure or serialize independent Make processes. `twins-pair` attests exact committed twin blobs, not deployment or publication authorization; CI must name the final published pair. Revalidate these limits before introducing concurrent deployments or changing the CI pair protocol.

## Open Decisions

- Whether `/omasync` keeps its "present proposed changes before editing" rule as a deliberate exception to shared guidance, under which an implementation request authorizes edits. Upstream sync is judgment-heavy and touches many files, which argues for keeping the rule with its reason stated in the skill.
- Whether to clean the inert leftovers on this host: the pre-quattro `~/.config/hypr/*.conf` set (including the orphaned NVIDIA `envs.conf`), the legacy `~/.local/share/omarchy` tree, the `*.omarchy-upgrade-to-quattro.*.bak` files, and the stale mise wrappers in `~/.local/bin` (`omarchy-refresh-applications` rewrites them in the current form). The active Lua chain reads none of the config leftovers, and the mise install directories precede `~/.local/bin` on `PATH`; cleanup is outside repo ownership.

## Deferred Work

- Reference maintenance host evidence: fixtures do not establish the state of the shared quarry. On the next authorized reference-dependent maintenance pass, preview with `bash scripts/update-references.sh --dry-run`, obtain approval for new clones/repointing, then run the preservation-first update. Confirm exact fetched parity and preservation of local tags and ignored/stale content without disclosing private values. Keep failures explicit; revalidate after updater or Git transport changes and remove this item when the host pass is complete.
- Coordinated twin CI remains pending: after both final commits are available, validate the explicit reviewed pair using full SHAs and retain both IDs in the hosted evidence. Do not treat a green earlier-peer run as final-pair confirmation or dispatch/publish without H's authorization.
- Watch omacom/omarchy#7327 (qt6-wayland install-reason gap from the quattro upgrade, filed from this account, open as of 2026-09-03); this host is repaired (`pacman -D --asexplicit qt6-wayland`), so drop this line when the issue closes.
- Upstream watches, rechecked at each omarchy package update (last 4.0.2-1, 2026-09-03): `tdl` still ends with `select-pane -t "$opencode_pane"` on a variable it never sets (cosmetic focus regression; no local guard is tracked); the planned "dots" user-config preservation feature (`022f6993`, plans only) could overlap this repo's stow approach when it ships.

## Revalidation Triggers

- Each omarchy package update (`pacman -Q omarchy`): rerun `/omasync`, recheck every item above that names a version, then run `make verify`.

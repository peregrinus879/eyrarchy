# Maintenance Ledger - EyrArcHy

Unresolved decisions, deferred work, active limitations, and the dated evidence behind them. Durable rules live in `AGENTS.md`, `DEVIATIONS.md`, a skill, a script header, or a test; remove an item here once its rule has moved there.

## Active Limitations

- Omarchy's config refresh and reset scripts copy defaults with no symlink awareness (checked against the installed 4.0.2-1 scripts on 2026-09-03; recheck at each omarchy package update): `omarchy-refresh-config`, and `omarchy-refresh-hyprland` through it, `cp -f` the shipped default through each stowed link into the repo working tree, leaving the link in place and a timestamped `.bak` of the personal content beside it; `omarchy-reinstall-configs` replays `/etc/skel` over `$HOME` with `cp -af`. After either, `git restore` the clobbered package files, then run `make recover`.

## Open Decisions

- Whether `/omasync` keeps its "present proposed changes before editing" rule as a deliberate exception to shared guidance, under which an implementation request authorizes edits. Upstream sync is judgment-heavy and touches many files, which argues for keeping the rule with its reason stated in the skill.
- Whether to clean the inert leftovers on this host: the pre-quattro `~/.config/hypr/*.conf` set (including the orphaned NVIDIA `envs.conf`), the legacy `~/.local/share/omarchy` tree, the `*.omarchy-upgrade-to-quattro.*.bak` files, and the stale mise wrappers in `~/.local/bin` (`omarchy-refresh-applications` rewrites them in the current form). The active Lua chain reads none of the config leftovers, and the mise install directories precede `~/.local/bin` on `PATH`; cleanup is outside repo ownership.

## Deferred Work

- Watch basecamp/omarchy#7327 (qt6-wayland install-reason gap from the quattro upgrade, filed from this account, open as of 2026-09-03); this host is repaired (`pacman -D --asexplicit qt6-wayland`), so drop this line when the issue closes.
- Upstream watches, rechecked at each omarchy package update (last 4.0.2-1, 2026-09-03): `tdl` still ends with `select-pane -t "$opencode_pane"` on a variable it never sets (cosmetic focus regression; no local guard is tracked); the planned "dots" user-config preservation feature (`022f6993`, plans only) could overlap this repo's stow approach when it ships.

## Revalidation Triggers

- Each omarchy package update (`pacman -Q omarchy`): rerun `/omasync`, recheck every item above that names a version, then run `make verify`.

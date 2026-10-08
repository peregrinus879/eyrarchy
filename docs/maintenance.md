# Maintenance Ledger

[Overview](../README.md) · [Operations](operations.md)

Open work only. Each item states what is open, why, and what closes it; when an item closes, any lasting rule moves to its owner and the item is removed. Read this ledger before package removals, Omarchy updates or work on a listed item.

## Open Decisions

- **`omasync`'s review-first rule.** The skill presents proposed changes before editing, an exception to global guidance, under which an implementation request authorizes edits. Upstream sync touches many files on judgment calls, which argues for keeping the rule with its reason stated in the skill. Closes with H's decision.
- **Host leftovers from the Omarchy 4 upgrade.** This host keeps inert pre-upgrade files: the old `~/.config/hypr/*.conf` set (including an orphaned NVIDIA `envs.conf`), the legacy `~/.local/share/omarchy` tree, the upgrade's `.bak` files and stale mise wrappers in `~/.local/bin`. Nothing active reads them, and they are outside this repository. Closes when H decides to remove or keep them.
- **Vault note workflows.** Rename and promote do not yet support an explicit target, completion or reference-safe renaming. Closes only on H's request, coordinated across both twins and the vault project's own scripts.

## Limitations Under Watch

| Limitation | Owner | Recheck when |
| --- | --- | --- |
| Omarchy's `omarchy-refresh-config` and `omarchy-reinstall-configs` copy defaults through the stowed links into the clone (checked on 4.0.4-1) | [setup](setup.md#recovery-after-omarchy-config-resets) | each Omarchy package update |
| `hdw`'s checks protect cooperating calls, not a server-side atomic transaction; real Herdr 0.8.2 cases passed in private namespaces, without an attached UI, real agents or WSL | [DEVIATIONS](../DEVIATIONS.md#bash) | the helper, Herdr's CLI or schema, or its layout behavior changes |
| Git review uses per-call file or explorer context (checked on Neovim 0.12.5, Snacks `882c996`, LazyVim `c10948c`, Neo-tree `0bd0eea`; H confirmed it across repositories; related upstream reports: [Snacks #1639](https://github.com/folke/snacks.nvim/issues/1639), [#2483](https://github.com/folke/snacks.nvim/issues/2483)) | [DEVIATIONS](../DEVIATIONS.md#neovim) | picker working-directory, root detection, Neo-tree state or LazyVim mappings change |
| The paired reference updater follows GitHub's canonical name without a pinned project identity, and can repoint `origin` before its dirty check | [operations](operations.md#make-targets) | fixed together in both twins, with rename, reused-ID and dirty-refusal tests |
| Deployment is serial within one Make invocation, not a transaction; `twins-pair` attests committed twin files, not deployment or publication | [operations](operations.md#make-targets) | before concurrent deployments or a CI pair-protocol change |
| The NVIDIA DIFR freeze is held off by the DKMS override carrying [PR #1286](https://github.com/NVIDIA/open-gpu-kernel-modules/pull/1286), still open upstream; the patch applies with exact context to 610.57.04 and 615.71.09 | [DEVIATIONS](../DEVIATIONS.md#host-gu605) | each `nvidia-open-dkms` update ([operations](operations.md#upstream-changes)). Retire the override ([setup](setup.md#5-host-system-files)) with its `system/` files, checks and entries when NVIDIA ships the fix (the journal reports "already contains PR #1286", or a release note covers it); rework it when the patch stops applying |

## Neovim theme-source exception

`~/.config/nvim/lua/plugins/all-themes.lua` temporarily uses `loctvl842/monokai-pro.nvim`: the `gthelding/monokai-pro.nvim` source in `omarchy-nvim` 2026.8.13-1 could not be resolved on 2026-10-08. Recheck on the next package update or config refresh. Closes when the local spec matches a reachable packaged source and the installed clone passes Lazy's origin check. Pre-repair files are retained at `~/Projects/eyrie/scrape/backups/nvim-theme-repair.EmAqGy/`.

## Upstream follow-up handoff

Resume by confirming the host, installed versions and current stable-channel availability, then checking the linked discussions. The commitments below authorize follow-up planning; live package or driver changes and public posts still need H's approval.

**Recheck, 2026-10-05:** this machine is the GU605CR, running Omarchy 4.0.4-1 and the baseline kernel and packages below. `/etc/pacman.d/mirrorlist` selects `stable-mirror.omarchy.org`; `/etc/pacman.conf` selects `pkgs.omarchy.org/stable`. Fresh reads of both repository databases returned HTTP 403, so current stable availability is **unverified**. Cached `pacman -Si` still lists NVIDIA 610.57.04-1 (`extra.db` dated 8 September) and limine-snapper-sync 1.31.0-1.1 (`omarchy.db` dated 4 October). Obtain fresh stable metadata before scheduling either test; cached listings do not establish that the fixes are unavailable.

### NVIDIA stock-driver comparison

- **Baseline, 2026-10-05:** GU605CR, `nvidia-open-dkms` and `nvidia-utils` 610.57.04-1, kernel 7.2.5-3-omarchy. The DKMS journal records PR #1286 applied on 26 September. `scripts/check-system.sh` confirmed the deployed override matches this repository and the loaded module carries the patch. H reports no further freezes since application; the previous frequency was roughly weekly during normal use without suspend. This observation does not prove the fault path has been exercised; the [DIFR evidence item](#deferred-work) remains open.
- **Commitment:** [posted and verified reply](https://github.com/NVIDIA/open-gpu-kernel-modules/pull/1286#issuecomment-5991695295): when Omarchy stable reaches **615.71.09 or later**, test the stock driver without PR #1286 and report back. The [NVIDIA maintainer expects](https://github.com/NVIDIA/open-gpu-kernel-modules/pull/1286#issuecomment-5901692959) its related suspend/resume fix to make the PR unnecessary. The earlier 615.71.09 result was compile testing only; there is no stock-driver runtime comparison yet. Omarchy's [stable mirror deliberately trails Arch](https://github.com/omacom/omarchy-mirror).
- **Recheck:** PR #1286 remains open, with no reply after H's linked commitment. The DKMS journal still records the patched builds; `journalctl -k --grep 'GPFIFO|DIFR prefetch'` returned no entries for the current boot, so it provides no evidence that the bounded wait engaged.
- **Next:** when that package reaches stable, agree the test and recovery procedure with H using [setup](setup.md#5-host-system-files), verify the running driver is the intended unpatched build, and record the observation period and any recurrence. `make verify` currently requires the patch, so plan the stock-driver verification explicitly. A version number alone is not evidence that the override can be retired. Closes when the result is posted and the override's disposition is recorded.

### Snapshot-clock fix

- **Upstream:** the handoff records [limine-snapper-sync #17](https://gitlab.com/Zesko/limine-snapper-sync/-/work_items/17) closed as fixed by [6865e06d](https://gitlab.com/Zesko/limine-snapper-sync/-/commit/6865e06ddfbba3ab1165ed7743f4239c669ced66). The first numbered fixed release is **1.32.1**: its [release commit and changelog](https://gitlab.com/Zesko/limine-snapper-sync/-/commit/b4c0da2d4532a993809219f9e5d51a1fa85fcb93) name #17, and its [SnapshotManager.java](https://gitlab.com/Zesko/limine-snapper-sync/-/blob/1.32.1/src/main/java/org/limine/snapper/processes/SnapshotManager.java) contains the ID comparison when the newest timestamp is earlier than the stored timestamp. GU605CR still has 1.31.0-1.1. The original fault occurred on the **ASUS Vivobook TP3402VA** during OmaSecBoot release testing.
- **Commitment:** H confirmed posting a GitLab reply to validate when the fix reaches Omarchy stable and report back. [The Omarchy status update](https://github.com/omacom/omarchy/issues/13367#issuecomment-5991797899) is posted and verified; its clock-convention/NTP proposals remain separate from the upstream snapshot fix.
- **Disposition:** H deferred validation as low priority on 2026-10-05 and will decide later whether it is needed; no test or test host is agreed. The posted commitment remains open. H also chose to keep the reconciliation with [OmaSecBoot's maintenance register](https://github.com/peregrinus879/omasecboot/blob/main/docs/maintenance.md), locally `../omasecboot/docs/maintenance.md`, pending here; its entry still says it awaits an upstream answer or fix.
- **Next, if H resumes testing:** confirm a fixed Omarchy stable package and the test host. Keep faulty-clock reproduction within owned scratch rather than changing the live system clock: use a future manifest timestamp and a higher-ID snapshot with an earlier timestamp, containing all writes and subprocess effects away from the host's snapshots and ESP. Confirm the resulting manifest and menu contain that snapshot, and that rerunning does not duplicate it. Closes when validation and its upstream report are complete, or H retires the testing commitment with an upstream update, and the owning register is reconciled.

### Watcher descriptor warning

- **Open:** the same GitLab report includes `flock: 200: Bad file descriptor` during bulk snapshot deletion. Commit `6865e06d` changes only snapshot detection and does not address this warning. H's posted reply asks whether Zesko wants a separate issue.
- **Next:** await that answer, then record the maintainer's disposition or prepare the separate report for approval. Closes when the observation has an explicit upstream disposition or its own tracking issue.

The GitLab reply was posted manually by H. At this recheck `glab` remains unavailable; the accessible issue page exposes the report but not the discussion replies, and the handoff records HTTP 401 from the unauthenticated discussion API. A new maintainer reply or the warning's disposition could not be verified. H's browser check or an authorized CLI session is needed before deciding whether to prepare a separate issue.

## Deferred Work

- **Workspace guide reconciliation.** Add the [system-menu keyboard alias](../DEVIATIONS.md#hyprland) to EyrAgents' `docs/workspace-guide-src/host-reference.json` and regenerate its guide. Closes when the Omarchy guide includes the additional shortcut.
- **DIFR fix evidence.** Whether the patch stops the freezes rests on direct evidence only. In the kernel log (`journalctl -k --grep 'GPFIFO|DIFR prefetch'`), `Timed out waiting for a free GPFIFO entry.` while the desktop keeps running shows the new bound engaged; `Failed to reset the DIFR prefetch channel.` shows a partial failure, prefetch disabled until the next modeset, and also goes in the report. A freeze with the patched module loaded shows the patch is insufficient, and its SysRq dump ([operations](operations.md#desktop-freeze)) goes with the report. Closes when either occurs and a follow-up to [PR #1286](https://github.com/NVIDIA/open-gpu-kernel-modules/pull/1286) is posted with H's approval, or when the override is retired.

- **Reference host pass.** On the next reference-dependent maintenance, preview with `make refs-plan`, get approval for new clones or repointing, run `make refs`, and confirm exact fetched parity with local tags and ignored or stale content preserved. Closes when that pass succeeds on the host.
- **Upstream issues.** [omacom/omarchy#7327](https://github.com/omacom/omarchy/issues/7327) (a `qt6-wayland` install-reason gap after the upgrade, repaired on this host) closes when the issue does. `tdl` ends by selecting an unset pane variable, a cosmetic focus regression; Omarchy's planned user-configuration preservation could overlap this repository's Stow approach when it ships. Both unchanged in 4.0.4; recheck at each Omarchy update.

## Reproducibility Follow-up

- **VIA rule refinement.** H keeps the current [rule](../DEVIATIONS.md#host-gu605) until the external keyboard is connected. Then identify its USB vendor/product IDs and configuration interface, assess device-scoped `uaccess` before `73-seat-late.rules`, and agree migration from `99-via.rules`. Closes with an approved replacement, retirement of the old broad rule, correct permissions after reconnection and a successful browser connection.
- **Other Omarchy hardware.** The tracked monitor settings target the GU605 panel and `make verify` expects its NVIDIA workaround. The documentation-led desktop selections can be reused, but these hardware assumptions need reconciliation before deploying on another model. Closes with a reviewed hardware scope and matching deployment/verification behavior for the additional host.
- **Fresh-session confirmation after user-default reconciliation.** Confirm Neovim theme loading/hot-reload and tmux help in fresh normal sessions after restoring the installed defaults, subject to the [theme-source exception](#neovim-theme-source-exception). Closes when both are confirmed. Prior files are retained at `~/Projects/eyrie/scrape/backups/omarchy-user-defaults.lc2gm1/`.
- **Post-reconciliation boot confirmation.** SDDM and the initramfs hook configuration match the installed Omarchy 4.0.4-1 package defaults. Syntax checks pass and the new hooks retain this GU605's previous KMS/console-file selections. Installed OmaSecBoot 0.1.0 has separate settings/signing hooks and watches the boot artifacts, not this configuration file; the copy generated no new boot image. Closes after confirming the greeter/login at the next normal SDDM startup and booting the next normally rebuilt image. Originals are retained under `~/Projects/eyrie/scrape/backups/`: `sddm-defaults.78Z3fA/10-wayland.conf` and `initramfs-defaults.nq380M/omarchy_hooks.conf`.

## Revalidation Triggers

- **Each Omarchy package update** (`pacman -Q omarchy`): run `/omasync`, recheck every item above that names a version, then `make verify`.

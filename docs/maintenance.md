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
| Omarchy's `omarchy-refresh-config` and `omarchy-reinstall-configs` copy defaults through the stowed links into the clone (checked on 4.0.4-1, 2026-09-25) | [setup](setup.md#recovery-after-omarchy-config-resets) | each Omarchy package update |
| `hdw`'s checks protect cooperating calls, not a server-side atomic transaction; 22 real Herdr 0.8.2 cases passed in private namespaces, without an attached UI, real agents or WSL | [DEVIATIONS](../DEVIATIONS.md#bash) | the helper, Herdr's CLI or schema, or its layout behavior changes |
| Git review uses per-call file or explorer context (checked on Neovim 0.12.5, Snacks `882c996`, LazyVim `c10948c`, Neo-tree `0bd0eea`; H confirmed it across repositories; related upstream reports: [Snacks #1639](https://github.com/folke/snacks.nvim/issues/1639), [#2483](https://github.com/folke/snacks.nvim/issues/2483)) | [DEVIATIONS](../DEVIATIONS.md#neovim) | picker working-directory, root detection, Neo-tree state or LazyVim mappings change |
| The paired reference updater follows GitHub's canonical name without a pinned project identity, and can repoint `origin` before its dirty check | [operations](operations.md#make-targets) | fixed together in both twins, with rename, reused-ID and dirty-refusal tests |
| Deployment is serial within one Make invocation, not a transaction; `twins-pair` attests committed twin files, not deployment or publication | [operations](operations.md#make-targets) | before concurrent deployments or a CI pair-protocol change |

## Deferred Work

- **Reference host pass.** On the next reference-dependent maintenance, preview with `make refs-plan`, get approval for new clones or repointing, run `make refs`, and confirm exact fetched parity with local tags and ignored or stale content preserved. Closes when that pass succeeds on the host.
- **Upstream issues.** [omacom/omarchy#7327](https://github.com/omacom/omarchy/issues/7327) (a `qt6-wayland` install-reason gap after the upgrade, repaired on this host) closes when the issue does. `tdl` ends by selecting an unset pane variable, a cosmetic focus regression; Omarchy's planned user-configuration preservation could overlap this repository's Stow approach when it ships. Both unchanged in 4.0.4; recheck at each Omarchy update.

## Revalidation Triggers

- **Each Omarchy package update** (`pacman -Q omarchy`): run `/omasync`, recheck every item above that names a version, then `make verify`.

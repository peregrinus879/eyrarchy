# Desktop Choices

[Overview](../README.md) · [Setup](setup.md) · [Deviations](../DEVIATIONS.md)

Personal selections to restore after installing Omarchy. Use Omarchy's installers and settings; these choices are documented rather than deployed by Stow.

## Default Applications

| Role | Selection | Restore |
| --- | --- | --- |
| Terminal | Ghostty, with Omarchy's supplied configuration | `omarchy install terminal ghostty` installs and selects it |
| Browser | Brave | `omarchy install browser brave`, then `omarchy default browser brave` |
| Mail links | HEY web app | `xdg-mime default HEY.desktop x-scheme-handler/mailto`, with the HEY launcher installed |
| Mail messages and message-ID links | Thunderbird | `xdg-mime default org.mozilla.Thunderbird.desktop message/rfc822 x-scheme-handler/mid` |

Install Thunderbird from the table below before selecting its handlers. Use its packaged desktop ID rather than copying a generated `userapp-Thunderbird-*.desktop` entry from another installation. Omarchy's preinstall set supplies the HEY web app.

Check terminal and browser selection with `omarchy default terminal` and `omarchy default browser`.

## Applications and Services

These are personal additions to the Omarchy base. Run the installation commands for the applications needed on the new machine; native installers may also launch the application.

| Application | Installation | Integration |
| --- | --- | --- |
| ChatGPT desktop | `omarchy install ai chatgpt` | Required by the personal desktop ChatGPT binding; package name is `openai-codex-desktop` |
| Gear Lever | Flatpak `it.mijorus.gearlever` | Required by the personal AppImages binding |
| Bitwarden | Flatpak `com.bitwarden.desktop` | Password-manager application |
| Signal | `omarchy install service signal` | Uses Omarchy's existing launcher/binding |
| Spotify | `omarchy install service spotify` | Uses Omarchy's existing music launcher/binding |
| Steam | `omarchy install gaming steam` | Installer selects the applicable graphics support |
| Tailscale | `omarchy install service tailscale` | Installer enables the system service, starts account setup with accepted routes, grants the current user operator access, enables Taildrop reception and adds the bar item |
| Syncthing | `omarchy pkg add syncthing` | Enable the user service with `systemctl --user enable --now syncthing.service`; configure device trust and shared folders through Syncthing |
| Thunderbird and Proton Mail Bridge | `omarchy pkg add thunderbird protonmail-bridge` | Configure the account through Bridge and Thunderbird; enable Bridge's start-on-login option, which launches `protonmail-bridge --no-window` |
| Foliate | `omarchy pkg add foliate` | E-book reader |
| Caligula | `omarchy pkg add caligula` | Disk-image writer |
| Android USB support | `omarchy pkg add android-udev` | Use where Android USB access is needed |
| ASUS ROG controls | `omarchy pkg add rog-control-center` | ASUS hosts only; Omarchy's hardware setup supplies `asusctl` |

For the Flatpak applications, install Flatpak, register Flathub if needed, then install the applications:

```bash
omarchy pkg add flatpak
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub it.mijorus.gearlever com.bitwarden.desktop
```

Yazi and repository maintenance tools are covered by [setup prerequisites](setup.md#1-prerequisites). AI-client configuration belongs to [EyrAgents](https://github.com/peregrinus879/eyragents); the vault owns its synchronization and note workflows.

## Appearance

Use Omarchy's **Gruvbox** theme and the [repository wallpaper](../wallpapers/README.md). Omarchy owns the theme files and generated application colors. The personal monitor geometry and window appearance remain in the [Hyprland overrides](../DEVIATIONS.md#hyprland).

From the repository root:

```bash
omarchy theme set gruvbox
install -D -m 644 wallpapers/RyuVsAkuma.jpg "$HOME/.config/omarchy/backgrounds/gruvbox/RyuVsAkuma.jpg"
omarchy theme bg set "$HOME/.config/omarchy/backgrounds/gruvbox/RyuVsAkuma.jpg"
```

If the destination image already exists and differs, compare and preserve it before replacement. The copy appears in Omarchy's user backgrounds for the selected theme; the final command selects it immediately. Check with `omarchy theme current` and `omarchy theme bg current`.

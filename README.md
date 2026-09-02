# Desktop Dotfiles

Personal Fedora Sway configuration with an Everforest theme, a Quickshell top
bar and notification center, Foot terminal settings, SDDM and lock-screen
styling, and a small Bash setup. User configuration is organized as GNU Stow
packages so each applicable top-level directory mirrors its destination under
`$HOME`.

## Features

### Sway

- Modular configuration in numbered `conf.d` fragments.
- Fedora's layered Sway defaults load between the base configuration and local
  overrides.
- Everforest wallpaper, native output scale, six-pixel inner gaps, four-pixel
  outer gaps, and two-pixel borders.
- Touchpad tap-to-click and two-finger scrolling.
- Three-finger horizontal workspace navigation.
- Automatic lock after 10 minutes, suspend after 15 minutes, and lock before
  sleep.
- Foot terminal and a native Quickshell application launcher.
- Quickshell replaces the visible Sway/Waybar bar.

Important keybindings:

| Binding | Action |
| --- | --- |
| `Mod+Return` | Open Foot |
| `Mod+Shift+Return` | Open Brave browser |
| `Mod+Alt+Return` | Open Herdr in the home directory |
| `Mod+Space` | Toggle the application launcher |
| `Mod+K` | Toggle the keybinding guide |
| `Mod+N` | Toggle the notification center |
| `Mod+Escape` | Toggle the power menu |
| `Mod+Shift+L` | Lock the session |
| `Mod+Shift+Q` | Close the focused window |
| `Mod+Shift+C` | Reload Sway |
| `Mod+Shift+B` | Restart Quickshell |
| `Mod+Shift+E` | Show the Sway exit prompt |
| `Mod+Arrow keys` | Move focus |
| `Mod+Shift+Arrow keys` | Move the focused window |
| `Mod+1` through `Mod+5` | Switch to workspace 1 through 5 |
| `Mod+Shift+1` through `Mod+Shift+5` | Move a window to a workspace |
| `Mod+B` / `Mod+V` | Horizontal / vertical split |
| `Mod+W` | Tabbed layout |
| `Mod+E` | Toggle split direction |
| `Mod+F` | Toggle fullscreen |
| `Mod+T` | Toggle floating |
| `Mod+Minus` | Show the scratchpad |
| `Mod+Shift+Minus` | Move a window to the scratchpad |
| `Mod+R` | Enter resize mode |

### Quickshell bar

The responsive 36-pixel top bar is created once per output. Low-priority labels
collapse on narrow displays, and inactive scratchpad and binding-mode indicators
remain hidden until they are relevant.

- Five fixed Sway workspace buttons, the scratchpad count, and the active Sway
  binding mode. Non-default modes such as resize are highlighted.
- Stay Awake, DND, system-local clock, and notification-center controls in the
  center. The coffee toggle inhibits Sway's automatic idle lock and suspend
  timers. DND uses a bell-off icon and suppresses notification popups while
  continuing to collect notification history.
- Event-driven volume controls backed by Quickshell's native PipeWire service.
  Click the volume pill to open output
  and input sliders, mute controls, and default-device selectors. Scroll over
  the pill to adjust output volume directly.
- Backlight percentage backed by `brightnessctl`. Click it for a brightness
  slider, focused-display list, and five display-scale presets centered on
  1.0×, or scroll to adjust brightness directly.
- Wi-Fi connection name from Quickshell's native NetworkManager integration.
  Click it to open a searchable access-point list and connect to open, saved,
  or password-protected networks without exposing credentials in process
  arguments. Its Advanced button opens NetworkManager's
  connection editor for enterprise, certificate-based, and other complex
  profiles.
- Active keyboard-layout abbreviation and click-to-switch support.
- Battery charge, charging state, and a red low-battery warning beside power.
  Click the battery pill to select Power Saver, Balanced, or Performance mode.
- The power button opens a centered Lock, Reboot, and Shutdown menu. Reboot and
  shutdown require a second confirmation within three seconds; lock is
  immediate. Use the arrow keys to select an action, Enter or Space to activate
  it, and Escape to close the menu.

Quickshell also acts as the desktop notification server:

- Up to three notification cards appear at the top right.
- Notifications remain in the center after their popup times out.
- Clicking a card invokes its default action, when available.
- The close button dismisses one notification; **Clear** dismisses all.
- Critical notifications receive a red accent.
- DND suppresses popup cards while continuing to collect notifications.
- Popups follow the currently focused output instead of always using the first
  connected display.
- Volume and brightness OSD events are ignored because their values are already
  visible in the bar.

Notification history survives a soft Quickshell configuration reload, but not
a complete Quickshell/session restart. DND and Stay Awake are session controls
and reset when the shell configuration reloads.

The centered application launcher is also provided by Quickshell. Press
`Mod+Space` to open or close it. By default it lists every available desktop
application alphabetically; type to filter the list, use the arrow keys to
select a result, and press Enter to launch it. Escape closes the launcher.

Press `Mod+K` to open a searchable, scrolling reference of the available Sway
shortcuts. Type to filter it, use the arrow or Page Up/Down keys to move through
results, and press `Mod+K` again, Escape, or click outside the card to close it.

### Foot

- Noto Sans Mono SemiBold at 12 points.
- 16-by-12 pixel internal padding and 10,000 lines of scrollback.
- Everforest dark palette with 95% opacity.
- Background blur is intentionally disabled because it is not supported by the
  standard Sway compositor.
- Clipboard, scrollback search, and font-size shortcuts.

### Gtklock and Bash

- Gtklock uses the matching Everforest wallpaper with a themed clock, date,
  authentication card, and password feedback.
- Bash prepends `~/.local/bin` and `~/bin` to `PATH`, sources `/etc/bashrc` and
  `~/.bashrc.d/*`, aliases `ls` to `eza`, and initializes Starship when it is
  installed. Starship uses a minimal two-line prompt with Everforest colors,
  the username, current directory, concise Git status, and Python context. The
  Python module recognizes `uv.lock` and displays an active virtual environment.

### SDDM login screen

- A Qt 6 login theme matches the Everforest Dark Medium desktop and gtklock
  styling.
- The greeter uses the same `fog_forest_1.png` wallpaper, a centered translucent
  authentication card, local time and date, session selection, and compact
  restart and shutdown actions.
- On multiple displays, every output shows the wallpaper while the login form
  appears only on SDDM's primary output.
- The installation script copies the theme and wallpaper into system-readable
  locations; SDDM cannot read them through this user's private home directory.

## Repository layout

```text
bash/.bashrc                         Bash configuration
starship/.config/starship.toml       Starship prompt and Everforest palette
foot/.config/foot/foot.ini          Foot terminal configuration
quickshell/.config/quickshell/       Bar, notification center, and UI components
sway/.config/sway/config             Sway entry point
sway/.config/sway/conf.d/            Ordered Sway fragments
gtklock/.config/gtklock/             Active lock-screen configuration and theme
swaylock/.config/swaylock/config     Retained upstream Swaylock configuration
sddm/everforest-sway/                Qt 6 SDDM login theme source
sddm/install.sh                      System-wide SDDM theme installer
themes/everforest-dark-medium/       Palette and reusable adapters
wallpapers/everforest/               Wallpaper collection
```

## Prerequisites

The current machine uses the following Fedora package names:

```bash
sudo dnf install \
    sway sway-config-fedora swayidle swaylock gtklock sddm \
    foot quickshell brave-browser \
    wireplumber brightnessctl NetworkManager nm-connection-editor \
    eza jq stow libnotify \
    cascadia-mono-nf-fonts google-noto-sans-vf-fonts \
    google-noto-sans-mono-vf-fonts
```

`quickshell` and `cascadia-mono-nf-fonts` may require an additional Fedora COPR
or another package source, depending on the Fedora release. Install Herdr and
Starship separately and ensure `herdr` and `starship` are available on `PATH`.
The required commands and their purpose are:

| Command/package | Used for |
| --- | --- |
| `sway`, `swaymsg` | Compositor, workspace data, input data, and layout changes |
| `swayidle`, `gtklock` | Idle handling and the active screen lock |
| `swaylock` | Upstream locker retained for `sway-config-fedora` compatibility |
| `sddm`, `sddm-greeter-qt6` | Display manager and Qt 6 login-screen renderer |
| `foot` | Terminal emulator |
| `brave-browser` | Default web browser and browser keybinding |
| `herdr` | Terminal workspace manager opened by the Herdr keybinding |
| `quickshell` 0.3.1 or newer | Top bar, notification server, and popup windows |
| PipeWire / WirePlumber | Event-driven volume, mute, and device control |
| `brightnessctl` | Backlight status and control |
| NetworkManager | Event-driven Wi-Fi status, scanning, and connections |
| `nm-connection-editor` | Advanced and enterprise network profiles |
| `systemctl` | Suspend, reboot, shutdown, and Dunst shutdown |
| `notify-send` / `libnotify` | Notification testing and application notifications |
| `eza` | Bash `ls` alias |
| `starship` | Bash prompt with directory and Git context |
| `jq` | Focused-workspace lookup for three-finger swipe navigation |
| `stow` | Symlink-based installation |

The Quickshell icons require **Cascadia Mono NF**, while interface copy uses
**Noto Sans**. Foot requires **Noto Sans Mono**, including its SemiBold weight.

## Required system configuration

### Paths

The wallpaper path is intentionally absolute in:

- `sway/.config/sway/conf.d/20-outputs.conf`
- `gtklock/.config/gtklock/config.ini`
- `gtklock/.config/gtklock/layout.xml`
- `swaylock/.config/swaylock/config`

Clone this repository to `/home/wenhan/Dotfiles`, or change all three files to
match the actual clone location. The desktop and lock screens will not resolve
the wallpaper if their paths are not updated together.

### Fedora Sway integration

The Sway entry point calls `/usr/libexec/sway/layered-include`, provided by
Fedora's `sway-config-fedora` package. On another distribution, remove or
replace that include line in `sway/.config/sway/config` with the distribution's
normal Sway defaults.

### SDDM login theme

The installed Fedora Sway system selects `03-sway-fedora` from
`/usr/lib/sddm/sddm.conf.d/wayland-sway.conf`. Install this repository's theme
and a later override with:

```bash
./sddm/install.sh
```

The script writes only these managed targets:

```text
/usr/share/sddm/themes/everforest-sway/
/etc/sddm.conf.d/90-everforest-theme.conf
```

It copies the wallpaper rather than symlinking it because `/home/wenhan` is not
traversable by the `sddm` service account. Changes to the source theme do not
reach the greeter until the installer is run again. Preview the source safely
inside an existing graphical session before installing it:

```bash
sddm-greeter-qt6 --test-mode --theme "$PWD/sddm/everforest-sway"
```

Test mode cannot authenticate or execute the power actions. To return to the
Fedora Sway theme, remove `/etc/sddm.conf.d/90-everforest-theme.conf`; the
vendor `wayland-sway.conf` will select `03-sway-fedora` again. Removing that
single override is also the recovery step from a text console if a future QML
change prevents the custom greeter from loading.

### Desktop services and permissions

- The bar clock follows the operating system timezone and does not hard-code a
  region. This machine is configured for `Asia/Singapore`; verify or change it
  with `timedatectl` and `sudo timedatectl set-timezone Asia/Singapore`.
- PipeWire and WirePlumber must be running with default audio sink and source
  devices for Quickshell's native PipeWire service.
- NetworkManager must be running for Quickshell's native networking service.
  Advanced profiles require `nm-connection-editor`.
- The user must be able to read and change the selected backlight device with
  `brightnessctl`. On many systems systemd-logind supplies the required device
  ACL; other distributions may require membership in a `video` group or a udev
  rule.
- The battery widget follows UPower's display device, so multi-battery systems
  use UPower's aggregate percentage and charging state.
- The power-profile selector uses Quickshell's native Power Profiles service.
  Fedora supplies it through `tuned-ppd`; other distributions can use
  `power-profiles-daemon`. The active user must be authorized by Polkit to
  change the profile.
- Suspend, reboot, and poweroff use systemd-logind/Polkit. The session must be
  authorized to perform those operations.
- The keyboard-layout widget is most useful when Sway has multiple XKB layouts
  configured. Add an `xkb_layout` rule to `40-inputs.conf` if the system defaults
  only provide one layout.

### Notification ownership

Only one process may own the `org.freedesktop.Notifications` DBus name. This
configuration uses Quickshell, not Dunst, as that process. The Sway bar startup
command stops `dunst.service` before launching Quickshell.

If notifications bypass the center, inspect the owner:

```bash
busctl --user status org.freedesktop.Notifications
```

The reported executable should be `quickshell`. To transition an existing
session from Dunst, run:

```bash
systemctl --user stop dunst.service
```

Quickshell automatically retries registration after the previous owner exits.
Test delivery with:

```bash
notify-send "Quickshell test" "Notification delivery is working"
```

If another notification daemon is enabled, disable or stop it as well. When
starting Quickshell outside Sway, stop the competing daemon before launching
Quickshell.

## Installation

Back up any existing files at the target paths first. GNU Stow refuses to
overwrite ordinary files, which protects existing configuration but requires
conflicts to be resolved manually.

From the repository root:

```bash
stow bash foot gtklock quickshell starship sway swaylock
```

The theme remains inside this repository. Foot and Quickshell load it from
`~/Dotfiles/themes/everforest-dark-medium/`.

The resulting links include:

```text
~/.bashrc -> .../Dotfiles/bash/.bashrc
~/.config/foot/foot.ini -> .../Dotfiles/foot/.config/foot/foot.ini
~/.config/quickshell -> .../Dotfiles/quickshell/.config/quickshell
~/.config/starship.toml -> .../Dotfiles/starship/.config/starship.toml
~/.config/sway -> .../Dotfiles/sway/.config/sway
~/.config/swaylock/config -> .../Dotfiles/swaylock/.config/swaylock/config
```

Start a new Sway session after the first installation. For changes during a
running session, use `Mod+Shift+C` to reload Sway and `Mod+Shift+B` to restart
Quickshell. New Foot windows automatically load the latest Foot configuration.

The SDDM files are system-wide and are intentionally not included in the Stow
command. Install or update them separately with `./sddm/install.sh`; the new
theme takes effect the next time SDDM starts.

To remove only the symlinks created by Stow:

```bash
stow --delete bash foot gtklock quickshell starship sway swaylock
```

## Validation and diagnostics

Run these checks after editing:

```bash
sway --validate --config sway/.config/sway/config
foot --check-config --config foot/.config/foot/foot.ini
STARSHIP_CONFIG=starship/.config/starship.toml starship print-config >/dev/null
sddm-greeter-qt6 --test-mode --theme "$PWD/sddm/everforest-sway"
git diff --check
git status --short
```

Useful live-session commands:

```bash
swaymsg reload
swaymsg -t get_outputs
swaymsg -t get_inputs
quickshell list
quickshell log -t 100 --no-color
```

If Nerd Font icons render as boxes, confirm the font is discoverable:

```bash
fc-match "Cascadia Mono NF"
fc-match "Noto Sans Mono:weight=semibold"
```

If a widget is empty or stuck, verify PipeWire, UPower, and NetworkManager with
`wpctl status`, `upower -d`, and `nmcli device status`; brightness remains backed
by `brightnessctl -m`.

## Customization notes

- Keep new Sway fragments in `sway/.config/sway/conf.d/` with a numeric prefix.
- Put hardware-specific monitor rules in `20-outputs.conf` and input rules in
  `40-inputs.conf`.
- Settings that must win over Fedora's layered defaults belong in a `90-*.conf`
  fragment.
- Quickshell's design tokens live in `DesignTokens.qml`. Shared pill and
  notification-card visuals live in `StatusPill.qml` and `NotificationCard.qml`;
  system integration is isolated in `SystemState.qml`.
- Use `themes/everforest-dark-medium/palette.json` as the
  canonical source when adding colors to another application. A CSS-variable
  adapter and semantic usage guide live beside it.
- Quickshell reads the canonical JSON directly and reloads it when it changes.
  Foot includes the adjacent `foot.ini` adapter while retaining a local
  bright-white override. Keep application adapters and swaylock's embedded
  values synchronized with the canonical palette.

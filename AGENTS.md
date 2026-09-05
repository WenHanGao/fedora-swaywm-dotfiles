# Repository Guidelines

## Project Structure & Module Organization

This repository stores personal Fedora Sway dotfiles and related assets. Each
top-level configuration directory is a GNU Stow package:

- `sway/.config/sway/`: Sway entry point and numbered `conf.d` fragments.
- `quickshell/.config/quickshell/`: top bar, notification server/center, popup
  cards, and shared QML components.
- `foot/.config/foot/foot.ini`: Foot terminal settings and Everforest palette.
- `swaylock/.config/swaylock/config`: lock-screen appearance.
- `bash/.bashrc`: Bash environment and aliases.
- `wallpapers/everforest/`: wallpaper assets referenced by Sway and swaylock.
- `themes/everforest-dark-medium/`: canonical named palette,
  terminal mapping, application adapters, and reuse documentation.
- `README.md`: user-facing features, dependencies, setup, and troubleshooting.

The Sway `config` file is only an entry point. Keep new rules in
`sway/.config/sway/conf.d/` with a numeric prefix that reflects load order, for
example `50-keybindings.conf` or `90-overrides.conf`. Quickshell's entry point is
`shell.qml`; reusable visual elements belong in focused PascalCase component
files such as `StatusPill.qml` and `NotificationCard.qml`.

## Build, Test, and Development Commands

There is no build step for this repo. Useful validation commands are:

- `sway --validate --config sway/.config/sway/config`: checks Sway syntax without starting a session.
- `foot --check-config --config foot/.config/foot/foot.ini`: checks Foot syntax.
- `swaymsg reload`: reloads the active Sway session after copying or symlinking files into place.
- `swaymsg -t get_outputs` and `swaymsg -t get_inputs`: discover monitor and device identifiers before adding output or input rules.
- `quickshell list` and `quickshell log -t 100 --no-color`: inspect the live
  shell and recent QML/runtime errors.
- `notify-send "Quickshell test" "Notification delivery is working"`: exercises
  the popup and notification-center path.
- `busctl --user status org.freedesktop.Notifications`: confirms Quickshell,
  rather than Dunst or another daemon, owns the notification service.
- `git diff --check`: detects whitespace errors.
- `git status --short`: review local config and asset changes before committing.

## Coding Style & Naming Conventions

Use plain Sway, swaylock, Foot INI, and declarative QML syntax. Keep comments
short and practical, especially around device identifiers, external services,
or precedence-sensitive settings. Group related Sway rules into existing
fragment files rather than expanding the entry-point `config`. Use four-space
indentation inside Sway and QML blocks and align continued commands as shown in
`10-variables.conf` and `30-idle.conf`. Prefer descriptive lowercase Sway
fragment names with hyphens after the load-order number.

For QML, use lower camel case for IDs, properties, and functions; use PascalCase
for reusable component filenames. Keep command execution in explicit
`Quickshell.Io.Process` objects with argument arrays. Reuse `StatusPill`,
`NotificationCard`, and `PowerActionButton` instead of duplicating established
bar, notification, or power-menu visuals. Use
`themes/everforest-dark-medium/palette.json` as the source of
truth for colors; keep its CSS and application adapters synchronized.

## Testing Guidelines

Run `sway --validate --config sway/.config/sway/config` for every Sway change.
For keybindings, gestures, input, output, bar startup, and lock-screen changes,
also test inside a live session with `swaymsg reload`. When changing wallpaper
paths, confirm both Sway and swaylock point to existing files under
`wallpapers/`.

Run Foot's config check for every `foot.ini` change. For Quickshell changes,
confirm the running instance reports `Configuration Loaded`, review its recent
log for QML warnings, and exercise the modified widget. `Mod+Shift+B` performs a
full Quickshell restart when a soft reload is insufficient.

Notification changes require an end-to-end `notify-send` test. Confirm
`org.freedesktop.Notifications` is owned by Quickshell; the startup rule in
`90-bar.conf` stops `dunst.service` before starting Quickshell. Do not run Dunst,
Mako, or another notification daemon concurrently. Test volume, brightness,
network, and input widgets against their backing commands (`wpctl`,
`brightnessctl`, `nmcli`, and `swaymsg`) when changing their parsing or actions.

Update `README.md` whenever functionality, prerequisites, system services,
installation steps, keybindings, or troubleshooting procedures change.

## Commit & Pull Request Guidelines

The current history uses short, imperative commit summaries, for example
`added sway config`. Keep commits focused by area, such as Sway, Quickshell,
Foot, swaylock, documentation, or wallpapers. Pull requests should describe the
visible behavior change, call out new runtime dependencies or system settings,
list validation performed, and include screenshots only when appearance changes
are relevant.

## Agent-Specific Instructions

Do not overwrite existing user configuration. Preserve uncommitted changes
unless explicitly asked to modify them, and keep edits scoped to the requested
dotfile or asset area. Wallpaper and theme adapters are exposed through
relative symlinks inside each Stow package; keep those links pointed at the
canonical files under `wallpapers/` and `themes/` when changing assets.
Preserve Fedora's layered include ordering unless intentionally changing
configuration precedence. Quickshell is the notification server for this setup,
so changes must not reintroduce Dunst polling or a competing DBus owner.

# Repository Guidelines

## Project Structure & Module Organization

This repository stores personal desktop dotfiles and related assets. Sway configuration lives under `sway/.config/sway/`; the top-level `config` is the entry point and loads numbered fragments from `sway/.config/sway/conf.d/`. Keep new Sway snippets in that directory with a numeric prefix that reflects load order, for example `50-keybindings.conf` or `90-overrides.conf`. Swaylock settings live in `swaylock/.config/swaylock/config`. Wallpaper assets are grouped in `wallpapers/everforest/`.

## Build, Test, and Development Commands

There is no build step for this repo. Useful validation commands are:

- `sway --validate --config sway/.config/sway/config`: checks Sway syntax without starting a session.
- `swaymsg reload`: reloads the active Sway session after copying or symlinking files into place.
- `swaymsg -t get_outputs` and `swaymsg -t get_inputs`: discover monitor and device identifiers before adding output or input rules.
- `git status --short`: review local config and asset changes before committing.

## Coding Style & Naming Conventions

Use plain Sway and swaylock configuration syntax. Keep comments short and practical, especially around device-specific identifiers or precedence-sensitive settings. Group related Sway rules into the existing fragment files rather than expanding the entry-point `config`. Use four-space indentation inside blocks and align continued commands as shown in `10-variables.conf` and `30-idle.conf`. Prefer descriptive lowercase fragment names with hyphens after the load-order number.

## Testing Guidelines

Run `sway --validate --config sway/.config/sway/config` for every Sway change. For keybindings, gestures, input, output, and lock-screen changes, also test inside a live session with `swaymsg reload`. When changing wallpaper paths, confirm both Sway and swaylock point to existing files under `wallpapers/`.

## Commit & Pull Request Guidelines

The current history uses short, imperative commit summaries, for example `added sway config`. Keep commits focused by area, such as Sway config, swaylock config, or wallpapers. Pull requests should describe the visible behavior change, list validation performed, and include screenshots only when wallpaper or appearance changes are relevant.

## Agent-Specific Instructions

Do not overwrite existing user configuration. Preserve uncommitted changes unless explicitly asked to modify them, and keep edits scoped to the requested dotfile or asset area.

# Everforest Dark Medium Palette

Canonical color source for applications in this dotfiles repository. The
values follow the official Everforest dark variant with medium contrast.

## Files

- `palette.json`: canonical named colors and suggested terminal mappings.
- `palette.css`: the same named colors as reusable CSS custom properties.
- `foot.ini`: Foot-native adapter loaded by the terminal configuration.
- `../../starship/.config/starship.toml`: prompt configuration containing the
  small Everforest color subset used by Starship.

Keep `palette.json` authoritative. When a value changes, update the matching
CSS property and any application-specific adapter that duplicates the color.

## Semantic roles

| Role | Color | Suggested use |
| --- | --- | --- |
| `bg_dim` | `#232a2e` | Dimmed or recessed background |
| `bg0` | `#2d353b` | Main application background |
| `bg1` | `#343f44` | Active surfaces and status bars |
| `bg2` | `#3d484d` | Popups and floating surfaces |
| `bg3` | `#475258` | Selection and inactive controls |
| `bg4` | `#4f585e` | Separators |
| `bg5` | `#56635f` | Raised neutral surface |
| `bg_visual` | `#543a48` | Visual selection |
| `bg_red` | `#514045` | Error or deletion background |
| `bg_yellow` | `#4d4c43` | Warning background |
| `bg_green` | `#425047` | Success or addition background |
| `bg_blue` | `#3a515d` | Information background |
| `bg_purple` | `#4a444e` | Purple accent background |
| `fg` | `#d3c6aa` | Primary foreground |
| `red` | `#e67e80` | Errors and destructive actions |
| `orange` | `#e69875` | Operators and secondary warnings |
| `yellow` | `#dbbc7f` | Warnings and types |
| `green` | `#a7c080` | Success, active state, and strings |
| `aqua` | `#83c092` | Constants and secondary success |
| `blue` | `#7fbbb3` | Information and links |
| `purple` | `#d699b6` | Numbers and special values |
| `grey0` | `#7a8478` | Muted foreground |
| `grey1` | `#859289` | Comments, borders, and disabled UI |
| `grey2` | `#9da9a0` | Secondary foreground |
| `statusline1` | `#a7c080` | Primary mode indicator |
| `statusline2` | `#d3c6aa` | Secondary mode indicator |
| `statusline3` | `#e67e80` | Alert mode indicator |

## Usage

Read a named color from JSON:

```bash
jq -r '.colors.bg0' ~/.config/quickshell/palette.json
```

Import the CSS adapter:

```css
/* Copy or symlink palette.css beside the consuming stylesheet. */
@import url("./palette.css");

.panel {
    color: var(--everforest-fg);
    background: var(--everforest-bg0);
    border-color: var(--everforest-bg3);
}
```

Applications that cannot import JSON or CSS should copy values by semantic
role. Prefer role names over choosing a nearby color by appearance; this keeps
error, warning, active, muted, and surface states consistent across the desktop.

The `terminal` object in `palette.json` maps the named colors to the standard
eight ANSI and eight bright ANSI slots. Values in those arrays are references
to entries in the `colors` object.

Quickshell reads `palette.json` directly and watches it for changes. Foot loads
`foot.ini`, because Foot cannot parse JSON; keep that adapter synchronized with
the canonical terminal mapping. Foot's main configuration may override an
adapter value for application-specific presentation.

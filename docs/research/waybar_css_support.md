# Waybar CSS Support Table

Waybar uses GTK (typically GTK3) for styling. Its `style.css` supports only a subset of web CSS—primarily properties relevant to widget appearance. Advanced layout (flex, grid), JS-style variables, and browser-only features are **not** available. This table summarizes support for CSS properties and value types in Waybar.

| Property                                 | Support     | Value Types / Examples                                  | Notes                                                                                         |
|-------------------------------------------|-------------|---------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| `margin`, `margin-*`                     | Partial     | `px`, `em`, `%`, `auto`                                 | Only for modules/widgets. Bar window margin must be set in config, not via CSS. Negative margins are clipped in new versions. |
| `padding`, `padding-*`                   | Supported   | `px`, `em`, `%`                                         | Fully supported for modules and widgets.                                                      |
| `border`, `border-*`                     | Supported   | `px` width, style, color                                | All border properties/shorthands are supported (e.g. `border: 1px solid #fff;`).              |
| `border-radius`                          | Supported   | `px`, `%`                                               | Fully supported on widgets and modules.                                                       |
| `background-color`                       | Supported   | Named, `#RRGGBB`, `#RGB`, `rgb()`, `rgba()`             | Standard CSS formats, RGBA for transparency.                                                  |
| `background-image`, `background`         | Partial     | `url("/path")`, `linear-gradient(...)`, color          | Images must be in quotes. No SVG, no radial/cross-fade gradients.                             |
| `background-repeat/position/size`        | Supported   | CSS keywords, `px`, `%`                                 | Fully supported.                                                                              |
| `color`                                  | Supported   | Named, `#RRGGBB`, `rgb()`, `rgba()`                     | Text color.                                                                                   |
| `font-family`                            | Supported   | Font names, comma-list                                  | Multiple fonts supported (e.g., FontAwesome).                                                 |
| `font-size`                              | Supported   | `px`, `em`, `%`, `pt`                                   | Both absolute and relative sizes.                                                             |
| `font-weight`                            | Supported   | `normal`, `bold`, `100`–`900`                           | All CSS formats.                                                                              |
| `font-style`, `font-variant`             | Supported   | `italic`, `oblique`, `small-caps`                       | Italic, small-caps, etc.                                                                      |
| `text-shadow`                            | Supported   | Offset(s) and color                                     | Fully supported for text.                                                                     |
| `text-decoration`                        | Supported   | `underline`, `line-through`, color                      | Fully supported.                                                                              |
| `box-shadow`                             | Supported   | Offsets, blur, color                                    | Fully supported, including inset.                                                             |
| `opacity`                                | Supported   | `0.0`–`1.0`                                             | Widget transparency.                                                                          |
| `min-width`, `min-height`                | Supported   | `px`, `%`                                               | Supported for widgets/modules.                                                                |
| `width`, `height` (fixed)                | Unsupported | N/A                                                    | Use min-width/height or container settings instead.                                           |
| `max-width`, `max-height`                | Unsupported | N/A                                                    | Ignored by GTK CSS.                                                                           |
| `display`, `position`, `float`           | Unsupported | N/A                                                    | Layout handled by Waybar/GTK, not CSS.                                                        |
| `cursor`                                 | Partial     | Only via config, not CSS                                | Set in config with numeric cursor ID; CSS `cursor` ignored.                                   |
| `transform`                              | Unsupported | N/A                                                    | Not implemented.                                                                              |
| `clip-path`                              | Unsupported | N/A                                                    | Not implemented.                                                                              |
| CSS variables (`--*`)                    | Unsupported | N/A                                                    | Use GTK theme vars (`@theme_base_color`) instead.                                             |
| `transition`, `transition-*`             | Supported   | Time (`s`, `ms`), property                              | Transitions work (e.g., `transition: background-color 0.2s;`).                                |
| `animation`, `animation-*`, `@keyframes` | Supported   | Names, duration, timing                                 | GTK CSS supports keyframes and animation properties.                                          |

---

## README: Waybar CSS Support & Limitations

### Summary
- Waybar’s `style.css` uses GTK CSS, **not** browser CSS.
- You can safely use: color, background, border, radius, shadow, font, and text styling.
- **You cannot use:** CSS variables (`--foo`), web layout (`display: flex`, `grid`), positioning, fixed width/height, or JS/SVG/CSS filters.
- Animations, transitions, and theme variables (`@theme_base_color`) are allowed.
- For bar margin, always use the JSON config, not CSS.

### Example
```css
window#waybar {
  background: rgba(43,48,59,0.5);
  border-bottom: 3px solid rgba(100,114,125,0.5);
  color: white;
  font-family: "JetBrains Mono", "Font Awesome 6 Free";
}
#workspaces button.focused {
  background: linear-gradient(to top, #262626, #444d4d);
  border-radius: 12px;
  box-shadow: inset 0 -3px #7bb7fa;
}
```

### Further Reading
- [Waybar Wiki: Style](https://github.com/Alexays/Waybar/wiki/Styling)
- [GTK 3 CSS Reference](https://docs.gtk.org/gtk3/css-properties.html)
- [Waybar GitHub Issues](https://github.com/Alexays/Waybar/issues)


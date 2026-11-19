# Ferret branding

The Ferret mark: a ferret standing up, cream on sable, with its dark mask. These SVGs are the only sources. Every app icon, the menubar glyph and the docs logo are rendered from them by `scripts/generate_icons.sh` (and `packaging/linux/icons/generate.sh` for Linux). Change a file here, run the script, commit both.

| File | What it is |
|---|---|
| `ferret-icon.svg` | The full-colour icon: 1024 canvas, 824 squircle plate on Apple's grid, soft shadow and rim. The macOS icon as is |
| `ferret-icon-dark.svg` | The same on a darker plate, for dark appearances (iOS dark icon) |
| `ferret-glyph.svg` | The ferret alone, no plate. Use it on a sable or dark background |
| `ferret-template.svg` | One colour: head and body silhouette, the mask and nose cut out. For the menubar, Android themed icons and the iOS tinted icon |

All four share the icon's coordinates (the glyph and the template crop the viewBox), so shapes line up when you stack them.

## Colours

| Role | Colour |
|---|---|
| Plate (sable) | `#2B2320`, top of the gradient `#352B27` |
| Fur (cream) | `#F5EBDC` |
| Inner ears (amber) | `#E39A33` |
| Mask, nose, paws (ink) | `#2B2320`, the plate colour, so they read as holes |
| Dark plate and ink | `#16110F`, top `#1E1815` |

## Clear space

Keep at least the width of one ear (about 15% of the glyph's width) free around the glyph or the plate. On a plate, the body runs off the bottom edge on purpose: the ferret pops up from below.

## Don'ts

- Don't put the cream glyph on a light background. Use the plated icon there.
- Don't recolour the fur, or add outlines, gradients or shadows to the ferret.
- Don't add eyes to the one-colour template, or draw it in more than one colour.
- Don't stretch, rotate or crop the head.
- Don't put the plated icon on another plate (macOS draws no plate of its own).

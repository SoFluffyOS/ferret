#!/usr/bin/env bash
# Renders the app icons for macOS, iOS, Android and Windows from the docs logo
# (apps/ferret_docs/web/images/logo.svg). Needs python3, rsvg-convert (librsvg)
# and ImageMagick 7. The Linux hicolor set has its own packaging/linux/icons/generate.sh.
#
#   scripts/generate_icons.sh            # write every platform's icons
#   scripts/generate_icons.sh --sheet    # also render temp/icons_contact_sheet.png
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for tool in python3 rsvg-convert magick; do
  command -v "$tool" >/dev/null || { echo "missing $tool (brew install librsvg imagemagick)" >&2; exit 1; }
done

work="$(mktemp -d)"
trap 'rm -r "$work"' EXIT

app="$root/apps/ferret"
macos="$app/macos/Runner/Assets.xcassets/AppIcon.appiconset"
ios="$app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
res="$app/android/app/src/main/res"
windows="$app/windows/runner/resources"

python3 - "$root/apps/ferret_docs/web/images/logo.svg" "$work" "$res" <<'PY'
import math, re, sys
logo_path, work, res = sys.argv[1:4]
src = open(logo_path).read()
inner = src[src.index('>', src.index('<svg')) + 1:src.rindex('</svg>')].strip()
LOGO_W, LOGO_H = 210, 274
NAVY = '#09387E'

def squircle(x, y, size, n=5.0, steps=720):
    r = size / 2
    cx, cy = x + r, y + r
    pts = []
    for i in range(steps):
        t = 2 * math.pi * i / steps
        c, s = math.cos(t), math.sin(t)
        pts.append((cx + r * math.copysign(abs(c) ** (2 / n), c),
                    cy + r * math.copysign(abs(s) ** (2 / n), s)))
    return 'M' + ' L'.join(f'{px:.2f},{py:.2f}' for px, py in pts) + ' Z'

def logo(cx, cy, height, recolor=None):
    s = height / LOGO_H
    body = inner
    for old, new in (recolor or {}).items():
        body = body.replace(old, new)
    return (f'<g transform="translate({cx - LOGO_W / 2 * s:.2f} {cy - LOGO_H / 2 * s:.2f}) '
            f'scale({s:.4f})">{body}</g>')

DEFS = '''<defs>
<linearGradient id="plate" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#DCE8F7"/>
</linearGradient>
<linearGradient id="sheen" x1="0" y1="0" x2="0" y2="1">
  <stop offset="0" stop-color="#FFFFFF" stop-opacity="0.9"/><stop offset="0.5" stop-color="#FFFFFF" stop-opacity="0"/>
</linearGradient>
<filter id="drop" x="-20%" y="-20%" width="140%" height="140%">
  <feGaussianBlur in="SourceAlpha" stdDeviation="14"/><feOffset dy="12"/>
  <feComponentTransfer><feFuncA type="linear" slope="0.30"/></feComponentTransfer>
  <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
</filter>
<filter id="lift" x="-20%" y="-20%" width="140%" height="140%">
  <feGaussianBlur in="SourceAlpha" stdDeviation="10"/><feOffset dy="10"/>
  <feColorMatrix values="0 0 0 0 0.035  0 0 0 0 0.22  0 0 0 0 0.49  0 0 0 0.28 0"/>
  <feMerge><feMergeNode/><feMergeNode in="SourceGraphic"/></feMerge>
</filter>
</defs>'''

def svg(body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" '
            f'viewBox="0 0 1024 1024">{DEFS}{body}</svg>')

def plated(x, size, shadow):
    plate = squircle(x, x, size)
    edge = squircle(x + size * 0.004, x + size * 0.004, size * 0.992)
    filt = ' filter="url(#drop)"' if shadow else ''
    return (f'<path d="{plate}" fill="url(#plate)"{filt}/>'
            f'<path d="{edge}" fill="none" stroke="url(#sheen)" stroke-width="{size * 0.006:.2f}"/>'
            f'<g filter="url(#lift)">{logo(512, 512 + size * 0.01, size * 0.70)}</g>')

def write(name, text):
    open(f'{work}/{name}', 'w').write(text)

# macOS: Apple's template grid, an 824 squircle centred on 1024 with a soft drop shadow.
write('macos.svg', svg(plated(100, 824, True)))
# Windows and legacy Android: the same plate, nearly edge to edge.
write('plate.svg', svg(plated(24, 976, False)))
# iOS masks the corners itself: full-bleed, opaque.
write('ios.svg', svg('<rect width="1024" height="1024" fill="url(#plate)"/>'
                     f'<g filter="url(#lift)">{logo(512, 520, 690)}</g>'))
# iOS 18 dark: transparent so the system draws its dark backdrop; the navy outline
# would vanish on it, so it turns into a lighter blue.
write('ios_dark.svg', svg(logo(512, 520, 690, {NAVY: '#1E5BB0'})))
write('logo_only.svg', svg(logo(512, 520, 690)))

# Android adaptive icon: 108dp canvas, the logo inside the 66dp safe circle.
def attrs(tag):
    return dict(re.findall(r'([\w-]+)="([^"]*)"', tag))

def color(value):
    return '#000000' if value == 'black' else value

def circle_path(a):
    cx, cy, r = float(a['cx']), float(a['cy']), float(a['r'])
    return f'M{cx - r},{cy}a{r},{r} 0 1,0 {2 * r},0a{r},{r} 0 1,0 {-2 * r},0Z'

shapes = []
for tag in re.findall(r'<(?:path|circle)\b[^>]*>', inner):
    a = attrs(tag)
    d = a['d'] if tag.startswith('<path') else circle_path(a)
    shapes.append((d, a))

height = 56
s = height / LOGO_H
group = (f'<group android:translateX="{54 - LOGO_W / 2 * s:.3f}" '
         f'android:translateY="{54 - LOGO_H / 2 * s:.3f}" android:scaleX="{s:.5f}" android:scaleY="{s:.5f}">')
head = ('<?xml version="1.0" encoding="utf-8"?>\n'
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
        '    android:width="108dp" android:height="108dp"\n'
        '    android:viewportWidth="108" android:viewportHeight="108">\n    ' + group + '\n')
tail = '    </group>\n</vector>\n'

fg = []
for d, a in shapes:
    line = f'        <path android:pathData="{d}"'
    if 'fill' in a:
        line += f' android:fillColor="{color(a["fill"])}"'
    if 'fill-opacity' in a:
        line += f' android:fillAlpha="{a["fill-opacity"]}"'
    if 'stroke' in a:
        line += f' android:strokeColor="{color(a["stroke"])}" android:strokeWidth="1"'
    fg.append(line + '/>')
open(f'{res}/drawable/ic_launcher_foreground.xml', 'w').write(head + '\n'.join(fg) + '\n' + tail)

# Monochrome (themed icons): the silhouette with the light muzzle and the eyes
# cut out, nose and pupils put back.
silhouette = shapes[0][0]
navy = [d for d, a in shapes if a.get('fill') == NAVY and 'stroke' not in a and d != silhouette]
cutouts = [d for d, a in shapes if a.get('fill') == '#40C4FF'] + navy[-2:]
pupils = [navy[0]] + [d for d, a in shapes if a.get('fill') == '#0066B4'][-2:]
mono = [f'        <path android:pathData="{" ".join([silhouette] + cutouts)}" '
        'android:fillColor="#FFFFFFFF" android:fillType="evenOdd"/>']
mono += [f'        <path android:pathData="{d}" android:fillColor="#FFFFFFFF"/>' for d in pupils]
open(f'{res}/drawable/ic_launcher_monochrome.xml', 'w').write(head + '\n'.join(mono) + '\n' + tail)
PY

render() { rsvg-convert -w "$2" -h "$2" "$work/$1.svg" -o "$3"; }

for size in 16 32 64 128 256 512 1024; do
  render macos "$size" "$macos/app_icon_$size.png"
done

render ios 1024 "$work/ios.png"
magick "$work/ios.png" -background white -alpha remove -alpha off "PNG24:$ios/Icon-App-1024x1024@1x.png"
render ios_dark 1024 "$ios/Icon-App-1024x1024@1x-dark.png"
render logo_only 1024 "$work/tinted.png"
magick "$work/tinted.png" -colorspace gray -auto-level -gamma 1.8 -background black -alpha remove -alpha off \
  "PNG24:$ios/Icon-App-1024x1024@1x-tinted.png"

for density in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  render plate "${density#*:}" "$res/mipmap-${density%%:*}/ic_launcher.png"
done

for size in 16 24 32 48 64 256; do
  render plate "$size" "$work/win_$size.png"
done
magick "$work"/win_{16,24,32,48,64,256}.png "$windows/app_icon.ico"

if [[ "${1:-}" == "--sheet" ]]; then
  sheet="$root/temp/icons_contact_sheet.png"
  mkdir -p "$root/temp"
  for size in 16 32 64 128 256; do
    for bg in '#FFFFFF' '#1E1E1E'; do
      rsvg-convert -w "$size" -h "$size" "$work/macos.svg" |
        magick - -background "$bg" -gravity center -extent 272x272 "$work/sheet_mac_${size}_${bg#\#}.png"
    done
  done
  render ios 256 "$work/s_ios.png"
  magick "$work/s_ios.png" \( -size 256x256 xc:black -fill white -draw "roundrectangle 0,0,255,255,58,58" \) \
    -alpha off -compose CopyOpacity -composite -compose Over \
    -background '#E9E9EE' -gravity center -extent 272x272 "$work/sheet_ios.png"
  render ios_dark 256 "$work/s_dark.png"
  magick -size 256x256 gradient:'#3A3A3C'-'#111111' "$work/s_dark.png" -composite \
    \( -size 256x256 xc:black -fill white -draw "roundrectangle 0,0,255,255,58,58" \) \
    -alpha off -compose CopyOpacity -composite -compose Over -background '#000000' -gravity center -extent 272x272 \
    "$work/sheet_ios_dark.png"
  magick "$ios/Icon-App-1024x1024@1x-tinted.png" -resize 256x256 \
    \( +clone -fill '#7FB2FF' -colorize 100 \) -compose Multiply -composite \
    \( -size 256x256 xc:black -fill white -draw "roundrectangle 0,0,255,255,58,58" \) \
    -alpha off -compose CopyOpacity -composite -compose Over -background '#000000' -gravity center -extent 272x272 \
    "$work/sheet_ios_tinted.png"
  magick "$res/mipmap-xxxhdpi/ic_launcher.png" -background '#F2F2F2' -gravity center -extent 272x272 \
    "$work/sheet_legacy.png"
  magick "$windows/app_icon.ico[0]" -filter point -resize 800% -background '#202020' -gravity center \
    -extent 272x272 "$work/sheet_win16.png"
  magick -background '#888888' \
    \( "$work"/sheet_mac_{16,32,64,128,256}_FFFFFF.png +append \) \
    \( "$work"/sheet_mac_{16,32,64,128,256}_1E1E1E.png +append \) \
    \( "$work"/sheet_{ios,ios_dark,ios_tinted,legacy,win16}.png +append \) \
    -append "$sheet"
  echo "$sheet"
fi

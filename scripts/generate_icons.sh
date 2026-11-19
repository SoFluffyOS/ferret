#!/usr/bin/env bash
# Renders every icon from the logo sources in branding/: macOS, iOS (light,
# dark, tinted), Android (adaptive, themed, legacy), Windows, Linux (through
# packaging/linux/icons/generate.sh), the Android notification and Quick
# Settings icons and splash, the iOS launch screen, the in-app logo, the
# Windows installer and MSIX images, the browser extension, the macOS menubar
# glyph and the docs logo, favicon, touch icon and social image. Needs
# python3, rsvg-convert (librsvg) and ImageMagick 7.
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
ico="$app/windows/runner/resources/app_icon.ico"
docs="$root/apps/ferret_docs/web"
menubar="$root/packages/ferret_menubar/macos/ferret_menubar/Sources/ferret_menubar/FerretGlyph.swift"
launch="$app/ios/Runner/Assets.xcassets/LaunchImage.imageset"
msix="$root/packaging/windows/msix/Assets"
extension="$root/extensions/browser/icons"
logo_svg="$root/packages/feature_kit/assets/ferret_logo.svg"
# The status bar, Quick Settings and notification icon: the app's own copy,
# and one per plugin that posts a notification of its own.
status_icons=(
  "$res/drawable/ic_stat_ferret.xml"
  "$root/packages/ferret_system/android/src/main/res/drawable/ferret_system_status.xml"
  "$root/packages/ferret_mirroring/android/src/main/res/drawable/ferret_mirroring_status.xml"
  "$root/packages/ferret_find/android/src/main/res/drawable/ferret_find_status.xml"
)

python3 - "$root/branding" "$work" "$res" "$docs" "$menubar" "$logo_svg" "${status_icons[@]}" <<'PY'
import re, sys
import xml.etree.ElementTree as ET

branding, work, res, docs, menubar, logo_svg = sys.argv[1:7]
status_icons = sys.argv[7:]
NS = 'http://www.w3.org/2000/svg'
ET.register_namespace('', NS)


def load(name):
    return ET.parse(f'{branding}/{name}.svg').getroot()


def by_id(tree, ident):
    return next(e for e in tree.iter() if e.get('id') == ident)


def text(element):
    return ET.tostring(element, encoding='unicode').replace(f' xmlns="{NS}"', '')


def svg(view_box, body, size=1024):
    return (f'<svg xmlns="{NS}" width="{size}" height="{size}" viewBox="{view_box}">{body}</svg>\n')


def write(name, content):
    open(f'{work}/{name}', 'w').write(content)


icon, dark, glyph, template = (load(n) for n in ('ferret-icon', 'ferret-icon-dark', 'ferret-glyph', 'ferret-template'))
PLATE_BOX = '100 100 824 824'


def defs(tree):
    return text(tree.find(f'{{{NS}}}defs'))


def plate_colour(tree):
    return by_id(tree, 'plate-fill').findall(f'{{{NS}}}stop')[-1].get('stop-color')


def flat(tree, view_box, size=1024):
    """The plated icon without its shadow, cropped to view_box."""
    return svg(view_box, defs(tree) + f'<path d="{by_id(tree, "plate").get("d")}" fill="url(#plate-fill)"/>'
               + text(by_id(tree, 'ferret')) + text(by_id(tree, 'rim')), size)


def full_bleed(tree):
    """iOS draws its own corners: an opaque square, the plate's art scaled to fill it."""
    return svg(PLATE_BOX, defs(tree) + '<rect width="1024" height="1024" fill="url(#plate-fill)"/>'
               + ''.join(text(child) for child in by_id(tree, 'ferret')))


write('macos.svg', open(f'{branding}/ferret-icon.svg').read())
write('plate.svg', flat(icon, PLATE_BOX))
write('windows.svg', flat(icon, '84 84 856 856'))
write('ios.svg', full_bleed(icon))
write('ios_dark.svg', full_bleed(dark))
write('template.svg', open(f'{branding}/ferret-template.svg').read())
write('glyph.svg', open(f'{branding}/ferret-glyph.svg').read())
open(f'{docs}/images/logo.svg', 'w').write(flat(icon, PLATE_BOX, size=64))

# The app's own logo inside the app (Home's welcome).
open(logo_svg, 'w').write(flat(icon, PLATE_BOX, size=64))

# Android adaptive icon: 108dp canvas. The plate's 824 maps onto the 72dp the
# launcher shows, which keeps the head and ears inside the 66dp safe circle.
# The body runs on past the bottom edge, as it does off the plate.
SCALE = 72 / 824
SHIFT = 54 - 512 * SCALE
fur = by_id(glyph, 'body').get('fill')
bleed = ET.Element(f'{{{NS}}}rect', x='316', y='900', width='392', height='380', fill=fur)
shapes = list(glyph)
body = next(i for i, e in enumerate(shapes) if e.get('id') == 'body')
foreground = shapes[:body] + [bleed] + shapes[body:]
silhouette = by_id(template, 'silhouette')


def path_data(element):
    tag = element.tag.removeprefix(f'{{{NS}}}')
    if tag == 'circle':
        cx, cy, r = (float(element.get(key)) for key in ('cx', 'cy', 'r'))
        return f'M{cx - r:g},{cy:g}a{r:g},{r:g} 0 1,0 {2 * r:g},0a{r:g},{r:g} 0 1,0 {-2 * r:g},0Z'
    if tag == 'rect':
        return 'M{x},{y}h{width}v{height}h-{width}Z'.format(**element.attrib)
    return element.get('d')


def vector(elements, colour=None):
    lines = []
    for element in elements:
        rule = ' android:fillType="evenOdd"' if element.get('fill-rule') == 'evenodd' else ''
        lines.append(f'        <path android:fillColor="{colour or element.get("fill")}"{rule}\n'
                     f'            android:pathData="{path_data(element)}"/>')
    return ('<?xml version="1.0" encoding="utf-8"?>\n'
            '<!-- Generated by scripts/generate_icons.sh from branding/. Do not edit. -->\n'
            '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
            '    android:width="108dp" android:height="108dp"\n'
            '    android:viewportWidth="108" android:viewportHeight="108">\n'
            f'    <group android:scaleX="{SCALE:.6f}" android:scaleY="{SCALE:.6f}"\n'
            f'        android:translateX="{SHIFT:.4f}" android:translateY="{SHIFT:.4f}">\n'
            + '\n'.join(lines) + '\n    </group>\n</vector>\n')


open(f'{res}/drawable/ic_launcher_foreground.xml', 'w').write(vector(foreground))

# Status bar icon: white on clear, the head and shoulders filling 22 of the
# 24dp box, so the mask still reads at that size. The viewport cuts the body.
STATUS_TOP, STATUS_HEIGHT = 213, 490
status_scale = 22 / STATUS_HEIGHT
status_x = 12 - 512 * status_scale
status_y = 1 - STATUS_TOP * status_scale
status = ('<?xml version="1.0" encoding="utf-8"?>\n'
          '<!-- Generated by scripts/generate_icons.sh from branding/ferret-template.svg. Do not edit. -->\n'
          '<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
          '    android:width="24dp" android:height="24dp"\n'
          '    android:viewportWidth="24" android:viewportHeight="24">\n'
          f'    <group android:scaleX="{status_scale:.6f}" android:scaleY="{status_scale:.6f}"\n'
          f'        android:translateX="{status_x:.4f}" android:translateY="{status_y:.4f}">\n'
          '        <path android:fillColor="#FFFFFFFF" android:fillType="evenOdd"\n'
          f'            android:pathData="{silhouette.get("d")}"/>\n'
          '    </group>\n</vector>\n')
for target in status_icons:
    open(target, 'w').write(status)
write('status.svg', svg('0 0 24 24', f'<g transform="translate({status_x} {status_y}) scale({status_scale})">'
                        f'<path fill="#FFFFFF" fill-rule="evenodd" d="{silhouette.get("d")}"/></g>', size=24))
open(f'{res}/drawable/ic_launcher_monochrome.xml', 'w').write(vector([silhouette, bleed], '#FFFFFFFF'))
open(f'{res}/values/ic_launcher_background.xml', 'w').write(
    '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
    f'    <color name="ic_launcher_background">{plate_colour(icon)}</color>\n</resources>\n')

# The same layers as SVG, for the legacy PNGs and the contact sheet.
group = f'<g transform="translate({SHIFT} {SHIFT}) scale({SCALE})">'
write('android.svg', svg('0 0 108 108', f'<rect width="108" height="108" fill="{plate_colour(icon)}"/>'
                         + group + ''.join(text(e) for e in foreground) + '</g>'))
write('android_mono.svg', svg('0 0 108 108', group + f'<path fill="#FFFFFF" fill-rule="evenodd" '
                              f'd="{silhouette.get("d")}"/>' + text(bleed).replace(fur, '#FFFFFF') + '</g>'))

# The docs site's social preview: the ferret on sable with the name and what it does.
glyph_box = glyph.get('viewBox')
glyph_art = ''.join(text(child) for child in glyph)
write('social.svg',
      f'<svg xmlns="{NS}" width="1200" height="630" viewBox="0 0 1200 630">'
      f'<rect width="1200" height="630" fill="{plate_colour(icon)}"/>'
      f'<svg x="110" y="95" width="346" height="535" viewBox="{glyph_box}">{glyph_art}</svg>'
      f'<text x="530" y="300" fill="{fur}" font-family="Helvetica Neue, Helvetica, Arial, sans-serif" '
      'font-size="112" font-weight="700">Ferret</text>'
      f'<text x="534" y="380" fill="{fur}" fill-opacity="0.72" font-family="Helvetica Neue, Helvetica, Arial, sans-serif" '
      'font-size="38">Continue on your other devices.</text>'
      f'<text x="534" y="432" fill="{fur}" fill-opacity="0.72" font-family="Helvetica Neue, Helvetica, Arial, sans-serif" '
      'font-size="38">Local network, no account.</text></svg>\n')
# The Windows installer's tall side picture: the ferret popping up from the bottom.
write('wizard.svg',
      f'<svg xmlns="{NS}" width="164" height="314" viewBox="0 0 164 314">'
      f'<rect width="164" height="314" fill="{plate_colour(icon)}"/>'
      f'<svg x="22" y="120" width="120" height="194" viewBox="{glyph_box.split()[0]} {glyph_box.split()[1]} 460 744">'
      f'{glyph_art}</svg></svg>\n')

# The menubar glyph: the template's path as Swift, so it stays sharp at any scale.
box = [float(v) for v in template.get('viewBox').split()]
swift = []
for command, args in re.findall(r'([MLCZ])([^MLCZ]*)', silhouette.get('d')):
    numbers = re.findall(r'-?[\d.]+', args)
    points = [f'NSPoint(x: {x}, y: {y})' for x, y in zip(numbers[::2], numbers[1::2])]
    if command == 'M':
        swift.append(f'        path.move(to: {points[0]})')
    if command == 'L':
        swift.append(f'        path.line(to: {points[0]})')
    if command == 'C':
        swift.append(f'        path.curve(to: {points[2]}, controlPoint1: {points[0]}, controlPoint2: {points[1]})')
    if command == 'Z':
        swift.append('        path.close()')

open(menubar, 'w').write(
    '// Generated by scripts/generate_icons.sh from branding/ferret-template.svg. Do not edit.\n'
    'import Cocoa\n\n'
    '/// The one-colour ferret: head and body, with the mask and the nose cut out.\n'
    'enum FerretGlyph {\n'
    '    /// The box the path was drawn in, in its own coordinates (y grows downwards).\n'
    f'    static let bounds = NSRect(x: {box[0]:g}, y: {box[1]:g}, width: {box[2]:g}, height: {box[3]:g})\n\n'
    '    static func path() -> NSBezierPath {\n'
    '        let path = NSBezierPath()\n'
    '        path.windingRule = .evenOdd\n'
    + '\n'.join(swift) + '\n'
    '        return path\n'
    '    }\n'
    '}\n')
PY

render() { rsvg-convert -w "$2" -h "$2" "$work/$1.svg" -o "$3"; }

for size in 16 32 64 128 256 512 1024; do
  render macos "$size" "$macos/app_icon_$size.png"
done

# No time stamps in the PNGs, so running the script again changes nothing.
still=(-define png:exclude-chunk=date,time)
render ios 1024 "$work/ios.png"
magick "$work/ios.png" -alpha remove -alpha off "${still[@]}" "PNG24:$ios/Icon-App-1024x1024@1x.png"
render ios_dark 1024 "$work/ios_dark.png"
magick "$work/ios_dark.png" -alpha remove -alpha off "${still[@]}" "PNG24:$ios/Icon-App-1024x1024@1x-dark.png"
# Tinted: grayscale on black, which iOS colours by brightness.
magick "$work/ios_dark.png" -alpha off -colorspace gray -level 9%,96% "${still[@]}" "$ios/Icon-App-1024x1024@1x-tinted.png"

for density in mdpi:48 hdpi:72 xhdpi:96 xxhdpi:144 xxxhdpi:192; do
  render plate "${density#*:}" "$res/mipmap-${density%%:*}/ic_launcher.png"
done

for size in 16 24 32 48 64 256; do
  render windows "$size" "$work/win_$size.png"
done
magick "$work"/win_{16,24,32,48,64,256}.png "$ico"

for size in 16 32 48; do
  render plate "$size" "$work/fav_$size.png"
done
magick "$work"/fav_{16,32,48}.png "$docs/favicon.ico"

render ios 180 "$work/touch.png"
magick "$work/touch.png" -alpha remove -alpha off "${still[@]}" "PNG24:$docs/images/apple-touch-icon.png"
rsvg-convert "$work/social.svg" | magick - "${still[@]}" "PNG24:$docs/images/social.png"

# iOS launch screen: the ferret on sable, 90 points wide.
for scale in 1 2 3; do
  suffix="@${scale}x"
  [[ $scale == 1 ]] && suffix=""
  rsvg-convert -w $((90 * scale)) -h $((139 * scale)) "$work/glyph.svg" | magick - "${still[@]}" "$launch/LaunchImage$suffix.png"
done

for size in 16 32 64 128; do
  render plate "$size" "$work/ext.png"
  magick "$work/ext.png" "${still[@]}" "$extension/icon-$size.png"
done

# MSIX: the plated icon on every tile, the wide tile with room either side.
msix_icon() { render windows "$1" "$work/msix.png" && magick "$work/msix.png" "${still[@]}" "$msix/$2"; }
msix_icon 150 Square150x150Logo.png
msix_icon 44 Square44x44Logo.png
msix_icon 50 StoreLogo.png
for size in 16 24 48 256; do
  msix_icon "$size" "Square44x44Logo.targetsize-${size}_altform-unplated.png"
done
render windows 150 "$work/wide.png"
magick "$work/wide.png" -background none -gravity center -extent 310x150 "${still[@]}" "$msix/Wide310x150Logo.png"

# Inno Setup: the small corner icon and the tall side picture, each at 100% and 200%.
inno="$root/packaging/windows"
for scale in 1 2; do
  render plate $((55 * scale)) "$work/small.png"
  magick "$work/small.png" -background white -alpha remove -alpha off -type truecolor "BMP3:$inno/wizard-small-$((scale * 100)).bmp"
  rsvg-convert -w $((164 * scale)) -h $((314 * scale)) "$work/wizard.svg" | \
    magick - -alpha off -type truecolor "BMP3:$inno/wizard-$((scale * 100)).bmp"
done

# Windows notifications read the icon from a file next to the app.
render plate 256 "$work/notice.png"
magick "$work/notice.png" "${still[@]}" "$root/modules/shell/assets/notice_icon.png"

"$root/packaging/linux/icons/generate.sh"

if [[ "${1:-}" == "--sheet" ]]; then
  sheet="$root/temp/icons_contact_sheet.png"
  mkdir -p "$root/temp"
  cell() { magick "$1" -background "$2" -gravity center -extent 200x200 "$3"; }
  zoom() { magick "$1" -filter point -resize "$2" "$3"; }
  rounded() {
    magick "$1" \( +clone -alpha off -fill black -colorize 100 -fill white \
      -draw "roundrectangle 0,0,179,179,40,40" \) -alpha off -compose CopyOpacity -composite "$2"
  }
  # The launcher shows the middle 72 of the adaptive icon's 108dp, here in a circle.
  circle() {
    magick "$1" \( +clone -alpha off -fill black -colorize 100 -fill white -draw "circle 90,90 90,30" \) \
      -alpha off -compose CopyOpacity -composite -gravity center -crop 120x120+0+0 +repage "$2"
  }

  for size in 16 32 64 128; do
    render macos "$size" "$work/m_$size.png"
    zoom "$work/m_$size.png" "$((128 / size * 100))%" "$work/z_$size.png"
    cell "$work/z_$size.png" '#FFFFFF' "$work/sheet_mac_${size}_light.png"
    cell "$work/z_$size.png" '#1E1E1E' "$work/sheet_mac_${size}_dark.png"
  done
  magick "$ios/Icon-App-1024x1024@1x.png" -resize 180x180 "$work/s_ios.png"
  magick "$ios/Icon-App-1024x1024@1x-dark.png" -resize 180x180 "$work/s_ios_dark.png"
  magick "$ios/Icon-App-1024x1024@1x-tinted.png" -resize 180x180 -colorspace sRGB \
    \( +clone -fill '#E8A867' -colorize 100 \) -compose Multiply -composite "$work/s_ios_tinted.png"
  for name in ios ios_dark ios_tinted; do
    rounded "$work/s_$name.png" "$work/r_$name.png"
  done
  cell "$work/r_ios.png" '#E9E9EE' "$work/sheet_ios.png"
  cell "$work/r_ios_dark.png" '#000000' "$work/sheet_ios_dark.png"
  cell "$work/r_ios_tinted.png" '#000000' "$work/sheet_ios_tinted.png"
  render android 180 "$work/s_android.png"
  circle "$work/s_android.png" "$work/c_android.png"
  cell "$work/c_android.png" '#F2F2F2' "$work/sheet_android.png"
  render android_mono 180 "$work/s_mono_mask.png"
  magick -size 180x180 xc:'#22364D' \( "$work/s_mono_mask.png" -fill '#D5E3F7' -colorize 100 \) -composite \
    "$work/s_mono.png"
  circle "$work/s_mono.png" "$work/c_mono.png"
  cell "$work/c_mono.png" '#F2F2F2' "$work/sheet_mono.png"
  cell "$res/mipmap-xxxhdpi/ic_launcher.png" '#F2F2F2' "$work/sheet_legacy.png"
  zoom "$ico[0]" 800% "$work/z_win16.png"
  cell "$work/z_win16.png" '#202020' "$work/sheet_win16.png"
  zoom "$ico[2]" 400% "$work/z_win32.png"
  cell "$work/z_win32.png" '#F3F3F3' "$work/sheet_win32.png"
  zoom "$root/packaging/linux/icons/hicolor/48x48/apps/io.sofluffy.ferret.png" 300% "$work/z_linux.png"
  cell "$work/z_linux.png" '#3C3C3C' "$work/sheet_linux.png"
  zoom "$docs/favicon.ico[0]" 800% "$work/z_fav.png"
  cell "$work/z_fav.png" '#FFFFFF' "$work/sheet_favicon.png"
  rsvg-convert -h 32 "$work/template.svg" -o "$work/s_menubar.png"
  zoom "$work/s_menubar.png" 400% "$work/z_menubar.png"
  magick "$work/z_menubar.png" -fill '#000000' -colorize 100 "$work/z_menubar_light.png"
  magick "$work/z_menubar.png" -fill '#FFFFFF' -colorize 100 "$work/z_menubar_dark.png"
  cell "$work/z_menubar_light.png" '#F6F6F6' "$work/sheet_menubar_light.png"
  cell "$work/z_menubar_dark.png" '#2B2B2B' "$work/sheet_menubar_dark.png"
  magick -background '#888888' \
    \( "$work"/sheet_mac_{16,32,64,128}_light.png "$work"/sheet_mac_{16,32,64,128}_dark.png +append \) \
    \( "$work"/sheet_{ios,ios_dark,ios_tinted,android,mono,legacy,win16,win32}.png +append \) \
    \( "$work"/sheet_{linux,favicon,menubar_light,menubar_dark}.png +append \) \
    -gravity west -append "$sheet"
  echo "$sheet"
fi

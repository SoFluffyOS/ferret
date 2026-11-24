#!/usr/bin/env bash
# Creates a feature: modules/<id> (Feature + FeatureUi + l10n + test) and its
# platform plugin packages/ferret_<id>, registers both in the workspace and
# wires the feature into the app.
#
#   scripts/new_feature.sh clipboard Clipboard ClipboardFeature clipboard
#   (id, title, class prefix, Lucide icon name)
set -euo pipefail
# shellcheck source=scripts/sdk.sh
. "$(dirname "${BASH_SOURCE[0]}")/sdk.sh"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
id="$1"
title="$2"
class="$3"
camel="$(echo "$id" | awk -F_ '{printf $1; for (i = 2; i <= NF; i++) printf toupper(substr($i,1,1)) substr($i,2)}')"
icon="${4:-box}"
module="$ROOT/modules/$id"
plugin="$ROOT/packages/ferret_$id"
leftovers="${TMPDIR:-/tmp}/ferret-template-leftovers/$id"

if [ -e "$module" ] || [ -e "$plugin" ]; then
  echo "Feature $id already exists" >&2
  exit 1
fi

mkdir -p "$leftovers"

# Platform plugin. Linux and Windows templates need desktop support switched
# on; restore the user's setting afterwards.
linux_was="$("${FLUTTER[@]}" config --list 2>/dev/null | sed -n 's/.*enable-linux-desktop: //p')"
windows_was="$("${FLUTTER[@]}" config --list 2>/dev/null | sed -n 's/.*enable-windows-desktop: //p')"
"${FLUTTER[@]}" config --enable-linux-desktop --enable-windows-desktop >/dev/null
"${FLUTTER[@]}" create --no-pub --template=plugin --org io.sofluffy \
  --platforms android,ios,macos,linux,windows "$plugin" >/dev/null || true
[ "$linux_was" = "true" ] || "${FLUTTER[@]}" config --no-enable-linux-desktop >/dev/null
[ "$windows_was" = "true" ] || "${FLUTTER[@]}" config --no-enable-windows-desktop >/dev/null

for leftover in pubspec.lock "ferret_$id.iml" CHANGELOG.md LICENSE analysis_options.yaml example test \
  "lib/ferret_${id}_platform_interface.dart" "lib/ferret_${id}_method_channel.dart" "lib/ferret_${id}_pigeon.dart"; do
  if [ -e "$plugin/$leftover" ]; then
    mv "$plugin/$leftover" "$leftovers/"
  fi
done
mkdir -p "$plugin/test"
cat > "$plugin/lib/ferret_$id.dart" <<DART
/// Platform code for Ferret's $(echo "$title" | tr '[:upper:]' '[:lower:]') feature. Each platform implements the
/// pigeon API in pigeon/messages.dart.
library;

export 'package:ferret_$id/src/messages.g.dart';
DART

python3 - "$plugin/pubspec.yaml" "$id" "$title" <<'PY'
import re, sys
path, feature, title = sys.argv[1:]
text = open(path).read()
plugin = text[text.index('\nflutter:\n'):]
plugin = re.sub(r'\n  #[^\n]*', '', plugin)
plugin = re.sub(r'\n{2,}', '\n', plugin).rstrip() + '\n'
dev_pigeon = '  pigeon: ^29.0.1\n' if 'pigeon' in text else ''
open(path, 'w').write(f"""name: ferret_{feature}
description: Platform code for Ferret's {title.lower()} feature, reusable on its own.
version: 0.1.0
publish_to: none
resolution: workspace

environment:
  sdk: ^3.14.0
  flutter: ">=3.50.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  lints: ^6.0.0
{dev_pigeon}
""" + plugin.lstrip('\n'))
PY

# Feature module.
mkdir -p "$module/lib/feature" "$module/lib/ui" "$module/lib/l10n/arb" "$module/test"
cat > "$module/pubspec.yaml" <<YAML
name: $id
description: Ferret's $(echo "$title" | tr '[:upper:]' '[:lower:]') feature.
version: 0.1.0
publish_to: none
resolution: workspace

environment:
  sdk: ^3.14.0
  flutter: ">=3.50.0"

dependencies:
  core:
    path: ../../packages/core
  engine:
    path: ../../packages/engine
  feature_kit:
    path: ../../packages/feature_kit
  ferret_$id:
    path: ../../packages/ferret_$id
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: ^0.20.3
  lucide_icons_flutter: ^4.0.3
  protobuf: ^6.1.0
  protocol:
    path: ../../packages/protocol
  provider: ^6.1.5+1
  sofluffy_ui:
    path: ../../packages/sofluffy_ui

dev_dependencies:
  flutter_test:
    sdk: flutter
  lints: ^6.0.0

flutter:
  generate: true
YAML

cat > "$module/l10n.yaml" <<YAML
arb-dir: lib/l10n/arb
template-arb-file: ${id}_en.arb
output-dir: lib/l10n/generated
output-localization-file: ${id}_localizations.dart
output-class: ${class}Localizations
nullable-getter: false
YAML

cat > "$module/lib/l10n/arb/${id}_en.arb" <<JSON
{
  "@@locale": "en",
  "title": "$title"
}
JSON

cat > "$module/lib/l10n/l10n.dart" <<DART
import 'package:$id/l10n/generated/${id}_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:$id/l10n/generated/${id}_localizations.dart';

extension ${class}L10n on BuildContext {
  ${class}Localizations get ${camel}L10n => ${class}Localizations.of(this);
}
DART

cat > "$module/lib/feature/${id}_feature.dart" <<DART
import 'package:engine/engine.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/protocol.dart';

/// The engine side of $title.
class ${class}Feature extends Feature {
  static const featureId = '$id';

  @override
  String get id => featureId;

  @override
  Future<GeneratedMessage?> onEnvelope(Session session, Envelope envelope) async => null;
}
DART

cat > "$module/lib/ui/${id}_feature_ui.dart" <<DART
import 'package:$id/feature/${id}_feature.dart';
import 'package:$id/l10n/l10n.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The app side of $title.
class ${class}FeatureUi extends FeatureUi {
  ${class}FeatureUi() : feature = ${class}Feature();

  @override
  final ${class}Feature feature;

  @override
  String get featureId => ${class}Feature.featureId;

  @override
  List<LocalizationsDelegate<Object>> get localizationsDelegates => const [${class}Localizations.delegate];

  @override
  String title(BuildContext context) => context.${camel}L10n.title;

  @override
  IconData get icon => LucideIcons.$icon;
}
DART

cat > "$module/lib/$id.dart" <<DART
/// Ferret's $(echo "$title" | tr '[:upper:]' '[:lower:]') feature.
library;

export 'package:$id/feature/${id}_feature.dart';
export 'package:$id/ui/${id}_feature_ui.dart';
DART

cat > "$module/test/${id}_feature_test.dart" <<DART
import 'package:$id/$id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the feature and its UI share one id', () {
    final ui = ${class}FeatureUi();

    expect(ui.featureId, ${class}Feature.featureId);
    expect(ui.feature.id, ${class}Feature.featureId);
  });
}
DART

(cd "$plugin" && "${DART[@]}" format "lib/ferret_$id.dart" >/dev/null)
(cd "$module" && "${FLUTTER[@]}" gen-l10n >/dev/null)
(cd "$module" && "${DART[@]}" fix --apply --code=directives_ordering >/dev/null && "${DART[@]}" format lib test >/dev/null)

# Register in the workspace and the app.
python3 - "$ROOT" "$id" "$class" <<'PY'
import re, sys
root, feature, cls = sys.argv[1:]

path = f'{root}/pubspec.yaml'
text = open(path).read()
head, rest = text.split('workspace:\n', 1)
members, tail = re.match(r'((?:  - [^\n]*\n)+)(.*)', rest, re.S).groups()
items = sorted(set(line for line in members.split('\n') if line.strip()) | {f'  - modules/{feature}', f'  - packages/ferret_{feature}'})
open(path, 'w').write(head + 'workspace:\n' + '\n'.join(items) + '\n' + tail)

path = f'{root}/apps/ferret/pubspec.yaml'
text = open(path).read()
text = text.replace('dependencies:\n', f'dependencies:\n  {feature}:\n    path: ../../modules/{feature}\n', 1)
open(path, 'w').write(text)

path = f'{root}/apps/ferret/lib/main.dart'
text = open(path).read()
new_import = f"import 'package:{feature}/{feature}.dart';"
imports = sorted(set(re.findall(r"import '[^']+';", text)) | {new_import})
body = text[text.index('Future<void> main()'):]
entries = re.findall(r'^    (\w+FeatureUi\(\)),$', body, re.M)
entries = sorted(set(entries) | {f'{cls}FeatureUi()'})
body = re.sub(r'(  features: \[\n)(?:    \w+FeatureUi\(\),\n)*', lambda m: m.group(1) + ''.join(f'    {entry},\n' for entry in entries), body, count=1)
open(path, 'w').write('\n'.join(imports) + '\n\n' + body)
PY

"$ROOT/scripts/with_lock.sh" pub "${FLUTTER[@]}" pub get >/dev/null
echo "Created modules/$id and packages/ferret_$id"

// ignore_for_file: avoid_print
/// Fixes iOS App Store validation error: "The large app icon can't be transparent or contain an alpha channel."
///
/// Run from vizidot-app: dart run tool/fix_ios_icon_alpha.dart
///
/// This composites the app icon onto an opaque background and overwrites the 1024x1024
/// icon in the iOS asset catalog so it has no alpha channel.
import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

void main() async {
  final scriptDir = p.dirname(p.fromUri(Platform.script));
  final projectRoot = p.dirname(scriptDir);
  final assetIcon = File(p.join(projectRoot, 'assets', 'icons', 'app_icon.png'));
  final outPath = p.join(
    projectRoot,
    'ios',
    'Runner',
    'Assets.xcassets',
    'AppIcon.appiconset',
    'icon-ios-1024x1024.png',
  );
  final outFile = File(outPath);

  if (!assetIcon.existsSync()) {
    print('Source icon not found: ${assetIcon.path}');
    exit(1);
  }

  final bytes = await assetIcon.readAsBytes();
  final icon = img.decodeImage(bytes);
  if (icon == null) {
    print('Failed to decode app_icon.png');
    exit(1);
  }

  const size = 1024;
  // Opaque white background (Apple accepts white or any solid color; no alpha).
  final background = img.Image(width: size, height: size, numChannels: 3);
  img.fill(background, color: img.ColorRgb8(255, 255, 255));

  final resized = icon.width != size || icon.height != size
      ? img.copyResize(icon, width: size, height: size, interpolation: img.Interpolation.cubic)
      : icon;

  // Ensure we composite from an image we can blend (no palette).
  final src = resized.hasPalette ? resized.convert(numChannels: 4) : resized;
  img.compositeImage(background, src, center: true, blend: img.BlendMode.alpha);

  final outBytes = img.encodePng(background);
  if (outBytes == null) {
    print('Failed to encode PNG');
    exit(1);
  }

  await outFile.parent.create(recursive: true);
  await outFile.writeAsBytes(outBytes);
  print('Wrote opaque 1024x1024 icon to: $outPath');
}

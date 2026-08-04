/// Web-only Selawik assets and dynamic loader for Fluent 2.
library;

import 'package:flutter/services.dart';

/// Loads the open-source Selawik substitute used by Fluent Web.
abstract final class FluentWebFonts {
  /// Font family registered with the Flutter engine.
  static const String family = 'Selawik';

  /// Package containing the Web assets.
  static const String package = 'fluent_2_fonts_web';

  /// Optional Light face, available for explicit application registration.
  static const String lightAsset = 'packages/$package/fonts/selawkl.ttf';

  /// Optional Semilight face, available for explicit app registration.
  static const String semilightAsset = 'packages/$package/fonts/selawksl.ttf';

  /// Whether the family has finished loading.
  static bool get isLoaded => _loaded;

  /// Loads Regular, Semibold, and Bold exactly once.
  static Future<void> ensureLoaded({AssetBundle? bundle}) =>
      _loading ??= _load(bundle ?? rootBundle);

  static Future<void> _load(AssetBundle bundle) async {
    final loader = FontLoader(family)
      ..addFont(bundle.load('packages/$package/lib/fonts/selawk.ttf'))
      ..addFont(bundle.load('packages/$package/lib/fonts/selawksb.ttf'))
      ..addFont(bundle.load('packages/$package/lib/fonts/selawkb.ttf'));
    await loader.load();
    _loaded = true;
  }

  static bool _loaded = false;
  static Future<void>? _loading;
}

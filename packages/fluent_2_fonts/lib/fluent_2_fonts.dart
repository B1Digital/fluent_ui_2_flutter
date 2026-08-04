/// Build-time platform font selection and dynamic loading for Fluent 2.
library;

import 'src/font_models.dart';
import 'src/platform_fonts_stub.dart'
    if (dart.library.js_interop) 'src/platform_fonts_web.dart'
    if (dart.library.io) 'src/platform_fonts_native.dart'
    as implementation;

export 'src/font_models.dart';

/// Resolves and, when necessary, dynamically loads Fluent platform fonts.
///
/// The conditional import keeps the Web loader out of native programs and the
/// native loaders out of Web programs. Font binaries are filtered separately
/// by each implementation package's `platforms` asset declaration.
abstract final class FluentFonts {
  /// The actual platform hosting the current Flutter engine.
  static FluentFontPlatform get currentPlatform =>
      implementation.currentFontPlatform;

  /// Returns the native or bundled families for [platform].
  static FluentFontFamilies familiesFor(FluentFontPlatform platform) =>
      implementation.fontFamiliesFor(platform);

  /// Whether [platform] uses a dynamically loaded bundled family.
  static bool requiresLoadingFor(FluentFontPlatform platform) =>
      platform == FluentFontPlatform.web ||
      platform == FluentFontPlatform.windows;

  /// Whether the current build needs a bundled font before first paint.
  static bool get requiresLoading => implementation.requiresFontLoading;

  /// Whether the current build's dynamic family is ready.
  static bool get isLoaded => implementation.isFontLoaded;

  /// Loads the font selected for this build exactly once.
  ///
  /// System-font platforms complete immediately.
  static Future<void> ensureLoaded() => implementation.ensureFontLoaded();
}

import 'package:flutter/foundation.dart';

/// A Fluent typography target, including Web which [TargetPlatform] omits.
enum FluentFontPlatform {
  /// Browser-hosted Flutter.
  web,

  /// Native Windows.
  windows,

  /// Native macOS.
  macOS,

  /// Native iOS.
  iOS,

  /// Native Android.
  android,

  /// Native Linux, for which Fluent publishes no dedicated ramp.
  linux,
}

/// The text and display families selected for one platform.
@immutable
class FluentFontFamilies {
  /// Creates a platform font-family pair.
  const FluentFontFamilies({required this.text, required this.display});

  /// Family for captions, body text, and other compact styles.
  final String text;

  /// Family for titles and display styles.
  final String display;
}

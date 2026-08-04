/// Fluent 2 design system core — tokens, theming and app shell.
///
/// This package replaces Material rather than layering on it: nothing here
/// imports `package:flutter/material.dart`. Use `FluentApp` instead of
/// `MaterialApp` and `FluentTheme` instead of `Theme`.
///
/// Token values are transcribed from `microsoft/fluentui` `packages/tokens`,
/// `fluentui-apple`, and `fluentui-android`; platform typography metrics track
/// the current `fluent2.microsoft.design/typography` tables.
library;

/// Platform-font facade, including Selawik loading for Web and Windows.
export 'package:fluent_2_fonts/fluent_2_fonts.dart';

/// Official Fluent icon set. Safe alongside the no-Material rule: it imports
/// only `package:flutter/widgets.dart` and depends on nothing but the Flutter
/// SDK, so it does not pull Material into the tree.
export 'package:fluentui_system_icons/fluentui_system_icons.dart';

export 'src/app.dart';
export 'src/theme.dart';
export 'src/tokens/alias_colors.dart';
export 'src/tokens/brand_generator.dart';
export 'src/tokens/color_token.dart';
export 'src/tokens/elevation.dart';
export 'src/tokens/global_colors.dart';
export 'src/tokens/layout.dart';
export 'src/tokens/materials.dart';
export 'src/tokens/motion.dart';
export 'src/tokens/palette_colors.dart';
export 'src/tokens/shared_colors.dart';
export 'src/tokens/theme_variants.dart';
export 'src/tokens/typography.dart';

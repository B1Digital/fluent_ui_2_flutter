/// Fluent 2 components for iOS and Android surfaces.
///
/// Re-exports `fluent_2_core`, so consumers need a single import:
///
/// ```dart
/// import 'package:fluent_2_mobile/fluent_2_mobile.dart';
/// ```
///
/// ## Surface, not platform
///
/// This package holds the *touch* rendering of each component — the larger hit
/// targets, mobile type ramp and press states Fluent 2 specifies for phones and
/// tablets. `fluent_2_web` holds the pointer rendering of the same components.
/// They are different widgets, not one widget with a platform switch, because
/// the specs genuinely diverge.
///
/// Tokens, theming and the app shell live in `fluent_2_core` and are shared by
/// both. Mobile ramps in core are transcribed from `fluentui-apple`
/// (`GlobalTokens.swift`) and `fluentui-android` (`FluentGlobalTokens.kt`).
///
/// ## Status
///
/// No widgets yet. This library currently re-exports core and nothing else.
library;

export 'package:fluent_2_core/fluent_2_core.dart';

import 'dart:async';

import 'package:fluent_2_fonts_web/fluent_2_fonts_web.dart';
import 'package:flutter/services.dart' show FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';

/// Loads the same Selawik family used by a release Web build before tests run,
/// plus the Fluent icon font.
///
/// `flutter test` registers neither. Selawik has always been loaded here;
/// the icon font — which a release build gets from
/// `package:fluentui_system_icons`' own `fonts:` declaration — was not, so
/// every `Icon` in the package rasterised as tofu and 129 goldens recorded the
/// tofu as their expected output. `fontPackage` on those `IconData` makes the
/// resolved family `packages/<pkg>/<family>`, not the bare family name.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await FluentWebFonts.ensureLoaded();
  for (final family in const <String>['Regular', 'Filled']) {
    final icons =
        FontLoader(
          'packages/fluentui_system_icons/FluentSystemIcons-$family',
        )..addFont(
          rootBundle.load(
            'packages/fluentui_system_icons/fonts/FluentSystemIcons-$family.ttf',
          ),
        );
    await icons.load();
  }
  await testMain();
}

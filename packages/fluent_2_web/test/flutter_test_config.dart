import 'dart:async';

import 'package:fluent_2_fonts_web/fluent_2_fonts_web.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads the same Selawik family used by a release Web build before tests run.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await FluentWebFonts.ensureLoaded();
  await testMain();
}

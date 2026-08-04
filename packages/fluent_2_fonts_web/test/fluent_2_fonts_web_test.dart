import 'package:fluent_2_fonts_web/fluent_2_fonts_web.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the three Web Selawik faces exactly once', () async {
    final regular = await rootBundle.load(
      'packages/fluent_2_fonts_web/lib/fonts/selawk.ttf',
    );
    expect(regular.lengthInBytes, greaterThan(0));

    final first = FluentWebFonts.ensureLoaded();
    final second = FluentWebFonts.ensureLoaded();
    expect(identical(first, second), isTrue);
    await first;
    expect(FluentWebFonts.isLoaded, isTrue);
  });
}

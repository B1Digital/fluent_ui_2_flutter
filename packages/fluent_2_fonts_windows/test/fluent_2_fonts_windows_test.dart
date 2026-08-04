import 'package:fluent_2_fonts_windows/fluent_2_fonts_windows.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the three Windows Selawik faces exactly once', () async {
    final regular = await rootBundle.load(
      'packages/fluent_2_fonts_windows/lib/fonts/selawk.ttf',
    );
    expect(regular.lengthInBytes, greaterThan(0));

    final first = FluentWindowsFonts.ensureLoaded();
    final second = FluentWindowsFonts.ensureLoaded();
    expect(identical(first, second), isTrue);
    await first;
    expect(FluentWindowsFonts.isLoaded, isTrue);
  });
}

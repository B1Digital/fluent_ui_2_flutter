import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Its own file on purpose: the Windows font loader memoizes per isolate, and
/// the remount only happened when `FluentApp` first built with the fonts still
/// loading. Any earlier Windows test in the same file would load them first.
void main() {
  testWidgets(
    'FluentApp keeps its subtree when it rebuilds after the fonts load',
    (tester) async {
      expect(FluentFonts.requiresLoading, isTrue);
      expect(FluentFonts.isLoaded, isFalse);

      final mode = ValueNotifier(FluentThemeMode.light);
      addTearDown(mode.dispose);
      await tester.pumpWidget(
        ValueListenableBuilder<FluentThemeMode>(
          valueListenable: mode,
          builder: (context, value, _) =>
              FluentApp(themeMode: value, home: const _Counter()),
        ),
      );
      await tester.pumpAndSettle();
      expect(FluentFonts.isLoaded, isTrue);

      final before = tester.state<_CounterState>(find.byType(_Counter))
        ..count = 3;

      // A parent toggling the theme used to swap FluentApp's root from the
      // FutureBuilder to a bare WidgetsApp, discarding every State below it:
      // routes, text, scroll offsets.
      mode.value = FluentThemeMode.dark;
      await tester.pump();

      final after = tester.state<_CounterState>(find.byType(_Counter));
      expect(after, same(before));
      expect(after.count, 3);
      expect(
        FluentTheme.of(tester.element(find.byType(_Counter))).brightness,
        Brightness.dark,
      );

      // A FluentApp mounted after the load still paints on its first frame,
      // not one frame late waiting on the completed future's snapshot.
      await tester.pumpWidget(
        FluentApp(key: UniqueKey(), home: const _Counter()),
      );
      expect(tester.state<_CounterState>(find.byType(_Counter)).count, 0);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  int count = 0;

  @override
  Widget build(BuildContext context) => Text('$count');
}

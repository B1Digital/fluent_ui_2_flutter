import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

const Map<FluentSwatchSize, String> _sizeNames = <FluentSwatchSize, String>{
  FluentSwatchSize.extraSmall: 'ExtraSmall',
  FluentSwatchSize.small: 'Small',
  FluentSwatchSize.medium: 'Medium',
  FluentSwatchSize.large: 'Large',
};

const Color _hotPink = Color(0xFFE3008C);

/// Figma's sample palettes are eight columns wide at every size, and its grid
/// variants are five rows deep.
const int _columns = 8;
const int _rows = 5;

void main() {
  const key = Key('picker');
  const childKey = Key('picker-child');

  FluentThemeData lightTheme() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget picker, {
    FluentThemeData? theme,
    double? width,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? lightTheme(),
      home: Center(
        child: width == null ? picker : SizedBox(width: width, child: picker),
      ),
    ),
  );

  List<Widget> swatches(int count) => <Widget>[
    for (var i = 0; i < count; i++)
      FluentSwatch(
        key: i == 0 ? childKey : null,
        color: _hotPink,
        semanticLabel: 'Swatch $i',
        onPressed: () {},
      ),
  ];

  BoxDecoration childDecoration(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(childKey),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .first;

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('swatch_picker');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 14);
      expect(spec.properties['Size'], _sizeNames.values.toList());
      expect(spec.properties['Layout'], <String>['Grid', 'Row']);
      expect(spec.properties['Spacing'], <String>['Medium', 'Small']);
    });

    test('every variant insets by Spacing/MNudge and gaps by XS or XXS', () {
      // Upstream's root is `padding: 0` with `gap: 4px` / `2px`. Figma binds
      // `Spacing/{Horizontal,Vertical}/MNudge` on all four sides of all 14
      // variants, so the inset is a divergence resolved toward Figma; the two
      // gaps agree.
      for (final variant in spec.variants) {
        expect(
          variant.padding,
          const EdgeInsets.all(FluentSpacing.mNudge),
          reason: variant.name,
        );
        expect(
          variant.gap,
          variant.props['Spacing'] == 'Medium'
              ? FluentSpacing.xs
              : FluentSpacing.xxs,
          reason: variant.name,
        );
        expect(
          variant.tokens['paddingLeft']?.first,
          'Spacing/Horizontal/MNudge',
          reason: variant.name,
        );
      }
    });

    testWidgets('every one of the 14 variants matches its frame', (
      tester,
    ) async {
      for (final variant in spec.variants) {
        final size = _sizeNames.entries
            .firstWhere((e) => e.value == variant.props['Size'])
            .key;
        final grid = variant.props['Layout'] == 'Grid';
        final spacing = variant.props['Spacing'] == 'Medium'
            ? FluentSwatchPickerSpacing.medium
            : FluentSwatchPickerSpacing.small;

        await pump(
          tester,
          FluentSwatchPicker(
            key: key,
            layout: grid
                ? FluentSwatchPickerLayout.grid
                : FluentSwatchPickerLayout.row,
            size: size,
            spacing: spacing,
            semanticLabel: 'Palette',
            children: swatches(grid ? _columns * _rows : _columns),
          ),
          // A row hugs its content, so its own width is the assertion. A wrap
          // needs the width Figma gives it before the row count means anything.
          width: grid ? variant.size.width : null,
        );

        final measured = tester.getSize(find.byKey(key));
        expect(measured.width, variant.size.width, reason: variant.name);
        expect(measured.height, variant.size.height, reason: variant.name);
      }
    });

    testWidgets('the picker pushes its size onto every swatch', (tester) async {
      const dimensions = <FluentSwatchSize, double>{
        FluentSwatchSize.extraSmall: 20,
        FluentSwatchSize.small: 24,
        FluentSwatchSize.medium: 28,
        FluentSwatchSize.large: 32,
      };
      for (final entry in dimensions.entries) {
        await pump(
          tester,
          FluentSwatchPicker(
            key: key,
            size: entry.key,
            semanticLabel: 'Palette',
            // The child asks for Large; the picker's value has to win, or the
            // row would not lay out.
            children: <Widget>[
              FluentSwatch(
                key: childKey,
                color: _hotPink,
                size: FluentSwatchSize.large,
                semanticLabel: 'Swatch',
                onPressed: () {},
              ),
            ],
          ),
        );
        expect(
          tester.getSize(find.byKey(childKey)),
          Size.square(entry.value),
          reason: entry.key.name,
        );
      }
    });

    testWidgets('the picker pushes its shape onto every swatch', (
      tester,
    ) async {
      await pump(
        tester,
        FluentSwatchPicker(
          key: key,
          shape: FluentSwatchShape.circular,
          semanticLabel: 'Palette',
          children: swatches(2),
        ),
      );
      expect(childDecoration(tester).borderRadius, FluentRadius.allCircular);
    });

    testWidgets('a child style still outranks the picker', (tester) async {
      await pump(
        tester,
        FluentSwatchPicker(
          key: key,
          size: FluentSwatchSize.small,
          semanticLabel: 'Palette',
          children: <Widget>[
            FluentSwatch(
              key: childKey,
              color: _hotPink,
              style: FluentSwatchStyle.from(size: const Size.square(40)),
              semanticLabel: 'Swatch',
              onPressed: () {},
            ),
          ],
        ),
      );
      expect(tester.getSize(find.byKey(childKey)), const Size.square(40));
    });
  });

  group('style resolution order', () {
    testWidgets('the widget style beats the subtree theme beats the defaults', (
      tester,
    ) async {
      await pump(
        tester,
        FluentSwatchPickerTheme(
          style: FluentSwatchPickerStyle.from(spacing: 20),
          child: FluentSwatchPicker(
            key: key,
            style: FluentSwatchPickerStyle.from(
              spacing: 30,
              padding: EdgeInsets.zero,
            ),
            semanticLabel: 'Palette',
            children: swatches(2),
          ),
        ),
      );
      // Two 28-wide swatches, no inset, a 30 gap.
      expect(tester.getSize(find.byKey(key)).width, 28 + 30 + 28);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      await pump(
        tester,
        FluentSwatchPickerTheme(
          style: FluentSwatchPickerStyle.from(
            spacing: 20,
            padding: EdgeInsets.zero,
          ),
          child: FluentSwatchPicker(
            key: key,
            semanticLabel: 'Palette',
            children: swatches(2),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(key)).width, 28 + 20 + 28);
    });

    testWidgets('a partial override keeps the resolved gap', (tester) async {
      await pump(
        tester,
        FluentSwatchPicker(
          key: key,
          spacing: FluentSwatchPickerSpacing.small,
          style: FluentSwatchPickerStyle.from(padding: EdgeInsets.zero),
          semanticLabel: 'Palette',
          children: swatches(2),
        ),
      );
      expect(
        tester.getSize(find.byKey(key)).width,
        28 + FluentSpacing.xxs + 28,
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentSwatchPickerBaseState(
        layout: FluentSwatchPickerLayout.row,
        children: <Widget>[
          SizedBox(width: 10, height: 10),
          SizedBox(width: 10, height: 10),
        ],
      );

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentSwatchPicker(
            base,
            FluentSwatchPickerStyle.from(
              spacing: 5,
              padding: const EdgeInsets.all(3),
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(tester.getSize(find.byKey(key)).width, 3 + 10 + 5 + 10 + 3);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentSwatchPickerState(
        children: const <Widget>[SizedBox(width: 10, height: 10)],
        spacing: FluentSwatchPickerSpacing.small,
      );
      final adjusted = resolveFluentSwatchPickerStyle(
        state,
        lightTheme(),
      ).merge(FluentSwatchPickerStyle.from(padding: EdgeInsets.zero));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentSwatchPicker(
            state,
            adjusted,
            const <WidgetState>{},
          ),
        ),
      );
      expect(tester.getSize(find.byKey(key)).width, 10);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches a swatch inside', (
      tester,
    ) async {
      const olive = Color(0xFF6B6B21);
      await tester.pumpWidget(
        FluentApp(
          theme: lightTheme(),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.transparentStroke: olive},
            child: Center(
              child: FluentSwatchPicker(
                key: key,
                semanticLabel: 'Palette',
                children: swatches(2),
              ),
            ),
          ),
        ),
      );
      expect(childDecoration(tester).border!.top.color, olive);
    });

    testWidgets('high contrast leaves no invisible border on a child', (
      tester,
    ) async {
      await pump(
        tester,
        FluentSwatchPicker(
          key: key,
          semanticLabel: 'Palette',
          children: swatches(2),
        ),
        theme: FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        ),
      );
      final border = childDecoration(tester).border;
      expect(border, isNotNull);
      expect(border!.top.color.a, 1.0);
    });
  });

  group('behaviour', () {
    testWidgets('a disabled swatch inside stays disabled', (tester) async {
      var taps = 0;
      await pump(
        tester,
        FluentSwatchPicker(
          key: key,
          semanticLabel: 'Palette',
          children: <Widget>[
            const FluentSwatch(
              key: childKey,
              color: _hotPink,
              semanticLabel: 'Disabled swatch',
            ),
            FluentSwatch(
              color: _hotPink,
              semanticLabel: 'Live swatch',
              onPressed: () => taps++,
            ),
          ],
        ),
      );

      await tester.tap(find.byKey(childKey), warnIfMissed: false);
      await tester.pump();
      expect(taps, 0);
      expect(
        childDecoration(tester).border!.top.color,
        lightTheme().colors.transparentStroke,
      );
    });

    testWidgets('the group carries a name and keeps its children announced', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        FluentSwatchPicker(
          key: key,
          semanticLabel: 'Highlight colour',
          children: swatches(2),
        ),
      );

      expect(find.bySemanticsLabel('Highlight colour'), findsOneWidget);
      expect(find.bySemanticsLabel('Swatch 0'), findsOneWidget);
      expect(find.bySemanticsLabel('Swatch 1'), findsOneWidget);
      handle.dispose();
    });
  });
}

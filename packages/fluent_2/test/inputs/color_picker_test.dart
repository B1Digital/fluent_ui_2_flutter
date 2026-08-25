import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `FluentColorPicker` is a colour, a shape and a change callback published to
/// the controls stacked inside it — upstream's React context, as an
/// [InheritedWidget].
///
/// Everything the picker can get wrong is a *sharing* problem, so that is what
/// this file tests: precedence between a control's own arguments and the
/// picker's, whether every control stays in lockstep through a drag, and
/// whether one null callback disables the lot.
void main() {
  const pickerKey = Key('picker');
  const areaKey = Key('area');
  const hueKey = Key('hue');
  const alphaKey = Key('alpha');

  FluentThemeData light() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  const teal = HSVColor.fromAHSV(1, 200, 0.5, 0.5);

  Future<void> pump(WidgetTester tester, Widget picker) => tester.pumpWidget(
    FluentApp(
      theme: light(),
      home: Center(child: SizedBox(width: 300, child: picker)),
    ),
  );

  /// The three demo controls, keyed so each can be found on its own.
  List<Widget> children() => const <Widget>[
    FluentColorArea(
      key: areaKey,
      saturationLabel: 'Saturation',
      brightnessLabel: 'Brightness',
    ),
    FluentColorSlider(key: hueKey, semanticLabel: 'Hue'),
    FluentAlphaSlider(key: alphaKey, semanticLabel: 'Alpha'),
  ];

  FluentColorAreaPainter areaPainter(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(areaKey),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((paint) => paint.painter)
      .whereType<FluentColorAreaPainter>()
      .first;

  FluentColorSliderPainter sliderPainter(WidgetTester tester, Key key) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((paint) => paint.painter)
      .whereType<FluentColorSliderPainter>()
      .first;

  group('layout', () {
    testWidgets('children stack with a spacingVerticalXS gap', (tester) async {
      await pump(
        tester,
        FluentColorPicker(
          key: pickerKey,
          color: teal,
          onColorChanged: (_) {},
          children: children(),
        ),
      );
      final area = tester.getRect(find.byKey(areaKey));
      final hue = tester.getRect(find.byKey(hueKey));
      expect(
        hue.top - area.bottom,
        FluentSpacing.xs,
        reason: 'gap: spacingVerticalXS on the root flex column',
      );
      // The colour area adds a margin of its own, so the visible gap under the
      // square is 4 + 6.
      expect(hue.top - (area.bottom - FluentSpacing.sNudge), 10);
    });

    testWidgets('it sizes to its widest child, however loose the parent', (
      tester,
    ) async {
      // Plain CrossAxisAlignment.stretch hands a child the *incoming* max
      // width, so this 800-wide slot would produce an 800-wide colour area.
      // IntrinsicWidth pins the column to the area's own 300 first.
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Align(
            alignment: Alignment.topLeft,
            child: FluentColorPicker(
              key: pickerKey,
              color: teal,
              onColorChanged: (_) {},
              children: children(),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(areaKey)).width, 300);
      expect(
        tester.getSize(find.byKey(hueKey)).width,
        300,
        reason: 'and the rails stretch to match, as upstream\'s do',
      );
    });

    testWidgets('it lays out unbounded, as a popover lays out its content', (
      tester,
    ) async {
      // RenderStack gives a Positioned child with only `left` and `top` fully
      // unbounded constraints, which is exactly what FluentPopover does — and
      // what the Color Picker Popup story needs.
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Stack(
            children: <Widget>[
              Positioned(
                left: 0,
                top: 0,
                child: FluentColorPicker(
                  key: pickerKey,
                  color: teal,
                  onColorChanged: (_) {},
                  children: children(),
                ),
              ),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byKey(areaKey)).width, 300);
      expect(tester.getSize(find.byKey(alphaKey)).width, 300);
    });

    testWidgets('spacing is a style field, merged the usual three ways', (
      tester,
    ) async {
      await pump(
        tester,
        FluentColorPickerTheme(
          style: FluentColorPickerStyle.from(spacing: 40),
          child: FluentColorPicker(
            key: pickerKey,
            color: teal,
            onColorChanged: (_) {},
            style: FluentColorPickerStyle.from(spacing: 24),
            children: children(),
          ),
        ),
      );
      expect(
        tester.getRect(find.byKey(hueKey)).top -
            tester.getRect(find.byKey(areaKey)).bottom,
        24,
        reason: 'the widget style wins over the subtree theme',
      );
    });
  });

  group('the scope', () {
    testWidgets('every control reads the picker\'s colour and shape', (
      tester,
    ) async {
      await pump(
        tester,
        FluentColorPicker(
          key: pickerKey,
          color: teal,
          shape: FluentColorPickerShape.square,
          onColorChanged: (_) {},
          children: children(),
        ),
      );
      expect(areaPainter(tester).saturation, 0.5);
      expect(areaPainter(tester).borderRadius, BorderRadius.zero);
      expect(sliderPainter(tester, hueKey).fraction, closeTo(200 / 360, 1e-9));
      expect(sliderPainter(tester, hueKey).railRadius, BorderRadius.zero);
      expect(sliderPainter(tester, alphaKey).fraction, 1);
    });

    testWidgets('a control\'s own colour, callback and shape all win', (
      tester,
    ) async {
      final fromChild = <HSVColor>[];
      final fromPicker = <HSVColor>[];
      await pump(
        tester,
        FluentColorPicker(
          key: pickerKey,
          color: teal,
          onColorChanged: fromPicker.add,
          children: <Widget>[
            FluentColorSlider(
              key: hueKey,
              color: const HSVColor.fromAHSV(1, 90, 1, 1),
              shape: FluentColorPickerShape.square,
              onChanged: fromChild.add,
              semanticLabel: 'Hue',
            ),
          ],
        ),
      );
      final painter = sliderPainter(tester, hueKey);
      expect(painter.fraction, closeTo(90 / 360, 1e-9));
      expect(painter.railRadius, BorderRadius.zero);

      final rail = tester.getRect(find.byKey(hueKey));
      await tester.tapAt(Offset(rail.left + rail.width / 2, rail.center.dy));
      await tester.pump();
      expect(fromChild, hasLength(1));
      expect(fromPicker, isEmpty, reason: 'the child\'s callback shadows it');
    });

    testWidgets('three controls stay in lockstep through a drag', (
      tester,
    ) async {
      var colour = teal;
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Center(
            child: SizedBox(
              width: 300,
              child: StatefulBuilder(
                builder: (context, setState) => FluentColorPicker(
                  key: pickerKey,
                  color: colour,
                  onColorChanged: (next) => setState(() => colour = next),
                  children: children(),
                ),
              ),
            ),
          ),
        ),
      );

      final rail = tester.getRect(find.byKey(hueKey));
      await tester.tapAt(Offset(rail.left + rail.width / 2, rail.center.dy));
      await tester.pump();

      expect(colour.hue, 180);
      // The regression this guards: upstream's uncontrolled mode gives each of
      // the three children its own copy of the value, and they drift apart the
      // moment one is dragged. There is no HSVColor field on any State here,
      // so drift is unrepresentable — and this fails if one is added.
      expect(
        areaPainter(tester).hueColor,
        const HSVColor.fromAHSV(1, 180, 1, 1).toColor(),
      );
      expect(
        sliderPainter(tester, alphaKey).railColors.last,
        const HSVColor.fromAHSV(1, 180, 0.5, 0.5).toColor(),
      );
    });

    testWidgets('a null callback disables every control inside', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        FluentColorPicker(key: pickerKey, color: teal, children: children()),
      );

      for (final label in const <String>[
        'Saturation',
        'Brightness',
        'Hue',
        'Alpha',
      ]) {
        expect(
          find.bySemanticsLabel(label),
          findsOneWidget,
          reason: '$label is still announced',
        );
      }
      expect(
        find.semantics.byAction(SemanticsAction.increase),
        findsNothing,
        reason:
            'and not one of the four offers a way to change the colour — a '
            'null callback on the picker disables every control inside',
      );

      handle.dispose();
    });

    testWidgets('a control outside a picker uses its own colour', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentColorSlider(key: hueKey, color: teal, semanticLabel: 'Hue'),
      );
      expect(sliderPainter(tester, hueKey).fraction, closeTo(200 / 360, 1e-9));
    });

    test('updateShouldNotify fires on colour, shape and callback', () {
      const child = SizedBox.shrink();
      void other(HSVColor _) {}
      final scope = FluentColorPickerScope(
        color: teal,
        shape: FluentColorPickerShape.rounded,
        onColorChanged: other,
        child: child,
      );
      expect(
        scope.updateShouldNotify(
          FluentColorPickerScope(
            color: const HSVColor.fromAHSV(1, 10, 0.5, 0.5),
            shape: FluentColorPickerShape.rounded,
            onColorChanged: other,
            child: child,
          ),
        ),
        isTrue,
      );
      expect(
        scope.updateShouldNotify(
          FluentColorPickerScope(
            color: teal,
            shape: FluentColorPickerShape.square,
            onColorChanged: other,
            child: child,
          ),
        ),
        isTrue,
      );
      expect(
        scope.updateShouldNotify(
          const FluentColorPickerScope(
            color: teal,
            shape: FluentColorPickerShape.rounded,
            onColorChanged: null,
            child: child,
          ),
        ),
        isTrue,
      );
      expect(
        scope.updateShouldNotify(
          FluentColorPickerScope(
            color: teal,
            shape: FluentColorPickerShape.rounded,
            onColorChanged: other,
            child: child,
          ),
        ),
        isFalse,
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      await pump(
        tester,
        KeyedSubtree(
          key: pickerKey,
          child: buildFluentColorPicker(
            const FluentColorPickerBaseState(
              children: <Widget>[
                SizedBox(key: areaKey, height: 10),
                SizedBox(key: hueKey, height: 10),
              ],
            ),
            FluentColorPickerStyle.from(spacing: 32),
            const <WidgetState>{},
          ),
        ),
      );
      expect(
        tester.getRect(find.byKey(hueKey)).top -
            tester.getRect(find.byKey(areaKey)).bottom,
        32,
      );
    });

    test('the style function can be reused and then adjusted', () {
      final resolved = resolveFluentColorPickerStyle(
        resolveFluentColorPickerState(children: const <Widget>[]),
        light(),
      );
      expect(
        resolved.spacing!.resolve(const <WidgetState>{}),
        FluentSpacing.xs,
      );
      expect(
        resolved
            .merge(FluentColorPickerStyle.from(spacing: 2))
            .spacing!
            .resolve(const <WidgetState>{}),
        2,
      );
    });
  });

  group('the colour model', () {
    test(
      'the initial colour is white, as upstream\'s INITIAL_COLOR_HSV is',
      () {
        expect(
          kFluentColorPickerInitialColor,
          const HSVColor.fromAHSV(1, 0, 0, 1),
        );
        expect(
          kFluentColorPickerInitialColor.toColor(),
          const Color(0xFFFFFFFF),
        );
      },
    );

    test('fluentColorFrom clamps every channel instead of asserting', () {
      final colour = fluentColorFrom(
        hue: 400,
        saturation: 2,
        value: -1,
        alpha: 5,
      );
      expect(colour.hue, 360, reason: 'clamped, never wrapped with % 360');
      expect(colour.saturation, 1);
      expect(colour.value, 0);
      expect(colour.alpha, 1);
    });

    test('fluentColorFrom quantises, so == is a usable change test', () {
      expect(
        fluentColorFrom(hue: 199.6, saturation: 0.5049, value: 0.5, alpha: 1),
        fluentColorFrom(hue: 200.4, saturation: 0.5, value: 0.5, alpha: 1),
      );
      expect(
        fluentColorFrom(hue: 200, saturation: 0.5051, value: 0.5, alpha: 1),
        isNot(fluentColorFrom(hue: 200, saturation: 0.5, value: 0.5, alpha: 1)),
      );
    });
  });

  group('accessibility', () {
    testWidgets('a label makes the picker a named group', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        FluentColorPicker(
          key: pickerKey,
          color: teal,
          onColorChanged: (_) {},
          semanticLabel: 'Highlight colour',
          children: children(),
        ),
      );
      expect(find.bySemanticsLabel('Highlight colour'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('without a label it adds no node of its own', (tester) async {
      await pump(
        tester,
        FluentColorPicker(
          key: pickerKey,
          color: teal,
          onColorChanged: (_) {},
          children: children(),
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(pickerKey),
          matching: find.byType(Semantics),
        ),
        // The controls' own nodes, and nothing wrapping them: upstream's root
        // is a plain div with no role.
        findsWidgets,
      );
      expect(
        tester
            .widget<Column>(
              find.descendant(
                of: find.byKey(pickerKey),
                matching: find.byType(Column),
              ),
            )
            .children,
        hasLength(3),
      );
    });
  });
}

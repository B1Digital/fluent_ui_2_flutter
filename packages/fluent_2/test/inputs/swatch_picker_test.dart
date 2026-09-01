import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/services.dart';
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
    TextDirection? direction,
  }) {
    final Widget body = Center(
      child: width == null ? picker : SizedBox(width: width, child: picker),
    );
    return tester.pumpWidget(
      FluentApp(
        theme: theme ?? lightTheme(),
        home: direction == null
            ? body
            : Directionality(textDirection: direction, child: body),
      ),
    );
  }

  List<Widget> swatches(int count) => <Widget>[
    for (var i = 0; i < count; i++)
      FluentSwatch(
        key: i == 0 ? childKey : null,
        color: _hotPink,
        semanticLabel: 'Swatch $i',
        onPressed: () {},
      ),
  ];

  /// One node per swatch, disposed with the test.
  List<FocusNode> focusNodes(int count) {
    final nodes = <FocusNode>[
      for (var i = 0; i < count; i++) FocusNode(debugLabel: 'swatch $i'),
    ];
    addTearDown(() {
      for (final node in nodes) {
        node.dispose();
      }
    });
    return nodes;
  }

  /// A picker whose swatches each carry a node, so a test can name the one that
  /// should hold focus. Swatches in [disabled] take `onPressed: null`, which is
  /// what makes a swatch refuse focus.
  FluentSwatchPicker keyboardPicker(
    List<FocusNode> nodes, {
    FluentSwatchPickerLayout layout = FluentSwatchPickerLayout.row,
    Set<int> disabled = const <int>{},
    void Function(int index)? onPressed,
  }) => FluentSwatchPicker(
    key: key,
    layout: layout,
    semanticLabel: 'Palette',
    children: <Widget>[
      for (var i = 0; i < nodes.length; i++)
        FluentSwatch(
          key: Key('swatch-$i'),
          color: _hotPink,
          semanticLabel: 'Swatch $i',
          focusNode: nodes[i],
          onPressed: disabled.contains(i) ? null : () => onPressed?.call(i),
        ),
    ],
  );

  /// The index of the swatch holding focus, or null when none does.
  int? focused(List<FocusNode> nodes) {
    for (var i = 0; i < nodes.length; i++) {
      if (nodes[i].hasFocus) return i;
    }
    return null;
  }

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

    testWidgets('a swatch stays selectable by click and by Space and Enter', (
      tester,
    ) async {
      final pressed = <int>[];
      final nodes = focusNodes(2);
      await pump(tester, keyboardPicker(nodes, onPressed: pressed.add));

      await tester.tap(find.byKey(const Key('swatch-1')));
      await tester.pump();
      expect(pressed, <int>[1], reason: 'the roving gate is not a hit barrier');

      nodes[0].requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(pressed, <int>[1, 0, 0]);
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

  /// A swatch publishes `inMutuallyExclusiveGroup`, so the picker owes
  /// assistive technology a composite widget: **one** tab stop with the arrows
  /// moving inside it.
  ///
  /// The oracle is `useSwatchPicker_unstable`
  /// (`@fluentui/react-swatch-picker@9.6.1`, recovered from the published
  /// sourcemap), which wraps the root in
  /// `useArrowNavigationGroup({circular: true, axis: isGrid ? 'grid-linear' :
  /// 'both', memorizeCurrent: true})`, and Tabster's `Mover._moveFocus`, which
  /// is what those options mean.
  group('keyboard', () {
    /// Two 10-square stops around the picker, to prove where Tab goes.
    Widget between(
      FocusNode before,
      Widget picker, [
      FocusNode? after,
    ]) => Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Focus(focusNode: before, child: const SizedBox(width: 10, height: 10)),
        picker,
        if (after != null)
          Focus(focusNode: after, child: const SizedBox(width: 10, height: 10)),
      ],
    );

    /// Four medium swatches in a grid this wide wrap two to a row: the
    /// picker's own `Spacing/MNudge` inset plus two 28s and the 4 gap —
    /// 10 + 28 + 4 + 28 + 10 = 80 — where a third would need 32 more.
    const gridWidth = 80.0;

    /// Three to a row: 10 + 28 + 4 + 28 + 4 + 28 + 10 = 112.
    ///
    /// Home and End need this and [gridWidth] will not do. Two to a row, the
    /// end of the run is also one step along it, so a picker that had never
    /// heard of Home and End would answer both the same way and the test would
    /// pass on a coincidence. Three wide, the two answers differ.
    const wideGridWidth = 112.0;

    testWidgets('the whole picker is one tab stop', (tester) async {
      final nodes = focusNodes(3);
      final outer = focusNodes(2);
      await pump(tester, between(outer[0], keyboardPicker(nodes), outer[1]));

      outer[0].requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focused(nodes), 0, reason: 'Tab enters at the roving swatch');

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focused(nodes), isNull, reason: 'no second stop inside');
      expect(outer[1].hasFocus, isTrue, reason: 'Tab leaves the picker');
    });

    testWidgets('a row layout walks the line on all four arrows and wraps', (
      tester,
    ) async {
      final nodes = focusNodes(3);
      await pump(tester, keyboardPicker(nodes));

      nodes[0].requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focused(nodes), 1);

      // `axis: 'both'` — the vertical arrows walk the same line.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focused(nodes), 2);

      // `circular: true`.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focused(nodes), 0, reason: 'wraps to the first swatch');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focused(nodes), 2, reason: 'and wraps back to the last');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focused(nodes), 1);
    });

    testWidgets('the horizontal arrows follow the reading direction', (
      tester,
    ) async {
      // Three swatches, starting in the middle: with two, "one forwards" and
      // "one backwards" wrap to the same swatch and the test proves nothing.
      final nodes = focusNodes(3);
      await pump(tester, keyboardPicker(nodes), direction: TextDirection.rtl);

      nodes[1].requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focused(nodes), 2, reason: 'Left is forwards in RTL');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focused(nodes), 1, reason: 'and Right is backwards');
    });

    testWidgets('a grid steps Left and Right across the row boundary', (
      tester,
    ) async {
      final nodes = focusNodes(4);
      await pump(
        tester,
        keyboardPicker(nodes, layout: FluentSwatchPickerLayout.grid),
        width: gridWidth,
      );

      nodes[1].requestFocus();
      await tester.pump();

      // What `grid-linear` adds over plain `grid`: the horizontal arrows are
      // findNext/findPrev over the whole list, not clamped to the row.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focused(nodes), 2, reason: 'off the end of row 0 into row 1');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focused(nodes), 1, reason: 'and back again');

      nodes[3].requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focused(nodes), 0, reason: 'circular at the end of the grid');
    });

    testWidgets('a grid moves Up and Down by a row, keeping the column', (
      tester,
    ) async {
      final nodes = focusNodes(4);
      await pump(
        tester,
        keyboardPicker(nodes, layout: FluentSwatchPickerLayout.grid),
        width: gridWidth,
      );

      nodes[1].requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focused(nodes), 3, reason: 'the same column, one row down');

      // Tabster's cyclic fallback lives only on the horizontal branch, so the
      // vertical axis stops at the edge rather than wrapping.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focused(nodes), 3, reason: 'no wrap off the bottom row');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focused(nodes), 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focused(nodes), 1, reason: 'nor off the top');
    });

    testWidgets('Home and End take the whole line in a row layout', (
      tester,
    ) async {
      final nodes = focusNodes(4);
      await pump(tester, keyboardPicker(nodes));

      nodes[2].requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(focused(nodes), 0);

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(focused(nodes), 3);
    });

    testWidgets('Home and End take the current row in a grid', (tester) async {
      // Six swatches three to a row: rows 0-1-2 and 3-4-5.
      final nodes = focusNodes(6);
      await pump(
        tester,
        keyboardPicker(nodes, layout: FluentSwatchPickerLayout.grid),
        width: wideGridWidth,
      );

      nodes[0].requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(
        focused(nodes),
        2,
        reason: 'the end of row 0 — not of the grid, and not one step along',
      );

      nodes[5].requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pump();
      expect(focused(nodes), 3, reason: 'the start of row 1');
    });

    testWidgets('a disabled swatch is stepped over', (tester) async {
      final nodes = focusNodes(3);
      await pump(tester, keyboardPicker(nodes, disabled: <int>{1}));

      nodes[0].requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focused(nodes), 2, reason: 'a disabled swatch refuses focus');
    });

    testWidgets('disabling the active swatch does not strand the picker', (
      tester,
    ) async {
      final nodes = focusNodes(3);
      final outer = focusNodes(1);

      await pump(tester, between(outer[0], keyboardPicker(nodes)));
      // Swatch 0 holds the tab stop, and is then the one taken away.
      await pump(
        tester,
        between(outer[0], keyboardPicker(nodes, disabled: <int>{0})),
      );
      await tester.pump();

      outer[0].requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(
        focused(nodes),
        1,
        reason: 'the tab stop re-parks instead of vanishing',
      );
    });

    testWidgets('a swatch that was gated shut comes back into the Tab order', (
      tester,
    ) async {
      final nodes = focusNodes(2);
      final outer = focusNodes(2);

      Widget tree() => between(outer[0], keyboardPicker(nodes), outer[1]);

      await pump(tester, tree());

      // Move the roving index off swatch 0, which shuts its gate.
      nodes[0].requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focused(nodes), 1);

      // Rebuild from above while the gate is shut. This is the trap: the
      // swatch's own `Focus` reads `skipTraversal` off its node — where it is
      // *derived* from the shut gate — and writes it back as a hard flag.
      await pump(tester, tree());
      await tester.pump();

      // Move back. The gate reopens, but the latched flag would not.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focused(nodes), 0);

      outer[0].requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(
        focused(nodes),
        0,
        reason: 'Tab still finds the swatch that was gated shut',
      );
    });

    testWidgets('the roving index is remembered across a Tab round trip', (
      tester,
    ) async {
      final nodes = focusNodes(3);
      final outer = focusNodes(1);
      await pump(tester, between(outer[0], keyboardPicker(nodes)));

      nodes[0].requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focused(nodes), 1);

      outer[0].requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      expect(focused(nodes), 1, reason: '`memorizeCurrent: true` upstream');
    });

    testWidgets('an arrow moves focus without selecting', (tester) async {
      final pressed = <int>[];
      final nodes = focusNodes(2);
      await pump(tester, keyboardPicker(nodes, onPressed: pressed.add));

      nodes[0].requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(focused(nodes), 1);
      expect(pressed, isEmpty, reason: 'selection is Space, Enter or a click');
    });
  });
}

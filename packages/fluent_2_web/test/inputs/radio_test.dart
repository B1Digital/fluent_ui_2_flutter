import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentRadio` paints its indicator with a [CustomPaint], so these tests read
/// the resolved tokens off [FluentRadioIndicatorPainter] rather than diffing
/// pixels — the same approach `FluentPresenceBadge` takes.
///
/// The numbers and tokens come from `test/fixtures/radio.json`, extracted from
/// the Figma `Radio` set (30 variants: `Layout` x `Checked` x `State`). The
/// component paints nothing on the variant frame itself — every value lives on
/// a child, so the assertions below read `variant.parts` rather than the frame.
///
/// Two values disagree with `microsoft/fluentui@master`
/// `react-radio/.../useRadioStyles.styles.ts`, and Figma wins in both; see
/// `doc/token-divergences.md`.
void main() {
  const key = Key('radio');

  FluentThemeData light() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(
    WidgetTester tester,
    Widget radio, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light(),
      home: Center(child: radio),
    ),
  );

  /// The indicator painter, skipping the focus ring's own `CustomPaint`.
  FluentRadioIndicatorPainter painterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((p) => p.painter)
      .whereType<FluentRadioIndicatorPainter>()
      .single;

  TextStyle labelStyleOf(WidgetTester tester) => tester
      .widget<RichText>(
        find.descendant(of: find.byKey(key), matching: find.byType(RichText)),
      )
      .text
      .style!;

  /// Moves a real mouse onto the radio and settles.
  Future<void> hover(WidgetTester tester) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(find.byKey(key)));
    await tester.pump();
  }

  Widget radio({
    bool checked = false,
    bool disabled = false,
    FluentRadioLabelPosition position = FluentRadioLabelPosition.after,
    ValueChanged<String>? onChanged,
    FluentRadioStyle? style,
    Widget? label = const Text('Option'),
    FocusNode? focusNode,
  }) => FluentRadio<String>(
    key: key,
    value: 'a',
    groupValue: checked ? 'a' : 'b',
    onChanged: onChanged ?? (_) {},
    labelPosition: position,
    disabled: disabled,
    style: style,
    focusNode: focusNode,
    label: label,
  );

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('radio');

    SpecPart partNamed(SpecVariant variant, String name) =>
        variant.parts.firstWhere((part) => part.name == name);

    /// The `Icon only` variants are the ones whose circles sit shallow enough
    /// to be captured as parts, so they carry the whole colour matrix.
    SpecVariant iconOnly({required bool checked, required String state}) =>
        spec.variant(<String, String>{
          'Layout': 'Icon only',
          'Checked': checked ? 'On' : 'Off',
          'State': state,
        });

    const interaction = <String, Set<WidgetState>>{
      'Rest': <WidgetState>{},
      'Hover': <WidgetState>{WidgetState.hovered},
      'Pressed': <WidgetState>{WidgetState.pressed},
      'Disabled': <WidgetState>{WidgetState.disabled},
    };

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 30);
      expect(
        spec.properties.keys,
        containsAll(<String>['Layout', 'Checked', 'State']),
      );
    });

    test('every Checked x State ring and dot is the token Figma binds', () {
      final theme = light();
      for (final checked in <bool>[false, true]) {
        for (final entry in interaction.entries) {
          final variant = iconOnly(checked: checked, state: entry.key);
          final states = entry.value;
          final style = resolveFluentRadioStyle(
            resolveFluentRadioState(
              checked: checked,
              enabled: entry.key != 'Disabled',
            ),
            theme,
          );

          final ring = partNamed(variant, 'Outer Circle');
          expect(
            style.indicatorColor!.resolve(states),
            ring.stroke,
            reason: '${variant.name}: ring is ${ring.token('strokes')}',
          );
          expect(
            style.indicatorBorderWidth!.resolve(states),
            ring.strokeWidth,
            reason: '${variant.name}: Stroke width/Thin',
          );
          expect(
            style.indicatorSize!.resolve(states),
            ring.size.width,
            reason: '${variant.name}: the indicator is 16 in every variant',
          );

          if (!checked) continue;
          final dot = partNamed(variant, 'Inside Circle');
          expect(
            style.indicatorFillColor!.resolve(states),
            dot.fill,
            reason: '${variant.name}: dot is ${dot.token('fills')}',
          );
          expect(
            style.indicatorFillSize!.resolve(states),
            dot.size.width,
            reason: '${variant.name}: the checked dot is 10',
          );
        }
      }
    });

    test('the label is one flat token, checked or not, in every state', () {
      // Figma binds Neutral/Foreground/1/Rest on all 30 variants. React ramps
      // 3 -> 2 -> 1 while unchecked; Figma wins.
      final theme = light();
      for (final checked in <bool>[false, true]) {
        final style = resolveFluentRadioStyle(
          resolveFluentRadioState(checked: checked),
          theme,
        );
        for (final entry in interaction.entries) {
          if (entry.key == 'Disabled') continue;
          final variant = spec.variant(<String, String>{
            'Layout': 'Icon+Label after',
            'Checked': checked ? 'On' : 'Off',
            'State': entry.key,
          });
          expect(variant.text!.tokens['fills'], <String>[
            'Neutral/Foreground/1/Rest',
          ], reason: variant.name);
          expect(
            style.foregroundColor!.resolve(entry.value),
            theme.colors.neutralForeground1,
            reason: variant.name,
          );
        }
      }
    });

    test('the label rides Figma\'s 14/20 type ramp', () {
      final theme = light();
      final text = spec.variant(<String, String>{
        'Layout': 'Icon+Label after',
        'Checked': 'Off',
        'State': 'Rest',
      }).text!;
      final style = resolveFluentRadioStyle(
        resolveFluentRadioState(),
        theme,
      ).textStyle!.resolve(const <WidgetState>{})!;
      expect(style.fontSize, text.fontSize);
      expect(style.height! * style.fontSize!, text.lineHeight);
    });

    test('the indicator block and both label boxes match the Figma insets', () {
      final theme = light();

      // Icon only: the 16 circle sits inside an 8-all-round base, so the whole
      // control is 32 square.
      final only = iconOnly(checked: false, state: 'Rest');
      final style = resolveFluentRadioStyle(resolveFluentRadioState(), theme);
      expect(
        style.indicatorPadding!.resolve(const <WidgetState>{}),
        partNamed(only, '.RadioBase').padding,
      );
      expect(only.size, const Size(32, 32));

      // Icon+Label after: XS between indicator and label, S to the right, and
      // SNudge above and below — the `Text container` inset that keeps a
      // 20-high label inside the 32-high block.
      final after = spec.variant(<String, String>{
        'Layout': 'Icon+Label after',
        'Checked': 'Off',
        'State': 'Rest',
      });
      final base = partNamed(after, '.RadioBase');
      final container = partNamed(after, 'Text container');
      expect(
        resolveFluentRadioStyle(
          resolveFluentRadioState(
            labelPosition: FluentRadioLabelPosition.after,
          ),
          theme,
        ).labelPadding!.resolve(const <WidgetState>{}),
        EdgeInsets.fromLTRB(
          base.gap!,
          container.padding!.top,
          base.padding!.right,
          container.padding!.bottom,
        ),
      );
      expect(after.size.height, 32);

      // Icon+Label below: XS above the label, S below, SNudge — not S — either
      // side. 6 + 33 + 6 is Figma's 45-wide frame.
      final below = spec.variant(<String, String>{
        'Layout': 'Icon+Label below',
        'Checked': 'Off',
        'State': 'Rest',
      });
      final belowBase = partNamed(below, '.RadioBase');
      expect(
        resolveFluentRadioStyle(
          resolveFluentRadioState(
            labelPosition: FluentRadioLabelPosition.below,
          ),
          theme,
        ).labelPadding!.resolve(const <WidgetState>{}),
        EdgeInsets.fromLTRB(
          belowBase.padding!.left,
          belowBase.gap!,
          belowBase.padding!.right,
          belowBase.padding!.bottom,
        ),
      );
      expect(belowBase.padding!.left, FluentSpacing.sNudge);
      expect(below.size, const Size(45, 64));
    });

    testWidgets('the rendered control reproduces Figma\'s frame', (
      tester,
    ) async {
      for (final position in FluentRadioLabelPosition.values) {
        final variant = spec.variant(<String, String>{
          'Layout': position == FluentRadioLabelPosition.after
              ? 'Icon+Label after'
              : 'Icon+Label below',
          'Checked': 'Off',
          'State': 'Rest',
        });
        await pump(tester, radio(position: position));
        await tester.pumpAndSettle();
        expect(
          tester.getSize(find.byKey(key)).height,
          variant.size.height,
          reason: variant.name,
        );
      }

      final only = iconOnly(checked: false, state: 'Rest');
      await pump(tester, radio(label: null));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(key)), only.size, reason: only.name);
    });

    testWidgets('the focus ring takes the radius Figma stroked', (
      tester,
    ) async {
      final variant = iconOnly(checked: false, state: 'Focus');
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, radio(focusNode: node));
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      node.requestFocus();
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FluentFocusRing>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(FluentFocusRing),
              ),
            )
            .borderRadius,
        variant.radius,
        reason: '${variant.name}: Corner radius/Medium',
      );
      expect(variant.strokeWidth, FluentStroke.thick);
      expect(
        partNamed(variant, '.RadioBase').strokeWidth,
        FluentStroke.thicker,
      );
    });
  });

  group('token fidelity — checked axis x interaction state', () {
    testWidgets('unchecked resolves the accessible neutral stroke ramp', (
      tester,
    ) async {
      final theme = light();

      await pump(tester, radio());
      await tester.pumpAndSettle();
      expect(painterOf(tester).ring, theme.colors.neutralStrokeAccessible);
      expect(painterOf(tester).dot, isNull, reason: 'unchecked paints no dot');
      expect(labelStyleOf(tester).color, theme.colors.neutralForeground1);

      await hover(tester);
      expect(painterOf(tester).ring, theme.colors.neutralStrokeAccessibleHover);
      expect(
        labelStyleOf(tester).color,
        theme.colors.neutralForeground1,
        reason: 'Figma binds Neutral/Foreground/1/Rest in every state',
      );

      await tester.startGesture(tester.getCenter(find.byKey(key)));
      await tester.pump();
      expect(
        painterOf(tester).ring,
        theme.colors.neutralStrokeAccessiblePressed,
      );
      expect(labelStyleOf(tester).color, theme.colors.neutralForeground1);
    });

    testWidgets('checked resolves the compound brand ramp', (tester) async {
      final theme = light();

      await pump(tester, radio(checked: true));
      await tester.pumpAndSettle();
      expect(painterOf(tester).ring, theme.colors.compoundBrandStroke);
      expect(painterOf(tester).dot, theme.colors.compoundBrandForeground1);
      expect(labelStyleOf(tester).color, theme.colors.neutralForeground1);

      await hover(tester);
      expect(painterOf(tester).ring, theme.colors.compoundBrandStrokeHover);
      expect(painterOf(tester).dot, theme.colors.compoundBrandForeground1Hover);
      expect(
        labelStyleOf(tester).color,
        theme.colors.neutralForeground1,
        reason: 'a checked label does not warm on hover',
      );

      await tester.startGesture(tester.getCenter(find.byKey(key)));
      await tester.pump();
      expect(painterOf(tester).ring, theme.colors.compoundBrandStrokePressed);
      expect(
        painterOf(tester).dot,
        theme.colors.compoundBrandForeground1Pressed,
      );
    });

    testWidgets('geometry matches the 16/10/1 indicator', (tester) async {
      await pump(tester, radio(checked: true));
      await tester.pumpAndSettle();

      final painter = painterOf(tester);
      expect(painter.ringWidth, FluentStroke.thin);
      expect(painter.dotSize, FluentSize.size100, reason: '16 x 0.625');
      expect(
        tester.getSize(
          find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is FluentRadioIndicatorPainter,
          ),
        ),
        const Size(FluentSize.size160, FluentSize.size160),
      );
    });

    testWidgets('the label rides the body1 ramp', (tester) async {
      final theme = light();
      await pump(tester, radio());
      await tester.pumpAndSettle();
      final style = labelStyleOf(tester);
      expect(style.fontSize, theme.typography.body1.fontSize);
      expect(style.height, theme.typography.body1.height);
      expect(
        style.fontSize! * style.height!,
        FluentLineHeight.base300,
        reason: 'the label inset arithmetic assumes lineHeightBase300',
      );
    });
  });

  group('label position axis', () {
    testWidgets('after keeps the control 32 high, below stacks to 64', (
      tester,
    ) async {
      await pump(tester, radio());
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(key)).height,
        FluentSize.size320,
        reason: 'the label must not make the radio taller than its indicator',
      );

      await pump(tester, radio(position: FluentRadioLabelPosition.below));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(key)).height,
        // 8 + 16 + 8 indicator block, then 4 + 20 + 8 label block.
        FluentSize.size320 +
            FluentSpacing.xs +
            FluentLineHeight.base300 +
            FluentSpacing.s,
      );
    });

    testWidgets('an unlabelled radio is exactly the indicator block', (
      tester,
    ) async {
      await pump(tester, radio(label: null));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(key)),
        const Size(FluentSize.size320, FluentSize.size320),
      );
    });

    testWidgets('below centres its label', (tester) async {
      await pump(tester, radio(position: FluentRadioLabelPosition.below));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DefaultTextStyle>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(DefaultTextStyle),
              ),
            )
            .textAlign,
        TextAlign.center,
      );
    });

    testWidgets('a wrapping label leaves the indicator at the top', (
      tester,
    ) async {
      // Upstream's root is `align-items: normal` with an explicitly-sized
      // indicator, so the ring stays beside the FIRST line rather than being
      // centred on the whole label block. Live probe of
      // components-radiogroup--default with a three-line label: root y=90
      // h=92, indicator y=98 = root top + its own 8px margin; centred would
      // have put it at y=128. Checkbox already does this.
      //
      // The label is sized by the caller: a `MainAxisSize.min` Row gives its
      // children unbounded width, so a bare Text overflows rather than wraps.
      await pump(
        tester,
        radio(
          label: const SizedBox(
            width: 100,
            child: Text('A label long enough to wrap over three lines'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final box = tester.getRect(find.byKey(key));
      final indicator = tester.getRect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byWidgetPredicate(
            (w) => w is CustomPaint && w.painter is FluentRadioIndicatorPainter,
          ),
        ),
      );
      expect(
        box.height,
        greaterThan(FluentSize.size320),
        reason: 'the label did not wrap, so this proves nothing',
      );
      expect(
        indicator.top - box.top,
        FluentSpacing.s,
        reason: 'the indicator sits under its own 8 padding, not centred',
      );
    });
  });

  group('motion — there is none', () {
    testWidgets('checking is instant, on the very next frame', (tester) async {
      // useRadioStyles.styles.ts declares no transition on any slot. The ring
      // and dot swap on the frame, deliberately, exactly like Checkbox.
      final theme = light();
      var selected = 'b';
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Center(
            child: StatefulBuilder(
              builder: (context, setState) => FluentRadio<String>(
                key: key,
                value: 'a',
                groupValue: selected,
                onChanged: (value) => setState(() => selected = value),
                label: const Text('Option'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).dot, isNull);

      await tester.tap(find.byKey(key));
      await tester.pump();
      expect(
        painterOf(tester).dot,
        theme.colors.compoundBrandForeground1,
        reason: 'no tween: the dot is final one frame after the tap',
      );
      expect(painterOf(tester).ring, theme.colors.compoundBrandStroke);
    });

    testWidgets('hover is instant too, and nothing animates the style', (
      tester,
    ) async {
      final theme = light();
      await pump(tester, radio());
      await tester.pumpAndSettle();

      await hover(tester);
      expect(painterOf(tester).ring, theme.colors.neutralStrokeAccessibleHover);

      // The structural claim behind the two assertions above: no implicit
      // animation is wired into this component at all.
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(ImplicitlyAnimatedWidget),
        ),
        findsNothing,
      );
    });
  });

  group('style resolution order', () {
    testWidgets('the widget style beats the subtree theme beats the defaults', (
      tester,
    ) async {
      const themed = Color(0xFF111111);
      const explicit = Color(0xFF222222);

      await pump(
        tester,
        FluentRadioTheme(
          style: FluentRadioStyle.from(indicatorColor: themed),
          child: radio(style: FluentRadioStyle.from(indicatorColor: explicit)),
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).ring, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentRadioTheme(
          style: FluentRadioStyle.from(indicatorColor: themed),
          child: radio(),
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).ring, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      final theme = light();
      await pump(
        tester,
        radio(
          checked: true,
          style: FluentRadioStyle.from(indicatorFillSize: 4),
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).dotSize, 4);
      expect(
        painterOf(tester).ring,
        theme.colors.compoundBrandStroke,
        reason: 'overriding the dot size must not drop the brand ring',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts the state, so styling can be substituted', (
      tester,
    ) async {
      const mine = Color(0xFF00FF00);
      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentRadio(
            const FluentRadioState(
              enabled: true,
              checked: true,
              labelPosition: FluentRadioLabelPosition.after,
              label: Text('Option'),
            ),
            FluentRadioStyle.from(
              indicatorColor: mine,
              indicatorFillColor: mine,
              indicatorSize: FluentSize.size160,
              indicatorFillSize: FluentSize.size100,
              indicatorBorderWidth: FluentStroke.thin,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).ring, mine);
      expect(painterOf(tester).dot, mine);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final theme = light();
      final state = resolveFluentRadioState(
        checked: true,
        label: const Text('O'),
      );
      final adjusted = resolveFluentRadioStyle(
        state,
        theme,
      ).merge(FluentRadioStyle.from(indicatorSize: 24));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentRadio(state, adjusted, const <WidgetState>{}),
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).ring, theme.colors.compoundBrandStroke);
      expect(
        tester
            .getSize(
              find.byWidgetPredicate(
                (w) =>
                    w is CustomPaint &&
                    w.painter is FluentRadioIndicatorPainter,
              ),
            )
            .width,
        24,
      );
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the radio', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.compoundBrandStroke: magenta},
            child: Center(child: radio(checked: true)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).ring, magenta);
    });

    testWidgets('high contrast keeps the ring opaque and visible', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );

      for (final checked in <bool>[false, true]) {
        await pump(tester, radio(checked: checked), theme: theme);
        await tester.pumpAndSettle();
        final painter = painterOf(tester);
        expect(
          painter.ring!.a,
          1.0,
          reason: 'checked=$checked: an invisible ring erases the control',
        );
        expect(
          painter.ring,
          isNot(theme.colors.neutralBackground1),
          reason: 'checked=$checked: the ring must not match the canvas',
        );
        expect(painter.ringWidth, greaterThan(0));
      }
    });

    testWidgets('disabled is a real token in high contrast too', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(tester, radio(disabled: true), theme: theme);
      await tester.pumpAndSettle();
      expect(painterOf(tester).ring, theme.colors.neutralForegroundDisabled);
      expect(painterOf(tester).ring!.a, 1.0);
    });
  });

  group('behaviour', () {
    testWidgets('fires on tap and on Enter with its own value', (tester) async {
      final chosen = <String>[];
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, radio(onChanged: chosen.add, focusNode: node));

      await tester.tap(find.byKey(key));
      await tester.pump();
      expect(chosen, <String>['a']);

      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(chosen, <String>['a', 'a'], reason: 'keyboard activation');
    });

    testWidgets('disabled is a real state, not a visual treatment', (
      tester,
    ) async {
      final theme = light();
      final chosen = <String>[];
      await pump(tester, radio(disabled: true, onChanged: chosen.add));
      await tester.pumpAndSettle();
      expect(painterOf(tester).ring, theme.colors.neutralForegroundDisabled);
      expect(
        labelStyleOf(tester).color,
        theme.colors.neutralForegroundDisabled,
      );

      await tester.tap(find.byKey(key), warnIfMissed: false);
      await tester.pump();
      expect(chosen, isEmpty, reason: 'a disabled radio never reports');

      await hover(tester);
      expect(
        painterOf(tester).ring,
        theme.colors.neutralForegroundDisabled,
        reason: 'a disabled radio must not adopt the hover ring',
      );
    });

    testWidgets('a checked disabled radio still uses the disabled tokens', (
      tester,
    ) async {
      final theme = light();
      await pump(tester, radio(checked: true, disabled: true));
      await tester.pumpAndSettle();
      expect(painterOf(tester).ring, theme.colors.neutralForegroundDisabled);
      expect(painterOf(tester).dot, theme.colors.neutralForegroundDisabled);
    });

    testWidgets('a null callback disables it just as thoroughly', (
      tester,
    ) async {
      final theme = light();
      await pump(
        tester,
        const FluentRadio<String>(key: key, value: 'a', label: Text('Option')),
      );
      await tester.pumpAndSettle();
      expect(painterOf(tester).ring, theme.colors.neutralForegroundDisabled);
    });

    testWidgets('the focus ring appears only for keyboard focus', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await pump(tester, radio(focusNode: node));
      await tester.pumpAndSettle();

      FluentFocusRing ringOf() => tester.widget<FluentFocusRing>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FluentFocusRing),
        ),
      );
      expect(ringOf().visible, isFalse);

      // Programmatic focus is not keyboard focus: upstream's keyborg flag is
      // raised by a KEY, not by an element gaining focus, so `.focus()` alone
      // draws nothing. Poking FocusManager.highlightStrategy used to stand in
      // for this and no longer can — Flutter's highlight mode cannot tell a
      // mouse from a key, which is the whole reason FluentInputModality exists.
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(
        ringOf().visible,
        isFalse,
        reason: 'focus without a key press is not focus-visible',
      );

      // Escape rather than Tab: it flips the modality without moving focus,
      // which is exactly the live re-evaluation keyborg does.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(ringOf().visible, isTrue);
      expect(
        ringOf().borderRadius,
        FluentRadius.allMedium,
        reason: 'upstream focus-within outline uses borderRadiusMedium',
      );
    });
  });

  group('accessibility', () {
    testWidgets('announces itself as one of a mutually exclusive set', (
      tester,
    ) async {
      await pump(
        tester,
        FluentRadio<String>(
          key: key,
          value: 'a',
          groupValue: 'a',
          onChanged: (_) {},
          semanticLabel: 'Option A',
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'Option A',
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('an unselected radio announces unchecked', (tester) async {
      await pump(
        tester,
        FluentRadio<String>(
          key: key,
          value: 'a',
          groupValue: 'b',
          onChanged: (_) {},
          semanticLabel: 'Option A',
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'Option A',
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
    });

    testWidgets('a disabled radio announces disabled', (tester) async {
      await pump(
        tester,
        const FluentRadio<String>(
          key: key,
          value: 'a',
          groupValue: 'a',
          semanticLabel: 'Option A',
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(
          label: 'Option A',
          isInMutuallyExclusiveGroup: true,
          hasCheckedState: true,
          isChecked: true,
          hasEnabledState: true,
          // isEnabled and isFocusable both absent: a disabled radio refuses
          // focus outright rather than looking disabled while still taking it.
          hasTapAction: false,
        ),
      );
    });
  });

  group('FluentRadioGroup', () {
    const groupKey = Key('group');
    const first = Key('first');

    Widget group({
      FluentRadioGroupLayout layout = FluentRadioGroupLayout.vertical,
      String? value = 'a',
      ValueChanged<String>? onChanged,
      bool disabled = false,
    }) => FluentRadioGroup<String>(
      key: groupKey,
      layout: layout,
      value: value,
      disabled: disabled,
      onChanged: onChanged ?? (_) {},
      semanticLabel: 'Favourite',
      children: const <Widget>[
        FluentRadio<String>(key: first, value: 'a', label: Text('A')),
        FluentRadio<String>(value: 'b', label: Text('B')),
      ],
    );

    testWidgets('the group selection reaches an unwired radio', (tester) async {
      final theme = light();
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Center(child: group()),
        ),
      );
      await tester.pumpAndSettle();

      final painters = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((p) => p.painter)
          .whereType<FluentRadioIndicatorPainter>()
          .toList();
      expect(painters.length, 2);
      expect(painters.first.dot, theme.colors.compoundBrandForeground1);
      expect(painters.last.dot, isNull);
    });

    testWidgets('choosing a radio reports through the group', (tester) async {
      final chosen = <String>[];
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Center(child: group(onChanged: chosen.add)),
        ),
      );
      await tester.tap(find.text('B'));
      await tester.pump();
      expect(chosen, <String>['b']);
    });

    testWidgets('Direction=Vertical stacks, Horizontal rows', (tester) async {
      for (final entry in <FluentRadioGroupLayout, bool>{
        FluentRadioGroupLayout.vertical: true,
        FluentRadioGroupLayout.horizontal: false,
        FluentRadioGroupLayout.horizontalStacked: false,
      }.entries) {
        await tester.pumpWidget(
          FluentApp(
            theme: light(),
            home: Center(child: group(layout: entry.key)),
          ),
        );
        await tester.pumpAndSettle();
        final a = tester.getTopLeft(find.text('A'));
        final b = tester.getTopLeft(find.text('B'));
        expect(
          b.dy > a.dy,
          entry.value,
          reason: '${entry.key.name}: vertical stacking',
        );
        expect(
          b.dx > a.dx,
          !entry.value,
          reason: '${entry.key.name}: horizontal flow',
        );
      }
    });

    testWidgets('the group adds no spacing of its own', (tester) async {
      // Figma's RadioGroup carries itemSpacing 0 in all three Directions and
      // aligns to the start on both axes. The space between options is the
      // indicator margin each radio already brings.
      for (final layout in FluentRadioGroupLayout.values) {
        await tester.pumpWidget(
          FluentApp(
            theme: light(),
            home: Center(child: group(layout: layout)),
          ),
        );
        await tester.pumpAndSettle();
        final options = <Rect>[
          for (var i = 0; i < 2; i++)
            tester.getRect(find.byType(FluentRadio<String>).at(i)),
        ];
        final whole = tester.getRect(find.byKey(groupKey));
        expect(
          layout == FluentRadioGroupLayout.vertical
              ? whole.height
              : whole.width,
          layout == FluentRadioGroupLayout.vertical
              ? options[0].height + options[1].height
              : options[0].width + options[1].width,
          reason: '${layout.name}: itemSpacing is 0',
        );
      }
    });

    testWidgets('Direction=Horizontal stacked puts every label below', (
      tester,
    ) async {
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Center(
            child: group(layout: FluentRadioGroupLayout.horizontalStacked),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The label sits under the indicator, so the radio is 64 tall, not 32.
      expect(
        tester.getSize(find.byKey(first)).height,
        FluentSize.size320 +
            FluentSpacing.xs +
            FluentLineHeight.base300 +
            FluentSpacing.s,
      );
      expect(
        tester.getCenter(find.text('A')).dx,
        moreOrLessEquals(tester.getCenter(find.byKey(first)).dx, epsilon: 0.01),
        reason: 'a stacked label is centred under its indicator',
      );
    });

    testWidgets('a disabled group disables every radio in it', (tester) async {
      final theme = light();
      final chosen = <String>[];
      await tester.pumpWidget(
        FluentApp(
          theme: theme,
          home: Center(child: group(disabled: true, onChanged: chosen.add)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<CustomPaint>(find.byType(CustomPaint))
            .map((p) => p.painter)
            .whereType<FluentRadioIndicatorPainter>()
            .every((p) => p.ring == theme.colors.neutralForegroundDisabled),
        isTrue,
      );

      await tester.tap(find.text('B'), warnIfMissed: false);
      await tester.pump();
      expect(chosen, isEmpty);
    });

    testWidgets('a radio may override the group it sits in', (tester) async {
      final own = <String>[];
      final groupChoices = <String>[];
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Center(
            child: FluentRadioGroup<String>(
              value: 'a',
              onChanged: groupChoices.add,
              children: <Widget>[
                FluentRadio<String>(
                  key: key,
                  value: 'a',
                  groupValue: 'z',
                  onChanged: own.add,
                  label: const Text('A'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        painterOf(tester).dot,
        isNull,
        reason: 'the radio\'s own groupValue wins over the group\'s',
      );
      await tester.tap(find.byKey(key));
      await tester.pump();
      expect(own, <String>['a']);
      expect(groupChoices, isEmpty);
    });

    testWidgets('the group names itself for assistive technology', (
      tester,
    ) async {
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Center(child: group()),
        ),
      );
      expect(
        tester.getSemantics(find.byKey(groupKey)).label,
        contains('Favourite'),
      );
    });
  });
}

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentProgressBar` is the first non-interactive component in the package, so
/// these tests carry two loads: the usual pixel fidelity against Figma, and the
/// proof that the button's contract — three-rung style resolution, three-function
/// recomposition — still holds for a component with no interaction states at all.
///
/// The fixture is the **Static_ProgressBar** set (node `9121:5771`). The sibling
/// `Animated_ProgressBar` set (node `9121:5796`, 38 variants) is deliberately not
/// fixtured: its extra `Status` axis is a keyframe strip — `Not started`,
/// `In progress`, `Complete`, `99% complete`, `Before`, `After`,
/// `Gradient before`, `Gradient after` — not API. Those keyframes are asserted
/// here as motion, not as variants.
void main() {
  const key = Key('progressbar');

  /// Figma draws the set 492 wide, so the harness pins the same width.
  const railWidth = 492.0;

  Future<void> pump(
    WidgetTester tester,
    Widget bar, {
    FluentThemeData? theme,
    TextDirection direction = TextDirection.ltr,
    bool reducedMotion = false,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      builder: reducedMotion
          ? (context, child) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: child!,
            )
          : null,
      home: Directionality(
        textDirection: direction,
        child: Center(
          child: SizedBox(width: railWidth, child: bar),
        ),
      ),
    ),
  );

  /// Every `BoxDecoration` under the bar, outermost first: rail fill, then the
  /// foreground outline, then the indicator.
  List<BoxDecoration> decorationsOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .toList();

  /// The rail: the outermost decoration carrying a fill.
  BoxDecoration railOf(WidgetTester tester) =>
      decorationsOf(tester).firstWhere((d) => d.color != null);

  /// The outline: the only decoration carrying a border.
  BoxDecoration outlineOf(WidgetTester tester) =>
      decorationsOf(tester).firstWhere((d) => d.border != null);

  /// The indicator: the innermost decoration carrying a fill.
  BoxDecoration indicatorOf(WidgetTester tester) =>
      decorationsOf(tester).lastWhere((d) => d.color != null);

  /// The indicator's laid-out size, which is what the value fraction and the
  /// indeterminate one-third are actually observable through.
  Size indicatorSizeOf(WidgetTester tester) => tester.getSize(
    find.descendant(
      of: find.byType(FractionallySizedBox),
      matching: find.byType(DecoratedBox),
    ),
  );

  /// The indeterminate sweep's current offset, as a fraction of the bar's own
  /// width — upstream's `translateX(…%)`.
  double sweepOf(WidgetTester tester) => tester
      .widget<FractionalTranslation>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FractionalTranslation),
        ),
      )
      .translation
      .dx;

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('progressbar');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 10);
      expect(spec.properties['Style'], ['Indeterminate', 'Determinate']);
      expect(spec.properties['State'], [
        'Default',
        'Success',
        'Error',
        'Warning',
      ]);
      expect(spec.properties['Size'], ['Medium', 'Large']);
    });

    testWidgets('every one of the 10 variants matches its Figma numbers', (
      tester,
    ) async {
      // `expectSpec` is not used here: it asserts padding off the outermost
      // Padding widget, and this component has none — Figma expresses the
      // determinate fraction as auto-layout padding on the variant frame, which
      // is an authoring device rather than a spec. Everything else the harness
      // would check is asserted directly below.
      for (final variant in spec.variants) {
        await pump(
          tester,
          FluentProgressBar(
            key: key,
            size: variant.props['Size'] == 'Large'
                ? FluentProgressBarSize.large
                : FluentProgressBarSize.medium,
            status: switch (variant.props['State']!) {
              'Success' => FluentProgressBarStatus.success,
              'Error' => FluentProgressBarStatus.error,
              'Warning' => FluentProgressBarStatus.warning,
              _ => FluentProgressBarStatus.none,
            },
            value: variant.props['Style'] == 'Indeterminate' ? null : 0.5,
          ),
        );

        final rendered = tester.getSize(find.byKey(key));
        expect(rendered.height, variant.size.height, reason: variant.name);
        expect(rendered.width, variant.size.width, reason: variant.name);
        expect(
          railOf(tester).borderRadius,
          variant.radius,
          reason: '${variant.name}: radius',
        );
        expect(
          railOf(tester).color,
          variant.fill,
          reason: '${variant.name}: rail fill (${variant.token('fills')})',
        );
        expect(
          outlineOf(tester).border!.top.width,
          variant.strokeWidth,
          reason: '${variant.name}: stroke width',
        );
        expect(
          outlineOf(tester).border!.top.color.a,
          variant.stroke!.a,
          reason:
              '${variant.name}: the outline is '
              'Neutral/Stroke/Transparent/Rest, which is transparent in light '
              'and opaque in high contrast — only the alpha is observable here',
        );
      }
    });

    testWidgets('the indicator takes the right token for every State', (
      tester,
    ) async {
      // The extractor reads the variant frame only, so the indicator colour is
      // not in the fixture — the frame's fill is the RAIL. These four hexes were
      // read straight off the `Track` child of each Static_ProgressBar variant
      // (nodes 9121:5772 / 5774 / 5776 / 5778) together with its bound variable.
      const figma = <FluentProgressBarStatus, (Color, String)>{
        FluentProgressBarStatus.none: (
          Color(0xFF0F6CBD),
          'Brand/Background/Compound/Rest',
        ),
        FluentProgressBarStatus.success: (
          Color(0xFF107C10),
          'Status/Success/Background/3/Rest',
        ),
        FluentProgressBarStatus.error: (
          Color(0xFFC50F1F),
          'Status/Danger/Background/3/Rest',
        ),
        FluentProgressBarStatus.warning: (
          Color(0xFFDA3B01),
          'Status/Severe/Background/3/Rest',
        ),
      };

      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final tokens = <FluentProgressBarStatus, Color>{
        FluentProgressBarStatus.none: theme.colors.compoundBrandBackground,
        FluentProgressBarStatus.success: theme.colors.statusSuccessBackground3,
        FluentProgressBarStatus.error: theme.colors.statusDangerBackground3,
        FluentProgressBarStatus.warning: theme.colors.statusSevereBackground3,
      };

      for (final status in FluentProgressBarStatus.values) {
        // Walks the fixture's State axis: this throws if the variant is gone.
        spec.variant({
          'Style': 'Determinate',
          'State': switch (status) {
            FluentProgressBarStatus.none => 'Default',
            FluentProgressBarStatus.success => 'Success',
            FluentProgressBarStatus.error => 'Error',
            FluentProgressBarStatus.warning => 'Warning',
          },
          'Size': 'Medium',
        });

        await pump(
          tester,
          FluentProgressBar(key: key, status: status, value: 0.5),
        );

        final (expected, token) = figma[status]!;
        expect(
          indicatorOf(tester).color,
          expected,
          reason: '${status.name}: indicator fill (token: $token)',
        );
        expect(
          indicatorOf(tester).color,
          tokens[status],
          reason: '${status.name}: must come from the token, not a literal',
        );
        expect(
          indicatorOf(tester).borderRadius,
          FluentRadius.allCircular,
          reason: '${status.name}: the indicator is circular too',
        );
      }
    });

    test(
      'Warning binds Figma Severe, which core has only on the status layer',
      () {
        final theme = FluentThemeData.light(
          fontPlatform: FluentFontPlatform.web,
        );
        expect(theme.colors.statusSevereBackground3, const Color(0xFFDA3B01));
        // The alias layer is the one FluentThemeOverride and the high contrast
        // variant act on, and it has no Severe member at all — its Warning family
        // is a different orange. Recorded rather than substituted.
        expect(
          theme.colors.statusWarningBackground3,
          isNot(theme.colors.statusSevereBackground3),
        );
      },
    );

    testWidgets('the determinate indicator fills the value fraction', (
      tester,
    ) async {
      for (final value in <double>[0, 0.25, 0.7967, 1]) {
        await pump(tester, FluentProgressBar(key: key, value: value));
        expect(
          indicatorSizeOf(tester).width,
          moreOrLessEquals(railWidth * value, epsilon: 0.01),
          reason: 'value $value',
        );
      }
    });

    testWidgets('an out-of-range value is clamped rather than overflowing', (
      tester,
    ) async {
      await pump(tester, const FluentProgressBar(key: key, value: 1.8));
      expect(indicatorSizeOf(tester).width, railWidth);

      await pump(tester, const FluentProgressBar(key: key, value: -0.4));
      expect(indicatorSizeOf(tester).width, 0);
    });

    testWidgets('the indeterminate indicator is one third of the rail', (
      tester,
    ) async {
      for (final size in FluentProgressBarSize.values) {
        final variant = spec.variant({
          'Style': 'Indeterminate',
          'State': 'Default',
          'Size': switch (size) {
            FluentProgressBarSize.medium => 'Medium',
            FluentProgressBarSize.large => 'Large',
          },
        });

        await pump(tester, FluentProgressBar(key: key, size: size));

        // Figma's indeterminate `Track` is a fixed 164 wide inside a 492 rail.
        // The fixture cannot carry that number — the extractor reads the variant
        // frame, and the frame's own auto-layout padding is a placeholder — so it
        // is asserted against the measured rail instead.
        expect(
          indicatorSizeOf(tester).width,
          moreOrLessEquals(164, epsilon: 0.01),
          reason: '${size.name}: indeterminate bar width',
        );
        expect(
          indicatorSizeOf(tester).height,
          variant.size.height,
          reason: '${size.name}: indeterminate bar height',
        );
      }
    });

    test('Figma gives the progress bar no disabled state', () {
      // Disabled is a real state on interactive Fluent components and a visual
      // treatment on none of them. A progress bar simply has no such variant:
      // the State axis is validation, not interaction, and there is no
      // `onPressed` to be null. Asserted so nobody adds a greyed-out lookalike.
      expect(spec.properties['State'], isNot(contains('Disabled')));
    });
  });

  group('motion', () {
    test('the indeterminate sweep is upstream 3000ms linear', () {
      expect(
        FluentProgressBar.indeterminateMotion,
        const FluentMotionSpec(
          duration: Duration(milliseconds: 3000),
          curve: FluentCurve.linear,
        ),
      );
    });

    testWidgets('it sweeps -100% to 300% and repeats forever', (tester) async {
      await pump(tester, const FluentProgressBar(key: key));
      // The ticker registers its start time on the frame after the one that
      // started it, so this pump is the animation's real t=0.
      await tester.pump();

      // Figma's Animated_ProgressBar keyframes, in bar-width units: Before -164
      // (-100%), Gradient before 0, Gradient after 328 (200%), After 492 (300%).
      expect(sweepOf(tester), -1.0, reason: 'Status=Before');
      await tester.pump(const Duration(milliseconds: 750));
      expect(
        sweepOf(tester),
        moreOrLessEquals(0, epsilon: 0.01),
        reason: 'Status=Gradient before',
      );
      await tester.pump(const Duration(milliseconds: 1500));
      expect(
        sweepOf(tester),
        moreOrLessEquals(2, epsilon: 0.01),
        reason: 'Status=Gradient after',
      );
      await tester.pump(const Duration(milliseconds: 749));
      final nearEnd = sweepOf(tester);
      expect(nearEnd, greaterThan(2.99), reason: 'approaching Status=After');
      expect(nearEnd, lessThan(3), reason: '300% is the last keyframe');

      // Infinite: crossing the period restarts the sweep rather than parking it
      // at the end.
      await tester.pump(const Duration(milliseconds: 20));
      expect(
        sweepOf(tester),
        lessThan(-0.9),
        reason: 'wrapped to Status=Before',
      );
    });

    testWidgets('the sweep runs the other way in RTL', (tester) async {
      await pump(
        tester,
        const FluentProgressBar(key: key),
        direction: TextDirection.rtl,
      );
      await tester.pump();
      expect(sweepOf(tester), 1.0);
      await tester.pump(const Duration(milliseconds: 1500));
      expect(sweepOf(tester), moreOrLessEquals(-1, epsilon: 0.01));
    });

    testWidgets('reduced motion parks the bar where Figma draws it statically', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentProgressBar(key: key),
        reducedMotion: true,
      );
      // Static_ProgressBar draws the indeterminate Track at x=0, which is
      // translation 0 — so honouring reduced motion lands on the design, not on
      // an arbitrary frozen frame.
      expect(sweepOf(tester), 0.0);
      await tester.pump(const Duration(milliseconds: 1500));
      expect(sweepOf(tester), 0.0);
      await tester.pump(const Duration(milliseconds: 3000));
      expect(sweepOf(tester), 0.0);
    });

    testWidgets('a determinate value change is instant', (tester) async {
      // Upstream gives the determinate bar no transition, and neither does
      // Figma. That is a decision, not an omission: a progress report that lags
      // its own value is lying about progress.
      await pump(tester, const FluentProgressBar(key: key, value: 0.25));
      expect(
        indicatorSizeOf(tester).width,
        moreOrLessEquals(123, epsilon: 0.01),
      );

      await pump(tester, const FluentProgressBar(key: key, value: 0.75));
      expect(
        indicatorSizeOf(tester).width,
        moreOrLessEquals(369, epsilon: 0.01),
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
        FluentProgressBarTheme(
          style: FluentProgressBarStyle.from(indicatorColor: themed),
          child: FluentProgressBar(
            key: key,
            value: 0.5,
            style: FluentProgressBarStyle.from(indicatorColor: explicit),
          ),
        ),
      );
      expect(indicatorOf(tester).color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentProgressBarTheme(
          style: FluentProgressBarStyle.from(indicatorColor: themed),
          child: const FluentProgressBar(key: key, value: 0.5),
        ),
      );
      expect(indicatorOf(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      await pump(
        tester,
        FluentProgressBar(
          key: key,
          value: 0.5,
          status: FluentProgressBarStatus.success,
          style: FluentProgressBarStyle.from(
            borderRadius: FluentRadius.allSmall,
          ),
        ),
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      expect(railOf(tester).borderRadius, FluentRadius.allSmall);
      expect(
        indicatorOf(tester).color,
        theme.colors.statusSuccessBackground3,
        reason: 'overriding radius must not drop the success fill',
      );
      expect(railOf(tester).color, theme.colors.neutralBackground6);
    });

    testWidgets('thickness is a style property, not a hard-coded height', (
      tester,
    ) async {
      await pump(
        tester,
        FluentProgressBar(
          key: key,
          value: 0.5,
          style: FluentProgressBarStyle.from(thickness: 12),
        ),
      );
      expect(tester.getSize(find.byKey(key)).height, 12);
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      // The point of typing buildFluentProgressBar against the base state:
      // Fluent's rendering and motion, entirely custom styling, no fork.
      const base = FluentProgressBarBaseState(value: 0.5);
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentProgressBar(
            base,
            FluentProgressBarStyle.from(
              railColor: const Color(0xFF000088),
              indicatorColor: mine,
              thickness: 6,
              borderRadius: FluentRadius.allLarge,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(indicatorOf(tester).color, mine);
      expect(railOf(tester).borderRadius, FluentRadius.allLarge);
      expect(tester.getSize(find.byKey(key)).height, 6);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentProgressBarState(
        value: 0.5,
        status: FluentProgressBarStatus.error,
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentProgressBarStyle(state, theme).merge(
        FluentProgressBarStyle.from(borderRadius: FluentRadius.allMedium),
      );

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentProgressBar(state, adjusted, const <WidgetState>{}),
        ),
      );
      expect(indicatorOf(tester).color, theme.colors.statusDangerBackground3);
      expect(railOf(tester).borderRadius, FluentRadius.allMedium);
    });

    test('the state resolver keeps null meaning indeterminate', () {
      expect(resolveFluentProgressBarState().indeterminate, isTrue);
      expect(resolveFluentProgressBarState(value: 0).indeterminate, isFalse);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the bar', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: const FluentThemeOverride(
            colors: {FluentColorToken.compoundBrandBackground: magenta},
            child: Center(
              child: SizedBox(
                width: railWidth,
                child: FluentProgressBar(key: key, value: 0.5),
              ),
            ),
          ),
        ),
      );
      expect(indicatorOf(tester).color, magenta);
    });

    testWidgets('high contrast paints a visible outline', (tester) async {
      await pump(
        tester,
        const FluentProgressBar(key: key, value: 0.5),
        theme: FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        ),
      );
      // Neutral/Stroke/Transparent/Rest becomes canvasText in high contrast, so
      // the outline that is invisible in light must be opaque here. A hard-coded
      // Colors.transparent would stay invisible and the rail would vanish into
      // the canvas.
      final outline = outlineOf(tester);
      expect(outline.border, isNotNull);
      expect(outline.border!.top.color.a, 1.0);
      expect(outline.border!.top.width, FluentStroke.thin);
    });

    testWidgets('dark resolves every surface without a transparent hole', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentProgressBar(key: key, value: 0.5),
        theme: FluentThemeData.dark(fontPlatform: FluentFontPlatform.web),
      );
      final theme = FluentThemeData.dark(fontPlatform: FluentFontPlatform.web);
      expect(railOf(tester).color, theme.colors.neutralBackground6);
      expect(indicatorOf(tester).color, theme.colors.compoundBrandBackground);
      expect(railOf(tester).color!.a, 1.0);
    });
  });

  group('accessibility', () {
    // Rewritten: this used to pin `value: '50%'`. At the package's Flutter
    // floor `SemanticsRole.progressBar` parses the value with a bare
    // `double.parse` and rejects the suffix (3.41.0 `semantics.dart:228`), so
    // the percent sign had to go. Upstream made the same trade
    // (`material/progress_indicator.dart:150`). The check that would have
    // caught it is not this matcher but the `pump` above it: the binding
    // reports `semanticsEnabled`, so every frame builds a `SemanticsUpdate`
    // and runs the role assert in `SemanticsNode._addToUpdate` (3.41.0
    // `semantics.dart:4012`).
    testWidgets('a determinate bar announces its value against a range', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentProgressBar(
          key: key,
          value: 0.5,
          semanticLabel: 'Uploading',
        ),
      );
      final node = tester.getSemantics(find.byKey(key));
      expect(
        node,
        matchesSemantics(
          label: 'Uploading',
          value: '50',
          minValue: '0',
          maxValue: '100',
        ),
      );
      // `matchesSemantics` gained a `role` argument after this package's
      // Flutter floor, so the role is read off the node instead.
      expect(node.role, SemanticsRole.progressBar);
    });

    testWidgets('an indeterminate bar announces no value and no role', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentProgressBar(key: key, semanticLabel: 'Loading'),
      );
      final node = tester.getSemantics(find.byKey(key));
      expect(node, matchesSemantics(label: 'Loading'));
      expect(node.minValue, isNull);
      expect(node.maxValue, isNull);
      // A progress bar with no value must not claim the role: the role's own
      // contract requires a value inside a range.
      expect(node.role, SemanticsRole.none);
    });
  });
}

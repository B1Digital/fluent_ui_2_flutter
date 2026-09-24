import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentTeachingPopover` is `FluentPopover` with a richer body, so these
/// tests split in two: the *content* is asserted against the Figma numbers
/// directly through `buildFluentTeachingPopover`, with no overlay in the way,
/// and the *composition* is asserted through the real widget — that the theme
/// survives the trip into the `Overlay`, that Escape hands focus back, that the
/// entrance collapses under reduced motion, and that a disabled popover never
/// reaches the overlay at all.
void main() {
  const titleKey = Key('title');
  const bodyKey = Key('body');
  const headerKey = Key('header');
  const mediaKey = Key('media');
  const primaryKey = Key('primary');
  const secondaryKey = Key('secondary');
  const triggerKey = Key('trigger');

  final spec = loadSpec('teaching_popover');
  final footerSpec = loadSpec('teaching_popover_footer');

  const empty = <WidgetState>{};

  FluentThemeData light() =>
      FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  FluentTeachingPopoverStyle resolved(
    FluentTeachingPopoverAppearance appearance, {
    FluentThemeData? theme,
  }) => resolveFluentTeachingPopoverStyle(
    resolveFluentTeachingPopoverState(
      appearance: appearance,
      title: const Text('Title'),
      body: const Text('Body'),
    ),
    theme ?? light(),
  );

  /// The fixture part whose Figma layer name starts with [prefix].
  ///
  /// `SpecVariant.part` matches the whole name, and the body copy's layer is
  /// named after the sentence it holds — with a full stop on one variant and
  /// none on the other.
  SpecPart partStartingWith(SpecVariant variant, String prefix) =>
      variant.parts.firstWhere((p) => p.name.startsWith(prefix));

  // ---------------------------------------------------------------- fixture

  group('Figma fixture', () {
    for (final (name, appearance)
        in <(String, FluentTeachingPopoverAppearance)>[
          ('Default', FluentTeachingPopoverAppearance.normal),
          ('Brand', FluentTeachingPopoverAppearance.brand),
        ]) {
      final variant = spec.variant(<String, String>{'Style': name});

      test('$name — content geometry', () {
        final style = resolved(appearance);
        final content = partStartingWith(variant, '.TeachingPopover Content');
        final headerBlock = variant.part('Header + Content');
        final main = variant.part('Main');
        final footer = variant.part('Footer');

        expect(
          style.contentWidth!.resolve(empty),
          content.size.width,
          reason: '${variant.name}: content width',
        );
        expect(
          style.contentGap!.resolve(empty),
          content.gap,
          reason: '${variant.name}: gap between the header, main and footer',
        );
        expect(
          style.headerGap!.resolve(empty),
          headerBlock.gap,
          reason: '${variant.name}: gap between the caption and the media',
        );
        expect(
          style.mainGap!.resolve(empty),
          main.gap,
          reason: '${variant.name}: gap between the title and the body',
        );
        expect(
          (style.footerPadding!.resolve(empty)! as EdgeInsets).top,
          footer.padding!.top,
          reason: '${variant.name}: inset above the footer',
        );
        expect(
          style.footerGap!.resolve(empty),
          footer.gap,
          reason: '${variant.name}: gap between the footer actions',
        );
      });

      test('$name — type ramps', () {
        final style = resolved(appearance);

        // `SpecVariant.text` is the first TEXT under the frame, which on both
        // variants is the caption in the header row.
        void ramp(String slot, SpecText expected, TextStyle? actual) {
          expect(
            actual?.fontSize,
            expected.fontSize,
            reason: '${variant.name}: $slot fontSize',
          );
          expect(
            actual!.height! * actual.fontSize!,
            expected.lineHeight,
            reason:
                '${variant.name}: $slot lineHeight — set TextStyle.height '
                'rather than letting the font metric decide',
          );
        }

        ramp('header', variant.text!, style.headerTextStyle!.resolve(empty));
        ramp(
          'title',
          variant.part('Title string').text!,
          style.titleTextStyle!.resolve(empty),
        );
        ramp(
          'body',
          partStartingWith(variant, 'A detailed description').text!,
          style.bodyTextStyle!.resolve(empty),
        );
      });

      test('$name — slot colours match the bound tokens', () {
        final theme = light();
        final style = resolved(appearance, theme: theme);
        final c = theme.colors;
        final brand = appearance == FluentTeachingPopoverAppearance.brand;

        final title = variant.part('Title string');
        final body = partStartingWith(variant, 'A detailed description');
        final dismiss = variant.part('Header dismiss');

        expect(
          style.titleColor!.resolve(empty)!.toARGB32(),
          title.fill!.toARGB32(),
          reason: '${variant.name}: title (${title.token('fills')})',
        );
        expect(
          style.bodyColor!.resolve(empty)!.toARGB32(),
          body.fill!.toARGB32(),
          reason: '${variant.name}: body (${body.token('fills')})',
        );
        expect(
          style.headerColor!.resolve(empty),
          brand ? c.neutralForegroundOnBrand : c.neutralForeground3,
          reason:
              '${variant.name}: caption '
              '(${variant.text!.tokens['fills']})',
        );

        // Figma binds the subtle ramp to the dismiss button's fill, and the
        // storybook paints none: `colorTransparentBackground` with no :hover or
        // :active rule, 0px of change on hover or press. The storybook wins.
        expect(dismiss.token('fills'), 'Neutral/Background/Subtle/Rest');
        for (final states in <Set<WidgetState>>[
          empty,
          {WidgetState.hovered},
          {WidgetState.pressed},
        ]) {
          expect(
            style.dismissBackgroundColor!.resolve(states),
            c.transparentBackground,
            reason: '${variant.name} $states: dismiss fill',
          );
          expect(
            style.dismissColor!.resolve(states),
            brand ? c.neutralForegroundOnBrand : c.neutralForeground2,
            reason: '${variant.name} $states: dismiss glyph',
          );
        }
      });

      test('$name — dismiss button geometry', () {
        final style = resolved(appearance);
        final dismiss = variant.part('Header dismiss');

        final padding = style.dismissPadding!
            .resolve(empty)!
            .resolve(TextDirection.ltr);
        expect(style.dismissBorderRadius!.resolve(empty), dismiss.radius);
        // Figma draws a 24-square target round a 20 glyph. The storybook's
        // button is 21 x 22: `Dismiss12Regular` in 4px of padding and a 1px
        // transparent border on every side but the end
        // (useTeachingPopoverHeaderStyles.styles.raw.js:26-45). It wins.
        expect(dismiss.size, const Size(24, 24));
        expect(style.dismissIconSize!.resolve(empty), 12);
        expect(padding, const EdgeInsets.fromLTRB(5, 5, 4, 5));
        expect(
          Size(padding.horizontal + 12, padding.vertical + 12),
          const Size(21, 22),
        );
      });
    }

    test('Brand restyles both footer buttons, Default leaves them alone', () {
      final theme = light();
      final c = theme.colors;

      final normal = resolved(
        FluentTeachingPopoverAppearance.normal,
        theme: theme,
      );
      expect(normal.primaryButtonStyle, isNull);
      expect(normal.secondaryButtonStyle, isNull);

      // …because a stock FluentButton already resolves what Figma binds.
      final single = footerSpec.variant(<String, String>{'Type': 'Single'});
      final buttons = single.parts.where((p) => p.name == 'Button').toList();
      expect(buttons.first.token('fills'), 'Brand/Background/1/Rest');
      expect(buttons.first.fill!.toARGB32(), c.brandBackground.toARGB32());
      expect(buttons.last.token('fills'), 'Neutral/Background/1/Rest');
      expect(buttons.last.fill!.toARGB32(), c.neutralBackground1.toARGB32());
      expect(buttons.last.token('strokes'), 'Neutral/Stroke/1/Rest');
      expect(buttons.last.stroke!.toARGB32(), c.neutralStroke1.toARGB32());

      final brand = resolved(
        FluentTeachingPopoverAppearance.brand,
        theme: theme,
      );
      expect(
        brand.primaryButtonStyle!.backgroundColor!.resolve(empty),
        c.neutralForegroundOnBrand,
      );
      expect(
        brand.primaryButtonStyle!.foregroundColor!.resolve(empty),
        c.brandForegroundOnLight,
      );
      expect(
        brand.secondaryButtonStyle!.backgroundColor!.resolve(empty),
        c.brandBackground,
      );
      expect(
        brand.secondaryButtonStyle!.borderColor!.resolve(empty),
        c.neutralStrokeOnBrand2,
      );
    });

    test('footer — Single is right aligned, Multi is space between', () {
      final single = footerSpec.variant(<String, String>{'Type': 'Single'});
      final multi = footerSpec.variant(<String, String>{'Type': 'Multi'});
      final style = resolved(FluentTeachingPopoverAppearance.normal);

      for (final variant in <SpecVariant>[single, multi]) {
        expect(
          (style.footerPadding!.resolve(empty)! as EdgeInsets).top,
          variant.padding!.top,
          reason: '${variant.name}: inset above the footer',
        );
        expect(
          style.footerGap!.resolve(empty),
          variant.gap,
          reason: '${variant.name}: gap between the footer children',
        );
      }
    });

    test('carousel dots', () {
      final theme = light();
      final style = resolved(
        FluentTeachingPopoverAppearance.normal,
        theme: theme,
      );
      final multi = footerSpec.variant(<String, String>{'Type': 'Multi'});

      final target = multi.part('Step one');
      final active = multi.part('Active carousel step');
      final inactive = multi.part('Inactive carousel step');
      final pageCount = multi.part('1 of 4');

      expect(style.activeDotSize!.resolve(empty), active.size);
      expect(style.dotSize!.resolve(empty), inactive.size);
      expect(style.dotBorderRadius!.resolve(empty), active.radius);
      // Figma's tap target is 4 + 16 + 4 wide, 6 + 8 + 6 tall round the active
      // pill. Upstream's nav sets the dots 4 apart with no padding, and the
      // footer buttons' 96 floor needs that spacing to fit a page count too,
      // so the padding keeps Figma's height and half its width.
      expect(
        style.dotPadding!.resolve(empty),
        EdgeInsets.symmetric(
          horizontal: target.padding!.left / 2,
          vertical: target.padding!.top,
        ),
      );
      expect(
        (target.padding!.horizontal) + active.size.width,
        target.size.width,
      );
      expect(
        (target.padding!.vertical) + active.size.height,
        target.size.height,
      );

      // One token for both dots. Figma binds the same variable to the pill and
      // to the circle, which is what lets this component select a token rather
      // than mixing 30% of one into transparent the way React does.
      expect(active.token('fills'), 'Brand/Foreground/2/Rest');
      expect(inactive.token('fills'), active.token('fills'));
      expect(
        style.dotColor!.resolve(empty)!.toARGB32(),
        active.fill!.toARGB32(),
      );
      expect(
        style.dotBackgroundColor!.resolve(empty),
        theme.colors.transparentBackground,
      );
      expect(target.token('fills'), 'Neutral/Background/Transparent/Rest');

      // The page count shares the body ramp and takes Foreground/3.
      expect(
        style.bodyTextStyle!.resolve(empty)!.fontSize,
        pageCount.text!.fontSize,
      );
      expect(
        style.pageCountColor!.resolve(empty)!.toARGB32(),
        pageCount.fill!.toARGB32(),
      );
    });

    test('the brand surface is FluentPopover\'s, not a second table', () {
      // The teaching popover adds no surface tokens of its own: the Figma
      // `Popover` instance under each variant is what paints, and its fill,
      // stroke, radius and inset are already asserted by popover_test.
      final surface = spec
          .variant(<String, String>{'Style': 'Brand'})
          .part('Popover');
      expect(surface.token('fills'), 'Brand/Background/1/Rest');
      expect(surface.token('strokes'), 'Brand/Stroke/1/Rest');
      expect(surface.radius, FluentRadius.allMedium);
      expect(surface.padding, const EdgeInsets.all(FluentSpacing.l));
    });
  });

  // ----------------------------------------------------------------- layout

  group('layout', () {
    Future<void> pumpContent(
      WidgetTester tester, {
      FluentTeachingPopoverAppearance appearance =
          FluentTeachingPopoverAppearance.normal,
      FluentTeachingPopoverCarousel? carousel,
      bool withMedia = true,
      FluentTeachingPopoverStyle? style,
    }) {
      final state = resolveFluentTeachingPopoverState(
        appearance: appearance,
        header: const Text('New', key: headerKey),
        media: withMedia ? const SizedBox(key: mediaKey, height: 90) : null,
        title: const Text('Title', key: titleKey),
        body: const Text('Body', key: bodyKey),
        onDismiss: () {},
        primaryAction: const SizedBox(key: primaryKey, height: 32, width: 74),
        secondaryAction: const SizedBox(
          key: secondaryKey,
          height: 32,
          width: 96,
        ),
        carousel: carousel,
      );
      return tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Center(
            child: buildFluentTeachingPopover(
              state,
              resolveFluentTeachingPopoverStyle(state, light()).merge(style),
              empty,
            ),
          ),
        ),
      );
    }

    testWidgets('the content column is 288 wide', (tester) async {
      await pumpContent(tester);
      expect(tester.getSize(find.byKey(mediaKey)).width, 288);
    });

    testWidgets('gaps match the Figma auto-layout', (tester) async {
      await pumpContent(tester);
      final variant = spec.variant(<String, String>{'Style': 'Default'});

      final header = tester.getRect(find.byKey(headerKey));
      final media = tester.getRect(find.byKey(mediaKey));
      final title = tester.getRect(find.byKey(titleKey));
      final body = tester.getRect(find.byKey(bodyKey));
      final primary = tester.getRect(find.byKey(primaryKey));

      // Measured from the header ROW, not from the caption's own glyph box:
      // the row is as tall as the 22-tall dismiss button beside it.
      final headerRow = tester.getRect(
        find
            .ancestor(of: find.byKey(headerKey), matching: find.byType(Row))
            .first,
      );
      expect(
        header.top,
        greaterThan(headerRow.bottom - headerRow.height),
        reason: 'the caption is centred in a row as tall as the dismiss button',
      );
      expect(
        media.top - headerRow.bottom,
        variant.part('Header + Content').gap,
        reason: 'caption to media',
      );
      expect(
        title.top - media.bottom,
        partStartingWith(variant, '.TeachingPopover Content').gap,
        reason: 'media to title',
      );
      expect(
        body.top - title.bottom,
        variant.part('Main').gap,
        reason: 'title to body',
      );
      expect(
        primary.top - body.bottom,
        partStartingWith(variant, '.TeachingPopover Content').gap! +
            variant.part('Footer').padding!.top,
        reason:
            'body to footer, which is the content gap plus the footer inset',
      );
    });

    testWidgets('a single-step footer is right aligned, primary first', (
      tester,
    ) async {
      await pumpContent(tester);
      final primary = tester.getRect(find.byKey(primaryKey));
      final secondary = tester.getRect(find.byKey(secondaryKey));
      final content = tester.getRect(find.byKey(mediaKey));

      expect(primary.right, lessThan(secondary.left));
      expect(secondary.right, content.right);
      expect(
        secondary.left - primary.right,
        footerSpec.variant(<String, String>{'Type': 'Single'}).gap,
      );
    });

    testWidgets('a carousel footer pushes the dots between the actions', (
      tester,
    ) async {
      await pumpContent(
        tester,
        carousel: const FluentTeachingPopoverCarousel(steps: 4, activeStep: 0),
      );
      final primary = tester.getRect(find.byKey(primaryKey));
      final secondary = tester.getRect(find.byKey(secondaryKey));
      final content = tester.getRect(find.byKey(mediaKey));

      // Multi reverses the order: back, dots, next.
      expect(secondary.left, content.left);
      expect(primary.right, content.right);
      expect(find.bySemanticsLabel('Step 1 of 4'), findsOneWidget);
    });

    testWidgets('the active dot is a pill and the rest are circles', (
      tester,
    ) async {
      await pumpContent(
        tester,
        carousel: const FluentTeachingPopoverCarousel(steps: 3, activeStep: 1),
      );
      final multi = footerSpec.variant(<String, String>{'Type': 'Multi'});
      // Every dot is an 8-tall box; nothing else in the content is.
      final sizes = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((b) => b.height == FluentSize.size80)
          .map((b) => Size(b.width!, b.height!))
          .toList();

      expect(sizes, <Size>[
        multi.part('Inactive carousel step').size,
        multi.part('Active carousel step').size,
        multi.part('Inactive carousel step').size,
      ]);
    });

    testWidgets('the dots sit 4 apart, as upstream\'s nav sets them', (
      tester,
    ) async {
      // Live probe of the Carousel story: dots at x 141, 161 and 173 — a
      // 16-wide pill then two 8-wide dots, `gap: 4px` between them. That
      // spacing is also what fits four dots and a page count between two
      // footer buttons at their 96 floor: 288 - 2 x 96 - 2 x 8 leaves 80.
      await pumpContent(
        tester,
        carousel: const FluentTeachingPopoverCarousel(steps: 3, activeStep: 0),
      );
      final dots = tester
          .widgetList<SizedBox>(find.byType(SizedBox))
          .where((b) => b.height == FluentSize.size80)
          .toList();
      final rects = <Rect>[
        for (final dot in dots) tester.getRect(find.byWidget(dot)),
      ];

      expect(rects.length, 3);
      for (var i = 1; i < rects.length; i++) {
        expect(rects[i].left - rects[i - 1].right, 4, reason: 'gap $i');
      }
    });

    testWidgets('the header block is skipped when there is nothing in it', (
      tester,
    ) async {
      final state = resolveFluentTeachingPopoverState(
        title: const Text('Title', key: titleKey),
        body: const Text('Body', key: bodyKey),
      );
      await tester.pumpWidget(
        FluentApp(
          theme: light(),
          home: Center(
            child: buildFluentTeachingPopover(
              state,
              resolveFluentTeachingPopoverStyle(state, light()),
              empty,
            ),
          ),
        ),
      );
      expect(find.byIcon(fluentTeachingPopoverDismissIcon), findsNothing);
      expect(tester.getRect(find.byKey(titleKey)).top, lessThan(300));
    });
  });

  // -------------------------------------------------------------- behaviour

  group('behaviour', () {
    late void Function({required bool show}) setOpen;
    late List<bool> changes;
    late List<int> steps;
    late int dismissed;
    final triggerFocus = FocusNode(debugLabel: 'trigger');

    tearDownAll(triggerFocus.dispose);

    Future<void> pump(
      WidgetTester tester, {
      bool open = false,
      bool enabled = true,
      FluentThemeData? theme,
      Map<FluentColorToken, Color> overrides =
          const <FluentColorToken, Color>{},
      FluentTeachingPopoverAppearance appearance =
          FluentTeachingPopoverAppearance.normal,
      FluentTeachingPopoverCarousel? carousel,
      bool withDismiss = true,
      bool reducedMotion = false,
      FluentTeachingPopoverStyle? style,
      FluentTeachingPopoverStyle? themeStyle,
    }) {
      changes = <bool>[];
      steps = <int>[];
      dismissed = 0;
      return tester.pumpWidget(
        FluentApp(
          theme: theme ?? light(),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reducedMotion),
            child: StatefulBuilder(
              builder: (context, setState) {
                setOpen = ({required bool show}) => setState(() => open = show);
                Widget popover = FluentTeachingPopover(
                  open: open,
                  onOpenChanged: enabled
                      ? (value) {
                          changes.add(value);
                          setState(() => open = value);
                        }
                      : null,
                  appearance: appearance,
                  header: const Text('New', key: headerKey),
                  title: const Text('Title', key: titleKey),
                  body: const Text('Body', key: bodyKey),
                  onDismiss: withDismiss ? () => dismissed++ : null,
                  primaryAction: FluentButton(
                    key: primaryKey,
                    appearance: FluentButtonAppearance.primary,
                    onPressed: () {},
                    child: const Text('Got it'),
                  ),
                  secondaryAction: FluentButton(
                    key: secondaryKey,
                    onPressed: () {},
                    child: const Text('Back'),
                  ),
                  carousel: carousel == null
                      ? null
                      : FluentTeachingPopoverCarousel(
                          steps: carousel.steps,
                          activeStep: carousel.activeStep,
                          onStepSelected: carousel.onStepSelected == null
                              ? null
                              : steps.add,
                          pageCount: carousel.pageCount,
                        ),
                  style: style,
                  child: FluentButton(
                    key: triggerKey,
                    focusNode: triggerFocus,
                    onPressed: () => setState(() => open = !open),
                    child: const Text('Show'),
                  ),
                );
                if (themeStyle != null) {
                  popover = FluentTeachingPopoverTheme(
                    style: themeStyle,
                    child: popover,
                  );
                }
                if (overrides.isNotEmpty) {
                  popover = FluentThemeOverride(
                    colors: overrides,
                    child: popover,
                  );
                }
                return Center(child: popover);
              },
            ),
          ),
        ),
      );
    }

    /// Opens the popover and settles the two frames it takes to reach the
    /// overlay. Motion is deliberately *not* settled.
    Future<void> show(WidgetTester tester) async {
      setOpen(show: true);
      await tester.pump();
      await tester.pump();
    }

    testWidgets('the content reaches the Overlay', (tester) async {
      await pump(tester);
      expect(find.byKey(titleKey), findsNothing);
      await show(tester);
      expect(find.byKey(titleKey), findsOneWidget);
      expect(find.byKey(bodyKey), findsOneWidget);
      expect(find.byKey(headerKey), findsOneWidget);
    });

    testWidgets('a FluentThemeOverride on the trigger reaches the overlay', (
      tester,
    ) async {
      const overridden = Color(0xFF780510);
      await pump(
        tester,
        overrides: const <FluentColorToken, Color>{
          FluentColorToken.neutralForeground1: overridden,
        },
      );
      await show(tester);
      await tester.pumpAndSettle();

      // The title resolves against the OVERRIDE, which lives above the trigger
      // and below the app — so it is only visible to the overlay if the themes
      // in between were captured on the way in. That is the single most likely
      // thing to be silently broken in an overlay-based component.
      final style = tester
          .widget<RichText>(
            find.descendant(
              of: find.byKey(titleKey),
              matching: find.byType(RichText),
            ),
          )
          .text
          .style;
      expect(style!.color, overridden);
      expect(style.color, isNot(light().colors.neutralForeground1));
    });

    testWidgets('a FluentTeachingPopoverTheme on the trigger reaches it too', (
      tester,
    ) async {
      await pump(
        tester,
        themeStyle: FluentTeachingPopoverStyle.from(
          titleColor: const Color(0xFF00FF00),
        ),
      );
      await show(tester);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RichText>(
              find.descendant(
                of: find.byKey(titleKey),
                matching: find.byType(RichText),
              ),
            )
            .text
            .style!
            .color,
        const Color(0xFF00FF00),
      );
    });

    testWidgets('the widget style wins over the subtree theme', (tester) async {
      await pump(
        tester,
        themeStyle: FluentTeachingPopoverStyle.from(
          titleColor: const Color(0xFF00FF00),
        ),
        style: FluentTeachingPopoverStyle.from(
          titleColor: const Color(0xFF0000FF),
        ),
      );
      await show(tester);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RichText>(
              find.descendant(
                of: find.byKey(titleKey),
                matching: find.byType(RichText),
              ),
            )
            .text
            .style!
            .color,
        const Color(0xFF0000FF),
      );
    });

    testWidgets('the brand appearance restyles the footer buttons', (
      tester,
    ) async {
      await pump(tester, appearance: FluentTeachingPopoverAppearance.brand);
      await show(tester);
      await tester.pumpAndSettle();

      final theme = light();
      expect(
        surfaceColorOf(tester, of: find.byKey(primaryKey)),
        theme.colors.neutralForegroundOnBrand,
        reason: 'the brand primary is a white button with brand text',
      );
      expect(
        surfaceColorOf(tester, of: find.byKey(secondaryKey)),
        theme.colors.brandBackground,
        reason: 'the brand secondary keeps the surface fill and outlines it',
      );
    });

    testWidgets('disabled is a real state: nothing reaches the overlay', (
      tester,
    ) async {
      await pump(tester, open: true, enabled: false);
      await tester.pump();
      await tester.pump();
      expect(find.byKey(titleKey), findsNothing);
    });

    testWidgets('Escape closes it and returns focus to the trigger', (
      tester,
    ) async {
      await pump(tester);
      triggerFocus.requestFocus();
      await tester.pump();
      await show(tester);
      await tester.pumpAndSettle();

      expect(triggerFocus.hasFocus, isFalse, reason: 'focus moved in');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(changes, contains(false));
      expect(find.byKey(titleKey), findsNothing);
      expect(triggerFocus.hasFocus, isTrue, reason: 'focus came back');
    });

    testWidgets('the dismiss button closes it and reports the dismissal', (
      tester,
    ) async {
      await pump(tester);
      await show(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(fluentTeachingPopoverDismissIcon));
      await tester.pumpAndSettle();

      expect(dismissed, 1);
      expect(changes, contains(false));
      expect(find.byKey(titleKey), findsNothing);
    });

    testWidgets('a mouse over the dismiss changes nothing, as upstream', (
      tester,
    ) async {
      // The storybook's dismiss is a bare transparent button: 21 x 22 round a
      // 12px `Dismiss12Regular`, and 0px of change on hover or press. The port
      // used to ramp a 24-square subtle fill through #F5F5F5 and #E0E0E0.
      for (final appearance in FluentTeachingPopoverAppearance.values) {
        await pump(tester, appearance: appearance);
        await show(tester);
        await tester.pumpAndSettle();

        final theme = light();
        final glyph = find.byIcon(fluentTeachingPopoverDismissIcon);
        final box = find
            .ancestor(of: glyph, matching: find.byType(DecoratedBox))
            .first;
        final rest = (
          (tester.widget<DecoratedBox>(box).decoration as BoxDecoration).color,
          IconTheme.of(tester.element(glyph)).color,
        );
        expect(rest, (
          theme.colors.transparentBackground,
          appearance == FluentTeachingPopoverAppearance.brand
              ? theme.colors.neutralForegroundOnBrand
              : theme.colors.neutralForeground2,
        ));
        expect(tester.getSize(box), const Size(21, 22));
        expect(IconTheme.of(tester.element(glyph)).size, 12);

        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer(location: Offset.zero);
        final at = tester.getCenter(glyph);
        await mouse.moveTo(at);
        await mouse.moveTo(at + const Offset(1, 0));
        await tester.pump();
        expect(
          (
            (tester.widget<DecoratedBox>(box).decoration as BoxDecoration)
                .color,
            IconTheme.of(tester.element(glyph)).color,
          ),
          rest,
          reason: '${appearance.name}: hover',
        );

        await mouse.down(at + const Offset(1, 0));
        await tester.pump();
        expect(
          (
            (tester.widget<DecoratedBox>(box).decoration as BoxDecoration)
                .color,
            IconTheme.of(tester.element(glyph)).color,
          ),
          rest,
          reason: '${appearance.name}: press',
        );
        await mouse.cancel();
        await mouse.removePointer();
      }
    });

    testWidgets('no dismiss handler draws no dismiss button', (tester) async {
      await pump(tester, withDismiss: false);
      await show(tester);
      await tester.pumpAndSettle();
      expect(find.byIcon(fluentTeachingPopoverDismissIcon), findsNothing);
    });

    testWidgets('the dismiss button announces itself', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      await show(tester);
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byIcon(fluentTeachingPopoverDismissIcon)),
        matchesSemantics(
          label: 'Close',
          isButton: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('a carousel dot selects its step', (tester) async {
      await pump(
        tester,
        carousel: FluentTeachingPopoverCarousel(
          steps: 4,
          activeStep: 0,
          onStepSelected: (_) {},
        ),
      );
      await show(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Step 3 of 4'));
      await tester.pumpAndSettle();
      expect(steps, <int>[2]);
    });

    testWidgets('a carousel dot\'s focus ring hugs the dot, not its target', (
      tester,
    ) async {
      // `useTeachingPopoverCarouselNavButtonStyles` puts
      // `createCustomFocusIndicatorStyle` on the dot element itself, at
      // `outline-offset: 0` — live, a tabbed-to selected dot is a 16 x 8 rect
      // with a 2px outline, so 20 x 12 outer. Figma has no focus stroke on the
      // `Step` frames at all, so the tap target they describe is not a defence
      // for wrapping the ring around it: doing that paints a 28 x 24 box with
      // the pill floating in the middle.
      await pump(
        tester,
        carousel: FluentTeachingPopoverCarousel(
          steps: 3,
          activeStep: 1,
          onStepSelected: (_) {},
        ),
      );
      await show(tester);
      await tester.pumpAndSettle();

      final multi = footerSpec.variant(<String, String>{'Type': 'Multi'});
      final rings = find.byType(FluentFocusRing);
      final sizes = <Size>[
        for (var i = 0; i < tester.widgetList(rings).length; i++)
          tester.getSize(rings.at(i)),
      ];

      expect(
        sizes,
        contains(multi.part('Active carousel step').size),
        reason: 'the ring measures the 16 x 8 pill',
      );
      expect(
        sizes,
        isNot(contains(multi.part('Step one').size)),
        reason: 'and never the 24 x 20 tap target around it',
      );
    });

    testWidgets('the arrow is drawn by default, unlike a plain popover', (
      tester,
    ) async {
      // `useTeachingPopover.ts`: `withArrow: props.withArrow ?? true`, and
      // `components-teachingpopover--default` renders one unasked. Figma agrees
      // far enough — `teaching_popover.json` ships a *visible* arrow part on
      // both variants, where `popover.json` ships all twelve of its arrow
      // layers hidden, which is why FluentPopover still defaults to false.
      await pump(tester);
      await show(tester);
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is FluentPopoverArrowPainter,
        ),
        findsOneWidget,
      );
    });

    testWidgets('dots with no handler are inert and unfocusable', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        carousel: const FluentTeachingPopoverCarousel(steps: 3, activeStep: 2),
      );
      await show(tester);
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.bySemanticsLabel('Step 3 of 3')),
        matchesSemantics(
          label: 'Step 3 of 3',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
        ),
        reason: 'an inert dot announces its state but offers no tap action',
      );
      handle.dispose();
    });

    testWidgets('the page count is drawn beside the dots', (tester) async {
      await pump(
        tester,
        carousel: const FluentTeachingPopoverCarousel(
          steps: 2,
          activeStep: 0,
          pageCount: Text('1/2'),
        ),
      );
      await show(tester);
      await tester.pumpAndSettle();
      expect(find.text('1/2'), findsOneWidget);
    });

    testWidgets('high contrast keeps every edge visible', (tester) async {
      final hc = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(tester, theme: hc);
      await show(tester);
      await tester.pumpAndSettle();

      // The surface's own border is FluentPopover's; what matters here is that
      // nothing in the content painted a hardcoded transparent that would stay
      // invisible where the token goes opaque. The header dismiss is not
      // listed: upstream gives it no hover fill at all, in any theme.
      final style = resolved(FluentTeachingPopoverAppearance.normal, theme: hc);
      const hovered = <WidgetState>{WidgetState.hovered};
      for (final entry in <String, Color?>{
        'dot target fill': style.dotBackgroundColor!.resolve(hovered),
      }.entries) {
        expect(
          entry.value!.a,
          greaterThan(0),
          reason: '${entry.key} vanished in high contrast',
        );
      }
      expect(style.dotColor!.resolve(empty), hc.colors.brandForeground2);
    });
  });

  // ----------------------------------------------------------------- motion

  group('motion', () {
    // The entrance is FluentPopover's — enter only, durationSlower on
    // curveDecelerateMid — so these assert that a teaching popover *inherits*
    // it rather than re-declaring one.
    late void Function({required bool show}) setOpen;

    Future<void> pump(WidgetTester tester, {bool reducedMotion = false}) {
      var open = false;
      return tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reducedMotion),
            child: StatefulBuilder(
              builder: (context, setState) {
                setOpen = ({required bool show}) => setState(() => open = show);
                return Center(
                  child: FluentTeachingPopover(
                    open: open,
                    onOpenChanged: (value) => setState(() => open = value),
                    title: const Text('Title', key: titleKey),
                    body: const Text('Body', key: bodyKey),
                    child: const Text('trigger', key: triggerKey),
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    double opacity(WidgetTester tester) => tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byKey(titleKey),
                matching: find.byType(Opacity),
              )
              .last,
        )
        .opacity;

    testWidgets('it fades in over durationSlower', (tester) async {
      await pump(tester);
      setOpen(show: true);
      await tester.pump();
      await tester.pump();

      expect(opacity(tester), 0);
      await tester.pump(FluentDuration.slower ~/ 2);
      expect(opacity(tester), greaterThan(0));
      expect(opacity(tester), lessThan(1));
      await tester.pump(FluentDuration.slower);
      expect(opacity(tester), 1);
    });

    testWidgets('reduced motion jumps straight to the end state', (
      tester,
    ) async {
      await pump(tester, reducedMotion: true);
      setOpen(show: true);
      await tester.pump();
      await tester.pump();

      // The very first painted frame is already the destination: fully opaque
      // and unshifted, with no ticker scheduled behind it.
      expect(opacity(tester), 1);
      expect(tester.binding.transientCallbackCount, 0);
    });
  });
}

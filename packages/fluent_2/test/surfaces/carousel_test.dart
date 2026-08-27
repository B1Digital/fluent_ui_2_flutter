import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentCarousel` is the first component in the package assembled almost
/// entirely out of other components: every chevron, every autoplay control and
/// every indicator step is a `FluentButton` underneath. The tests below
/// therefore assert composition as a structural fact — the real widget type has
/// to be in the tree — as well as the numbers.
///
/// Two behaviours get more attention than the pixels: autoplay, which must stop
/// for reduced motion, for a hovering pointer and for focus; and disabled,
/// which is a real state rather than a paint job.
void main() {
  final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
  final highContrast = FluentThemeData.highContrast(
    fontPlatform: FluentFontPlatform.web,
  );

  /// A slide that is trivially identifiable and paints nothing of its own.
  Widget slide(int i) => SizedBox.expand(key: ValueKey<int>(i));

  List<Widget> slides(int n) => <Widget>[for (var i = 0; i < n; i++) slide(i)];

  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    FluentThemeData? theme,
    bool reducedMotion = false,
    Size size = const Size(415, 400),
  }) => tester.pumpWidget(
    FluentApp(
      theme: theme ?? light,
      builder: reducedMotion
          ? (context, inner) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: inner!,
            )
          : null,
      home: Center(
        child: SizedBox(width: size.width, height: size.height, child: child),
      ),
    ),
  );

  /// The carousel under test, sized the way Figma's variant frame is.
  Widget carousel({
    int count = 5,
    List<Widget>? previews,
    bool autoplay = false,
    bool enabled = true,
    bool loop = false,
    int initialIndex = 0,
    ValueChanged<int>? onIndexChanged,
    FluentCarouselLayout layout = FluentCarouselLayout.outsideContent,
    FluentCarouselChevronPlacement placement =
        FluentCarouselChevronPlacement.flexibleToEdges,
    FluentCarouselPauseButton pauseButton =
        FluentCarouselPauseButton.onContentClick,
    FluentCarouselStyle? style,
    Widget? header,
  }) => Column(
    children: <Widget>[
      SizedBox(
        height: 297,
        child: FluentCarousel(
          slides: slides(count),
          previews: previews,
          header: header,
          autoplay: autoplay,
          enabled: enabled,
          loop: loop,
          initialIndex: initialIndex,
          onIndexChanged: onIndexChanged,
          layout: layout,
          chevronPlacement: placement,
          pauseButton: pauseButton,
          style: style,
          semanticLabel: 'Product highlights',
        ),
      ),
    ],
  );

  Future<TestGesture> hover(WidgetTester tester, Finder target) async {
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pump();
    await mouse.moveTo(tester.getCenter(target));
    await tester.pump();
    return mouse;
  }

  // ---------------------------------------------------------------------------
  // Figma fidelity: `.Carousel step`, component set 9380:3589 on page 8995:2.
  // ---------------------------------------------------------------------------

  group('pixel fidelity — .Carousel step', () {
    final spec = loadSpec('carousel_step');

    /// Figma cannot store a colour without an RGB triple, so a fully
    /// transparent token is recorded as transparent *white* while core stores
    /// CSS `transparent`, which is transparent *black*. Both are invisible, so
    /// a zero-alpha value is compared on alpha alone — see
    /// `doc/token-divergences.md`.
    void expectColor(Color actual, Color expected, String reason) {
      if (expected.a == 0) {
        expect(actual.a, 0, reason: '$reason — expected fully transparent');
        return;
      }
      expect(actual.toARGB32(), expected.toARGB32(), reason: reason);
    }

    const states = <String, Set<WidgetState>>{
      'Rest': <WidgetState>{},
      'Hover': <WidgetState>{WidgetState.hovered},
      'Pressed': <WidgetState>{WidgetState.pressed},
    };

    for (final type in <String>['Active', 'Inactive']) {
      for (final stateName in states.keys) {
        final variant = spec.variant(<String, String>{
          'Type': type,
          'State': stateName,
        });

        testWidgets(variant.name, (tester) async {
          await pump(
            tester,
            Center(
              child: FluentCarouselStep(
                selected: type == 'Active',
                semanticLabel: 'Slide 1 of 5',
                onPressed: () {},
              ),
            ),
          );

          final step = find.byType(FluentCarouselStep);

          // The 24x24 hit target, its inset and its corner radius all live on
          // the composed FluentButton, which is exactly the point.
          expect(tester.getSize(step), variant.size);
          expect(
            tester
                .widget<Padding>(
                  find
                      .descendant(of: step, matching: find.byType(Padding))
                      .first,
                )
                .padding
                .resolve(TextDirection.ltr),
            variant.padding,
          );
          expect(resolvedRadiusOf(tester, of: step), variant.radius);

          // The hit target's fill. Never Colors.transparent: this token turns
          // opaque in high contrast.
          expectColor(
            surfaceColorOf(tester, of: step),
            variant.fill!,
            '${variant.name} hit-target fill',
          );
          expect(
            variant.token('fills'),
            'Neutral/Background/Transparent/$stateName',
            reason: 'the Figma token bound to the step frame',
          );
          expect(variant.token('radius'), 'button-corner-radius');

          // The mark itself: an 8x8 circle, or a 16x8 pill when current.
          final part = variant.part(
            type == 'Active'
                ? 'Active carousel step'
                : 'Inactive carousel step',
          );
          final mark = find
              .descendant(of: step, matching: find.byType(DecoratedBox))
              .last;
          expect(tester.getSize(mark), part.size);

          final decoration =
              tester.widget<DecoratedBox>(mark).decoration as BoxDecoration;
          expect(
            decoration.borderRadius?.resolve(TextDirection.ltr),
            part.radius,
            reason: 'the mark is a pill, radius 9999 — not React\'s 4px',
          );

          // The mark's colour comes off the resolved style, which is what the
          // composed button hands down through IconTheme.
          final resolved = resolveFluentCarouselStyle(
            resolveFluentCarouselState(),
            light,
          );
          expectColor(
            resolved.stepColor!.resolve(states[stateName]!)!,
            part.fill!,
            '${variant.name} mark fill',
          );
          expect(part.token('fills'), stateName);
        });
      }
    }

    testWidgets('the mark tracks the live interaction state', (tester) async {
      await pump(
        tester,
        Center(
          child: FluentCarouselStep(
            selected: true,
            semanticLabel: 'Slide 1 of 5',
            onPressed: () {},
          ),
        ),
      );

      final step = find.byType(FluentCarouselStep);
      Color markColor() =>
          (tester
                      .widget<DecoratedBox>(
                        find
                            .descendant(
                              of: step,
                              matching: find.byType(DecoratedBox),
                            )
                            .last,
                      )
                      .decoration
                  as BoxDecoration)
              .color!;

      expect(markColor(), light.colors.neutralForeground2);
      await hover(tester, step);
      expect(
        markColor(),
        light.colors.neutralForeground2Hover,
        reason: 'the mark reads the colour the button resolved, via IconTheme',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Figma fidelity: `.CarouselNav`, component set 9380:3505.
  // ---------------------------------------------------------------------------

  group('pixel fidelity — .CarouselNav', () {
    final spec = loadSpec('carousel_nav');

    /// The nav strip's own box, measured from the outermost controls: the
    /// leading group's left edge to the trailing chevron's right edge.
    Rect navRect(WidgetTester tester) {
      final buttons = find.byType(FluentButton);
      final first = tester.getRect(buttons.first);
      final last = tester.getRect(buttons.last);
      return Rect.fromLTRB(
        first.left,
        first.top,
        last.right,
        first.top +
            tester.getSize(find.byType(FluentCarouselStep).first).height,
      );
    }

    const modes = <String, ({bool autoplay, bool preview})>{
      'StepsDefault': (autoplay: false, preview: false),
      'StepsAutoPlay': (autoplay: true, preview: false),
      'ImagePreview default': (autoplay: false, preview: true),
      'ImagePreviewAutoPlay': (autoplay: true, preview: true),
    };

    modes.forEach((mode, config) {
      final variant = spec.variant(<String, String>{'Mode': mode});

      testWidgets(variant.name, (tester) async {
        await pump(
          tester,
          carousel(
            autoplay: config.autoplay,
            pauseButton: config.autoplay
                ? FluentCarouselPauseButton.inNav
                : FluentCarouselPauseButton.onContentClick,
            placement: FluentCarouselChevronPlacement.groupedToSteps,
            previews: config.preview ? slides(5) : null,
          ),
        );

        final rect = navRect(tester);
        expect(
          rect.width,
          moreOrLessEquals(variant.size.width, epsilon: 0.01),
          reason: 'nav width: 24 + 12 + indicator + 12 + 24',
        );
        expect(
          rect.height,
          moreOrLessEquals(variant.size.height, epsilon: 0.01),
        );
        expect(variant.token('itemSpacing'), 'Spacing/Horizontal/M');

        // The indicator strip's own frame — `.Carousel steps` (120x24) or
        // `.Image Preview nav` (256x48).
        final indicator = variant.parts
            .where((p) => p.name != 'ChevronLeft' && p.name != 'ChevronRight')
            .single;
        final steps = find.byType(FluentCarouselStep);
        final stripLeft = tester.getRect(steps.first).left;
        final stripRight = tester.getRect(steps.last).right;
        expect(
          stripRight - stripLeft,
          moreOrLessEquals(indicator.size.width, epsilon: 0.01),
          reason: '${indicator.name} width',
        );
        expect(
          tester.getSize(steps.first).height,
          moreOrLessEquals(indicator.size.height, epsilon: 0.01),
        );

        // Gap between the leading group and the indicator: Spacing/Horizontal/M.
        final chevron = variant.parts.firstWhere(
          (p) => p.name.startsWith('Chev'),
        );
        expect(chevron.gap, FluentSpacing.s, reason: 'autoplay-to-chevron gap');
        expect(chevron.size.width, config.autoplay ? 56 : 24);
      });
    });

    testWidgets('the autoplay control sits before the previous chevron, '
        'Spacing/Horizontal/S away', (tester) async {
      await pump(
        tester,
        carousel(
          autoplay: true,
          pauseButton: FluentCarouselPauseButton.inNav,
          placement: FluentCarouselChevronPlacement.groupedToSteps,
        ),
      );

      final buttons = find.byType(FluentButton);
      final control = tester.getRect(buttons.at(0));
      final previous = tester.getRect(buttons.at(1));
      expect(previous.left - control.right, FluentSpacing.s);
      expect(control.size, const Size(24, 24));
    });
  });

  // ---------------------------------------------------------------------------
  // The four axes of the `Carousel` set itself (9380:3615).
  // ---------------------------------------------------------------------------

  group('layout axes', () {
    testWidgets('Chevron placement=Flexible to edges insets the chevrons '
        'Spacing/Horizontal/M from the edges', (tester) async {
      await pump(tester, carousel());

      final carouselRect = tester.getRect(find.byType(FluentCarousel));
      final buttons = find.byType(FluentButton);
      expect(
        tester.getRect(buttons.first).left - carouselRect.left,
        FluentSpacing.m,
      );
      expect(
        carouselRect.right - tester.getRect(buttons.last).right,
        FluentSpacing.m,
      );
    });

    testWidgets('Chevron placement=Grouped to steps hugs and centres', (
      tester,
    ) async {
      await pump(
        tester,
        carousel(placement: FluentCarouselChevronPlacement.groupedToSteps),
      );

      final carouselRect = tester.getRect(find.byType(FluentCarousel));
      final buttons = find.byType(FluentButton);
      final left = tester.getRect(buttons.first).left - carouselRect.left;
      final right = carouselRect.right - tester.getRect(buttons.last).right;
      expect(left, moreOrLessEquals(right, epsilon: 0.5));
      expect(left, greaterThan(FluentSpacing.m));
    });

    testWidgets('Chevron placement=Centered to content flanks the slide', (
      tester,
    ) async {
      await pump(
        tester,
        carousel(placement: FluentCarouselChevronPlacement.centeredToContent),
      );

      final slideRect = tester.getRect(find.byType(PageView));
      final previous = tester.getRect(find.byType(FluentButton).first);
      expect(
        previous.center.dy,
        moreOrLessEquals(slideRect.center.dy, epsilon: 0.5),
        reason: 'vertically centred on the slide, not on the nav strip',
      );
      expect(
        previous.right + FluentSpacing.m,
        moreOrLessEquals(slideRect.left, epsilon: 0.5),
      );
    });

    testWidgets('Layout=Over content washes the strip in '
        'Neutral/Background/Alpha/1 and floats it over the slide', (
      tester,
    ) async {
      await pump(tester, carousel(layout: FluentCarouselLayout.overContent));

      final slideRect = tester.getRect(find.byType(PageView));
      final strip = tester.getRect(find.byType(FluentCarouselStep).first);
      expect(
        strip.bottom,
        lessThanOrEqualTo(slideRect.bottom),
        reason: 'the strip is inside the slide box',
      );

      final wash = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.color == light.colors.neutralBackgroundAlpha);
      expect(wash, hasLength(1));
      expect(
        wash.single.borderRadius?.resolve(TextDirection.ltr),
        FluentRadius.allXLarge,
      );
    });

    testWidgets('Layout=Outside content leaves the strip unwashed, '
        'Spacing/Vertical/M below the slide', (tester) async {
      await pump(tester, carousel());

      final slideRect = tester.getRect(find.byType(PageView));
      final strip = tester.getRect(find.byType(FluentCarouselStep).first);
      expect(strip.top - slideRect.bottom, FluentSpacing.m);
      expect(
        tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .map((d) => d.decoration)
            .whereType<BoxDecoration>()
            .where((d) => d.color == light.colors.neutralBackgroundAlpha),
        isEmpty,
      );
    });

    testWidgets('Nav Type=Image preview swaps the dots for thumbnails: '
        '40 at rest, 48 selected, radius Corner radius/Small', (tester) async {
      await pump(tester, carousel(previews: slides(5)));

      final steps = find.byType(FluentCarouselStep);
      expect(tester.getSize(steps.at(0)), const Size(48, 48));
      expect(tester.getSize(steps.at(1)), const Size(40, 40));
      expect(
        tester.getRect(steps.at(1)).left - tester.getRect(steps.at(0)).right,
        FluentSpacing.m,
      );
      expect(
        tester
            .widget<ClipRRect>(
              find.descendant(
                of: steps.at(0),
                matching: find.byType(ClipRRect),
              ),
            )
            .borderRadius
            .resolve(TextDirection.ltr),
        FluentRadius.allSmall,
      );
    });

    testWidgets('a header sits Spacing/Vertical/M above the slide', (
      tester,
    ) async {
      await pump(
        tester,
        carousel(header: const SizedBox(key: Key('header'), height: 52)),
      );

      expect(
        tester.getRect(find.byType(PageView)).top -
            tester.getRect(find.byKey(const Key('header'))).bottom,
        FluentSpacing.m,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Composition — the point of this wave.
  // ---------------------------------------------------------------------------

  group('composition', () {
    testWidgets('every control is a real FluentButton', (tester) async {
      await pump(
        tester,
        carousel(autoplay: true, pauseButton: FluentCarouselPauseButton.inNav),
      );

      // play/pause + previous + next + five steps.
      expect(find.byType(FluentButton), findsNWidgets(8));
      expect(
        find.descendant(
          of: find.byType(FluentCarouselStep),
          matching: find.byType(FluentButton),
        ),
        findsNWidgets(5),
        reason: 'a step is a FluentButton, not a re-implemented hit target',
      );
    });

    testWidgets('the chevrons use the subtle appearance and Figma\'s '
        'icon-only inset', (tester) async {
      await pump(tester, carousel());

      final previous = tester.widget<FluentButton>(
        find.byType(FluentButton).first,
      );
      expect(previous.appearance, FluentButtonAppearance.subtle);
      expect(previous.size, FluentButtonSize.small);
      expect(
        previous.style!.padding!.resolve(<WidgetState>{}),
        const EdgeInsets.all(FluentSpacing.xxs),
      );
      expect(
        tester.getSize(find.byType(FluentButton).first),
        const Size(24, 24),
      );
    });

    testWidgets('the slide viewport is a PageView, not a hand-rolled pager', (
      tester,
    ) async {
      await pump(tester, carousel());
      expect(find.byType(PageView), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // Motion.
  // ---------------------------------------------------------------------------

  group('motion', () {
    test('the slide spec is the transcribed embla duration', () {
      expect(fluentCarouselSlide.duration, FluentDuration.gentle);
      expect(fluentCarouselSlide.curve, FluentCurve.decelerateMid);
      expect(fluentCarouselAutoplayInterval, const Duration(seconds: 4));
    });

    testWidgets('the slide animates over the spec duration', (tester) async {
      await pump(tester, carousel());

      final controller = tester
          .widget<PageView>(find.byType(PageView))
          .controller!;
      await tester.tap(find.byType(FluentButton).last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 125));
      expect(
        controller.page,
        allOf(greaterThan(0.0), lessThan(1.0)),
        reason: 'mid-flight, so the transition is real',
      );

      await tester.pumpAndSettle();
      expect(controller.page, 1.0);
    });

    testWidgets('reduced motion jumps instead', (tester) async {
      await pump(tester, carousel(), reducedMotion: true);

      final controller = tester
          .widget<PageView>(find.byType(PageView))
          .controller!;
      await tester.tap(find.byType(FluentButton).last);
      await tester.pump();
      expect(
        controller.page,
        1.0,
        reason: 'arrived on the first frame, with nothing left scheduled',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Autoplay.
  // ---------------------------------------------------------------------------

  group('autoplay', () {
    testWidgets('advances on the upstream interval', (tester) async {
      var index = 0;
      await pump(
        tester,
        carousel(autoplay: true, onIndexChanged: (i) => index = i),
      );

      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(index, 1);
    });

    testWidgets('does not run at all under reduced motion', (tester) async {
      var index = 0;
      await pump(
        tester,
        carousel(autoplay: true, onIndexChanged: (i) => index = i),
        reducedMotion: true,
      );

      await tester.pump(const Duration(seconds: 20));
      expect(
        index,
        0,
        reason:
            'content that advances past a reader who asked for reduced '
            'motion is an accessibility failure, not a faster animation',
      );
    });

    testWidgets('pauses while the pointer is over the carousel', (
      tester,
    ) async {
      var index = 0;
      await pump(
        tester,
        carousel(autoplay: true, onIndexChanged: (i) => index = i),
      );

      final mouse = await hover(tester, find.byType(PageView));
      await tester.pump(const Duration(seconds: 12));
      expect(index, 0);

      await mouse.moveTo(Offset.zero);
      await tester.pump();
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(index, 1, reason: 'and resumes when the pointer leaves');
    });

    testWidgets('pauses while focus is anywhere inside', (tester) async {
      var index = 0;
      await pump(
        tester,
        carousel(autoplay: true, onIndexChanged: (i) => index = i),
      );

      final node = Focus.of(
        tester.element(find.byType(Icon).last),
        scopeOk: true,
      );
      node.requestFocus();
      await tester.pump();
      await tester.pump(const Duration(seconds: 12));
      expect(index, 0);
    });

    testWidgets('the in-nav control toggles playback and swaps its glyph', (
      tester,
    ) async {
      var index = 0;
      await pump(
        tester,
        carousel(
          autoplay: true,
          pauseButton: FluentCarouselPauseButton.inNav,
          onIndexChanged: (i) => index = i,
        ),
      );

      final control = find.byType(FluentButton).first;
      expect(
        tester
            .widget<Icon>(
              find.descendant(of: control, matching: find.byType(Icon)),
            )
            .icon,
        FluentIcons.pause_20_regular,
      );

      await tester.tap(control);
      await tester.pump();
      expect(
        tester
            .widget<Icon>(
              find.descendant(of: control, matching: find.byType(Icon)),
            )
            .icon,
        FluentIcons.play_20_regular,
      );

      await tester.pump(const Duration(seconds: 12));
      expect(index, 0, reason: 'paused');
    });

    testWidgets('onContentClick toggles playback by tapping the slide', (
      tester,
    ) async {
      var index = 0;
      await pump(
        tester,
        carousel(autoplay: true, onIndexChanged: (i) => index = i),
      );

      await tester.tapAt(tester.getCenter(find.byType(PageView)));
      await tester.pump();
      await tester.pump(const Duration(seconds: 12));
      expect(index, 0);
    });

    testWidgets('stops at the last slide when not looping', (tester) async {
      var index = 0;
      await pump(
        tester,
        carousel(
          count: 2,
          initialIndex: 1,
          autoplay: true,
          onIndexChanged: (i) => index = i,
        ),
      );

      await tester.pump(const Duration(seconds: 12));
      expect(index, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // Disabled, keyboard, semantics.
  // ---------------------------------------------------------------------------

  group('disabled is a real state', () {
    testWidgets('every control refuses input and the slide will not drag', (
      tester,
    ) async {
      var index = 0;
      await pump(
        tester,
        carousel(enabled: false, onIndexChanged: (i) => index = i),
      );

      for (final button in tester.widgetList<FluentButton>(
        find.byType(FluentButton),
      )) {
        expect(button.onPressed, isNull);
      }

      await tester.tap(find.byType(FluentButton).last);
      await tester.pumpAndSettle();
      expect(index, 0);

      expect(
        tester.widget<PageView>(find.byType(PageView)).physics,
        isA<NeverScrollableScrollPhysics>(),
      );
    });

    testWidgets('the previous chevron is disabled on the first slide '
        'and enabled once past it', (tester) async {
      await pump(tester, carousel());

      expect(
        tester.widget<FluentButton>(find.byType(FluentButton).first).onPressed,
        isNull,
      );

      await tester.tap(find.byType(FluentButton).last);
      await tester.pumpAndSettle();
      expect(
        tester.widget<FluentButton>(find.byType(FluentButton).first).onPressed,
        isNotNull,
      );
    });

    testWidgets('a disabled step resolves the disabled foreground token', (
      tester,
    ) async {
      final style = resolveFluentCarouselStyle(
        resolveFluentCarouselState(),
        light,
      );
      expect(
        style.stepColor!.resolve(<WidgetState>{WidgetState.disabled}),
        light.colors.neutralForegroundDisabled,
      );
    });
  });

  group('keyboard', () {
    testWidgets('the arrow keys move between slides', (tester) async {
      var index = 0;
      await pump(tester, carousel(onIndexChanged: (i) => index = i));

      await tester.tap(find.byType(FluentButton).last);
      await tester.pumpAndSettle();
      expect(index, 1);

      // The shortcuts are declared closer to the focused node than the app's
      // own directional-traversal bindings, so they win while a nav control
      // holds focus.
      Focus.of(
        tester.element(
          find.descendant(
            of: find.byType(FluentButton).last,
            matching: find.byType(Icon),
          ),
        ),
        scopeOk: true,
      ).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(index, 0, reason: 'left arrow, with focus on the next chevron');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(index, 1);
    });

    testWidgets('Space activates a focused step', (tester) async {
      var index = 0;
      await pump(tester, carousel(onIndexChanged: (i) => index = i));

      final node = Focus.of(
        tester.element(
          find
              .descendant(
                of: find.byType(FluentCarouselStep).at(2),
                matching: find.byType(DecoratedBox),
              )
              .first,
        ),
        scopeOk: true,
      );
      node.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(index, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // `PageView` is already direction-aware, so RTL is the one place where the
  // physical arrows and the logical page order can disagree.
  // ---------------------------------------------------------------------------

  group('RTL', () {
    Widget mirrored(Widget child) =>
        Directionality(textDirection: TextDirection.rtl, child: child);

    testWidgets('the arrow keys follow the visible motion, not the page order', (
      tester,
    ) async {
      var index = 0;
      await pump(tester, mirrored(carousel(onIndexChanged: (i) => index = i)));

      // The next chevron: enabled at slide 0, so it can hold focus and put the
      // carousel's own shortcuts closest to the focused node.
      Focus.of(
        tester.element(
          find.descendant(
            of: find.byType(FluentButton).last,
            matching: find.byType(Icon),
          ),
        ),
        scopeOk: true,
      ).requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(index, 1, reason: 'slide 1 is to the left of slide 0 in RTL');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(index, 0, reason: 'right arrow goes back in RTL');
    });

    testWidgets('the chevrons sit on the reading-order edges', (tester) async {
      await pump(tester, mirrored(carousel()));

      final carouselRect = tester.getRect(find.byType(FluentCarousel));
      final buttons = find.byType(FluentButton);
      expect(
        carouselRect.right - tester.getRect(buttons.first).right,
        FluentSpacing.m,
        reason: 'previous hugs the start edge, which is the right in RTL',
      );
      expect(
        tester.getRect(buttons.last).left - carouselRect.left,
        FluentSpacing.m,
      );
    });

    testWidgets('the flanking chevrons mirror with the slide', (tester) async {
      await pump(
        tester,
        mirrored(
          carousel(
            placement: FluentCarouselChevronPlacement.centeredToContent,
            layout: FluentCarouselLayout.overContent,
          ),
        ),
      );

      // Centered to content puts both chevrons inside the slide's own stack, so
      // they come before the strip's steps in tree order — `.last` here is the
      // trailing step, not the next chevron.
      final slideRect = tester.getRect(find.byType(PageView));
      final buttons = find.byType(FluentButton);
      final previous = tester.getRect(buttons.at(0));
      final next = tester.getRect(buttons.at(1));
      expect(
        slideRect.right - previous.right,
        moreOrLessEquals(FluentSpacing.m, epsilon: 0.5),
        reason: 'PositionedDirectional.start is the right edge in RTL',
      );
      expect(
        next.left - slideRect.left,
        moreOrLessEquals(FluentSpacing.m, epsilon: 0.5),
      );
    });
  });

  group('semantics', () {
    testWidgets('the carousel, its chevrons and its steps all announce', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        carousel(autoplay: true, pauseButton: FluentCarouselPauseButton.inNav),
      );

      expect(find.bySemanticsLabel('Product highlights'), findsOneWidget);
      expect(find.bySemanticsLabel('Previous slide'), findsOneWidget);
      expect(find.bySemanticsLabel('Next slide'), findsOneWidget);
      expect(find.bySemanticsLabel('Slide 3 of 5'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Pause automatic slide show'),
        findsOneWidget,
      );

      handle.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // Theming.
  // ---------------------------------------------------------------------------

  group('theming', () {
    testWidgets('a subtree FluentThemeOverride reaches the steps', (
      tester,
    ) async {
      const override = Color(0xFF7A0B2E);
      await tester.pumpWidget(
        FluentApp(
          theme: light,
          home: FluentThemeOverride(
            colors: const <FluentColorToken, Color>{
              FluentColorToken.neutralForeground2: override,
            },
            child: Center(
              child: FluentCarouselStep(
                selected: true,
                semanticLabel: 'Slide 1 of 5',
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find
                        .descendant(
                          of: find.byType(FluentCarouselStep),
                          matching: find.byType(DecoratedBox),
                        )
                        .last,
                  )
                  .decoration
              as BoxDecoration;
      expect(decoration.color, override);
    });

    testWidgets('FluentCarouselTheme restyles a subtree and the widget\'s own '
        'style still wins', (tester) async {
      await pump(
        tester,
        FluentCarouselTheme(
          style: FluentCarouselStyle.from(navGap: 40, controlGap: 30),
          child: carousel(
            placement: FluentCarouselChevronPlacement.groupedToSteps,
            autoplay: true,
            pauseButton: FluentCarouselPauseButton.inNav,
            style: FluentCarouselStyle.from(controlGap: 4),
          ),
        ),
      );

      final buttons = find.byType(FluentButton);
      expect(
        tester.getRect(buttons.at(1)).left -
            tester.getRect(buttons.at(0)).right,
        4,
        reason: 'the widget style beats the subtree theme',
      );
      expect(
        tester.getRect(find.byType(FluentCarouselStep).first).left -
            tester.getRect(buttons.at(1)).right,
        40,
        reason: 'and the subtree theme beats the resolved defaults',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // High contrast.
  // ---------------------------------------------------------------------------

  group('high contrast', () {
    /// A bug shipped for four waves: an inverted foreground resolved to the
    /// same colour as the surface under it, so the text vanished while the
    /// border still drew and the layout still measured right. Nothing about
    /// this component may repeat it.
    test('no foreground matches the surface it paints on', () {
      final style = resolveFluentCarouselStyle(
        resolveFluentCarouselState(layout: FluentCarouselLayout.overContent),
        highContrast,
      );
      final c = highContrast.colors;

      for (final states in const <Set<WidgetState>>[
        <WidgetState>{},
        <WidgetState>{WidgetState.hovered},
        <WidgetState>{WidgetState.pressed},
        <WidgetState>{WidgetState.disabled},
      ]) {
        final mark = style.stepColor!.resolve(states)!;
        final hitTarget = style.stepBackgroundColor!.resolve(states)!;
        final wash = style.indicatorBackgroundColor!.resolve(states)!;

        // What the mark actually paints on: its own hit target once that is
        // opaque, otherwise the wash showing through it. Getting this wrong is
        // how an invisible foreground ships — the border still draws and the
        // layout still measures right.
        final beneath = hitTarget.a == 1.0 ? hitTarget : wash;
        expect(
          mark,
          isNot(beneath),
          reason:
              'the step mark would vanish into the surface under it '
              'for $states',
        );
        expect(beneath.a, 1.0, reason: 'the surface under the mark is opaque');
        // Only the *interactive* transparent tokens gain a high-contrast
        // override — Hover, Pressed and Selected resolve to the system
        // Highlight, while Rest stays genuinely see-through in every theme. A
        // hardcoded Colors.transparent would stay invisible on hover too, and
        // a hovered step would then have no surface at all here.
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.pressed)) {
          expect(
            hitTarget.a,
            1.0,
            reason:
                'the transparent token is opaque in high contrast for '
                '$states',
          );
        }
      }

      // The chevrons are FluentButtons on the subtle ramp; their foreground
      // must clear the same wash the strip paints.
      expect(c.neutralForeground2, isNot(c.subtleBackground));
      expect(c.neutralForeground2, isNot(c.neutralBackgroundAlpha));
    });

    testWidgets('the rendered surfaces differ too', (tester) async {
      await pump(
        tester,
        carousel(layout: FluentCarouselLayout.overContent),
        theme: highContrast,
      );

      final decorations = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(FluentCarouselStep).first,
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .toList();

      expect(decorations, hasLength(2));
      expect(
        decorations.last.color,
        isNot(decorations.first.color),
        reason: 'the mark and the hit target it sits on',
      );
    });
  });
}

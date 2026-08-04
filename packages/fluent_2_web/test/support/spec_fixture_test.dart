import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'spec_fixture.dart';

/// The harness that every component will use to prove it matches the official
/// design. Since no component exists yet, it is proved against a plain
/// [Container] built from the fixture — including a deliberately wrong build,
/// because a matcher that cannot fail is worthless.
void main() {
  const target = Key('target');

  final spec = loadSpec('button');

  /// The Primary/Rest/Medium/Icon-and-label row, whose numbers were confirmed
  /// against a live Figma read before the fixture was committed.
  final anchor = spec.variant(const {
    'Style': 'Primary',
    'State': 'Rest',
    'Size': 'Medium',
    'Layout': 'Icon and label',
  });

  /// Builds the variant as a plain [Container]. The label is a single glyph
  /// rather than 'Button': the harness compares font size and line height only,
  /// never a rendered glyph box, so the string is irrelevant.
  Widget build(SpecVariant v, {EdgeInsets? padding}) => Directionality(
    textDirection: TextDirection.ltr,
    child: Center(
      child: Container(
        key: target,
        width: v.size.width,
        height: v.size.height,
        padding: padding ?? v.padding,
        decoration: BoxDecoration(color: v.fill, borderRadius: v.radius),
        child: Text(
          'B',
          style: TextStyle(
            fontSize: v.text!.fontSize,
            height: v.text!.heightMultiplier,
          ),
        ),
      ),
    ),
  );

  group('loadSpec', () {
    test('reads every variant of the component set', () {
      expect(spec.component, 'button');
      expect(spec.variants, hasLength(150));
    });

    test("strips Figma's ' (Default)' marker from property values", () {
      // Figma calls the default value "Medium (Default)". A lookup should read
      // {'Size': 'Medium'}, and the untouched name stays on the row.
      expect(spec.properties['Size'], ['Large', 'Medium', 'Small']);
      expect(spec.properties['Style'], contains('Secondary'));
      expect(anchor.props['Size'], 'Medium');
      expect(anchor.figmaName, contains('Medium (Default)'));
    });

    test('matches the values read live from Figma', () {
      // These are the sanity anchors. If the fixture is ever regenerated
      // against a moved or re-authored component set, this is what catches it
      // before 150 component tests start lying.
      expect(anchor.size, const Size(94, 32));
      expect(
        anchor.padding,
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      );
      expect(anchor.gap, 6);
      expect(anchor.radius, BorderRadius.circular(4));
      expect(anchor.fill, const Color(0xFF0F6CBD));
      expect(anchor.text!.fontFamily, 'Segoe UI');
      expect(anchor.text!.fontStyle, 'Semibold');
      expect(anchor.text!.fontSize, 14);
      expect(anchor.text!.lineHeight, 20);
    });

    test('names the token to reach for, not just the resolved number', () {
      // The whole reason the fixture carries tokens: a component author must
      // never reverse-engineer #0F6CBD back into a token, and must never
      // compute a hover colour from a rest colour.
      expect(anchor.token('fills'), 'Brand/Background/1/Rest');
      expect(anchor.token('paddingLeft'), 'Spacing/Horizontal/M');
      expect(anchor.text!.tokens['fills'], [
        'Neutral/Foreground/On Brand/Rest',
      ]);

      final hover = spec.variant(const {
        'Style': 'Primary',
        'State': 'Hover',
        'Size': 'Medium',
        'Layout': 'Icon and label',
      });
      expect(hover.token('fills'), 'Brand/Background/1/Hover');
    });

    test('records a fully transparent token as a real colour, not a null', () {
      // Fluent's transparent tokens are real tokens with real values, and in
      // high contrast they become opaque. #00FFFFFF is not Colors.transparent.
      final transparent = spec.variant(const {
        'Style': 'Transparent',
        'State': 'Rest',
        'Size': 'Medium',
        'Layout': 'Icon and label',
      });
      expect(transparent.fill, const Color(0x00FFFFFF));
      expect(transparent.token('fills'), 'Neutral/Background/Transparent/Rest');
    });

    test('reports no stroke width when nothing is stroked', () {
      // Figma keeps the last-authored strokeWeight on a node with no stroke at
      // all — Primary reports 2. Trusting it would spec a 2px border onto every
      // filled button.
      expect(anchor.strokeWidth, 0);
      expect(anchor.stroke, isNull);

      final outline = spec.variant(const {
        'Style': 'Outline',
        'State': 'Rest',
        'Size': 'Medium',
        'Layout': 'Icon and label',
      });
      expect(outline.strokeWidth, 1);
      expect(outline.stroke, const Color(0xFFD1D1D1));
      expect(outline.token('strokes'), 'Neutral/Stroke/1/Rest');
    });

    test('carries no text for icon-only variants', () {
      final iconOnly = spec.variant(const {
        'Style': 'Primary',
        'State': 'Rest',
        'Size': 'Medium',
        'Layout': 'Icon only',
      });
      expect(iconOnly.text, isNull);
      expect(iconOnly.size, const Size(32, 32));
    });

    test('where() narrows without needing every property', () {
      // 5 states x 3 sizes x 2 layouts.
      expect(spec.where(const {'Style': 'Primary'}), hasLength(30));
      expect(
        spec.where(const {'Style': 'Primary', 'Size': 'Small'}),
        hasLength(10),
      );
    });

    test('names the offending property when a lookup finds nothing', () {
      expect(
        () => spec.variant(const {'Style': 'Ghost'}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('Style=Ghost'), contains('Primary')),
          ),
        ),
      );
    });

    test('refuses an ambiguous lookup rather than picking one', () {
      expect(
        () => spec.variant(const {'Style': 'Primary', 'State': 'Rest'}),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            allOf(contains('6 variants'), contains('Size'), contains('Layout')),
          ),
        ),
      );
    });
  });

  group('expectSpec', () {
    testWidgets('passes on a widget built from the fixture', (tester) async {
      await tester.pumpWidget(build(anchor));
      expectSpec(tester, find.byKey(target), anchor);
    });

    testWidgets('fails naming the variant and the property', (tester) async {
      // The point of the harness. An agent debugging one of 150 variants has
      // nothing to go on but this message.
      await tester.pumpWidget(
        build(anchor, padding: anchor.padding!.copyWith(left: 10)),
      );
      expect(
        () => expectSpec(tester, find.byKey(target), anchor),
        throwsA(
          isA<TestFailure>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('Style=Primary, State=Rest, Size=Medium'),
              contains('padding.left'),
              contains('expected 12'),
              contains('got 10'),
            ),
          ),
        ),
      );
    });

    testWidgets('catches a wrong surface colour', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Container(
              key: target,
              width: anchor.size.width,
              height: anchor.size.height,
              padding: anchor.padding,
              decoration: BoxDecoration(
                color: const Color(0xFF0F6CBE), // one blue off
                borderRadius: anchor.radius,
              ),
            ),
          ),
        ),
      );
      expect(
        () => expectSpec(tester, find.byKey(target), anchor),
        throwsA(
          isA<TestFailure>().having(
            (e) => e.message,
            'message',
            allOf(
              contains('fill'),
              contains('#FF0F6CBD'),
              contains('#FF0F6CBE'),
            ),
          ),
        ),
      );
    });

    testWidgets('catches a line height left to the font default', (
      tester,
    ) async {
      // Fluent specifies line height explicitly. Leaving it null means the
      // metric comes from whichever font happens to be installed — the exact
      // flakiness this harness exists to avoid.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Container(
              key: target,
              width: anchor.size.width,
              height: anchor.size.height,
              padding: anchor.padding,
              decoration: BoxDecoration(
                color: anchor.fill,
                borderRadius: anchor.radius,
              ),
              child: const Text('B', style: TextStyle(fontSize: 14)),
            ),
          ),
        ),
      );
      expect(
        () => expectSpec(tester, find.byKey(target), anchor),
        throwsA(
          isA<TestFailure>().having(
            (e) => e.message,
            'message',
            allOf(contains('text.lineHeight'), contains('no explicit height')),
          ),
        ),
      );
    });
  });

  group('resolvers', () {
    testWidgets('read back what the widget actually resolved to', (
      tester,
    ) async {
      await tester.pumpWidget(build(anchor));
      final of = find.byKey(target);

      expect(surfaceColorOf(tester, of: of), const Color(0xFF0F6CBD));
      expect(resolvedRadiusOf(tester, of: of), BorderRadius.circular(4));

      final style = resolvedTextStyleOf(tester, of: of);
      expect(style.fontSize, 14);
      expect(style.height! * style.fontSize!, closeTo(20, 0.01));
    });

    testWidgets('say what is missing rather than throwing a cast error', (
      tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(key: target, width: 10, height: 10),
        ),
      );
      expect(
        () => surfaceColorOf(tester, of: find.byKey(target)),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('CustomPaint'),
          ),
        ),
      );
    });
  });
}

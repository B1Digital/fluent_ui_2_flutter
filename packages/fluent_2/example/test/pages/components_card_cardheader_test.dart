import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// CardHeader has one section and no knobs: its subject is the four-slot grid
/// itself, rendered eight times, once per combination of image, description and
/// action. So the tests are about which slots each of those eight rows actually
/// produced, where the optional slots push the required one, and whether the two
/// text slots still carry the type ramp the props table promises — the claims
/// that a composition demo quietly loses when someone re-lays it out.
void main() {
  const String page = 'components-card-cardheader';
  final DocsSection section = sectionOf('components-card-cardheader--default');

  // The demo's own declared width, which is what the shell renders it at.
  const Size viewport = Size(300, 700);

  final Finder titles = find.text('App Name');
  final Finder images = find.byIcon(FluentIcons.slide_layout_24_regular);
  final Finder actions = find.byWidgetPredicate(
    (Widget w) => w is FluentButton && w.semanticLabel == 'More options',
  );

  /// The row [index] of the eight, addressed through its always-present title.
  Finder rowAt(int index) =>
      find.ancestor(of: titles.at(index), matching: find.byType(Row)).first;

  group('slots', () {
    testWidgets(
      'the eight rows cover every combination of the optional slots',
      (WidgetTester tester) async {
        await pumpSection(tester, section, size: viewport);

        // Upstream's story is a truth table: title alone, title + each optional
        // slot, and every pair. Counting each slot is what proves the table is
        // still complete after an edit — `render_test` would pass on one row.
        expect(titles, findsNWidgets(8));
        expect(
          images,
          findsNWidgets(4),
          reason: 'four of the eight rows carry the logo',
        );
        expect(
          find.text('Developer'),
          findsNWidgets(4),
          reason: 'four of the eight rows carry a description',
        );
        expect(
          actions,
          findsNWidgets(4),
          reason: 'four of the eight rows carry a trailing action',
        );
      },
    );

    testWidgets('the logo keeps its alternative text', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, size: viewport);

      // The story stands in a Fluent glyph for upstream's PowerPoint logo, so
      // the semantics label is the only thing left that says what it depicts.
      expect(
        tester
            .widgetList<Semantics>(
              find.ancestor(of: images.first, matching: find.byType(Semantics)),
            )
            .any(
              (Semantics s) =>
                  s.properties.label == 'Microsoft PowerPoint logo' &&
                  s.properties.image == true,
            ),
        isTrue,
      );
    });
  });

  group('geometry', () {
    testWidgets('the image slot insets the title by the logo and its gap', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, size: viewport);

      // Row 0 carries the logo, row 1 does not. A grid that dropped the gap, or
      // one that reserved the image column even when empty, changes exactly
      // this number and nothing else visible.
      final double withImage = tester.getRect(titles.at(0)).left;
      final double withoutImage = tester.getRect(titles.at(1)).left;
      expect(tester.getRect(images.first).width, 32);
      expect(withImage - withoutImage, 32 + 12);

      // Rows 2, 3 and 6 carry the logo too; 4, 5 and 7 do not. Every row in a
      // group must align, or the eight rows read as a ragged list.
      for (final int i in <int>[2, 3, 6]) {
        expect(tester.getRect(titles.at(i)).left, withImage);
      }
      for (final int i in <int>[4, 5, 7]) {
        expect(tester.getRect(titles.at(i)).left, withoutImage);
      }
    });

    testWidgets('the action is pinned to the trailing edge of its row', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, size: viewport);

      // Rows 0, 1, 2 and 4 are the ones with an action, in that order.
      for (final (int action, int row) in <(int, int)>[
        (0, 0),
        (1, 1),
        (2, 2),
        (3, 4),
      ]) {
        expect(
          tester.getRect(actions.at(action)).right,
          tester.getRect(rowAt(row)).right,
          reason: 'the action in row $row must sit at the far end',
        );
      }
    });

    testWidgets('the description sits under the title, not beside it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, size: viewport);

      final Rect title = tester.getRect(titles.at(0));
      final Rect description = tester.getRect(find.text('Developer').first);
      expect(description.left, title.left);
      expect(
        description.top,
        greaterThanOrEqualTo(title.bottom),
        reason: 'title over description is the grid this header is named for',
      );
    });
  });

  group('typography', () {
    testWidgets('the title carries body1Strong and the description caption1', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, size: viewport);
      final FluentTypography type = FluentTheme.of(
        tester.element(titles.first),
      ).typography;

      // The Texts themselves carry no style: the ramp arrives through the
      // DefaultTextStyle each slot wraps, which is exactly the wiring that a
      // refactor drops without changing a single character on screen. Reading
      // the paragraph's own span is the only way to see it.
      TextStyle? styleOf(Finder text) =>
          tester.renderObject<RenderParagraph>(text).text.style;

      expect(styleOf(titles.first)?.fontWeight, type.body1Strong.fontWeight);
      expect(styleOf(titles.first)?.fontSize, type.body1Strong.fontSize);
      expect(
        styleOf(find.text('Developer').first)?.fontSize,
        type.caption1.fontSize,
      );
      expect(
        styleOf(find.text('Developer').first)?.fontWeight,
        type.caption1.fontWeight,
      );
    });
  });

  group('interaction', () {
    testWidgets('each row action responds to its own pointer only', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, size: viewport);

      Color? glyphOf(int index) => IconTheme.of(
        tester.element(
          find.descendant(of: actions.at(index), matching: find.byType(Icon)),
        ),
      ).color;

      final Color? resting = glyphOf(0);
      expect(glyphOf(3), resting);

      // A transparent button's fill stays transparent on hover by design, so
      // its whole affordance is the glyph turning brand-coloured — and only a
      // real mouse produces it. Reading a second row at the same time is what
      // catches an action wired to shared state instead of its own.
      final (Color?, Color?) hovered = await whileHovering(
        tester,
        actions.at(0),
        () => (glyphOf(0), glyphOf(3)),
      );
      expect(hovered.$1, isNot(resting), reason: 'row 0 must react');
      expect(hovered.$2, resting, reason: 'row 4 must not react');

      await mouseClick(tester, actions.at(0));
      expect(glyphOf(0), resting, reason: 'the glyph must return to rest');
    });

    testWidgets('every action is live', (WidgetTester tester) async {
      await pumpSection(tester, section, size: viewport);

      for (final FluentButton button in tester.widgetList<FluentButton>(
        actions,
      )) {
        expect(
          button.onPressed,
          isNotNull,
          reason: 'a header action with no callback is a dead affordance',
        );
      }
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section, size: viewport);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Divider's page has no knobs and nothing to press: six sections, each a
/// stack of dividers that differ only in the axis the section is named after.
/// So the axis IS the assertion here — a rule that lands in the same place,
/// the same colour and the same thickness whatever the section passes is a
/// component ignoring its own props, and a mount-only test cannot tell that
/// apart from a working one. Every test below measures the rule and the label
/// rather than reading a widget field back.
void main() {
  const String page = 'components-divider';

  group('default', () {
    final DocsSection section = sectionOf('components-divider--default');

    testWidgets('a bare divider is one rule across the whole width', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(find.byType(FluentDivider), findsNWidgets(2));
      expect(
        rulesOf(0),
        findsOneWidget,
        reason: 'nothing interrupts a divider with no label',
      );
      final Rect rule = tester.getRect(rulesOf(0));
      final Rect divider = tester.getRect(dividerAt(0));
      expect(rule.left, divider.left);
      expect(rule.right, divider.right);
      expect(
        rule.height,
        FluentStroke.thin,
        reason: 'the rule is a hairline, not a bar',
      );
    });

    testWidgets('a label splits the rule in two and sits between them', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        rulesOf(1),
        findsNWidgets(2),
        reason: 'a labelled divider is a rule, the label, and a rule',
      );
      final Rect leading = tester.getRect(rulesOf(1).at(0));
      final Rect trailing = tester.getRect(rulesOf(1).at(1));
      final Rect label = tester.getRect(find.text('Text'));

      expect(leading.right, lessThanOrEqualTo(label.left));
      expect(trailing.left, greaterThanOrEqualTo(label.right));
      // Both halves flex, so a label that is not centred means the two rules
      // were not given the same flex — the failure this section exists to show.
      expect(leading.width, closeTo(trailing.width, 0.5));
      expect(leading.center.dy, closeTo(trailing.center.dy, 0.01));
    });
  });

  group('vertical', () {
    testWidgets('the rule runs down the box instead of across it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-divider--vertical'));

      final Rect rule = tester.getRect(rulesOf(0));
      expect(
        rule.width,
        FluentStroke.thin,
        reason: 'vertical swaps the pinned axis: thickness is now the width',
      );
      expect(
        rule.height,
        greaterThan(rule.width * 10),
        reason:
            'a vertical divider that still lays out horizontally would '
            'measure the other way round',
      );
      // Upstream gives the vertical divider `height: 100%`, so it has to fill
      // the 96-tall frame it is centred in rather than collapse to its content.
      expect(rule.height, closeTo(96, 0.01));
    });

    testWidgets('a vertical label splits the rule top and bottom', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-divider--vertical'));

      expect(rulesOf(1), findsNWidgets(2));
      final Rect above = tester.getRect(rulesOf(1).at(0));
      final Rect below = tester.getRect(rulesOf(1).at(1));
      final Rect label = tester.getRect(find.text('Text'));

      expect(above.bottom, lessThanOrEqualTo(label.top));
      expect(below.top, greaterThanOrEqualTo(label.bottom));
      expect(above.height, closeTo(below.height, 0.5));
    });
  });

  group('appearance', () {
    testWidgets('each appearance paints its own pair of tokens', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-divider--appearance'));

      final FluentColors colors = themeOf(tester).colors;
      // Figma binds the rule and the label together, as one mode of the
      // `Divider appearance` collection — so a section that recoloured only the
      // line, or only the text, would be half an appearance.
      const List<String> labels = <String>[
        '(default)',
        'subtle',
        'brand',
        'strong',
      ];
      final List<Color> lines = <Color>[
        colors.neutralStroke2,
        colors.neutralStroke3,
        colors.brandStroke1,
        colors.neutralStroke1,
      ];
      final List<Color> content = <Color>[
        colors.neutralForeground2,
        colors.neutralForeground3,
        colors.brandForeground1,
        colors.neutralForeground1,
      ];

      for (int i = 0; i < labels.length; i++) {
        expect(
          ruleInk(tester, i),
          lines[i],
          reason: 'row $i took a rule ink that is not its own token',
        );
        expect(
          textStyleOf(tester, find.text(labels[i]))?.color,
          content[i],
          reason: '${labels[i]} took the wrong label ink',
        );
      }
      expect(
        lines.toSet(),
        hasLength(4),
        reason:
            'four appearances that resolve to one colour would make every '
            'assertion above pass on a component that ignores the axis',
      );
    });
  });

  group('inset', () {
    testWidgets('inset pulls the rule off both ends of its container', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-divider--inset'));

      final Rect divider = tester.getRect(dividerAt(0));
      final Rect rule = tester.getRect(rulesOf(0));
      expect(rule.left, closeTo(divider.left + FluentSpacing.m, 0.01));
      expect(rule.right, closeTo(divider.right - FluentSpacing.m, 0.01));

      // The padding follows the divider's own axis: Figma keeps two variables
      // rather than one precisely so an inset vertical rule is shortened at the
      // ends, not squeezed at the sides — a rule 12px narrower than a hairline
      // would not render at all.
      final Rect vertical = tester.getRect(dividerAt(2));
      final Rect verticalRule = tester.getRect(rulesOf(2));
      expect(verticalRule.top, closeTo(vertical.top + FluentSpacing.m, 0.01));
      expect(
        verticalRule.bottom,
        closeTo(vertical.bottom - FluentSpacing.m, 0.01),
      );
      expect(verticalRule.width, FluentStroke.thin);
    });

    testWidgets('the same divider without inset reaches its container edges', (
      WidgetTester tester,
    ) async {
      // The other half of the claim. Measured on the Default section, whose
      // dividers differ from the Inset ones in nothing but the flag.
      await pumpSection(tester, sectionOf('components-divider--default'));
      final Rect divider = tester.getRect(dividerAt(0));
      final Rect rule = tester.getRect(rulesOf(0));
      expect(rule.left, divider.left);
      expect(rule.right, divider.right);
    });
  });

  group('align content', () {
    final DocsSection section = sectionOf('components-divider--align-content');

    testWidgets('the label walks along the horizontal rule', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // Leading edges, not centres: the three labels are different lengths, so
      // a centre comparison would partly measure the text rather than the
      // alignment.
      final double start = tester.getRect(find.text('start').first).left;
      final double centre = tester
          .getRect(find.text('center (default)').first)
          .left;
      final double end = tester.getRect(find.text('end').first).left;

      expect(start, lessThan(centre));
      expect(centre, lessThan(end));
      // `start` pins a short fixed rule ahead of the label; anything else means
      // the leading rule is still flexing and the label is not at the edge.
      expect(start, lessThan(FluentSpacing.s + FluentSpacing.m + 1));
    });

    testWidgets('the label walks along the vertical rule too', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // `.last`: each label text appears twice on this section, once on the
      // horizontal row and once on the vertical one below it.
      final double start = tester.getRect(find.text('start').last).top;
      final double centre = tester
          .getRect(find.text('center (default)').last)
          .top;
      final double end = tester.getRect(find.text('end').last).top;

      expect(start, lessThan(centre));
      expect(centre, lessThan(end));
      // Each vertical example lives in its own 96-tall frame stacked 5px apart,
      // so the three tops would be ~101px apart if alignment did nothing at all.
      expect(
        tester.getRect(find.text('start').last).top,
        greaterThan(tester.getRect(dividerAt(3)).top),
      );
    });
  });

  group('custom styles', () {
    final DocsSection section = sectionOf('components-divider--custom-styles');

    testWidgets('the width and height overrides bound the divider', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        tester.getRect(dividerAt(0)).width,
        200,
        reason: 'the 200px box is the point of the first example',
      );
      expect(
        tester.getRect(find.text('Custom width (200px)')).width,
        closeTo(176, 0.01),
        reason: 'the label carries the width, less the 24px content padding',
      );
      expect(
        tester.getRect(dividerAt(1)).height,
        50,
        reason: 'a vertical divider takes the height its parent bounds it to',
      );
    });

    testWidgets('the style override beats the theme on font, ink and rule', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final FluentThemeData theme = themeOf(tester);
      final TextStyle? font = textStyleOf(
        tester,
        find.text('Custom font (14px bold)'),
      );
      expect(font?.fontSize, 14);
      expect(font?.fontWeight, FontWeight.bold);
      expect(
        font?.fontSize,
        isNot(theme.typography.caption1.fontSize),
        reason: 'a style that matched the default ramp would prove nothing',
      );

      expect(
        ruleInk(tester, 3),
        theme.colors.palette.stroke2Rest(FluentPaletteFamily.red),
        reason: 'lineColor must reach the rule, not just the style object',
      );
      expect(ruleInk(tester, 3), isNot(theme.colors.neutralStroke2));

      expect(
        tester.getRect(rulesOf(4).first).height,
        2,
        reason:
            'lineThickness must reach the rule; the dash pattern is the '
            'documented divergence, the 2px is not',
      );
      expect(tester.getRect(rulesOf(3).first).height, FluentStroke.thin);
    });
  });

  group('pointer', () {
    testWidgets('a real mouse over a divider changes nothing', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, sectionOf('components-divider--appearance'));

      final Color resting = ruleInk(tester, 0);
      // Every divider on this section carries a label, so it has two rules;
      // the leading one is the target.
      final Rect geometry = tester.getRect(rulesOf(0).first);
      // A divider is non-interactive by design: no hover, no press, no focus
      // ring, no transition. `tester.tap` synthesises no hover at all, so a
      // rule that lit up under a pointer would pass every synthetic test on
      // this page and still be wrong in a browser.
      final Color hovered = await whileHovering(
        tester,
        rulesOf(0).first,
        () => ruleInk(tester, 0),
      );
      expect(hovered, resting);
      expect(tester.getRect(rulesOf(0).first), geometry);

      // A press is not an interaction either: a divider takes no onPressed and
      // must not repaint, move or start a transition under a real click.
      await mouseClick(tester, rulesOf(0).first);
      expect(ruleInk(tester, 0), resting);
      expect(tester.getRect(rulesOf(0).first), geometry);
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// The [index]-th divider on the mounted section, in declaration order.
Finder dividerAt(int index) => find.byType(FluentDivider).at(index);

/// The rules the [index]-th divider painted, in reading order.
///
/// `buildFluentDivider` draws each rule as a `ColoredBox` inside a pinned
/// `SizedBox`, and paints nothing at all when no line colour resolved — so
/// counting these is also how "the rule reached the screen" is asserted. The
/// surface behind each example is a `ColoredBox` too, but it is an *ancestor*
/// of the divider rather than a descendant.
Finder rulesOf(int index) =>
    find.descendant(of: dividerAt(index), matching: find.byType(ColoredBox));

/// The colour the [at]-th rule of the [index]-th divider actually painted.
Color ruleInk(WidgetTester tester, int index, {int at = 0}) =>
    tester.widget<ColoredBox>(rulesOf(index).at(at)).color;

/// The theme the mounted section resolved against.
FluentThemeData themeOf(WidgetTester tester) =>
    FluentTheme.of(tester.element(find.byType(FluentDivider).first));

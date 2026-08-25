import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Label is five demos of one non-interactive widget, and every axis it has —
/// size, weight, disabled, required — lands in the *text style* rather than in
/// the widget tree. `FluentLabel` colours its child through an inherited
/// `DefaultTextStyle`, so the `Text` widget's own `style` is null exactly where
/// the interesting answer lives: a label whose size axis reached nothing renders
/// the same tree, the same string and the same `Text.style` as one that worked.
/// Every test below therefore reads the resolved paragraph style, which is the
/// only place the difference exists.
///
/// The demos are all self-sizing, so they are mounted `loose` — the story stage
/// aligns each one, and measuring them against a tight scroll-view width would
/// measure the harness instead of the page.
void main() {
  const String page = 'components-label';

  group('default', () {
    final DocsSection section = sectionOf('components-label--default');

    testWidgets('the default label is body text in the enabled colour', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, loose: true);

      final Finder label = find.text('This is a label');
      expect(label, findsOneWidget);
      expect(
        find.text('*'),
        findsNothing,
        reason: 'nothing asked for a required indicator',
      );

      final FluentThemeData theme = FluentTheme.of(
        tester.element(find.byType(FluentLabel)),
      );
      final TextStyle? painted = textStyleOf(tester, label);
      expect(painted?.fontSize, theme.typography.body1.fontSize);
      expect(painted?.fontWeight, theme.typography.body1.fontWeight);
      // The enabled colour is a token, not the absence of the disabled one —
      // `resolveFluentLabelStyle` selects between two `Neutral/Foreground`
      // entries rather than fading one.
      expect(painted?.color, theme.colors.neutralForeground1);
    });

    testWidgets('a real mouse leaves the label exactly as it was', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, loose: true);
      final Finder label = find.text('This is a label');
      final TextStyle? rest = textStyleOf(tester, label);

      // A label names a field; it is not the field. There is no hover, focus or
      // pressed treatment anywhere in `FluentLabelStyle`, and hover is invisible
      // to `tester.tap`, so only a real device resting on the text can catch one
      // that crept in.
      final TextStyle? hovered = await whileHovering(
        tester,
        label,
        () => textStyleOf(tester, label),
      );
      expect(hovered?.color, rest?.color);

      await mouseClick(tester, label);
      expect(textStyleOf(tester, label)?.color, rest?.color);
      expect(label, findsOneWidget);
    });
  });

  group('size', () {
    testWidgets('the three sizes land on three different ramp steps', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-label--size'),
        loose: true,
      );

      final FluentThemeData theme = FluentTheme.of(
        tester.element(find.byType(FluentLabel).first),
      );
      // Named ramp steps rather than literal point sizes: `FluentLabel` maps its
      // size axis onto caption1, body1 and body2, and the six platform ramps put
      // different numbers behind those names. Comparing against the resolved
      // theme is the assertion that stays true wherever the test runs.
      expect(
        textStyleOf(tester, find.text('Small'))?.fontSize,
        theme.typography.caption1.fontSize,
      );
      expect(
        textStyleOf(tester, find.text('Medium'))?.fontSize,
        theme.typography.body1.fontSize,
      );
      expect(
        textStyleOf(tester, find.text('Large'))?.fontSize,
        theme.typography.body2.fontSize,
      );

      // Three distinct line boxes, not three ascending ones: the native ramps
      // order body1 and body2 the other way round from the web one, so "large is
      // taller" is true of the surface this page deploys on and false of the
      // ramp a VM test resolves. What is platform-independent — and what the
      // section actually claims — is that the axis moved all three.
      final Set<double> boxes = <double>{
        tester.getRect(find.text('Small')).height,
        tester.getRect(find.text('Medium')).height,
        tester.getRect(find.text('Large')).height,
      };
      expect(
        boxes,
        hasLength(3),
        reason: 'two sizes share a line box, so the size axis is lossy',
      );
    });
  });

  group('weight', () {
    testWidgets('semibold is a heavier face, not a bigger one', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-label--weight'),
        loose: true,
      );

      final FluentThemeData theme = FluentTheme.of(
        tester.element(find.byType(FluentLabel)),
      );
      final TextStyle? painted = textStyleOf(tester, find.text('Strong label'));
      expect(painted?.fontWeight, theme.typography.body1Strong.fontWeight);
      // The weight axis has to move the weight and nothing else. Figma binds
      // Label's two Type values against the same Font size variable, so a
      // semibold label that also grew would be reading the wrong ramp row.
      expect(painted?.fontWeight, isNot(theme.typography.body1.fontWeight));
      expect(painted?.fontSize, theme.typography.body1.fontSize);
    });
  });

  group('disabled', () {
    testWidgets('disabled greys the label and its asterisk together', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-label--disabled'),
        loose: true,
      );

      final FluentThemeData theme = FluentTheme.of(
        tester.element(find.byType(FluentLabel)),
      );
      final Color disabled = theme.colors.neutralForegroundDisabled;
      expect(textStyleOf(tester, find.text('Disabled label'))?.color, disabled);
      expect(disabled, isNot(theme.colors.neutralForeground1));

      // This demo is the only place on the page where both axes are on at once,
      // and it is where the documented divergence shows: Figma greys the
      // asterisk along with the label where React leaves it red. A test that
      // asserted the danger token here would be asserting React's behaviour on
      // a component ported from Figma.
      expect(find.text('*'), findsOneWidget);
      expect(
        textStyleOf(tester, find.text('*'))?.color,
        disabled,
        reason: 'the asterisk must follow the label into the disabled state',
      );
    });
  });

  group('required', () {
    testWidgets('both indicators trail their label in the danger tone', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-label--required'),
        loose: true,
      );

      final FluentThemeData theme = FluentTheme.of(
        tester.element(find.byType(FluentLabel).first),
      );
      final Color danger = theme.colors.statusDangerForeground3;

      // The built-in asterisk and the hand-composed `***` are the section's two
      // halves, and the page comment claims they use the same token. They are
      // reached through completely different code — one from
      // `FluentLabelStyle.requiredColor`, one written at the call site — so the
      // claim is only true if it is checked.
      expect(textStyleOf(tester, find.text('*'))?.color, danger);
      expect(textStyleOf(tester, find.text('***'))?.color, danger);

      // And both trail their label rather than leading it: `required` renders
      // *after* the child, which is the half of the API this section documents.
      expect(
        tester.getRect(find.text('*')).left,
        greaterThanOrEqualTo(
          tester.getRect(find.text('Required label').at(0)).right,
        ),
      );
      expect(
        tester.getRect(find.text('***')).left,
        greaterThanOrEqualTo(
          tester.getRect(find.text('Required label').at(1)).right,
        ),
      );
    });

    testWidgets('the indicator is not read out as part of the name', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-label--required'),
        loose: true,
      );

      // "Required label star" is not what a screen reader should say —
      // required-ness belongs to the field, which marks itself. The asterisk is
      // therefore inside an `ExcludeSemantics`, and that is a property of the
      // rendered tree rather than of anything visible, so nothing else on this
      // page can catch its loss.
      expect(
        find.ancestor(
          of: find.text('*'),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
    });
  });

  group('lifecycle', () {
    testWidgets('every section unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section, loose: true);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

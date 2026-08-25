import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// A menu button is not a widget here — it is a `FluentButton` carrying
/// [fluentMenuChevron] hung off a [FluentMenu] — so this page has two things to
/// prove that `render_test.dart` cannot. First, that the composition still opens
/// a menu: every one of these buttons is inert until pressed, and a page of ten
/// dead chevrons mounts perfectly. Second, that the props the sections are named
/// after actually reach the paint: shape, appearance and size are all invisible
/// to a widget-tree walk and all visible on screen.
void main() {
  const String page = 'components-button-menubutton';

  group('default', () {
    final DocsSection section = sectionOf(
      'components-button-menubutton--default',
    );

    testWidgets('the chevron trails the label and the button opens a menu', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final Finder chevron = find.byIcon(FluentIcons.chevron_down_20_regular);
      expect(chevron, findsOneWidget);
      // `iconPosition: after` is the whole difference between a menu button and
      // a button with a leading glyph, and only geometry can see it.
      expect(
        tester.getRect(chevron).left,
        greaterThan(tester.getRect(find.text('Example')).right),
      );

      expect(find.text('Item a'), findsNothing);
      await openOverlay(tester, find.text('Example'));
      expect(find.text('Item a'), findsOneWidget);
      expect(find.text('Item b'), findsOneWidget);

      await tapAndSettle(tester, find.text('Item a'), what: 'Item a');
      expect(
        find.text('Item a'),
        findsNothing,
        reason: 'picking a row must take the surface down',
      );
    });

    testWidgets('the button opens and commits under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.text('Example'));
      await settle(tester, frames: 10);
      expect(find.text('Item b'), findsOneWidget);

      await mouseClick(tester, find.text('Item b'));
      expect(
        find.text('Item b'),
        findsNothing,
        reason: 'a mouse press on a row must invoke it, not merely dismiss',
      );
    });

    testWidgets('the keyboard opens it, and gets the trigger back on Escape', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await settle(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester, frames: 10);
      expect(find.text('Item a'), findsOneWidget);

      // Closing hands focus back to whatever inside the trigger had it. Nothing
      // on screen says whether that happened — the proof is that the next Enter
      // still reaches the button instead of falling on the floor, which is what
      // a keyboard user experiences as the menu being usable twice.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await settle(tester);
      expect(find.text('Item a'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await settle(tester, frames: 10);
      expect(
        find.text('Item a'),
        findsOneWidget,
        reason: 'focus never came back to the trigger',
      );
    });
  });

  group('shape', () {
    testWidgets('each shape rounds its corners differently', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-button-menubutton--shape'),
      );
      expect(find.byType(FluentButton), findsNWidgets(3));

      // Three buttons that differ in exactly one prop, and that prop is a corner
      // radius: identical geometry, identical text, and nothing but the painted
      // decoration to tell them apart.
      final Radius rounded = cornerOf(tester, 'Rounded');
      final Radius circular = cornerOf(tester, 'Circular');
      final Radius square = cornerOf(tester, 'Square');
      expect(square, Radius.zero);
      expect(rounded.x, greaterThan(0));
      expect(circular.x, greaterThan(rounded.x));
    });
  });

  group('appearance', () {
    testWidgets('each appearance paints a different surface', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-button-menubutton--appearance'),
      );
      expect(find.byType(FluentButton), findsNWidgets(5));

      final BoxDecoration secondary = surfaceOf(tester, 'Default');
      final BoxDecoration primary = surfaceOf(tester, 'Primary');
      expect(secondary.color!.a, 1, reason: 'the default fill is opaque');
      expect(primary.color, isNot(secondary.color));
      expect(primary.color!.a, 1, reason: 'the primary fill is opaque');

      // Outline, subtle and transparent all resolve to a see-through fill; what
      // separates outline from the other two is that it keeps the border.
      for (final String label in <String>['Outline', 'Subtle', 'Transparent']) {
        expect(
          surfaceOf(tester, label).color!.a,
          0,
          reason: '$label must let the page through',
        );
      }
      expect(secondary.border, isNotNull);
      expect(surfaceOf(tester, 'Outline').border, isNotNull);
      for (final String label in <String>['Primary', 'Subtle', 'Transparent']) {
        expect(
          surfaceOf(tester, label).border,
          isNull,
          reason: '$label draws no outline',
        );
      }

      // The leading glyph rides inside the label rather than in a slot of its
      // own, so it has no `IconTheme` to tint it — the page reads the button's
      // resolved foreground instead, and a primary button whose icon fell back
      // to the ambient neutral would be invisible on the brand fill.
      final Color? onBrand = labelColourOf(tester, 'Primary');
      expect(onBrand, isNot(labelColourOf(tester, 'Default')));
      expect(
        tester
            .widget<Icon>(
              find
                  .descendant(
                    of: buttonAround('Primary'),
                    matching: find.byIcon(
                      FluentIcons.calendar_month_20_regular,
                    ),
                  )
                  .first,
            )
            .color,
        onBrand,
      );
    });
  });

  group('icon', () {
    testWidgets('the trailing slot is the chevron, or whatever replaces it', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-button-menubutton--icon'),
      );

      // Upstream's `menuIcon` slot is this button's `icon` slot, and the chevron
      // is only its default: the middle button swaps a filter glyph in, and the
      // two either side keep theirs.
      expect(
        find.byIcon(FluentIcons.chevron_down_20_regular),
        findsNWidgets(2),
      );
      final Finder filter = find.byIcon(FluentIcons.filter_20_regular);
      expect(filter, findsOneWidget);
      expect(
        find.descendant(of: find.byType(FluentButton).at(1), matching: filter),
        findsOneWidget,
        reason: 'the filter glyph belongs to the middle button',
      );

      const IconData calendar = FluentIcons.calendar_month_20_regular;
      expect(find.byIcon(calendar), findsNWidgets(3));
      final Rect leading = tester.getRect(
        find
            .descendant(
              of: find.byType(FluentButton).first,
              matching: find.byIcon(calendar),
            )
            .first,
      );
      final Rect label = tester.getRect(find.text('With calendar icon'));
      expect(
        leading.right,
        lessThanOrEqualTo(label.left),
        reason: 'the calendar glyph leads the label',
      );
      expect(
        tester
            .getRect(
              find
                  .descendant(
                    of: find.byType(FluentButton).first,
                    matching: find.byIcon(FluentIcons.chevron_down_20_regular),
                  )
                  .first,
            )
            .left,
        greaterThanOrEqualTo(label.right),
        reason: 'the chevron trails it',
      );
    });

    testWidgets('the icon-only button announces itself', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-button-menubutton--icon'),
      );
      // A button with no text is a dead end for a screen reader, so the third
      // one carries a semantic label and a tooltip instead of a caption.
      expect(
        tester
            .widget<FluentButton>(find.byType(FluentButton).at(2))
            .semanticLabel,
        'With calendar icon and no contents',
      );
      await hoverOver(tester, find.byType(FluentButton).at(2));
      expect(
        find.text('With calendar icon and no contents'),
        findsWidgets,
        reason: 'the tooltip is the only caption this button has',
      );
    });
  });

  group('size', () {
    testWidgets('the three ramps are three heights', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-button-menubutton--size'),
      );
      // Ordering rather than three literals: a labelled button's height is its
      // label's line box plus the ramp's padding, and this harness mounts a bare
      // `FluentApp`, whose default typography is the 16/24 mobile ramp rather
      // than the 14/20 web one the showroom selects. The ordering is the knob;
      // the absolute numbers are pinned below, on the buttons that carry no text.
      final double small = tester.getSize(buttonAround('Size: small')).height;
      final double medium = tester.getSize(buttonAround('Size: medium')).height;
      expect(medium, greaterThan(small));
      expect(
        tester.getSize(buttonAround('Size: large')).height,
        greaterThan(medium),
      );
    });

    for (final ({String id, String label, double height}) ramp
        in <({String id, String label, double height})>[
          (id: 'size-small', label: 'Small', height: 24),
          (id: 'size-medium', label: 'Medium', height: 32),
          (id: 'size-large', label: 'Large', height: 40),
        ]) {
      testWidgets('${ramp.id} sits on the ${ramp.label} ramp', (
        WidgetTester tester,
      ) async {
        await pumpSection(
          tester,
          sectionOf('components-button-menubutton--${ramp.id}'),
        );
        final Finder buttons = find.byType(FluentButton);
        expect(buttons, findsNWidgets(3));

        // The third button is icon-only, so its height is the ramp's and
        // nothing else: the glyph plus the ramp's vertical padding comes to
        // exactly the ramp height at all three sizes. That is the one reading
        // no font can move.
        expect(
          tester.getSize(buttons.at(2)).height,
          ramp.height,
          reason: 'the icon-only button left the ${ramp.label} ramp',
        );
        for (int i = 0; i < 2; i++) {
          expect(
            tester.getSize(buttons.at(i)).height,
            greaterThanOrEqualTo(ramp.height),
            reason: 'button $i fell below the ${ramp.label} floor',
          );
        }
      });
    }
  });

  group('disabled', () {
    final DocsSection section = sectionOf(
      'components-button-menubutton--disabled',
    );

    testWidgets('only the enabled button opens its menu', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      for (final String label in <String>[
        'Disabled state',
        'Disabled focusable state',
      ]) {
        await tapAndSettle(
          tester,
          find.text(label),
          what: label,
          warnIfMissed: false,
        );
        expect(
          find.text('Item a'),
          findsNothing,
          reason: '"$label" opened a menu it has no callback for',
        );
      }

      await openOverlay(tester, find.text('Enabled state'));
      expect(find.text('Item a'), findsOneWidget);
    });

    testWidgets('the disabled pair paints the disabled ramp', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      final BoxDecoration enabled = surfaceOf(tester, 'Enabled state');
      for (final String label in <String>[
        'Disabled state',
        'Disabled focusable state',
      ]) {
        expect(
          surfaceOf(tester, label).color,
          isNot(enabled.color),
          reason: '"$label" is painted as though it worked',
        );
        expect(
          labelColourOf(tester, label),
          isNot(labelColourOf(tester, 'Enabled state')),
        );
      }
    });

    testWidgets('the focusable variant carries the extra Focus', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // A null `onPressed` both disables the button and drops it out of the tab
      // order; the page puts it back with a `Focus` of its own. The two disabled
      // buttons are siblings in one Wrap, so everything above them is shared and
      // the difference in ancestors is exactly that widget.
      expect(
        focusAncestors(tester, 'Disabled focusable state'),
        focusAncestors(tester, 'Disabled state') + 1,
      );
    });
  });

  group('with long text', () {
    testWidgets('the capped label wraps and grows the button', (
      WidgetTester tester,
    ) async {
      await pumpSection(
        tester,
        sectionOf('components-button-menubutton--with-long-text'),
      );
      const String long =
          'Long text wraps after it hits the max width of the component';

      // The label is pinned to 230 so that 230 plus the medium ramp's padding,
      // gap and chevron comes to upstream's 280. A label that refused to wrap
      // would leave the button one line tall and far wider than that.
      expect(tester.getSize(find.text(long)).width, 230);
      expect(
        tester.getSize(buttonAround(long)).height,
        greaterThan(tester.getSize(buttonAround('Short text')).height),
      );
      expect(tester.getSize(buttonAround(long)).width, closeTo(280, 1));
    });
  });

  group('every section', () {
    testWidgets('opens a menu from its first button', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        expect(
          find.text('Item a'),
          findsNothing,
          reason: '${section.id} opened unprompted',
        );

        await openOverlay(tester, find.byType(FluentButton).first);
        expect(
          find.text('Item a'),
          findsOneWidget,
          reason: "${section.id}'s first button raised no menu",
        );
        await dismissOverlay(tester);
        expect(find.text('Item a'), findsNothing);
      }
    });

    testWidgets('unmounts without throwing, menu open', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await openOverlay(tester, find.byType(FluentButton).first);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// The button whose label reads [label].
Finder buttonAround(String label) => find
    .ancestor(of: find.text(label), matching: find.byType(FluentButton))
    .first;

/// The decoration [label]'s button painted: fill, border and corner radius.
BoxDecoration surfaceOf(WidgetTester tester, String label) =>
    decorationUnder(tester, buttonAround(label));

/// The top-left corner radius [label]'s button painted.
Radius cornerOf(WidgetTester tester, String label) =>
    (surfaceOf(tester, label).borderRadius! as BorderRadius).topLeft;

/// The colour [label]'s button resolved for its own text.
Color? labelColourOf(WidgetTester tester, String label) => tester
    .widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    )
    .style
    .color;

/// How many [Focus] widgets sit above the button labelled [label].
int focusAncestors(WidgetTester tester, String label) => find
    .ancestor(of: find.text(label), matching: find.byType(Focus))
    .evaluate()
    .length;

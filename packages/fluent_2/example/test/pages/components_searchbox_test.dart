import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// SearchBox's page has no knob widgets at all: its controls are the box
/// itself, the clear button that only exists while the field has focus, and the
/// typeahead's result list. So this suite drives all three — including the
/// result rows under a real mouse, because a row that highlights on hover and
/// refuses to commit under a pointer is exactly the failure a synthetic tap
/// cannot see.
void main() {
  const String page = 'components-searchbox';

  /// The [at]-th search box in the mounted section.
  Finder boxAt(int at) => find.byType(FluentSearchBox).at(at);

  /// The [which] glyph, wherever it is painted.
  ///
  /// Both of SearchBox's glyphs are painted rather than composed from icon
  /// widgets, and the painter publishes its inputs for exactly this: asserting
  /// "the clear affordance is on screen" without diffing pixels.
  Finder glyph(FluentSearchBoxGlyph which) => find.byWidgetPredicate(
    (Widget widget) =>
        widget is CustomPaint &&
        widget.painter is FluentSearchBoxGlyphPainter &&
        (widget.painter! as FluentSearchBoxGlyphPainter).glyph == which,
    description: '$which glyph',
  );

  /// How far the editor of the [at]-th box starts from that box's leading edge.
  double leadingInset(WidgetTester tester, int at) =>
      tester
          .getRect(
            find
                .descendant(of: boxAt(at), matching: find.byType(EditableText))
                .first,
          )
          .left -
      tester.getRect(boxAt(at)).left;

  group('default', () {
    final DocsSection section = sectionOf('components-searchbox--default');

    testWidgets('the clear button arrives with focus, not before', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        glyph(FluentSearchBoxGlyph.dismiss),
        findsNothing,
        reason: 'an unfocused, empty box must not offer a clear affordance',
      );

      await tester.enterText(find.byType(FluentSearchBox), 'abc');
      await settle(tester);
      expect(editedText(tester, find.byType(FluentSearchBox)), 'abc');
      expect(glyph(FluentSearchBoxGlyph.dismiss), findsOneWidget);
    });

    testWidgets('the clear button empties the field under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await tester.enterText(find.byType(FluentSearchBox), 'abc');
      await settle(tester);

      // The clear button is the page's primary affordance and it is only ever
      // reachable with a pointer — it is deliberately skipped by Tab — so a
      // real press is the only honest way to prove it works. A touch tap does
      // clear the field; a mouse press does not, because a mouse press outside
      // the editor's TapRegion unfocuses it, and the button only exists while
      // the editor has focus.
      await mouseClick(tester, glyph(FluentSearchBoxGlyph.dismiss));
      expect(editedText(tester, find.byType(FluentSearchBox)), isEmpty);
      expect(
        glyph(FluentSearchBoxGlyph.dismiss),
        findsOneWidget,
        reason:
            'clearing returns focus to the field, so the button must survive '
            'its own press rather than vanishing under the cursor',
      );
    });
  });

  group('appearance', () {
    final DocsSection section = sectionOf('components-searchbox--appearance');

    testWidgets('the four boxes carry the four appearances', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        tester
            .widgetList<FluentSearchBox>(find.byType(FluentSearchBox))
            .map((FluentSearchBox b) => b.appearance),
        <FluentSearchBoxAppearance>[
          FluentSearchBoxAppearance.outline,
          FluentSearchBoxAppearance.transparent,
          FluentSearchBoxAppearance.filledLighter,
          FluentSearchBoxAppearance.filledDarker,
        ],
      );
    });

    testWidgets('each box owns its own value', (WidgetTester tester) async {
      await pumpSection(tester, section);

      await tester.enterText(boxAt(3), 'darker only');
      await settle(tester);
      expect(editedText(tester, boxAt(3)), 'darker only');
      for (final int other in <int>[0, 1, 2]) {
        expect(
          editedText(tester, boxAt(other)),
          isEmpty,
          reason: 'box $other must not share a controller with box 3',
        );
      }
      // Focus is per-box too: only the box being edited may show a clear
      // button, or the section reads as four boxes wired to one field.
      expect(glyph(FluentSearchBoxGlyph.dismiss), findsOneWidget);
    });
  });

  group('content before/after', () {
    final DocsSection section = sectionOf(
      'components-searchbox--content-before-after',
    );

    testWidgets('a custom icon replaces the magnifier inside the border', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        paintersOf<FluentSearchBoxGlyphPainter>(tester, boxAt(0)),
        isEmpty,
        reason: 'a supplied icon must replace the default glyph, not join it',
      );
      expect(
        tester
            .getRect(boxAt(0))
            .contains(
              tester.getRect(find.byIcon(FluentIcons.person_20_regular)).center,
            ),
        isTrue,
        reason: 'the contentBefore icon must sit inside the box border',
      );
      // The middle box takes no icon, so it is the one that still paints the
      // default magnifier — the control against which the other two read.
      expect(
        paintersOf<FluentSearchBoxGlyphPainter>(
          tester,
          boxAt(1),
        ).map((FluentSearchBoxGlyphPainter p) => p.glyph),
        <FluentSearchBoxGlyph>[FluentSearchBoxGlyph.search],
      );
    });

    testWidgets('the voice button beside the box is live and reachable', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder mic = find.byType(FluentButton);
      expect(tester.widget<FluentButton>(mic).onPressed, isNotNull);
      // warnIfMissed is the assertion: the box's own tap-to-focus gesture is
      // greedy, and a button that lost the hit test would still look live.
      await tapAndSettle(tester, mic, what: 'the voice button');
      expect(editedText(tester, boxAt(1)), isEmpty);
    });

    testWidgets('an empty icon drops the leading slot', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The third box passes `icon: SizedBox.shrink()`, which the prop table on
      // this very page documents as "pass an empty SizedBox to drop the slot
      // entirely". Dropping it means the text starts where the padding ends —
      // otherwise the field carries a glyph's worth of dead space beside the
      // "Search:" label with nothing drawn in it.
      expect(
        leadingInset(tester, 2),
        lessThan(leadingInset(tester, 1)),
        reason:
            'an empty icon must not reserve the same inset as a painted one',
      );
    });
  });

  group('disabled', () {
    final DocsSection section = sectionOf('components-searchbox--disabled');

    testWidgets('the disabled box shows its value and offers nothing', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder box = find.byType(FluentSearchBox);
      expect(editedText(tester, box), 'disabled value');
      expect(
        tester
            .widget<EditableText>(
              find
                  .descendant(of: box, matching: find.byType(EditableText))
                  .first,
            )
            .readOnly,
        isTrue,
      );

      // A disabled box must not become clearable just because a pointer landed
      // on it: the clear button is gated on focus, and focus is what `enabled:
      // false` is supposed to refuse.
      await mouseClick(tester, box);
      expect(glyph(FluentSearchBoxGlyph.dismiss), findsNothing);
      expect(editedText(tester, box), 'disabled value');
    });

    testWidgets('the magnifier is painted in the disabled tone', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final FluentColors colors = FluentTheme.of(
        tester.element(find.byType(FluentSearchBox)),
      ).colors;
      expect(
        paintersOf<FluentSearchBoxGlyphPainter>(tester).single.color,
        colors.neutralForegroundDisabled,
        reason: 'disabled is a token swap, not only a refused keystroke',
      );
    });
  });

  group('placeholder', () {
    final DocsSection section = sectionOf('components-searchbox--placeholder');

    testWidgets('the placeholder yields to typed text and comes back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(find.text('This is a placeholder'), findsOneWidget);

      await tester.enterText(find.byType(FluentSearchBox), 'a');
      await settle(tester);
      expect(
        find.text('This is a placeholder'),
        findsNothing,
        reason: 'a placeholder left behind the value is unreadable overprint',
      );

      await tester.enterText(find.byType(FluentSearchBox), '');
      await settle(tester);
      expect(find.text('This is a placeholder'), findsOneWidget);
    });
  });

  group('size', () {
    final DocsSection section = sectionOf('components-searchbox--size');

    testWidgets('the three sizes step up in height', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        tester
            .widgetList<FluentSearchBox>(find.byType(FluentSearchBox))
            .map((FluentSearchBox b) => b.size),
        <FluentSearchBoxSize>[
          FluentSearchBoxSize.small,
          FluentSearchBoxSize.medium,
          FluentSearchBoxSize.large,
        ],
      );
      // Fluent pins 24/32/40, so this is an exact ramp rather than an ordering:
      // a size axis that only moved the type would leave three identical boxes.
      expect(tester.getSize(boxAt(0)).height, 24);
      expect(tester.getSize(boxAt(1)).height, 32);
      expect(tester.getSize(boxAt(2)).height, 40);
    });
  });

  group('controlled', () {
    final DocsSection section = sectionOf('components-searchbox--controlled');

    testWidgets('the 21st character is refused and reported', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final Finder box = find.byType(FluentSearchBox);
      expect(editedText(tester, box), 'initial value');
      expect(find.text('Input is limited to 20 characters.'), findsNothing);

      await tester.enterText(box, 'twenty one characters');
      await settle(tester);
      // Two things have to happen, and either one alone is a half-working
      // demo: the value goes back to the last accepted one, AND the field says
      // why it did.
      expect(editedText(tester, box), 'initial value');
      expect(find.text('Input is limited to 20 characters.'), findsOneWidget);
      expect(find.byIcon(FluentIcons.warning_12_filled), findsOneWidget);
      expect(
        tester.widget<FluentField>(find.byType(FluentField)).validationState,
        FluentFieldValidationState.warning,
      );

      await tester.enterText(box, 'short enough');
      await settle(tester);
      expect(editedText(tester, box), 'short enough');
      expect(
        find.text('Input is limited to 20 characters.'),
        findsNothing,
        reason: 'the warning must clear once the value is legal again',
      );
    });
  });

  group('typeahead', () {
    final DocsSection section = sectionOf('components-searchbox--typeahead');

    /// Types [query] and advances past the 300ms debounce and the 500ms fetch.
    ///
    /// Explicit pumps rather than `pumpAndSettle`: the loading state holds a
    /// [FluentSpinner], which never stops animating.
    Future<void> search(WidgetTester tester, String query) async {
      await tester.enterText(find.byType(FluentSearchBox), query);
      await tester.pump();
    }

    testWidgets('the spinner shows while the debounced fetch is in flight', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await search(tester, 'Button');

      expect(
        find.text('Loading results…'),
        findsOneWidget,
        reason: 'the dropdown opens on the first keystroke, not on the result',
      );
      expect(find.byType(FluentSpinner), findsOneWidget);

      // Still loading a frame after the debounce elapsed: the request has only
      // just been issued. A demo that resolved here would not be debouncing.
      await tester.pump(const Duration(milliseconds: 350));
      expect(find.text('Loading results…'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Loading results…'), findsNothing);
      expect(find.text('Button component'), findsOneWidget);
    });

    testWidgets('a result highlights under the mouse and commits on click', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await search(tester, 'Button');
      await tester.pump(const Duration(milliseconds: 950));

      const ValueKey<String> row = ValueKey<String>('2');
      Color? rowColor() => tester
          .widget<ColoredBox>(
            find.descendant(
              of: find.byKey(row),
              matching: find.byType(ColoredBox),
            ),
          )
          .color;

      final Color? resting = rowColor();
      final Color? hovered = await whileHovering(
        tester,
        find.byKey(row),
        rowColor,
      );
      expect(
        hovered,
        isNot(resting),
        reason: 'the row must respond to the pointer it is only reachable by',
      );

      await mouseClick(tester, find.byKey(row));
      expect(
        tester
            .widget<FluentSearchBox>(find.byType(FluentSearchBox))
            .controller!
            .text,
        'Button component',
        reason:
            'a mouse press on a result must commit it, not merely dismiss the '
            'list',
      );
      expect(find.byKey(row), findsNothing);
    });

    testWidgets('a query with no matches says so', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await search(tester, 'zzzz');
      await tester.pump(const Duration(milliseconds: 950));

      expect(find.text('No results found'), findsOneWidget);
      expect(find.text('Loading results…'), findsNothing);
    });

    testWidgets('clearing the box closes the dropdown', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await search(tester, 'Button');
      await tester.pump(const Duration(milliseconds: 950));
      expect(find.text('Button component'), findsOneWidget);

      // A touch tap on purpose: the mouse path into this same button is broken
      // and is reported by "the clear button empties the field under a real
      // mouse" above. Repeating it here would report one defect twice and
      // leave the dropdown's own close path untested.
      await tapAndSettle(tester, glyph(FluentSearchBoxGlyph.dismiss));
      // onClear runs `_close`, which drops the results as well as the flag —
      // a list left standing over an empty box is the bug this catches.
      expect(find.text('Button component'), findsNothing);
      expect(find.text('No results found'), findsNothing);
      expect(
        tester
            .widget<FluentSearchBox>(find.byType(FluentSearchBox))
            .controller!
            .text,
        isEmpty,
      );
      await expectCleanTeardown(tester, section.id);
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

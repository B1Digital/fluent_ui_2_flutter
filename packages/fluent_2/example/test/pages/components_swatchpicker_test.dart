import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Nearly every section on this page is the same contract twice over: pressing
/// a swatch has to move the *selection ring* and repaint the demo's preview
/// tile. Asserting only the first is how a picker that highlights a choice and
/// hands the caller nothing gets shipped; asserting only the second misses a
/// picker that applies the colour but leaves the old swatch ringed. So the
/// tests below check both sides of every press, and the geometry sections check
/// the pixels the prop is supposed to buy rather than the enum that asked for
/// them.
void main() {
  const String page = 'components-swatchpicker';

  group('default', () {
    final DocsSection section = sectionOf('components-swatchpicker--default');

    testWidgets('a click moves the ring and repaints the preview', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(previewTile(tester).color, const Color(0xFF00B053));
      expect(selectedLabels(tester), <String>['green']);

      final BoxBorder? unringed = decorationUnder(tester, swatch('red')).border;
      await mouseClick(tester, swatch('red'));

      expect(previewTile(tester).color, const Color(0xFFFF1921));
      expect(
        selectedLabels(tester),
        <String>['red'],
        reason: 'picking one swatch must un-pick the previous one',
      );
      expect(
        decorationUnder(tester, swatch('red')).border,
        isNot(unringed),
        reason:
            'selection is drawn as the swatch\'s own band, so a selected '
            'swatch that repaints identically is not showing the choice',
      );
    });

    testWidgets('the disabled swatch refuses the click', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // Upstream disables "dark blue" in this story; it is the only swatch on
      // the page that must swallow a press.
      expect(
        tester.widget<FluentSwatch>(swatch('dark blue')).onPressed,
        isNull,
      );

      await mouseClick(tester, swatch('dark blue'));
      expect(previewTile(tester).color, const Color(0xFF00B053));
      expect(selectedLabels(tester), <String>['green']);
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('swatch picker size', () {
    final DocsSection section = sectionOf(
      'components-swatchpicker--swatch-picker-size',
    );

    testWidgets('each picker sizes its swatches to the documented square', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      // The section's own description names all four numbers, so these are the
      // pixels a reader is promised rather than a guess at the ramp.
      const Map<String, double> expected = <String, double>{
        'SwatchPicker large size': 32,
        'SwatchPicker medium size': 28,
        'SwatchPicker small size': 24,
        'SwatchPicker extra small size': 20,
      };
      expected.forEach((String label, double edge) {
        expect(
          tester.getSize(swatchIn(picker(label), 'red')),
          Size.square(edge),
          reason: '$label must lay its swatches out at ${edge}x$edge',
        );
      });
    });

    testWidgets('the four pickers share one selection', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(selectedLabels(tester), isEmpty);

      await mouseClick(
        tester,
        swatchIn(picker('SwatchPicker extra small size'), 'orange'),
      );
      // One `_selectedValue` backs all four rows, so a press in the smallest
      // picker has to ring the same colour in the other three.
      expect(selectedLabels(tester), <String>[
        'orange',
        'orange',
        'orange',
        'orange',
      ]);
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('swatch picker shape', () {
    final DocsSection section = sectionOf(
      'components-swatchpicker--swatch-picker-shape',
    );

    testWidgets('square, rounded and circular are three different corners', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final double square = corner(tester, 'SwatchPicker square shape');
      final double rounded = corner(tester, 'SwatchPicker rounded shape');
      final double circular = corner(tester, 'SwatchPicker circular shape');

      expect(square, 0, reason: 'the default shape has no corner radius');
      expect(rounded, greaterThan(square));
      expect(
        circular,
        greaterThan(rounded),
        reason: 'circular is the full half-edge, so it must outrun rounded',
      );
    });

    testWidgets('every shape still takes a click', (WidgetTester tester) async {
      await pumpSection(tester, section);

      await mouseClick(
        tester,
        swatchIn(picker('SwatchPicker circular shape'), 'purple'),
      );
      expect(selectedLabels(tester), <String>['purple', 'purple', 'purple']);
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('swatch picker layout', () {
    final DocsSection section = sectionOf(
      'components-swatchpicker--swatch-picker-layout',
    );

    testWidgets('row keeps one line and grid wraps onto several', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      expect(
        rowCount(tester, picker('SwatchPicker row layout')),
        1,
        reason: 'the row layout is a single line by definition',
      );
      expect(
        rowCount(tester, picker('SwatchPicker grid layout')),
        greaterThan(1),
        reason:
            'the grid is boxed to three columns, so nine swatches have to wrap',
      );
    });

    testWidgets('a click in the grid repaints the preview', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(previewTile(tester).color, const Color(0xFF00B053));

      await mouseClick(
        tester,
        swatchIn(picker('SwatchPicker grid layout'), 'pink'),
      );
      expect(previewTile(tester).color, const Color(0xFFFF0099));
      expect(selectedLabels(tester), <String>['pink', 'pink']);
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('swatch picker spacing', () {
    final DocsSection section = sectionOf(
      'components-swatchpicker--swatch-picker-spacing',
    );

    testWidgets('small leaves a narrower gap than medium', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      final double medium = gap(tester, 'SwatchPicker medium spacing');
      final double small = gap(tester, 'SwatchPicker small spacing');
      expect(medium, 4, reason: 'medium spacing is the 4px token');
      expect(small, 2, reason: 'small spacing is the 2px token');
    });

    testWidgets('both pickers still take a click', (WidgetTester tester) async {
      await pumpSection(tester, section);

      await mouseClick(
        tester,
        swatchIn(picker('SwatchPicker small spacing'), 'green'),
      );
      expect(selectedLabels(tester), <String>['green', 'green']);
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('swatch picker image', () {
    final DocsSection section = sectionOf(
      'components-swatchpicker--swatch-picker-image',
    );

    testWidgets('a click swaps the full-size image', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(fullImageAsset(tester), 'assets/storybook/bridge-full-img.jpg');
      expect(selectedLabels(tester), <String>['bridge']);

      await mouseClick(tester, swatch('park'));
      expect(
        fullImageAsset(tester),
        'assets/storybook/park-full-img.jpg',
        reason: 'the preview under the picker is what the swatch chooses',
      );
      expect(selectedLabels(tester), <String>['park']);

      await mouseClick(tester, swatch('sea'));
      expect(fullImageAsset(tester), 'assets/storybook/sea-full-img.jpg');
    });

    testWidgets('the style override wins over the picker ramp', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // The picker installs `medium` (28) on its children through a theme; the
      // demo overrides it per swatch with a `style`, which is the higher rung.
      expect(tester.getSize(swatch('sea')), const Size.square(100));
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('empty swatch example', () {
    final DocsSection section = sectionOf(
      'components-swatchpicker--empty-swatch-example',
    );

    testWidgets('Add new color fills the empty slots one at a time', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(kindCount(tester, FluentSwatchKind.color), 4);
      expect(kindCount(tester, FluentSwatchKind.empty), 4);

      await mouseClick(tester, find.text('Add new color'));
      expect(kindCount(tester, FluentSwatchKind.color), 5);
      expect(
        kindCount(tester, FluentSwatchKind.empty),
        3,
        reason: 'the picker holds eight slots, so a new colour costs an empty',
      );

      for (int i = 0; i < 3; i++) {
        await tapAndSettle(tester, find.text('Add new color'));
      }
      expect(kindCount(tester, FluentSwatchKind.color), 8);
      expect(kindCount(tester, FluentSwatchKind.empty), 0);
      expect(
        tester.widget<FluentButton>(button('Add new color')).onPressed,
        isNull,
        reason: 'the limit is eight, so the button must disable itself at it',
      );
    });

    testWidgets('Reset example puts the four empty slots back', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await mouseClick(tester, find.text('Add new color'));
      expect(kindCount(tester, FluentSwatchKind.empty), 3);

      await mouseClick(tester, find.text('Reset example'));
      expect(kindCount(tester, FluentSwatchKind.color), 4);
      expect(kindCount(tester, FluentSwatchKind.empty), 4);
      expect(
        tester.widget<FluentButton>(button('Add new color')).onPressed,
        isNotNull,
        reason: 'resetting has to re-enable the button it disabled',
      );
    });

    testWidgets('the empty slots draw no prohibited glyph', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // The demo passes `disabledIcon: SizedBox.shrink()` precisely so the
      // empty slots read as slots rather than as refusals.
      expect(find.byIcon(FluentIcons.prohibited_20_regular), findsNothing);
    });

    testWidgets('a colour swatch still repaints the preview', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(previewTile(tester).color, const Color(0xFF00B053));

      await mouseClick(tester, swatch('dark orange'));
      expect(previewTile(tester).color, const Color(0xFFFF7A00));
      expect(selectedLabels(tester), <String>['dark orange']);
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('color swatch variants', () {
    final DocsSection section = sectionOf(
      'components-swatchpicker--color-swatch-variants',
    );

    testWidgets('the four enabled variants each take the selection', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(selectedLabels(tester), isEmpty);

      for (final String label in <String>[
        'Hot pink',
        'Gradient yellow pink',
        'heart icon',
        'initials',
      ]) {
        await mouseClick(tester, swatch(label));
        expect(
          selectedLabels(tester),
          <String>[label],
          reason: '$label did not become the one selected swatch',
        );
      }
    });

    testWidgets('the two disabled variants stay unselectable', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      await mouseClick(tester, swatch('Hot pink'));

      for (final String label in <String>['blue', 'light blue']) {
        expect(tester.widget<FluentSwatch>(swatch(label)).onPressed, isNull);
        await mouseClick(tester, swatch(label));
        expect(
          selectedLabels(tester),
          <String>['Hot pink'],
          reason: 'the disabled $label swatch stole the selection',
        );
      }
    });

    testWidgets('the icon and initials slots render their content', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(
        find.descendant(
          of: swatch('heart icon'),
          matching: find.byIcon(FluentIcons.heart_20_filled),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: swatch('initials'), matching: find.text('A')),
        findsOneWidget,
      );
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('swatch picker mixed swatches', () {
    final DocsSection section = sectionOf(
      'components-swatchpicker--swatch-picker-mixed-swatches',
    );

    testWidgets('an image choice clears the colour and back again', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(previewTile(tester).color, const Color(0xFF00B053));
      expect(previewTile(tester).image, isNull);

      await mouseClick(tester, swatch('park'));
      expect(
        previewTile(tester).color,
        isNull,
        reason: 'an image choice has to drop the colour it replaces',
      );
      expect(
        (previewTile(tester).image!.image as AssetImage).assetName,
        'assets/storybook/park-swatch.jpg',
      );

      await mouseClick(tester, swatch('light blue'));
      expect(previewTile(tester).color, const Color(0xFF00AFED));
      expect(
        previewTile(tester).image,
        isNull,
        reason: 'a colour choice has to drop the image it replaces',
      );
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('swatch picker with tooltip', () {
    final DocsSection section = sectionOf(
      'components-swatchpicker--swatch-picker-with-tooltip',
    );

    testWidgets('resting a mouse on a swatch names it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      // The label is nowhere in the tree until the tip opens: a swatch carries
      // its colour name only as a semantic label, so this is the one section
      // whose whole point is unreachable through `tester.tap`.
      expect(find.text('light green'), findsNothing);

      final TestGesture mouse = await mouseHover(tester, swatch('light green'));
      expect(
        find.text('light green'),
        findsOneWidget,
        reason: 'each swatch is supposed to have a descriptive tooltip',
      );

      await mouseAway(tester, mouse);
      expect(
        find.text('light green'),
        findsNothing,
        reason: 'the tip must go away with the pointer',
      );
    });

    testWidgets('a tooltipped swatch still commits its colour', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(previewTile(tester).color, const Color(0xFF00B053));

      // The tooltip wraps the swatch, so its own MouseRegion sits between the
      // pointer and the control: a press that the wrapper swallowed would open
      // a tip and change nothing.
      await mouseClick(tester, swatch('purple'));
      expect(previewTile(tester).color, const Color(0xFF712F9E));
      expect(selectedLabels(tester), <String>['purple', 'purple']);
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('swatch picker focus mode', () {
    final DocsSection section = sectionOf(
      'components-swatchpicker--swatch-picker-focus-mode',
    );

    testWidgets('both pickers report into the same selection', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(selectedLabels(tester), <String>['green', 'green']);

      await mouseClick(
        tester,
        swatchIn(picker('SwatchPicker with tab navigation'), 'blue'),
      );
      expect(selectedLabels(tester), <String>['blue', 'blue']);
    });

    testWidgets('every swatch is a tab stop', (WidgetTester tester) async {
      await pumpSection(tester, section);
      // Both pickers are labelled after a focus mode this port does not
      // implement, because Flutter's traversal already walks the row. That
      // claim is only true if each swatch actually publishes a focus node.
      expect(
        find.descendant(
          of: picker('SwatchPicker with arrow navigation'),
          matching: find.byType(FocusableActionDetector),
        ),
        findsNWidgets(6),
      );
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('swatch picker popup', () {
    final DocsSection section = sectionOf(
      'components-swatchpicker--swatch-picker-popup',
    );

    testWidgets('the trigger opens the popover', (WidgetTester tester) async {
      await pumpSection(tester, section);
      expect(find.text('Color set 1'), findsNothing);

      await mouseClick(tester, find.text('Choose color'));
      expect(
        find.text('Color set 1'),
        findsOneWidget,
        reason: 'the button says what it does; it has to do it',
      );
      expect(find.text('Color set 2'), findsOneWidget);
    });

    testWidgets('picking inside the popover commits and closes it', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);
      expect(previewTile(tester).color, const Color(0xFF00B053));

      await mouseClick(tester, find.text('Choose color'));
      // Under a real pointer rather than a synthetic tap on purpose: an overlay
      // that dismisses on any press outside its content will close on the way
      // to the swatch and leave the choice uncommitted, and only a press that
      // travels the way a hand does can tell the two apart.
      await mouseClick(tester, swatch('purple'));

      expect(
        previewTile(tester).color,
        const Color(0xFF712F9E),
        reason: 'the swatch that was pressed must reach the preview tile',
      );
      expect(
        find.text('Color set 1'),
        findsNothing,
        reason: 'choosing a colour closes the popup it was chosen in',
      );
    });

    testWidgets('a pick rings exactly one swatch', (WidgetTester tester) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.text('Choose color'));
      await mouseClick(tester, swatch('gradient blue-purple'));

      // Reopened, because the popup closes on a pick and the ring only exists
      // inside it. Selection is single by construction — one `_selected` — so
      // whatever a reader sees ringed is what they are about to get, and two
      // rings for one press means the swatch they did not choose is claiming
      // their choice.
      await mouseClick(tester, find.text('Choose color'));
      expect(
        selectedLabels(tester),
        <String>['gradient blue-purple'],
        reason: 'one press must leave exactly one swatch ringed',
      );
    });

    testWidgets('a gradient choice paints the preview as a gradient', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section);

      await mouseClick(tester, find.text('Choose color'));
      await mouseClick(tester, swatch('gradient rainbow'));

      final BoxDecoration tile = previewTile(tester);
      expect(
        tile.gradient,
        isA<LinearGradient>().having(
          (LinearGradient gradient) => gradient.colors.length,
          'stops',
          9,
        ),
        reason: 'a multi-colour choice carries its whole ramp to the preview',
      );
      expect(tile.color, isNull);
    });

    testWidgets('unmounts cleanly', (WidgetTester tester) async {
      await pumpSection(tester, section);
      await expectCleanTeardown(tester, section.id);
    });
  });

  group('lifecycle', () {
    testWidgets('every section mounts and unmounts without throwing', (
      WidgetTester tester,
    ) async {
      for (final DocsSection section in sectionsOf(page)) {
        await pumpSection(tester, section);
        await expectCleanTeardown(tester, section.id);
      }
    });
  });
}

/// The swatch announced as [label].
///
/// A swatch has no text of its own — its colour name lives only in
/// `semanticLabel` — so this is the only stable way to name one.
Finder swatch(String label) => find.byWidgetPredicate(
  (Widget widget) => widget is FluentSwatch && widget.semanticLabel == label,
);

/// The picker announced as [label].
Finder picker(String label) => find.byWidgetPredicate(
  (Widget widget) =>
      widget is FluentSwatchPicker && widget.semanticLabel == label,
);

/// The swatch announced as [label] inside [group].
///
/// Several sections repeat one palette across two or four pickers, so
/// [swatch] alone matches more than one.
Finder swatchIn(Finder group, String label) =>
    find.descendant(of: group, matching: swatch(label));

/// The labels of every swatch currently drawn selected, in tree order.
///
/// The list rather than a bool: a picker that lights the new choice without
/// clearing the old one is a real defect, and only the whole set shows it.
List<String> selectedLabels(WidgetTester tester) => tester
    .widgetList<FluentSwatch>(find.byType(FluentSwatch))
    .where((FluentSwatch item) => item.selected)
    .map((FluentSwatch item) => item.semanticLabel)
    .toList();

/// How many swatches of [kind] are on screen.
int kindCount(WidgetTester tester, FluentSwatchKind kind) => tester
    .widgetList<FluentSwatch>(find.byType(FluentSwatch))
    .where((FluentSwatch item) => item.kind == kind)
    .length;

/// The corner radius the picker labelled [label] draws its swatches with.
double corner(WidgetTester tester, String label) => decorationUnder(
  tester,
  swatchIn(picker(label), 'red'),
).borderRadius!.resolve(TextDirection.ltr).topLeft.x;

/// The horizontal gap between the first two swatches of the picker [label].
double gap(WidgetTester tester, String label) {
  final Finder swatches = find.descendant(
    of: picker(label),
    matching: find.byType(FluentSwatch),
  );
  return tester.getRect(swatches.at(1)).left -
      tester.getRect(swatches.at(0)).right;
}

/// How many distinct lines the swatches of [group] were laid out on.
///
/// Row and grid are the same nine widgets in the same order, so the layout prop
/// only shows up in where they landed.
int rowCount(WidgetTester tester, Finder group) {
  final Finder swatches = find.descendant(
    of: group,
    matching: find.byType(FluentSwatch),
  );
  final int count = swatches.evaluate().length;
  return <double>{
    for (int i = 0; i < count; i++) tester.getTopLeft(swatches.at(i)).dy,
  }.length;
}

/// The 100x100 tile most of these sections paint the current choice onto.
BoxDecoration previewTile(WidgetTester tester) =>
    tester
            .widget<Container>(
              find.byWidgetPredicate(
                (Widget widget) =>
                    widget is Container &&
                    widget.constraints ==
                        const BoxConstraints.tightFor(width: 100, height: 100),
              ),
            )
            .decoration!
        as BoxDecoration;

/// The asset behind the Image section's full-size preview.
String fullImageAsset(WidgetTester tester) {
  final BoxDecoration decoration =
      tester
              .widget<Container>(
                find.byWidgetPredicate(
                  (Widget widget) =>
                      widget is Container &&
                      widget.constraints?.maxHeight == 466,
                ),
              )
              .decoration!
          as BoxDecoration;
  return (decoration.image!.image as AssetImage).assetName;
}

/// The button whose child reads [label].
Finder button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(FluentButton));

import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/widgets/toolbar_parts.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/mouse.dart';

/// The pieces both toolbars are built from, against the numbers read off
/// Storybook 9.1.17's `.sb-bar` (`Toolbar.tsx:235-271`, `Button.tsx:82-250`,
/// `bar/separator.tsx:9-16`) with a real mouse in real Chrome.
///
/// Every press here goes through [mouseClick] and every hover through
/// [mouseHover]: the bar lives at the top of the window, where a synthesised
/// still touch has hidden dead controls before.
void main() {
  group(
    'ToolbarButton colours, priority pressed > hovered > active > rest',
    () {
      testWidgets('rest: #73828C on transparent', (WidgetTester tester) async {
        await _pump(tester, _grid());
        expect(_ink(tester), ToolbarColors.rest);
        expect(_fill(tester), const Color(0x00000000));
      });

      testWidgets('hover: #029CFD on rgba(2,156,253,.14)', (
        WidgetTester tester,
      ) async {
        await _pump(tester, _grid());
        final TestGesture mouse = await mouseHover(
          tester,
          find.byType(FluentButton),
        );
        await tester.pumpAndSettle();
        expect(_ink(tester), ToolbarColors.hover);
        expect(_fill(tester), ToolbarColors.hoverFill);
        await mouse.removePointer();
      });

      testWidgets('pressed beats hovered: #0078D4 on rgba(0,120,212,.10)', (
        WidgetTester tester,
      ) async {
        await _pump(tester, _grid());
        final TestGesture mouse = await tester.startGesture(
          tester.getCenter(find.byType(FluentButton)),
          kind: PointerDeviceKind.mouse,
        );
        await tester.pumpAndSettle();
        expect(_ink(tester), ToolbarColors.active);
        expect(_fill(tester), ToolbarColors.pressedFill);
        await mouse.up();
        await tester.pumpAndSettle();
        // Released but still under the pointer: back to hover, not to rest.
        expect(_ink(tester), ToolbarColors.hover);
        await mouse.removePointer();
      });

      testWidgets('active: #0078D4 on rgba(115,130,140,.10)', (
        WidgetTester tester,
      ) async {
        await _pump(tester, _grid(active: true));
        expect(_ink(tester), ToolbarColors.active);
        expect(_fill(tester), ToolbarColors.activeFill);
      });

      testWidgets('active + hover shows the hover colours', (
        WidgetTester tester,
      ) async {
        await _pump(tester, _grid(active: true));
        final TestGesture mouse = await mouseHover(
          tester,
          find.byType(FluentButton),
        );
        await tester.pumpAndSettle();
        expect(_ink(tester), ToolbarColors.hover);
        expect(_fill(tester), ToolbarColors.hoverFill);
        await mouse.removePointer();
      });

      testWidgets('the label takes the same state colour as the icon', (
        WidgetTester tester,
      ) async {
        await _pump(tester, _theme(active: true));
        expect(
          _paragraph(tester, 'Theme: Teams Dark').text.style!.color,
          ToolbarColors.active,
        );
      });
    },
  );

  group('ToolbarButton geometry', () {
    testWidgets('icon-only is 28x28 around a 14px glyph, radius 4', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _grid());
      expect(tester.getSize(find.byType(FluentButton)), const Size(28, 28));
      expect(tester.getSize(find.byType(Icon)), const Size(14, 14));
      final BoxDecoration box = _box(tester);
      expect(box.borderRadius, const BorderRadius.all(Radius.circular(4)));
      expect(box.border, isNull);
    });

    testWidgets('icon + label: 28 tall, padding 0 7, gap 6, 12px/700 label', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _theme());
      final Rect button = tester.getRect(find.byType(FluentButton));
      final Rect icon = tester.getRect(find.byType(Icon));
      final Rect label = tester.getRect(find.text('Theme: Teams Dark'));
      expect(button.height, 28);
      expect(icon.left - button.left, 7);
      expect(label.left - icon.right, 6);
      expect(button.right - label.right, 7);

      final TextStyle style = _paragraph(
        tester,
        'Theme: Teams Dark',
      ).text.style!;
      expect(style.fontSize, 12);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.height, 1);
      expect(style.fontFamily, 'Selawik');
      expect(style.color, ToolbarColors.rest);
    });

    testWidgets('label-only is 28 tall', (WidgetTester tester) async {
      await _pump(
        tester,
        ToolbarButton(
          tooltip: 'Change Direction',
          label: const Text('Direction: LTR'),
          onPressed: () {},
        ),
      );
      expect(tester.getSize(find.byType(FluentButton)).height, 28);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('the tooltip is the text, and names an icon-only button', (
      WidgetTester tester,
    ) async {
      await _pump(tester, _grid());
      final FluentTooltip tooltip = tester.widget(find.byType(FluentTooltip));
      expect((tooltip.content as Text).data, 'Apply a grid to the preview');
      expect(
        tester.widget<FluentButton>(find.byType(FluentButton)).semanticLabel,
        'Apply a grid to the preview',
      );
    });

    testWidgets('semanticLabel overrides the tooltip as the name', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        ToolbarButton(
          tooltip: 'Go full screen [⌥ F]',
          semanticLabel: 'Go full screen',
          icon: FluentIcons.arrow_maximize_20_regular,
          onPressed: () {},
        ),
      );
      expect(
        tester.widget<FluentButton>(find.byType(FluentButton)).semanticLabel,
        'Go full screen',
      );
    });

    testWidgets('a mouse click fires onPressed', (WidgetTester tester) async {
      int presses = 0;
      await _pump(
        tester,
        ToolbarButton(
          tooltip: 'Apply a grid to the preview',
          icon: FluentIcons.grid_20_regular,
          onPressed: () => presses++,
        ),
      );
      await mouseClick(tester, find.byType(FluentButton));
      expect(presses, 1);
    });
  });

  group('ToolbarMenuButton', () {
    testWidgets('opens below the bar on a mouse click, and an item fires', (
      WidgetTester tester,
    ) async {
      String? picked;
      await _pump(
        tester,
        ToolbarFrame(
          start: <Widget>[
            ToolbarMenuButton(
              tooltip: 'Change the background of the preview',
              icon: FluentIcons.image_20_regular,
              items: <FluentMenuItem>[
                FluentMenuItem(
                  label: toolbarItemLabel('light'),
                  onPressed: () => picked = 'light',
                ),
                FluentMenuItem(
                  label: toolbarItemLabel('dark', chosen: true),
                  onPressed: () => picked = 'dark',
                ),
              ],
            ),
          ],
        ),
      );
      expect(find.text('light'), findsNothing);

      await mouseClick(tester, find.byType(FluentButton));
      expect(find.text('light'), findsOneWidget);
      expect(
        tester.getRect(find.text('light')).top,
        greaterThanOrEqualTo(ToolbarFrame.height),
      );
      // The chosen row's explicit style beats the row's DefaultTextStyle.merge.
      final TextStyle chosen = _paragraph(tester, 'dark').text.style!;
      expect(chosen.color, ToolbarColors.active);
      expect(chosen.fontWeight, FontWeight.w700);
      expect(
        _paragraph(tester, 'light').text.style!.color,
        isNot(ToolbarColors.active),
      );

      await mouseClick(tester, find.text('light'));
      expect(picked, 'light');
      expect(find.text('light'), findsNothing);
    });
  });

  group('toolbarItemLabel', () {
    test('chosen is #0078D4 bold; otherwise unstyled', () {
      final Text chosen = toolbarItemLabel('dark', chosen: true) as Text;
      expect(chosen.data, 'dark');
      expect(chosen.style!.color, ToolbarColors.active);
      expect(chosen.style!.fontWeight, FontWeight.w700);
      expect((toolbarItemLabel('light') as Text).style, isNull);
    });
  });

  group('ToolbarFrame and ToolbarSeparator', () {
    testWidgets('40px, white, #E0E0E0 hairline inside, 10px inset, 6px gaps', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        ToolbarFrame(
          start: <Widget>[
            _grid(key: const Key('a')),
            _grid(key: const Key('b')),
          ],
          end: <Widget>[_grid(key: const Key('z'))],
        ),
      );
      expect(tester.getSize(find.byType(ToolbarFrame)), const Size(800, 40));
      final DecoratedBox bar = tester.widget(
        find
            .descendant(
              of: find.byType(ToolbarFrame),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        bar.decoration,
        const BoxDecoration(
          color: Color(0xFFFFFFFF),
          border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
        ),
      );
      // A BoxDecoration border paints inside its box and shifts no child —
      // the analogue of upstream's `box-shadow: #e0e0e0 0 -1px 0 0 inset`.
      expect(tester.getSize(find.byWidget(bar)).height, 40);

      final Rect a = tester.getRect(find.byKey(const Key('a')));
      final Rect b = tester.getRect(find.byKey(const Key('b')));
      final Rect z = tester.getRect(find.byKey(const Key('z')));
      expect(a.left, 10);
      expect(b.left - a.right, 6);
      expect(z.right, 790);
      expect(a.top, 6, reason: '28px tools centred in 40');
    });

    testWidgets('separator: 1x20 #E0E0E0, 2px margin, vertically centred', (
      WidgetTester tester,
    ) async {
      await _pump(
        tester,
        ToolbarFrame(
          start: <Widget>[
            _grid(key: const Key('a')),
            const ToolbarSeparator(),
            _grid(key: const Key('b')),
          ],
        ),
      );
      final Rect a = tester.getRect(find.byKey(const Key('a')));
      final Rect separator = tester.getRect(find.byType(ToolbarSeparator));
      final Finder line = find.descendant(
        of: find.byType(ToolbarSeparator),
        matching: find.byType(ColoredBox),
      );
      final Rect rule = tester.getRect(line);
      expect(tester.widget<ColoredBox>(line).color, ToolbarColors.rule);
      expect(rule.size, const Size(1, 20));
      expect(separator.size, const Size(5, 20));
      expect(rule.left - separator.left, 2);
      expect(separator.left - a.right, 6);
      expect(rule.center.dy, 20);
    });
  });
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    FluentApp(
      debugShowCheckedModeBanner: false,
      home: Align(alignment: Alignment.topLeft, child: child),
    ),
  );
  await tester.pumpAndSettle();
}

ToolbarButton _grid({Key? key, bool active = false}) => ToolbarButton(
  key: key,
  tooltip: 'Apply a grid to the preview',
  icon: FluentIcons.grid_20_regular,
  active: active,
  onPressed: () {},
);

ToolbarButton _theme({bool active = false}) => ToolbarButton(
  tooltip: 'Change Fluent theme',
  icon: FluentIcons.arrow_down_20_regular,
  label: const Text('Theme: Teams Dark'),
  active: active,
  onPressed: () {},
);

/// The resolved glyph colour: [Icon] renders a [RichText] whose style carries
/// the `IconTheme` colour FluentButton pushed down (`button.dart:332-335`).
Color? _ink(WidgetTester tester) => tester
    .renderObject<RenderParagraph>(
      find.descendant(of: find.byType(Icon), matching: find.byType(RichText)),
    )
    .text
    .style!
    .color;

/// The button surface — the one [DecoratedBox] `buildFluentButton` paints.
BoxDecoration _box(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(FluentButton),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

Color? _fill(WidgetTester tester) => _box(tester).color;

RenderParagraph _paragraph(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text));

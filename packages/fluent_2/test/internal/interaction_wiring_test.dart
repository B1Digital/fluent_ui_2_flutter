import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Which [FluentInteractive] flags each component passes, measured against
/// upstream's styles files: the disabled cursor and whether pressed is
/// `:hover:active`.
void main() {
  const key = Key('control');
  final light = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(WidgetTester tester, Widget child, {double width = 300}) =>
      tester.pumpWidget(
        FluentApp(
          theme: light,
          home: Center(
            child: SizedBox(
              width: width,
              child: Align(
                alignment: Alignment.centerLeft,
                child: KeyedSubtree(key: key, child: child),
              ),
            ),
          ),
        ),
      );

  group('the disabled cursor', () {
    // Upstream's `cursor: 'not-allowed'` (useButtonStyles, useLinkStyles,
    // useTabStyles, useTagStyles, useInteractionTag*Styles,
    // useColorSwatchStyles, useAccordionHeaderStyles) or `cursor: 'default'`
    // (useCheckboxStyles, useRadioStyles, useSwitchStyles, useSliderStyles,
    // useListItemStyles).
    final cases = <String, (Widget, MouseCursor)>{
      'compound button': (
        const FluentCompoundButton(child: Text('C')),
        SystemMouseCursors.forbidden,
      ),
      'split button': (
        const FluentSplitButton(menuSemanticLabel: 'More', child: Text('S')),
        SystemMouseCursors.forbidden,
      ),
      'link': (
        const FluentLink(child: Text('Link')),
        SystemMouseCursors.forbidden,
      ),
      'swatch': (
        const FluentSwatch(color: Color(0xFFFF0000), semanticLabel: 'Red'),
        SystemMouseCursors.forbidden,
      ),
      'interaction tag': (
        const FluentInteractionTag(child: Text('Tag')),
        SystemMouseCursors.forbidden,
      ),
      'tag dismiss': (
        FluentTag(enabled: false, onDismiss: () {}, child: const Text('Tag')),
        SystemMouseCursors.forbidden,
      ),
      'tab': (
        FluentTabList<int>(
          selectedValue: 0,
          onSelect: (_) {},
          tabs: const <FluentTab<int>>[
            FluentTab(value: 1, enabled: false, child: Text('Off')),
          ],
        ),
        SystemMouseCursors.forbidden,
      ),
      'accordion header': (
        const FluentAccordion(
          children: <FluentAccordionItem>[
            FluentAccordionItem(
              value: 1,
              enabled: false,
              header: Text('Header'),
              child: Text('Panel'),
            ),
          ],
        ),
        SystemMouseCursors.forbidden,
      ),
      'breadcrumb': (
        const FluentBreadcrumb(
          items: <FluentBreadcrumbItem>[
            FluentBreadcrumbItem(label: Text('Off'), enabled: false),
            FluentBreadcrumbItem(label: Text('Here')),
          ],
        ),
        SystemMouseCursors.forbidden,
      ),
      'checkbox': (
        const FluentCheckbox(label: Text('Check')),
        SystemMouseCursors.basic,
      ),
      'radio': (
        const FluentRadio<int>(value: 1, disabled: true, label: Text('Radio')),
        SystemMouseCursors.basic,
      ),
      'switch': (
        const FluentSwitch(label: Text('Switch')),
        SystemMouseCursors.basic,
      ),
      'slider': (const FluentSlider(value: 0.5), SystemMouseCursors.basic),
      'list item': (
        FluentList<int>(
          selection: FluentListSelection.checkbox,
          onSelectionChange: (_) {},
          items: const <FluentListItem<int>>[
            FluentListItem(value: 1, enabled: false, child: Text('Row')),
          ],
        ),
        SystemMouseCursors.basic,
      ),
    };

    for (final MapEntry(key: name, value: (widget, expected))
        in cases.entries) {
      testWidgets('$name: $expected', (tester) async {
        await pump(tester, widget);
        final mouse = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          pointer: 1,
        );
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        final target = find
            .descendant(
              of: find.byKey(key),
              matching: find.byType(FluentInteractive),
            )
            .first;
        await mouse.moveTo(tester.getCenter(target));
        await tester.pump();
        await mouse.moveBy(const Offset(1, 0));
        await tester.pump();
        expect(
          RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
          expected,
        );
      });
    }
  });

  group('pressed under :hover:active', () {
    // useButtonStyles, useCompoundButtonStyles, useSplitButtonStyles,
    // useSwitchStyles, useRadioStyles, useColorSwatchStyles,
    // useInfoButtonStyles and useCalendarDayStyles all write pressed under
    // `:hover:active`; tags, tabs, checkboxes and links under `:active`.
    final cases = <String, (Widget, bool)>{
      'compound button': (
        FluentCompoundButton(onPressed: () {}, child: const Text('C')),
        true,
      ),
      'split button': (
        FluentSplitButton(
          menuSemanticLabel: 'More',
          onPressed: () {},
          onMenuPressed: () {},
          child: const Text('S'),
        ),
        true,
      ),
      'switch': (FluentSwitch(onChanged: (_) {}), true),
      'radio': (
        FluentRadio<int>(value: 1, onChanged: (_) {}, label: const Text('R')),
        true,
      ),
      'swatch': (
        FluentSwatch(
          color: const Color(0xFFFF0000),
          semanticLabel: 'Red',
          onPressed: () {},
        ),
        true,
      ),
      'info button': (
        const FluentInfoButton(info: Text('Info'), semanticLabel: 'Info'),
        true,
      ),
      'checkbox': (FluentCheckbox(onChanged: (_) {}), false),
      'link': (FluentLink(onPressed: () {}, child: const Text('L')), false),
      'interaction tag': (
        FluentInteractionTag(onPressed: () {}, child: const Text('T')),
        false,
      ),
    };

    for (final MapEntry(key: name, value: (widget, expected))
        in cases.entries) {
      testWidgets('$name: $expected', (tester) async {
        await pump(tester, widget);
        final flags = tester
            .widgetList<FluentInteractive>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(FluentInteractive),
              ),
            )
            .map((w) => w.pressedRequiresHover);
        expect(flags, everyElement(expected));
      });
    }

    testWidgets('calendar: nav, caption and month cells, not day cells', (
      tester,
    ) async {
      await pump(
        tester,
        FluentCalendar(
          today: DateTime(2024, 5, 15),
          value: DateTime(2024, 5, 15),
          onSelectDate: (_) {},
        ),
        width: 700,
      );
      final interactive = tester.widgetList<FluentInteractive>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FluentInteractive),
        ),
      );
      final hovered = interactive.where((w) => w.pressedRequiresHover).length;
      expect(hovered, greaterThan(0), reason: 'nav, caption, year cells');
      expect(
        interactive.where((w) => !w.pressedRequiresHover).length,
        greaterThanOrEqualTo(28),
        reason: 'the day cells keep a plain :active',
      );
    });
  });
}

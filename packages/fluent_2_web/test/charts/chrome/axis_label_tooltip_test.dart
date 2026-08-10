// The deep import this file used to carry became redundant the moment the
// barrel started exporting `src/charts/chrome/axis_label_tooltip.dart`, and
// `unnecessary_import` is fatal here.
import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    FluentApp(
      theme: theme,
      home: Center(child: child),
    ),
  );

  testWidgets('an untruncated label gets no tooltip at all', (tester) async {
    await pump(
      tester,
      const FluentAxisLabelTooltip(
        fullText: 'January',
        renderedText: 'January',
        child: Text('January'),
      ),
    );
    expect(
      tester.widget<FluentTooltip>(find.byType(FluentTooltip)).enabled,
      isFalse,
      reason:
          'tooltipOfAxislabels (utilities.ts:1302-1304) skips any tick whose '
          'rendered text equals its data-full attribute, so an untruncated '
          'label has no hover affordance.',
    );
  });

  testWidgets('a truncated label shows the full text', (tester) async {
    await pump(
      tester,
      const FluentAxisLabelTooltip(
        fullText: 'January 2026',
        renderedText: 'Janu...',
        child: Text('Janu...'),
      ),
    );
    final tooltip = tester.widget<FluentTooltip>(find.byType(FluentTooltip));
    expect(
      tooltip.enabled,
      isTrue,
      reason:
          'utilities.ts:1308-1319 wires mouseover on exactly the ticks whose '
          'text differs from data-full.',
    );
    expect(
      (tooltip.content as Text).data,
      'January 2026',
      reason: 'utilities.ts:1313-1314 sets the tooltip text to the full label.',
    );
  });

  testWidgets('the tooltip carries an arrow', (tester) async {
    await pump(
      tester,
      const FluentAxisLabelTooltip(
        fullText: 'January 2026',
        renderedText: 'Janu...',
        child: Text('Janu...'),
      ),
    );
    expect(
      tester.widget<FluentTooltip>(find.byType(FluentTooltip)).withArrow,
      isTrue,
      reason:
          'SVGTooltipText.tsx:187 applies withArrow AFTER the props spread, so '
          'it cannot be overridden — where FluentTooltip defaults it to false '
          '(surfaces/tooltip.dart:418).',
    );
  });
}

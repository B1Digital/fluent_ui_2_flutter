import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/docs_metrics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// Introduction has no sections and no controls: it is a markdown document the
/// scaffold hands to `MarkdownBody`. So "does it work" is a question about the
/// renderer — headings that keep their level, bullets that read as bullets,
/// bold and code runs that survive the parse, a link that is coloured but
/// deliberately inert. Prose that renders as one flat paragraph would still
/// mount, still contain every word, and be useless.
void main() {
  const String page = 'concepts-introduction';

  /// The item text of every bullet, in document order.
  ///
  /// Each item is a `Row` of a marker and the item's own span, so the marker is
  /// the anchor: it is the one string the renderer emits itself.
  List<String> bullets(WidgetTester tester) {
    final Finder markers = find.text('•  ');
    return <String>[
      for (int i = 0; i < markers.evaluate().length; i++)
        tester
                .widgetList<Text>(
                  find.descendant(
                    of: find
                        .ancestor(of: markers.at(i), matching: find.byType(Row))
                        .first,
                    matching: find.byType(Text),
                  ),
                )
                .last
                .textSpan
                ?.toPlainText() ??
            '',
    ];
  }

  group('the document', () {
    testWidgets('drops its own leading heading, which the scaffold drew', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      // The page's `<h1>` is printed by the scaffold above the body, so the
      // source's first heading has to go or the title appears twice.
      expect(find.text('Fluent UI Flutter v9'), findsNothing);
      expect(find.textContaining('Lightweight components'), findsOneWidget);
    });

    testWidgets('keeps every heading at its own level', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      for (final String heading in <String>['What\'s new', 'Questions?']) {
        expect(find.text(heading), findsOneWidget, reason: heading);
        expect(
          textStyleOf(tester, find.text(heading))?.fontSize,
          DocsMetrics.h2.fontSize,
          reason: '$heading is an h2 in the source',
        );
      }
      expect(
        textStyleOf(tester, find.text('Overview'))?.fontSize,
        DocsMetrics.h3.fontSize,
        reason: 'Overview is an h3, and must not read as loud as What\'s new',
      );
      // The levels have to be distinguishable, or "keeps its level" is vacuous.
      expect(DocsMetrics.h2.fontSize, greaterThan(DocsMetrics.h3.fontSize!));
    });

    testWidgets('renders the standards as five separate bullets', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      const List<String> standards = <String>[
        'Customizable',
        'Performance',
        'Bundle size',
        'Accessibility',
        'Design to Code',
      ];
      final List<String> items = bullets(tester);
      expect(
        items,
        hasLength(standards.length),
        reason: 'a list that renders as one paragraph still contains the words',
      );
      for (final (int i, String standard) in standards.indexed) {
        expect(
          items[i],
          startsWith(standard),
          reason:
              'bullet $i must begin at its own label, not at whitespace: '
              '"${items[i]}"',
        );
      }
    });

    testWidgets('the label of each standard is set bold', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      final Finder item = find.textContaining('Optimized for render');
      final List<TextSpan> bold = inlineRuns(
        tester,
        item,
        (TextStyle style) => style.fontWeight == FontWeight.w600,
      );
      expect(
        bold.map((TextSpan span) => span.text),
        <String>['Performance'],
        reason: 'the strong run is the label, and only the label',
      );
    });

    testWidgets('package names keep the monospace face', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);

      final Finder paragraph = find.textContaining('react-northstar');
      final List<TextSpan> code = inlineRuns(
        tester,
        paragraph,
        (TextStyle style) => style.fontFamily == FluentFontFamily.monospace,
      );
      expect(
        code.map((TextSpan span) => span.text),
        containsAll(<String>['@fluentui/react', '@fluentui/react-northstar']),
        reason:
            'inline code that renders as prose loses the only signal that '
            'these are package names',
      );
    });
  });

  group('the GitHub reference', () {
    testWidgets('is coloured as a link', (WidgetTester tester) async {
      await pumpPageBody(tester, page);

      final List<TextSpan> links = inlineRuns(
        tester,
        find.textContaining('Reach out to the Fluent UI React team'),
        (TextStyle style) => style.color == DocsMetrics.railActive,
      );
      expect(
        links.map((TextSpan span) => span.text),
        <String>['GitHub'],
        reason: 'exactly the anchor text is painted in the link colour',
      );
    });

    testWidgets('a real click on it navigates nowhere', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      final String before = textSnapshot(tester);
      final Finder line = find.textContaining(
        'Reach out to the Fluent UI React team',
      );

      // Rendered, not clickable: every link in this corpus points into
      // Microsoft's own repository, and a document viewer that navigates away
      // from itself is a surprise rather than a feature. A synthetic tap could
      // not tell an inert run from one that only responds to a hovering
      // pointer, so this goes through a real mouse.
      await mouseClick(tester, line);
      expect(textSnapshot(tester), before);
    });
  });

  group('lifecycle', () {
    testWidgets('the page unmounts without throwing', (
      WidgetTester tester,
    ) async {
      await pumpPageBody(tester, page);
      await expectCleanTeardown(tester, page);
    });
  });
}

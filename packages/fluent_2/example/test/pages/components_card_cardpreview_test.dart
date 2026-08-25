import 'package:fluent_2/fluent_2.dart';
import 'package:fluent_2_example/shell/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

/// CardPreview has one section and no knobs: the whole page is a claim about
/// geometry — the preview bleeds to the card's edge, is clipped to its corner
/// radius, and carries the media's alt text — plus one about behaviour, that a
/// card given no `onPressed` is inert rather than a button with nothing to do.
/// Each test below pins one of those claims, because a section with no controls
/// is exactly the kind that silently rots into a plain image.
void main() {
  const String page = 'components-card-cardpreview';
  final DocsSection section = sectionOf('components-card-cardpreview--default');

  // The card is a block element and fills the width it is given, so the demo is
  // pumped at the preview's own 480 rather than the harness default: at 1600 the
  // image would sit in the left third of a 1600-wide card and "bleeds to the
  // edge" could not be told apart from "happens to start at the left edge".
  const Size viewport = Size(480, 900);

  group('preview slot', () {
    testWidgets('the preview bleeds to every edge of the card', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, size: viewport);

      final Finder card = find.byType(FluentCard);
      final Rect cardRect = tester.getRect(card);
      final Rect imageRect = tester.getRect(find.byType(Image));

      // Not "the image is inside the card": the preview is the one slot the
      // card's padding must NOT inset, and a 12px inset on any side is the
      // regression this catches.
      expect(
        imageRect,
        cardRect,
        reason: 'the preview must fill the card, not sit inside its padding',
      );
      expect(
        cardRect.height,
        240,
        reason: 'a card with no header, body or footer adds no padded group',
      );
    });

    testWidgets('the preview is clipped to the card corner radius', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, size: viewport);

      final Finder card = find.byType(FluentCard);
      final ClipRRect clip = tester.widget<ClipRRect>(
        find.descendant(of: card, matching: find.byType(ClipRRect)).first,
      );

      // The clip and the fill must agree: a preview clipped to a different
      // radius than the surface it covers shows a sliver of fill at each corner.
      expect(clip.borderRadius, FluentRadius.allMedium);
      expect(clip.borderRadius, decorationUnder(tester, card).borderRadius);
    });

    testWidgets('the logo overlay sits 12 in from the leading edge and floor', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, size: viewport);

      final Rect cardRect = tester.getRect(find.byType(FluentCard));
      final Rect logo = tester.getRect(
        find.byIcon(FluentIcons.document_20_regular),
      );

      // The overlay is `Positioned` inside the preview's Stack. If the Stack
      // ever collapsed to its child's intrinsic size, or the preview stopped
      // filling the card, the glyph would drift off the bottom-left corner it is
      // meant to pin to.
      expect(logo.left - cardRect.left, 12);
      expect(cardRect.bottom - logo.bottom, 12);
      expect(logo.size, const Size(32, 32));
    });

    testWidgets('the media keeps its alternative text', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, size: viewport);

      // Upstream's story is about a document preview; dropping the labels turns
      // the whole card into an unannounced image for a screen reader.
      expect(
        tester.widget<Image>(find.byType(Image)).semanticLabel,
        'Preview of a Word document ',
      );
      expect(
        tester
            .widget<Icon>(find.byIcon(FluentIcons.document_20_regular))
            .semanticLabel,
        'Microsoft Word logo',
      );
    });
  });

  group('interaction', () {
    testWidgets('the card is inert under a real mouse', (
      WidgetTester tester,
    ) async {
      await pumpSection(tester, section, size: viewport);
      final Finder card = find.byType(FluentCard);

      final Color? resting = decorationUnder(tester, card).color;
      final Color? underPointer = await whileHovering(
        tester,
        card,
        () => decorationUnder(tester, card).color,
      );

      // A card with no `onPressed` is documented as inert, not as a button with
      // nothing to do: it must keep its resting fill under the pointer. Only a
      // real mouse can tell the two apart — `tester.tap` never enters the
      // MouseRegion that would raise the hover token.
      expect(
        underPointer,
        resting,
        reason: 'an inert card must not report hover',
      );

      await mouseClick(tester, card);
      expect(
        decorationUnder(tester, card).color,
        resting,
        reason: 'clicking an inert card must leave it exactly as it was',
      );
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

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Flutter's ready-made selection toolbars are Material-only, so every text
/// control here would otherwise have no cut/copy/paste menu at all — selection
/// and keyboard shortcuts keep working, so the gap only shows on right-click.
void main() {
  Future<void> pump(
    WidgetTester tester,
    List<ContextMenuButtonItem> items, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: FluentTextContextMenu(anchor: const Offset(100, 100), items: items),
    ),
  );

  group('labels', () {
    testWidgets('come from WidgetsLocalizations, not hardcoded English', (
      tester,
    ) async {
      // The point of this test: WidgetsLocalizations carries cut/copy/paste,
      // unlike most text affordances, so no Material dependency is needed.
      await pump(tester, [
        ContextMenuButtonItem(
          type: ContextMenuButtonType.copy,
          onPressed: () {},
        ),
        ContextMenuButtonItem(
          type: ContextMenuButtonType.paste,
          onPressed: () {},
        ),
      ]);

      final l = WidgetsLocalizations.of(
        tester.element(find.byType(FluentTextContextMenu)),
      );
      expect(find.text(l.copyButtonLabel), findsOneWidget);
      expect(find.text(l.pasteButtonLabel), findsOneWidget);
    });

    testWidgets('an explicit label wins over the localized one', (
      tester,
    ) async {
      await pump(tester, [
        ContextMenuButtonItem(
          type: ContextMenuButtonType.copy,
          label: 'Duplicate',
          onPressed: () {},
        ),
      ]);
      expect(find.text('Duplicate'), findsOneWidget);
    });
  });

  group('behaviour', () {
    testWidgets('invokes the item callback on tap', (tester) async {
      var copied = 0;
      await pump(tester, [
        ContextMenuButtonItem(
          type: ContextMenuButtonType.copy,
          onPressed: () => copied++,
        ),
      ]);
      final l = WidgetsLocalizations.of(
        tester.element(find.byType(FluentTextContextMenu)),
      );
      await tester.tap(find.text(l.copyButtonLabel));
      await tester.pump();
      expect(copied, 1);
    });

    testWidgets('renders nothing when there is nothing to offer', (
      tester,
    ) async {
      await pump(tester, const []);
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('each item is a button to assistive technology', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, [
        ContextMenuButtonItem(
          type: ContextMenuButtonType.copy,
          onPressed: () {},
        ),
      ]);
      final l = WidgetsLocalizations.of(
        tester.element(find.byType(FluentTextContextMenu)),
      );
      expect(
        tester.getSemantics(find.text(l.copyButtonLabel)),
        matchesSemantics(
          label: l.copyButtonLabel,
          isButton: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });
  });

  group('theming', () {
    testWidgets('the surface follows a subtree token override', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.neutralBackground1: magenta},
            child: FluentTextContextMenu(
              anchor: const Offset(100, 100),
              items: [
                ContextMenuButtonItem(
                  type: ContextMenuButtonType.copy,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      final decoration = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.border != null);
      expect(decoration.color, magenta);
    });

    testWidgets('high contrast keeps the border opaque', (tester) async {
      await pump(
        tester,
        [
          ContextMenuButtonItem(
            type: ContextMenuButtonType.copy,
            onPressed: () {},
          ),
        ],
        theme: FluentThemeData.highContrast(
          fontPlatform: FluentFontPlatform.web,
        ),
      );
      final decoration = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((d) => d.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.border != null);
      expect(decoration.border!.top.color.a, 1.0);
    });
  });

  group('wired into the text controls', () {
    testWidgets('every EditableText gets a context menu builder', (
      tester,
    ) async {
      // Regression: three of the four text controls shipped with no builder at
      // all, so right-click produced nothing while everything else worked.
      for (final child in <Widget>[
        FluentInput(controller: TextEditingController()),
        FluentTextarea(controller: TextEditingController()),
        FluentSearchBox(controller: TextEditingController()),
        FluentSpinButton(value: 1, onChanged: (_) {}),
      ]) {
        await tester.pumpWidget(
          FluentApp(
            theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
            home: Center(child: child),
          ),
        );
        final editable = tester.widget<EditableText>(
          find.byType(EditableText).first,
        );
        expect(
          editable.contextMenuBuilder,
          isNotNull,
          reason: '${child.runtimeType} has no context menu',
        );
      }
    });
  });
}

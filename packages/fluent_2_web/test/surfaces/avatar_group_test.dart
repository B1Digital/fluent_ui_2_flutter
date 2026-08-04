import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// `FluentAvatarGroup` has no spec fixture of its own, and that is a decision
/// rather than an omission: the `Avatar/Avatar group` set (`9278:11479`) has two
/// variants at one size, and all 26 `Avatar/Avatar pie` variants (`9278:11492`)
/// are the same three numbers scaled — a half, a quadrant, and a 2px rule. What
/// the design file actually *states* lives in two variable collections, and
/// those are what the tables below transcribe:
///
/// * `Avatar group size` (`VariableCollectionId:9044:23`) — `Spread` and
///   `Stack`, one value per avatar size.
/// * `Avatar shape` — the circular clip the pie takes.
void main() {
  const key = Key('group');

  Future<void> pump(
    WidgetTester tester,
    Widget group, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(child: group),
    ),
  );

  List<Widget> members(int count) => <Widget>[
    for (var i = 0; i < count; i++)
      FluentAvatar(key: ValueKey<int>(i), initials: 'A$i'),
  ];

  FluentAvatarPiePainter pieOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((paint) => paint.foregroundPainter)
      .whereType<FluentAvatarPiePainter>()
      .single;

  Iterable<FluentAvatarRingPainter> outlinesOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((paint) => paint.painter)
      .whereType<FluentAvatarRingPainter>()
      // Every member draws its own (empty) activity ring painter too; the
      // stack outline is the one with a width.
      .where((painter) => painter.width > 0);

  double spacingOf(FluentAvatarGroupLayout layout, FluentAvatarSize size) =>
      resolveFluentAvatarGroupStyle(
        resolveFluentAvatarGroupState(
          children: const <Widget>[],
          layout: layout,
          size: size,
        ),
        FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      ).spacing!.resolve(const <WidgetState>{})!;

  group('Avatar group size, transcribed', () {
    test('Spread is the collection verbatim', () {
      const expected = <FluentAvatarSize, double>{
        FluentAvatarSize.size16: FluentSpacing.s,
        FluentAvatarSize.size20: FluentSpacing.mNudge,
        FluentAvatarSize.size24: FluentSpacing.mNudge,
        FluentAvatarSize.size28: FluentSpacing.mNudge,
        FluentAvatarSize.size32: FluentSpacing.m,
        FluentAvatarSize.size36: FluentSpacing.m,
        FluentAvatarSize.size40: FluentSpacing.m,
        FluentAvatarSize.size48: FluentSpacing.m,
        FluentAvatarSize.size56: FluentSpacing.m,
        FluentAvatarSize.size64: FluentSpacing.l,
        FluentAvatarSize.size72: FluentSpacing.l,
        FluentAvatarSize.size96: FluentSpacing.xl,
        FluentAvatarSize.size120: FluentSpacing.xl,
      };
      for (final entry in expected.entries) {
        expect(
          spacingOf(FluentAvatarGroupLayout.spread, entry.key),
          entry.value,
          reason: entry.key.name,
        );
      }
    });

    test('Stack is the collection verbatim, and negative', () {
      const expected = <FluentAvatarSize, double>{
        FluentAvatarSize.size16: -2,
        FluentAvatarSize.size20: -2,
        FluentAvatarSize.size24: -4,
        FluentAvatarSize.size28: -4,
        FluentAvatarSize.size32: -4,
        FluentAvatarSize.size36: -4,
        FluentAvatarSize.size40: -4,
        FluentAvatarSize.size48: -8,
        FluentAvatarSize.size56: -8,
        FluentAvatarSize.size64: -8,
        FluentAvatarSize.size72: -8,
        FluentAvatarSize.size96: -16,
        FluentAvatarSize.size120: -16,
      };
      for (final entry in expected.entries) {
        expect(
          spacingOf(FluentAvatarGroupLayout.stack, entry.key),
          entry.value,
          reason: entry.key.name,
        );
      }
    });

    testWidgets('the two Layout variants reproduce their frame width', (
      tester,
    ) async {
      // `Layout=Spread` measures 208 and `Layout=Stack` 144, both five 32px
      // avatars: 5 * 32 + 4 * 12 and 5 * 32 - 4 * 4.
      for (final entry in const <FluentAvatarGroupLayout, double>{
        FluentAvatarGroupLayout.spread: 208,
        FluentAvatarGroupLayout.stack: 144,
      }.entries) {
        await pump(
          tester,
          FluentAvatarGroup(key: key, layout: entry.key, children: members(5)),
        );
        expect(
          tester.getSize(find.byKey(key)),
          Size(entry.value, 32),
          reason: entry.key.name,
        );
      }
    });

    testWidgets('members sit at the gap the collection states', (tester) async {
      await pump(tester, FluentAvatarGroup(key: key, children: members(3)));
      final left = tester.getRect(const ValueKey<int>(0).findByKey());
      final middle = tester.getRect(const ValueKey<int>(1).findByKey());
      expect(middle.left - left.right, FluentSpacing.m);
    });

    testWidgets('a stacked member overlaps the one before it', (tester) async {
      await pump(
        tester,
        FluentAvatarGroup(
          key: key,
          layout: FluentAvatarGroupLayout.stack,
          children: members(3),
        ),
      );
      final left = tester.getRect(const ValueKey<int>(0).findByKey());
      final middle = tester.getRect(const ValueKey<int>(1).findByKey());
      expect(middle.left - left.right, -FluentSpacing.xs);
    });
  });

  group('stack outline', () {
    testWidgets('every member is ringed in neutralBackground2', (tester) async {
      // Figma draws overlapping avatars with no separator at all, so this is
      // upstream's `boxShadow: 0 0 0 <width> colorNeutralBackground2` — the one
      // place a silent design file is read as an omission rather than intent.
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      const widths = <FluentAvatarSize, double>{
        FluentAvatarSize.size32: FluentStroke.thick,
        FluentAvatarSize.size56: FluentStroke.thicker,
        FluentAvatarSize.size72: FluentStroke.thickest,
      };

      for (final entry in widths.entries) {
        await pump(
          tester,
          FluentAvatarGroup(
            key: key,
            layout: FluentAvatarGroupLayout.stack,
            size: entry.key,
            children: <Widget>[
              for (var i = 0; i < 3; i++)
                FluentAvatar(key: ValueKey<int>(i), size: entry.key),
            ],
          ),
        );
        final outlines = outlinesOf(tester).toList();
        expect(outlines.length, 3, reason: '${entry.key.name}: one per member');
        for (final outline in outlines) {
          expect(outline.color, theme.colors.neutralBackground2);
          expect(outline.width, entry.value, reason: entry.key.name);
          expect(outline.gap, 0, reason: 'a stack outline hugs the avatar');
          expect(outline.gapColor, isNull);
        }
      }
    });

    testWidgets('spread draws no outline at all', (tester) async {
      await pump(tester, FluentAvatarGroup(key: key, children: members(3)));
      expect(outlinesOf(tester), isEmpty);
    });
  });

  group('pie', () {
    testWidgets('it is exactly one avatar wide at every size', (tester) async {
      for (final size in FluentAvatarSize.values) {
        await pump(
          tester,
          FluentAvatarGroup(
            key: key,
            layout: FluentAvatarGroupLayout.pie,
            size: size,
            children: members(2),
          ),
        );
        expect(
          tester.getSize(find.byKey(key)),
          Size(size.edge, size.edge),
          reason: size.name,
        );
      }
    });

    testWidgets('the rule is Neutral/Stroke/on Brand/1/Rest, 2px, every size', (
      tester,
    ) async {
      // All 26 pie variants bind `Stroke width/Thick` on a `Divider` rectangle
      // filled with `Neutral/Stroke/on Brand/1/Rest`. React instead ramps the
      // width with size and reveals `colorTransparentStroke` between clipped
      // slices; Figma wins on both counts.
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      for (final size in <FluentAvatarSize>[
        FluentAvatarSize.size16,
        FluentAvatarSize.size56,
        FluentAvatarSize.size72,
        FluentAvatarSize.size120,
      ]) {
        await pump(
          tester,
          FluentAvatarGroup(
            key: key,
            layout: FluentAvatarGroupLayout.pie,
            size: size,
            children: members(2),
          ),
        );
        final painter = pieOf(tester);
        expect(painter.width, FluentStroke.thick, reason: size.name);
        expect(painter.color, theme.colors.neutralStrokeOnBrand);
        expect(painter.quartered, isFalse);
      }
    });

    testWidgets('a third member quarters the right half', (tester) async {
      await pump(
        tester,
        FluentAvatarGroup(
          key: key,
          layout: FluentAvatarGroupLayout.pie,
          children: members(3),
        ),
      );
      expect(pieOf(tester).quartered, isTrue);

      final group = tester.getRect(find.byKey(key));
      // The two right-hand members are half-scale and fill their quadrants.
      expect(
        tester.getRect(const ValueKey<int>(1).findByKey()),
        Rect.fromLTWH(group.left + 16, group.top, 16, 16),
      );
      expect(
        tester.getRect(const ValueKey<int>(2).findByKey()),
        Rect.fromLTWH(group.left + 16, group.top + 16, 16, 16),
      );
    });

    testWidgets('two members each show their own middle half', (tester) async {
      await pump(
        tester,
        FluentAvatarGroup(
          key: key,
          layout: FluentAvatarGroupLayout.pie,
          children: members(2),
        ),
      );
      final group = tester.getRect(find.byKey(key));
      // Each member still lays out at full size; the crop and the offset are
      // what put its middle half in one half of the circle.
      expect(
        tester.getRect(const ValueKey<int>(0).findByKey()),
        Rect.fromLTWH(group.left - 8, group.top, 32, 32),
      );
      expect(
        tester.getRect(const ValueKey<int>(1).findByKey()),
        Rect.fromLTWH(group.left + 8, group.top, 32, 32),
      );
    });

    testWidgets('the whole pie is clipped to the avatar radius', (
      tester,
    ) async {
      await pump(
        tester,
        FluentAvatarGroup(
          key: key,
          layout: FluentAvatarGroupLayout.pie,
          children: members(2),
        ),
      );
      final clip = tester.widget<ClipRRect>(
        find.descendant(of: find.byKey(key), matching: find.byType(ClipRRect)),
      );
      expect(clip.borderRadius, FluentRadius.allCircular);
    });
  });

  group('style resolution order', () {
    testWidgets('the widget style beats the subtree theme beats the defaults', (
      tester,
    ) async {
      await pump(
        tester,
        FluentAvatarGroupTheme(
          style: FluentAvatarGroupStyle.from(spacing: 3),
          child: FluentAvatarGroup(
            key: key,
            style: FluentAvatarGroupStyle.from(spacing: 7),
            children: members(2),
          ),
        ),
      );
      expect(tester.getSize(find.byKey(key)).width, 2 * 32 + 7);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        FluentAvatarGroup(
          key: key,
          layout: FluentAvatarGroupLayout.pie,
          style: FluentAvatarGroupStyle.from(dividerWidth: 5),
          children: members(2),
        ),
      );
      final painter = pieOf(tester);
      expect(painter.width, 5);
      expect(
        painter.color,
        theme.colors.neutralStrokeOnBrand,
        reason: 'overriding the width must not drop the rule token',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      final base = FluentAvatarGroupBaseState(
        layout: FluentAvatarGroupLayout.spread,
        children: members(2),
      );

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentAvatarGroup(
            base,
            FluentAvatarGroupStyle.from(spacing: 100, diameter: 32),
            const <WidgetState>{},
          ),
        ),
      );
      expect(tester.getSize(find.byKey(key)).width, 2 * 32 + 100);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the pie rule', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.neutralStrokeOnBrand: magenta},
            child: Center(
              child: FluentAvatarGroup(
                key: key,
                layout: FluentAvatarGroupLayout.pie,
                children: members(2),
              ),
            ),
          ),
        ),
      );
      expect(pieOf(tester).color, magenta);
    });

    testWidgets('high contrast keeps the rule and the outline opaque', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(
        tester,
        FluentAvatarGroup(
          key: key,
          layout: FluentAvatarGroupLayout.pie,
          children: members(2),
        ),
        theme: theme,
      );
      expect(pieOf(tester).color!.a, 1.0);

      await pump(
        tester,
        FluentAvatarGroup(
          key: key,
          layout: FluentAvatarGroupLayout.stack,
          children: members(3),
        ),
        theme: theme,
      );
      for (final outline in outlinesOf(tester)) {
        expect(outline.color!.a, 1.0);
      }
    });
  });

  group('behaviour', () {
    testWidgets('it is non-interactive and has no disabled state', (
      tester,
    ) async {
      // Neither Figma set carries a `State` axis, so there is nothing to grey
      // out and nothing to hover.
      await pump(tester, FluentAvatarGroup(key: key, children: members(2)));
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FluentInteractive),
        ),
        findsNothing,
      );
    });

    testWidgets('an empty group still occupies one avatar of height', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentAvatarGroup(key: key, children: <Widget>[]),
      );
      expect(tester.getSize(find.byKey(key)).height, 32);
    });

    testWidgets('each member keeps its own semantics', (tester) async {
      await pump(
        tester,
        const FluentAvatarGroup(
          key: key,
          children: <Widget>[
            FluentAvatar(name: 'Ada', initials: 'A'),
            FluentAvatar(name: 'Grace', initials: 'G'),
          ],
        ),
      );
      expect(find.bySemanticsLabel('Ada'), findsOneWidget);
      expect(find.bySemanticsLabel('Grace'), findsOneWidget);
    });
  });
}

extension on ValueKey<int> {
  Finder findByKey() => find.byKey(this);
}

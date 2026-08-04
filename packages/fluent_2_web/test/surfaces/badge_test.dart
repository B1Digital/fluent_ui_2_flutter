import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// Badge and Presence Badge share this file because they share a Figma page and
/// a token story: both are the first consumers of the `Status/*` and
/// `Palette/*` layers ported into core, and the fixture token names are the
/// only thing standing between a correct mapping and a plausible-looking one.
///
/// The whole point of the `token` helper below is that mapping. Every colour
/// assertion
/// goes through it, so a test failure names the Figma variable rather than a
/// hex code nobody can place.
void main() {
  const key = Key('badge');

  Future<void> pump(
    WidgetTester tester,
    Widget badge, {
    FluentThemeData? theme,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(child: badge),
    ),
  );

  /// The badge's own decorated surface.
  BoxDecoration decorationOf(WidgetTester tester) => tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((d) => d.decoration)
      .whereType<BoxDecoration>()
      .first;

  TextStyle textStyleOf(WidgetTester tester) =>
      resolvedTextStyleOf(tester, of: find.byKey(key));

  FluentPresenceBadgePainter painterOf(WidgetTester tester) => tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((p) => p.painter)
      .whereType<FluentPresenceBadgePainter>()
      .first;

  /// Resolves a Figma variable path against a theme.
  ///
  /// This is the mapping under test. Nothing in the component may reach for a
  /// token this table does not name, and nothing here may be "close enough" —
  /// the fixture states the exact variable each property is bound to.
  Color token(FluentThemeData theme, String name) {
    final c = theme.colors;
    return switch (name) {
      'Brand/Background/1/Rest' => c.brandBackground,
      'Brand/Background/2/Rest' => c.brandBackground2,
      'Brand/Stroke/1/Rest' => c.brandStroke1,
      'Brand/Stroke/2/Rest' => c.brandStroke2,
      'Brand/Foreground/1/Rest' => c.brandForeground1,
      'Brand/Foreground/2/Rest' => c.brandForeground2,
      'Status/Danger/Background/1/Rest' => c.statusDangerBackground1,
      'Status/Danger/Background/3/Rest' => c.statusDangerBackground3,
      'Status/Danger/Stroke/1/Rest' => c.statusDangerBorder1,
      'Status/Danger/Stroke/2/Rest' => c.statusDangerBorder2,
      'Status/Danger/Foreground/1/Rest' => c.statusDangerForeground1,
      'Status/Danger/Foreground/3/Rest' => c.statusDangerForeground3,
      'Status/Success/Background/1/Rest' => c.statusSuccessBackground1,
      'Status/Success/Background/3/Rest' => c.statusSuccessBackground3,
      'Status/Success/Stroke/1/Rest' => c.statusSuccessBorder1,
      'Status/Success/Stroke/2/Rest' => c.statusSuccessBorder2,
      'Status/Success/Foreground/1/Rest' => c.statusSuccessForeground1,
      'Status/Success/Foreground/3/Rest' => c.statusSuccessForeground3,
      'Status/Warning/Background/1/Rest' => c.statusWarningBackground1,
      'Status/Warning/Background/3/Rest' => c.statusWarningBackground3,
      'Status/Warning/Stroke/1/Rest' => c.statusWarningBorder1,
      'Status/Warning/Foreground/2/Rest' => c.statusWarningForeground2,
      'Status/Available/Foreground/3/Rest' => c.statusAvailableForeground3,
      'Status/Away/Background/3/Rest' => c.statusAwayBackground3,
      'Status/Oof/Foreground/3/Rest' => c.statusOofForeground3,
      'Neutral/Foreground/1/Rest' => c.neutralForeground1,
      'Neutral/Foreground/3/Rest' => c.neutralForeground3,
      'Neutral/Foreground/On Brand/Rest' => c.neutralForegroundOnBrand,
      'Neutral/Foreground/Static/Rest' => c.neutralForeground1Static,
      'Neutral/Background/1/Rest' => c.neutralBackground1,
      'Neutral/Background/4/Rest' => c.neutralBackground4,
      'Neutral/Background/5/Rest' => c.neutralBackground5,
      'Neutral/Stroke/2/Rest' => c.neutralStroke2,
      'Neutral/Stroke/Accessible/Rest' => c.neutralStrokeAccessible,
      _ => fail('no core token is mapped to the Figma variable "$name"'),
    };
  }

  const colors = <String, FluentBadgeColor>{
    'Brand': FluentBadgeColor.brand,
    'Danger': FluentBadgeColor.danger,
    'Warning': FluentBadgeColor.warning,
    'Success': FluentBadgeColor.success,
    'Important': FluentBadgeColor.important,
    'Informative': FluentBadgeColor.informative,
    'Subtle': FluentBadgeColor.subtle,
  };
  const sizes = <String, FluentBadgeSize>{
    'Extra large': FluentBadgeSize.extraLarge,
    'Large': FluentBadgeSize.large,
    'Medium': FluentBadgeSize.medium,
    'Small': FluentBadgeSize.small,
  };
  const appearances = <String, FluentBadgeAppearance>{
    'Filled': FluentBadgeAppearance.filled,
    'Tint': FluentBadgeAppearance.tint,
    'Outline': FluentBadgeAppearance.outline,
    'Subtle': FluentBadgeAppearance.subtle,
  };

  group('Badge — pixel fidelity against Figma', () {
    final spec = loadSpec('badge');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 112);
      expect(spec.properties['Color'], colors.keys.toList());
      expect(spec.properties['Size'], sizes.keys.toList());
      expect(spec.properties['Appearance'], appearances.keys.toList());
    });

    test('geometry is a function of size alone', () {
      // The size test below pumps one colour per size. That is only sound
      // because Figma gives all 28 colour/appearance pairs identical geometry,
      // which is asserted here rather than assumed.
      for (final size in sizes.keys) {
        final group = spec.where({'Size': size});
        expect(group, hasLength(28), reason: size);
        for (final variant in group) {
          expect(variant.padding, group.first.padding, reason: variant.name);
          expect(variant.gap, group.first.gap, reason: variant.name);
          expect(variant.radius, group.first.radius, reason: variant.name);
          expect(
            variant.size.height,
            group.first.size.height,
            reason: variant.name,
          );
          expect(
            variant.text!.fontSize,
            group.first.text!.fontSize,
            reason: variant.name,
          );
        }
      }
    });

    testWidgets('geometry matches every size', (tester) async {
      for (final entry in sizes.entries) {
        final variant = spec.variant({
          'Color': 'Brand',
          'Appearance': 'Filled',
          'Size': entry.key,
        });

        await pump(
          tester,
          FluentBadge(
            key: key,
            color: FluentBadgeColor.brand,
            size: entry.value,
            icon: const SizedBox.shrink(),
            child: const Text('99'),
          ),
        );

        final padding = tester
            .widgetList<Padding>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(Padding),
              ),
            )
            .first
            .padding
            .resolve(TextDirection.ltr);

        expect(
          padding.left,
          variant.padding!.left,
          reason: '${entry.key}: padding.left',
        );
        expect(
          padding.right,
          variant.padding!.right,
          reason: '${entry.key}: padding.right',
        );
        expect(
          padding.top,
          variant.padding!.top,
          reason: '${entry.key}: padding.top',
        );
        expect(
          decorationOf(tester).borderRadius,
          variant.radius,
          reason: '${entry.key}: radius',
        );
        expect(
          tester.getSize(find.byKey(key)).height,
          variant.size.height,
          reason: '${entry.key}: height',
        );

        final row = tester.widget<Row>(
          find.descendant(of: find.byKey(key), matching: find.byType(Row)),
        );
        expect(row.spacing, variant.gap, reason: '${entry.key}: gap');

        final text = variant.text!;
        final style = textStyleOf(tester);
        expect(
          style.fontSize,
          text.fontSize,
          reason: '${entry.key}: text.fontSize',
        );
        expect(
          style.height! * style.fontSize!,
          text.lineHeight,
          reason: '${entry.key}: text.lineHeight',
        );
      }
    });

    testWidgets('a badge with no content is at least as wide as it is tall', (
      tester,
    ) async {
      // Figma pins minWidth to the height on every size, which is what keeps a
      // count badge round rather than collapsing to its padding.
      for (final entry in sizes.entries) {
        final variant = spec.variant({
          'Color': 'Brand',
          'Appearance': 'Filled',
          'Size': entry.key,
        });
        await pump(tester, FluentBadge(key: key, size: entry.value));
        expect(
          tester.getSize(find.byKey(key)),
          Size(variant.size.height, variant.size.height),
          reason: entry.key,
        );
      }
    });

    testWidgets('fill, border and label colour match all 28 colour/appearance '
        'pairs', (tester) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

      for (final appearance in appearances.entries) {
        for (final color in colors.entries) {
          final variant = spec.variant({
            'Color': color.key,
            'Appearance': appearance.key,
            'Size': 'Medium',
          });

          await pump(
            tester,
            FluentBadge(
              key: key,
              color: color.value,
              appearance: appearance.value,
              child: const Text('99'),
            ),
            theme: theme,
          );

          final where = '${color.key}/${appearance.key}';
          final decoration = decorationOf(tester);

          // Fill.
          final fillToken = variant.token('fills');
          if (fillToken == null) {
            // Figma paints no fill at all here. The component must still hold a
            // real Fluent transparent token, never a literal — the token turns
            // opaque in high contrast and a literal never would.
            expect(decoration.color!.a, 0, reason: '$where: fill alpha');
            expect(
              decoration.color,
              theme.colors.transparentBackground,
              reason: '$where: fill must be transparentBackground',
            );
          } else {
            expect(
              decoration.color,
              token(theme, fillToken),
              reason: '$where: fill ($fillToken)',
            );
            expect(
              decoration.color!.toARGB32(),
              variant.fill!.toARGB32(),
              reason: '$where: fill hex',
            );
          }

          // Border.
          final strokeToken = variant.token('strokes');
          if (strokeToken == null) {
            expect(decoration.border, isNull, reason: '$where: border');
            expect(variant.strokeWidth, 0, reason: '$where: fixture stroke');
          } else {
            final border = decoration.border!.top;
            expect(
              border.color,
              token(theme, strokeToken),
              reason: '$where: border ($strokeToken)',
            );
            expect(
              border.color.toARGB32(),
              variant.stroke!.toARGB32(),
              reason: '$where: border hex',
            );
            expect(
              border.width,
              variant.strokeWidth,
              reason: '$where: border width',
            );
          }

          // Label.
          final labelToken = variant.text!.tokens['fills']!.single;
          expect(
            textStyleOf(tester).color,
            token(theme, labelToken),
            reason: '$where: label ($labelToken)',
          );
        }
      }
    });

    testWidgets('icon size follows the size ramp', (tester) async {
      // Figma: 20 / 16 / 12 / 12 for extra large / large / medium / small.
      const expected = <FluentBadgeSize, double>{
        FluentBadgeSize.extraLarge: 20,
        FluentBadgeSize.large: 16,
        FluentBadgeSize.medium: 12,
        FluentBadgeSize.small: 12,
      };
      for (final entry in expected.entries) {
        await pump(
          tester,
          FluentBadge(
            key: key,
            size: entry.key,
            icon: const Icon(FluentIcons.checkmark_20_regular),
            child: const Text('99'),
          ),
        );
        final data = IconTheme.of(
          tester.element(
            find.descendant(of: find.byKey(key), matching: find.byType(Icon)),
          ),
        );
        expect(data.size, entry.value, reason: entry.key.name);
      }
    });
  });

  group('Badge — motion', () {
    testWidgets('there is no transition; the surface changes on the frame', (
      tester,
    ) async {
      // Upstream ships no `transition` on Badge at all, so unlike Button there
      // is deliberately no FluentAnimatedStyle here. Asserting the absence is
      // the only way to stop one being "helpfully" added later.
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        const FluentBadge(key: key, child: Text('99')),
        theme: theme,
      );
      expect(decorationOf(tester).color, theme.colors.brandBackground);

      await pump(
        tester,
        const FluentBadge(
          key: key,
          color: FluentBadgeColor.danger,
          child: Text('99'),
        ),
        theme: theme,
      );
      expect(
        decorationOf(tester).color,
        theme.colors.statusDangerBackground3,
        reason: 'must be instant, not tweened',
      );
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FluentAnimatedStyle<Color>),
        ),
        findsNothing,
      );
    });
  });

  group('Badge — style resolution order', () {
    testWidgets('the widget style beats the subtree theme beats the defaults', (
      tester,
    ) async {
      const themed = Color(0xFF111111);
      const explicit = Color(0xFF222222);

      await pump(
        tester,
        FluentBadgeTheme(
          style: FluentBadgeStyle.from(backgroundColor: themed),
          child: const FluentBadge(key: key, child: Text('99')),
        ),
      );
      expect(decorationOf(tester).color, themed);

      await pump(
        tester,
        FluentBadgeTheme(
          style: FluentBadgeStyle.from(backgroundColor: themed),
          child: FluentBadge(
            key: key,
            style: FluentBadgeStyle.from(backgroundColor: explicit),
            child: const Text('99'),
          ),
        ),
      );
      expect(decorationOf(tester).color, explicit);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        FluentBadge(
          key: key,
          style: FluentBadgeStyle.from(borderRadius: FluentRadius.allCircular),
          child: const Text('99'),
        ),
        theme: theme,
      );
      expect(decorationOf(tester).borderRadius, FluentRadius.allCircular);
      expect(decorationOf(tester).color, theme.colors.brandBackground);
    });
  });

  group('Badge — recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentBadgeBaseState(
        iconPosition: FluentBadgeIconPosition.before,
        label: Text('99'),
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentBadge(
            base,
            FluentBadgeStyle.from(
              backgroundColor: mine,
              borderRadius: FluentRadius.allLarge,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(decorationOf(tester).color, mine);
      expect(decorationOf(tester).borderRadius, FluentRadius.allLarge);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentBadgeState(
        color: FluentBadgeColor.success,
        appearance: FluentBadgeAppearance.tint,
        label: const Text('99'),
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentBadgeStyle(
        state,
        theme,
      ).merge(FluentBadgeStyle.from(borderRadius: FluentRadius.allCircular));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentBadge(state, adjusted, const <WidgetState>{}),
        ),
      );
      expect(decorationOf(tester).color, theme.colors.statusSuccessBackground1);
      expect(decorationOf(tester).borderRadius, FluentRadius.allCircular);
    });
  });

  group('Badge — theming', () {
    testWidgets('a single-token override reaches the badge', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: const FluentThemeOverride(
            colors: {FluentColorToken.statusDangerBackground3: magenta},
            child: Center(
              child: FluentBadge(
                key: key,
                color: FluentBadgeColor.danger,
                child: Text('99'),
              ),
            ),
          ),
        ),
      );
      expect(decorationOf(tester).color, magenta);
    });

    testWidgets('high contrast leaves no invisible border', (tester) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      for (final appearance in [
        FluentBadgeAppearance.tint,
        FluentBadgeAppearance.outline,
      ]) {
        for (final color in colors.values) {
          await pump(
            tester,
            FluentBadge(
              key: key,
              color: color,
              appearance: appearance,
              child: const Text('99'),
            ),
            theme: theme,
          );
          final border = decorationOf(tester).border;
          expect(
            border,
            isNotNull,
            reason: '${color.name}/${appearance.name} border',
          );
          expect(
            border!.top.color.a,
            1.0,
            reason: '${color.name}/${appearance.name} border opacity',
          );
        }
      }
    });
  });

  group('Badge — behaviour', () {
    testWidgets('it is non-interactive: hover does not change it', (
      tester,
    ) async {
      // A badge is a status marker, not a control. Fluent gives it no hover,
      // pressed or disabled tokens, so there is nothing for an interaction
      // layer to select and none is installed.
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        const FluentBadge(key: key, child: Text('99')),
        theme: theme,
      );
      expect(find.byType(FluentInteractive), findsNothing);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.byKey(key)));
      await tester.pumpAndSettle();

      expect(decorationOf(tester).color, theme.colors.brandBackground);
    });

    testWidgets('the disabled state selects nothing of its own', (
      tester,
    ) async {
      // Disabled is not a visual treatment to be faked here: Figma has no
      // disabled Badge variant, so resolving with it must be a no-op.
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final state = resolveFluentBadgeState(label: const Text('99'));
      final style = resolveFluentBadgeStyle(state, theme);
      expect(
        style.backgroundColor!.resolve(const {WidgetState.disabled}),
        style.backgroundColor!.resolve(const {}),
      );
      expect(
        style.foregroundColor!.resolve(const {WidgetState.disabled}),
        style.foregroundColor!.resolve(const {}),
      );
    });

    testWidgets('a semantic label is announced', (tester) async {
      await pump(
        tester,
        const FluentBadge(
          key: key,
          semanticLabel: '3 unread',
          child: Text('3'),
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(label: '3 unread'),
      );
    });
  });

  // --------------------------------------------------------- Presence Badge

  const statuses = <String, FluentPresenceStatus>{
    'Offline': FluentPresenceStatus.offline,
    'Available': FluentPresenceStatus.available,
    'Busy': FluentPresenceStatus.busy,
    'Away': FluentPresenceStatus.away,
    'Blocked': FluentPresenceStatus.blocked,
    'Do not disturb': FluentPresenceStatus.doNotDisturb,
    'Unknown': FluentPresenceStatus.unknown,
    'OOF': FluentPresenceStatus.outOfOffice,
  };
  const presenceSizes = <String, FluentPresenceBadgeSize>{
    'Extra-large huge': FluentPresenceBadgeSize.extraLarge,
    'Large': FluentPresenceBadgeSize.large,
    'Medium': FluentPresenceBadgeSize.medium,
    'Small': FluentPresenceBadgeSize.small,
    'Extra-small': FluentPresenceBadgeSize.extraSmall,
    'Tiny': FluentPresenceBadgeSize.tiny,
  };

  /// The Fluent icon each `glyphIcon` variant name resolves to.
  ///
  /// Keyed exactly as Figma names its icon component — `State=…, Size=…,
  /// Theme=…` — so the mapping can be read against the design file line by
  /// line. Figma only kept the icon as an instance on the 10/12/16 sizes.
  const glyphs = <String, IconData>{
    'State=Available, Size=10, Theme=Filled':
        FluentIcons.presence_available_10_filled,
    'State=Available, Size=10, Theme=Regular':
        FluentIcons.presence_available_10_regular,
    'State=Available, Size=12, Theme=Filled':
        FluentIcons.presence_available_12_filled,
    'State=Available, Size=12, Theme=Regular':
        FluentIcons.presence_available_12_regular,
    'State=Available, Size=16, Theme=Filled':
        FluentIcons.presence_available_16_filled,
    'State=Available, Size=16, Theme=Regular':
        FluentIcons.presence_available_16_regular,
    'State=Away, Size=10, Theme=Filled': FluentIcons.presence_away_10_filled,
    'State=Away, Size=12, Theme=Filled': FluentIcons.presence_away_12_filled,
    'State=Away, Size=16, Theme=Filled': FluentIcons.presence_away_16_filled,
    'State=Busy, Size=10, Theme=Filled': FluentIcons.presence_busy_10_filled,
    'State=Busy, Size=12, Theme=Filled': FluentIcons.presence_busy_12_filled,
    'State=Busy, Size=16, Theme=Filled': FluentIcons.presence_busy_16_filled,
    'State=Blocked, Size=10, Theme=Regular':
        FluentIcons.presence_blocked_10_regular,
    'State=Blocked, Size=12, Theme=Regular':
        FluentIcons.presence_blocked_12_regular,
    'State=Blocked, Size=16, Theme=Regular':
        FluentIcons.presence_blocked_16_regular,
    'State=DND, Size=10, Theme=Filled': FluentIcons.presence_dnd_10_filled,
    'State=DND, Size=10, Theme=Regular': FluentIcons.presence_dnd_10_regular,
    'State=DND, Size=12, Theme=Filled': FluentIcons.presence_dnd_12_filled,
    'State=DND, Size=12, Theme=Regular': FluentIcons.presence_dnd_12_regular,
    'State=DND, Size=16, Theme=Filled': FluentIcons.presence_dnd_16_filled,
    'State=DND, Size=16, Theme=Regular': FluentIcons.presence_dnd_16_regular,
    'State=Offline, Size=10, Theme=Regular':
        FluentIcons.presence_offline_10_regular,
    'State=Offline, Size=12, Theme=Regular':
        FluentIcons.presence_offline_12_regular,
    'State=Offline, Size=16, Theme=Regular':
        FluentIcons.presence_offline_16_regular,
    'State=OOF, Size=10, Theme=Regular': FluentIcons.presence_oof_10_regular,
    'State=OOF, Size=12, Theme=Regular': FluentIcons.presence_oof_12_regular,
    'State=OOF, Size=16, Theme=Regular': FluentIcons.presence_oof_16_regular,
    'State=Unknown, Size=10, Theme=Regular':
        FluentIcons.presence_unknown_10_regular,
    'State=Unknown, Size=12, Theme=Regular':
        FluentIcons.presence_unknown_12_regular,
    'State=Unknown, Size=16, Theme=Regular':
        FluentIcons.presence_unknown_16_regular,
  };

  group('Presence Badge — pixel fidelity against Figma', () {
    final spec = loadSpec('presence_badge');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 96);
      expect(spec.properties['Status'], statuses.keys.toList());
      expect(spec.properties['Size'], presenceSizes.keys.toList());
    });

    testWidgets('every one of the 96 variants resolves to Figma\'s numbers', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);

      for (final variant in spec.variants) {
        // Figma's axis is "In office", so False is the out-of-office badge.
        final outOfOffice = variant.props['In office'] == 'False';
        final status = statuses[variant.props['Status']]!;
        final size = presenceSizes[variant.props['Size']]!;

        await pump(
          tester,
          FluentPresenceBadge(
            key: key,
            status: status,
            outOfOffice: outOfOffice,
            size: size,
          ),
          theme: theme,
        );

        final where = variant.name;
        expect(
          tester.getSize(find.byKey(key)),
          variant.size,
          reason:
              '$where: size (the ring paints outside, so it must not '
              'change layout)',
        );

        final painter = painterOf(tester);
        expect(
          painter.ring,
          token(theme, variant.token('strokes')!),
          reason: '$where: ring',
        );
        expect(
          painter.ring!.toARGB32(),
          variant.stroke!.toARGB32(),
          reason: '$where: ring hex',
        );
        expect(
          painter.ringWidth,
          variant.strokeWidth,
          reason: '$where: ring width',
        );

        final glyphColor = token(theme, variant.token('glyphFills')!);
        final glyphHex = Color(
          int.parse(variant.token('glyphFill')!.substring(1), radix: 16),
        );
        expect(
          glyphColor.toARGB32(),
          glyphHex.toARGB32(),
          reason: '$where: glyph hex',
        );

        final iconFinder = find.descendant(
          of: find.byKey(key),
          matching: find.byType(Icon),
        );
        if (size == FluentPresenceBadgeSize.tiny) {
          // Tiny is a bare dot in Figma — no icon component at all.
          expect(iconFinder, findsNothing, reason: '$where: tiny is a dot');
          expect(painter.dot, glyphColor, reason: '$where: dot');
        } else {
          expect(painter.dot, isNull, reason: '$where: no dot');
          final icon = tester.widget<Icon>(iconFinder);
          expect(icon.color, glyphColor, reason: '$where: glyph colour');
          expect(
            icon.size,
            variant.size.width,
            reason: '$where: glyph fills the badge',
          );
          final expectedGlyph = variant.token('glyphIcon');
          if (expectedGlyph != null) {
            expect(
              icon.icon,
              glyphs[expectedGlyph],
              reason: '$where: glyph ($expectedGlyph)',
            );
          }
        }
      }
    });

    testWidgets('out of office swaps the glyph, not only the colour', (
      tester,
    ) async {
      // The two cases nobody guesses right: away goes berry-and-OOF, and busy
      // borrows the *unknown* glyph while keeping the danger colour.
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      Future<Icon> glyphFor(FluentPresenceStatus s, {required bool oof}) async {
        await pump(
          tester,
          FluentPresenceBadge(key: key, status: s, outOfOffice: oof),
          theme: theme,
        );
        return tester.widget<Icon>(
          find.descendant(of: find.byKey(key), matching: find.byType(Icon)),
        );
      }

      final away = await glyphFor(FluentPresenceStatus.away, oof: true);
      expect(away.icon, FluentIcons.presence_oof_16_regular);
      expect(away.color, theme.colors.statusOofForeground3);

      final busy = await glyphFor(FluentPresenceStatus.busy, oof: true);
      expect(busy.icon, FluentIcons.presence_unknown_16_regular);
      expect(busy.color, theme.colors.statusDangerBackground3);

      final blocked = await glyphFor(FluentPresenceStatus.blocked, oof: false);
      expect(
        blocked.icon,
        FluentIcons.presence_blocked_16_regular,
        reason: 'blocked has no filled glyph in either state',
      );
    });
  });

  group('Presence Badge — motion, theming and semantics', () {
    testWidgets('there is no transition; the glyph changes on the frame', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        const FluentPresenceBadge(
          key: key,
          status: FluentPresenceStatus.available,
        ),
        theme: theme,
      );
      await pump(
        tester,
        const FluentPresenceBadge(key: key, status: FluentPresenceStatus.busy),
        theme: theme,
      );
      final icon = tester.widget<Icon>(
        find.descendant(of: find.byKey(key), matching: find.byType(Icon)),
      );
      expect(icon.color, theme.colors.statusDangerBackground3);
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FluentAnimatedStyle<Color>),
        ),
        findsNothing,
      );
    });

    testWidgets('a subtree override reaches the ring and the glyph', (
      tester,
    ) async {
      const paper = Color(0xFFFAF7F0);
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: const FluentThemeOverride(
            colors: {
              FluentColorToken.neutralBackground1: paper,
              FluentColorToken.statusDangerBackground3: magenta,
            },
            child: Center(
              child: FluentPresenceBadge(
                key: key,
                status: FluentPresenceStatus.busy,
              ),
            ),
          ),
        ),
      );
      expect(painterOf(tester).ring, paper);
      expect(
        tester
            .widget<Icon>(
              find.descendant(of: find.byKey(key), matching: find.byType(Icon)),
            )
            .color,
        magenta,
      );
    });

    testWidgets('high contrast keeps ring and glyph fully opaque', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      for (final status in statuses.values) {
        await pump(
          tester,
          FluentPresenceBadge(key: key, status: status),
          theme: theme,
        );
        expect(painterOf(tester).ring!.a, 1.0, reason: '${status.name}: ring');
        final icon = tester.widget<Icon>(
          find.descendant(of: find.byKey(key), matching: find.byType(Icon)),
        );
        expect(icon.color!.a, 1.0, reason: '${status.name}: glyph');
        expect(
          icon.color,
          isNot(painterOf(tester).ring),
          reason: '${status.name}: glyph must not vanish into the ring',
        );
      }
    });

    testWidgets('every status announces itself', (tester) async {
      await pump(
        tester,
        const FluentPresenceBadge(
          key: key,
          status: FluentPresenceStatus.doNotDisturb,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(label: 'Do not disturb'),
      );

      await pump(
        tester,
        const FluentPresenceBadge(
          key: key,
          status: FluentPresenceStatus.available,
          outOfOffice: true,
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(label: 'Available out of office'),
      );

      await pump(
        tester,
        const FluentPresenceBadge(
          key: key,
          status: FluentPresenceStatus.available,
          semanticLabel: 'Ada is available',
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        matchesSemantics(label: 'Ada is available'),
      );
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentPresenceBadgeState(
        status: FluentPresenceStatus.available,
        size: FluentPresenceBadgeSize.large,
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      const ink = Color(0xFF101010);
      final adjusted = resolveFluentPresenceBadgeStyle(
        state,
        theme,
      ).merge(FluentPresenceBadgeStyle.from(borderColor: ink));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentPresenceBadge(
            state,
            adjusted,
            const <WidgetState>{},
          ),
        ),
      );
      expect(painterOf(tester).ring, ink);
      expect(tester.getSize(find.byKey(key)), const Size(20, 20));
    });
  });
}

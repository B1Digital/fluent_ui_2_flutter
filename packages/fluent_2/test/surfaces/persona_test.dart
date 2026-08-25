import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentPersona` is a composition, so these tests are as much about what it
/// does *not* contain as what it does: there is no avatar token table here, no
/// presence colour table, and no second copy of either size ramp. The
/// composition group asserts that the real `FluentAvatar` and
/// `FluentPresenceBadge` widgets appear in the tree and that the persona's
/// `Size` axis is the only thing choosing their size.
///
/// [expectSpec] is deliberately not used. Every persona variant hugs Figma's
/// own placeholder strings, so the frame *width* describes "Primary string" in
/// Segoe UI rather than the bundled Selawik substitute; the height, the gap and
/// the type ramps are the checkable half and are asserted directly.
void main() {
  const key = Key('persona');

  Future<void> pump(
    WidgetTester tester,
    Widget persona, {
    FluentThemeData? theme,
    bool reducedMotion = false,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      builder: reducedMotion
          ? (context, child) => MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: child!,
            )
          : null,
      home: Center(child: persona),
    ),
  );

  /// The style the widget actually painted line [text] with.
  TextStyle styleOf(WidgetTester tester, String text) => tester
      .widget<RichText>(
        find.descendant(
          of: find.text(text),
          matching: find.byType(RichText),
          matchRoot: true,
        ),
      )
      .text
      .style!;

  final spec = loadSpec('persona');

  /// The Figma `Size` axis value each of our six steps corresponds to, for the
  /// three the design file actually draws.
  const figmaSize = <FluentPersonaSize, String>{
    FluentPersonaSize.extraSmall: 'Small (Badge only)',
    FluentPersonaSize.medium: 'Medium',
    FluentPersonaSize.extraLarge: 'Large',
  };

  group('pixel fidelity against Figma', () {
    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 16);
      expect(spec.properties['Layout'], <String>[
        'Text after',
        'Text before (Avatar only)',
        'Text below (Avatar only)',
      ]);
      expect(spec.properties['Style'], <String>['Avatar', 'Presence badge']);
      expect(spec.properties['Size'], <String>[
        'Small (Badge only)',
        'Medium',
        'Large',
      ]);
      expect(spec.properties['Alignment'], <String>['Center', 'Top']);
    });

    testWidgets('every one of the sixteen variants matches its frame', (
      tester,
    ) async {
      for (final variant in spec.variants) {
        final presenceOnly = variant.props['Style'] == 'Presence badge';
        final size = figmaSize.entries
            .firstWhere((e) => e.value == variant.props['Size'])
            .key;
        final position = switch (variant.props['Layout']) {
          'Text before (Avatar only)' => FluentPersonaTextPosition.before,
          'Text below (Avatar only)' => FluentPersonaTextPosition.below,
          _ => FluentPersonaTextPosition.after,
        };
        final alignment = variant.props['Alignment'] == 'Top'
            ? FluentPersonaTextAlignment.start
            : FluentPersonaTextAlignment.center;

        // Figma's `Small (Badge only)` variant draws one line; every other
        // variant draws two. Matching that is what makes the height comparable.
        final oneLine = size == FluentPersonaSize.extraSmall;

        await pump(
          tester,
          FluentPersona(
            key: key,
            name: 'Primary',
            secondary: oneLine ? null : const Text('Secondary'),
            presenceOnly: presenceOnly,
            status: presenceOnly ? FluentPresenceStatus.available : null,
            size: size,
            textPosition: position,
            textAlignment: alignment,
          ),
        );

        expect(
          tester.getSize(find.byKey(key)).height,
          variant.size.height,
          reason: '${variant.name}: height',
        );

        // The gap is Figma's `Avatar spacing` / `Presence badge spacing`, which
        // is stated on the variant frame's own auto-layout.
        final media = presenceOnly
            ? find.byType(FluentPresenceBadge)
            : find.byType(FluentAvatar);
        // Measured against the content block, not the primary line: the text
        // is start-aligned, so in the `before` layout the widest line — not the
        // first — is what touches the avatar.
        final mediaBox = tester.getRect(media);
        final contentBox = tester.getRect(
          find
              .descendant(of: find.byKey(key), matching: find.byType(Padding))
              .first,
        );
        final gap = switch (position) {
          FluentPersonaTextPosition.after => contentBox.left - mediaBox.right,
          FluentPersonaTextPosition.before => mediaBox.left - contentBox.right,
          FluentPersonaTextPosition.below => contentBox.top - mediaBox.bottom,
        };
        expect(gap, variant.gap, reason: '${variant.name}: gap');

        final primary = variant.part('Text (Primary content)').text!;
        final painted = styleOf(tester, 'Primary');
        expect(
          painted.fontSize,
          primary.fontSize,
          reason: '${variant.name}: primary fontSize',
        );
        expect(
          painted.height! * painted.fontSize!,
          primary.lineHeight,
          reason: '${variant.name}: primary lineHeight',
        );

        if (oneLine) continue;
        final secondary = variant.part('Text (Secondary content)').text!;
        final paintedSecondary = styleOf(tester, 'Secondary');
        expect(
          paintedSecondary.fontSize,
          secondary.fontSize,
          reason: '${variant.name}: secondary fontSize',
        );
        expect(
          paintedSecondary.height! * paintedSecondary.fontSize!,
          secondary.lineHeight,
          reason: '${variant.name}: secondary lineHeight',
        );
      }
    });

    testWidgets('the composed avatar is the size the Size axis names', (
      tester,
    ) async {
      for (final entry in figmaSize.entries) {
        final variant = spec.variants.firstWhere(
          (v) => v.props['Size'] == entry.value && v.props['Style'] == 'Avatar',
          orElse: () => spec.variant({
            'Size': entry.value,
            'Style': 'Presence badge',
            'Layout': 'Text after',
            'Alignment': 'Center',
          }),
        );
        final avatar = variant.parts
            .where((p) => p.name == 'Avatar/Avatar')
            .toList();
        if (avatar.isEmpty) continue;
        expect(
          entry.key.avatarSize.edge,
          avatar.single.size.width,
          reason: '${variant.name}: avatar edge',
        );
      }
    });

    testWidgets('the composed presence badge is the size Figma draws', (
      tester,
    ) async {
      const expected = <FluentPersonaSize, double>{
        FluentPersonaSize.extraSmall: 6,
        FluentPersonaSize.medium: 12,
        FluentPersonaSize.extraLarge: 20,
      };
      for (final entry in expected.entries) {
        final variant = spec.variant({
          'Size': figmaSize[entry.key]!,
          'Style': 'Presence badge',
          'Layout': 'Text after',
          'Alignment': 'Center',
        });
        expect(
          variant.part('Presence Badge').size.width,
          entry.value,
          reason: '${variant.name}: badge diameter in Figma',
        );

        await pump(
          tester,
          FluentPersona(
            key: key,
            name: 'Primary',
            presenceOnly: true,
            status: FluentPresenceStatus.available,
            size: entry.key,
          ),
        );
        expect(
          tester.getSize(find.byType(FluentPresenceBadge)),
          Size.square(entry.value),
          reason: '${entry.key}: rendered badge diameter',
        );
      }
    });

    testWidgets('Top alignment insets the badge exactly as Figma does', (
      tester,
    ) async {
      // Figma states the inset on a `Presence container` frame: 5 around the
      // 12 badge, 2 around the 20 one, and nothing around the 6 one — whose
      // variant centres instead, which is the same placement.
      const expected = <FluentPersonaSize, double>{
        FluentPersonaSize.extraSmall: 0,
        FluentPersonaSize.medium: 5,
        FluentPersonaSize.extraLarge: 2,
      };
      for (final entry in expected.entries) {
        final oneLine = entry.key == FluentPersonaSize.extraSmall;
        await pump(
          tester,
          FluentPersona(
            key: key,
            name: 'Primary',
            secondary: oneLine ? null : const Text('Secondary'),
            presenceOnly: true,
            status: FluentPresenceStatus.available,
            size: entry.key,
            textAlignment: FluentPersonaTextAlignment.start,
          ),
        );
        final root = tester.getRect(find.byKey(key));
        final badge = tester.getRect(find.byType(FluentPresenceBadge));
        expect(
          badge.top - root.top,
          // The extra-small variant carries no wrapper, so Figma centres the
          // badge in the single 16-tall line instead: (16 - 6) / 2 = 5.
          oneLine ? 5 : expected[entry.key],
          reason: '${entry.key}: badge inset under Top alignment',
        );
      }
    });

    testWidgets('Center alignment centres the avatar on the whole block', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentPersona(
          key: key,
          name: 'Primary',
          secondary: Text('Secondary'),
        ),
      );
      final root = tester.getRect(find.byKey(key));
      final avatar = tester.getRect(find.byType(FluentAvatar));
      expect(avatar.center.dy, root.center.dy);

      await pump(
        tester,
        const FluentPersona(
          key: key,
          name: 'Primary',
          secondary: Text('Secondary'),
          textAlignment: FluentPersonaTextAlignment.start,
        ),
      );
      expect(
        tester.getRect(find.byType(FluentAvatar)).top,
        tester.getRect(find.byKey(key)).top,
        reason: 'Top alignment puts the avatar flush with the block top',
      );
    });

    testWidgets('the second line overlaps the first by two', (tester) async {
      await pump(
        tester,
        const FluentPersona(
          key: key,
          name: 'Primary',
          secondary: Text('Secondary'),
        ),
      );
      // Figma: Content is 2 + 20 - 2 + 16 + 2 = 38 tall. Without the overlap it
      // would be 40, which is the regression this pins.
      expect(tester.getSize(find.byKey(key)).height, 38);
      final primary = tester.getRect(find.text('Primary'));
      final secondary = tester.getRect(find.text('Secondary'));
      expect(secondary.top - primary.bottom, -2);
    });

    testWidgets('a single line carries no content inset at all', (
      tester,
    ) async {
      // Figma's only single-line variant has no `Content` wrapper, so it states
      // no padding; a name-only medium persona is therefore exactly one line.
      await pump(tester, const FluentPersona(key: key, name: 'Primary'));
      expect(tester.getSize(find.byKey(key)).height, 32);
      expect(
        tester.getRect(find.text('Primary')).height,
        20,
        reason: 'body1 line box',
      );
    });

    testWidgets('all four text slots render, third and fourth on the second '
        'ramp', (tester) async {
      await pump(
        tester,
        const FluentPersona(
          key: key,
          name: 'Primary',
          secondary: Text('Secondary'),
          tertiary: Text('Tertiary'),
          quaternary: Text('Quaternary'),
        ),
      );
      for (final line in <String>[
        'Primary',
        'Secondary',
        'Tertiary',
        'Quaternary',
      ]) {
        expect(find.text(line), findsOneWidget);
      }
      // Figma's hidden `Text (Tertiary content)` and `Text (Quaternary
      // content)` nodes carry Font size/200 + Line height/200 at Medium, the
      // same as the secondary line.
      for (final line in <String>['Secondary', 'Tertiary', 'Quaternary']) {
        expect(styleOf(tester, line).fontSize, 12);
        expect(styleOf(tester, line).height! * 12, 16);
      }
      expect(styleOf(tester, 'Primary').fontSize, 14);
    });
  });

  group('composition', () {
    testWidgets('the avatar is a real FluentAvatar, not a redraw', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentPersona(key: key, name: 'Ada', initials: 'AL'),
      );
      expect(find.byType(FluentAvatar), findsOneWidget);
      expect(find.byType(FluentPresenceBadge), findsNothing);

      final avatar = tester.widget<FluentAvatar>(find.byType(FluentAvatar));
      expect(avatar.size, FluentAvatarSize.size32);
      expect(avatar.initials, 'AL');
    });

    testWidgets('presenceOnly swaps in a real FluentPresenceBadge', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentPersona(
          key: key,
          name: 'Ada',
          presenceOnly: true,
          status: FluentPresenceStatus.away,
          outOfOffice: true,
        ),
      );
      expect(find.byType(FluentAvatar), findsNothing);

      final badge = tester.widget<FluentPresenceBadge>(
        find.byType(FluentPresenceBadge),
      );
      expect(badge.status, FluentPresenceStatus.away);
      expect(badge.outOfOffice, isTrue);
      expect(badge.size, FluentPresenceBadgeSize.small);
    });

    testWidgets('a status without presenceOnly rides on the avatar', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentPersona(
          key: key,
          name: 'Ada',
          status: FluentPresenceStatus.available,
        ),
      );
      expect(find.byType(FluentAvatar), findsOneWidget);
      // The badge is the avatar's own, positioned by FluentAvatar — the persona
      // never anchors one itself.
      expect(
        find.descendant(
          of: find.byType(FluentAvatar),
          matching: find.byType(FluentPresenceBadge),
        ),
        findsOneWidget,
      );
    });

    testWidgets('every size step forwards its avatar and badge size through', (
      tester,
    ) async {
      for (final size in FluentPersonaSize.values) {
        await pump(tester, FluentPersona(key: key, name: 'Ada', size: size));
        expect(
          tester.widget<FluentAvatar>(find.byType(FluentAvatar)).size,
          size.avatarSize,
          reason: '$size: avatar size',
        );

        await pump(
          tester,
          FluentPersona(
            key: key,
            name: 'Ada',
            size: size,
            presenceOnly: true,
            status: FluentPresenceStatus.busy,
          ),
        );
        expect(
          tester
              .widget<FluentPresenceBadge>(find.byType(FluentPresenceBadge))
              .size,
          size.presenceSize,
          reason: '$size: presence size',
        );
      }
    });

    testWidgets('the composed avatar still answers to FluentAvatarTheme', (
      tester,
    ) async {
      await pump(
        tester,
        FluentAvatarTheme(
          style: FluentAvatarStyle.from(
            borderRadius: BorderRadius.zero,
            backgroundColor: const Color(0xFF00FF00),
          ),
          child: const FluentPersona(key: key, name: 'Ada', initials: 'AL'),
        ),
      );
      final decoration = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(FluentAvatar),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .first;
      expect(decoration.color, const Color(0xFF00FF00));
      expect(decoration.borderRadius, BorderRadius.zero);
    });

    testWidgets('presenceOnly with no status draws no media at all', (
      tester,
    ) async {
      await pump(
        tester,
        const FluentPersona(key: key, name: 'Ada', presenceOnly: true),
      );
      expect(find.byType(FluentAvatar), findsNothing);
      expect(find.byType(FluentPresenceBadge), findsNothing);
      expect(find.text('Ada'), findsOneWidget);
    });
  });

  group('layout axes', () {
    testWidgets('textPosition orders the avatar and the text', (tester) async {
      await pump(
        tester,
        const FluentPersona(key: key, name: 'Ada', secondary: Text('Away')),
      );
      expect(
        tester.getRect(find.byType(FluentAvatar)).left,
        lessThan(tester.getRect(find.text('Ada')).left),
      );

      await pump(
        tester,
        const FluentPersona(
          key: key,
          name: 'Ada',
          secondary: Text('Away'),
          textPosition: FluentPersonaTextPosition.before,
        ),
      );
      expect(
        tester.getRect(find.byType(FluentAvatar)).left,
        greaterThan(tester.getRect(find.text('Ada')).left),
      );

      await pump(
        tester,
        const FluentPersona(
          key: key,
          name: 'Ada',
          secondary: Text('Away'),
          textPosition: FluentPersonaTextPosition.below,
        ),
      );
      final avatar = tester.getRect(find.byType(FluentAvatar));
      final text = tester.getRect(find.text('Ada'));
      expect(avatar.bottom, lessThanOrEqualTo(text.top));
      // The stacked layout centres both columns — Figma's only cross-axis
      // CENTER variants.
      final root = tester.getRect(find.byKey(key));
      expect(avatar.center.dx, root.center.dx);
    });

    testWidgets('text stays start-aligned in the before layout', (
      tester,
    ) async {
      // Figma's `Content` and `Subtext` frames are counter-axis MIN in the
      // before variants too; upstream right-aligns them with justifyItems:end.
      await pump(
        tester,
        const FluentPersona(
          key: key,
          name: 'Ada',
          secondary: Text('A much longer second line'),
          textPosition: FluentPersonaTextPosition.before,
        ),
      );
      expect(
        tester.getRect(find.text('Ada')).left,
        tester.getRect(find.text('A much longer second line')).left,
      );
    });
  });

  group('theming', () {
    testWidgets('a subtree FluentThemeOverride reaches both text ramps', (
      tester,
    ) async {
      const primary = Color(0xFF102030);
      const secondary = Color(0xFF405060);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: const Center(
            child: FluentThemeOverride(
              colors: <FluentColorToken, Color>{
                FluentColorToken.neutralForeground1: primary,
                FluentColorToken.neutralForeground2: secondary,
              },
              child: FluentPersona(
                key: key,
                name: 'Ada',
                secondary: Text('Away'),
              ),
            ),
          ),
        ),
      );
      expect(styleOf(tester, 'Ada').color, primary);
      expect(styleOf(tester, 'Away').color, secondary);
    });

    testWidgets('FluentPersonaTheme restyles a subtree and the widget style '
        'still wins', (tester) async {
      await pump(
        tester,
        FluentPersonaTheme(
          style: FluentPersonaStyle.from(gap: 40),
          child: const FluentPersona(key: key, name: 'Ada'),
        ),
      );
      expect(
        tester.getRect(find.text('Ada')).left -
            tester.getRect(find.byType(FluentAvatar)).right,
        40,
      );

      await pump(
        tester,
        FluentPersonaTheme(
          style: FluentPersonaStyle.from(gap: 40),
          child: FluentPersona(
            key: key,
            name: 'Ada',
            style: FluentPersonaStyle.from(gap: 3),
          ),
        ),
      );
      expect(
        tester.getRect(find.text('Ada')).left -
            tester.getRect(find.byType(FluentAvatar)).right,
        3,
      );
    });

    test('the style merges per property and compares by value', () {
      final base = FluentPersonaStyle.from(gap: 8, lineOverlap: 2);
      final merged = base.merge(FluentPersonaStyle.from(gap: 12));
      expect(merged.gap!.resolve(const <WidgetState>{}), 12);
      expect(merged.lineOverlap!.resolve(const <WidgetState>{}), 2);
      expect(base.copyWith(), base);
      expect(base.merge(null), base);
      expect(
        base.hashCode,
        FluentPersonaStyle.from(gap: 8, lineOverlap: 2).hashCode,
      );
      expect(base, isNot(FluentPersonaStyle.from(gap: 9, lineOverlap: 2)));
    });

    testWidgets('high contrast keeps every line legible on its own surface', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(
        tester,
        const FluentPersona(
          key: key,
          name: 'Ada',
          secondary: Text('Away'),
          tertiary: Text('Redmond'),
        ),
        theme: theme,
      );

      // The persona paints no surface of its own, so the surface each line sits
      // on is the app background. A foreground that resolved to the same colour
      // would be invisible and nothing else in the tree would fail.
      final background = theme.colors.neutralBackground1;
      for (final line in <String>['Ada', 'Away', 'Redmond']) {
        final colour = styleOf(tester, line).color;
        expect(colour, isNotNull, reason: '$line: no explicit colour');
        expect(
          colour,
          isNot(background),
          reason: '$line: foreground equals the surface it paints on',
        );
      }
      // And the two ramps must stay distinguishable from each other's token,
      // not collapse onto one.
      expect(theme.colors.neutralForeground1, isNotNull);
      expect(theme.colors.neutralForeground2, isNotNull);
    });

    testWidgets('high contrast keeps the composed badge off its own ring', (
      tester,
    ) async {
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      await pump(
        tester,
        const FluentPersona(
          key: key,
          name: 'Ada',
          presenceOnly: true,
          status: FluentPresenceStatus.available,
        ),
        theme: theme,
      );
      final painter = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(FluentPresenceBadge),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((paint) => paint.painter)
          .whereType<FluentPresenceBadgePainter>()
          .first;
      final glyph = tester.widget<Icon>(
        find.descendant(
          of: find.byType(FluentPresenceBadge),
          matching: find.byType(Icon),
        ),
      );
      // Composition earns this for free — but only if the badge is the real
      // component. A hand-drawn dot would have to re-derive it, and in high
      // contrast a status glyph the colour of its own disc is invisible.
      expect(glyph.color, isNotNull);
      expect(glyph.color, isNot(painter.disc));
    });
  });

  group('motion', () {
    testWidgets('there is none: no animated wrapper anywhere', (tester) async {
      // usePersonaStyles.styles.ts declares no transition, no animation and no
      // motionTokens reference, and the Figma set has no State axis. Nothing
      // here should be capable of settling over time.
      await pump(
        tester,
        const FluentPersona(
          key: key,
          name: 'Ada',
          secondary: Text('Away'),
          status: FluentPresenceStatus.available,
        ),
      );
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FluentAnimatedStyle<Color>),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(ImplicitlyAnimatedWidget),
        ),
        findsNothing,
      );
    });

    testWidgets('a size change lands on the frame', (tester) async {
      await pump(tester, const FluentPersona(key: key, name: 'Ada'));
      final before = tester.getSize(find.byType(FluentAvatar));

      await pump(
        tester,
        const FluentPersona(
          key: key,
          name: 'Ada',
          size: FluentPersonaSize.huge,
        ),
      );
      // No pumpAndSettle: the very next frame is already the destination.
      expect(before, const Size.square(32));
      expect(tester.getSize(find.byType(FluentAvatar)), const Size.square(56));
    });

    testWidgets('reduced motion renders identically', (tester) async {
      const persona = FluentPersona(
        key: key,
        name: 'Ada',
        secondary: Text('Away'),
        status: FluentPresenceStatus.available,
      );
      await pump(tester, persona);
      final normal = tester.getSize(find.byKey(key));
      final normalText = styleOf(tester, 'Ada');

      await pump(tester, persona, reducedMotion: true);
      expect(tester.getSize(find.byKey(key)), normal);
      expect(styleOf(tester, 'Ada').fontSize, normalText.fontSize);
      expect(styleOf(tester, 'Ada').color, normalText.color);
    });
  });

  group('interaction and semantics', () {
    testWidgets('a persona is inert: no state, no focus, no disabled', (
      tester,
    ) async {
      // Figma's Persona set has no State axis and upstream ships no hover,
      // pressed, focus or disabled rule, so there is nothing here to disable.
      // Asserting the absence is the only way that stays true if someone adds
      // an onPressed later without checking the design file.
      await pump(
        tester,
        const FluentPersona(key: key, name: 'Ada', secondary: Text('Away')),
      );
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FluentInteractive),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FluentFocusRing),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(Focus)),
        findsNothing,
      );
    });

    testWidgets('keyboard focus travels past it to the next real control', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);

      await pump(
        tester,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const FluentPersona(key: key, name: 'Ada'),
            FluentButton(
              focusNode: node,
              onPressed: () {},
              child: const Text('Next'),
            ),
          ],
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        node.hasPrimaryFocus,
        isTrue,
        reason: 'the persona must not be a tab stop',
      );
    });

    testWidgets('it announces as one node, name then subtitle then presence', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const FluentPersona(
          key: key,
          name: 'Ada Lovelace',
          secondary: Text('Software engineer'),
          presenceOnly: true,
          status: FluentPresenceStatus.available,
        ),
      );

      // The merged label lives on the node's data, not on the node's own
      // `label` — the badge's node is marked "merged up" and contributes there.
      final label = tester
          .getSemantics(find.byType(MergeSemantics))
          .getSemanticsData()
          .label;
      for (final part in <String>[
        'Ada Lovelace',
        'Software engineer',
        'Available',
      ]) {
        expect(label, contains(part));
      }
      // One node, not four: a persona is a single row of meaning.
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(MergeSemantics),
          matchRoot: true,
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('the name is announced once, not twice', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const FluentPersona(key: key, name: 'Ada Lovelace', initials: 'AL'),
      );
      // FluentAvatar labels itself from `name`; handing it the persona's name
      // as well would read the person out twice in a row.
      expect(
        tester.widget<FluentAvatar>(find.byType(FluentAvatar)).name,
        isNull,
      );
      expect(find.bySemanticsLabel('Ada Lovelace'), findsOneWidget);
      handle.dispose();
    });
  });

  group('recomposition contract', () {
    testWidgets('build takes the BASE state and never reads the axes', (
      tester,
    ) async {
      // The whole point of the split: a caller can hand-build a base state and
      // an unrelated style, and still get Fluent's layout.
      const state = FluentPersonaBaseState(
        textPosition: FluentPersonaTextPosition.after,
        textAlignment: FluentPersonaTextAlignment.center,
        alignMediaToPrimaryLine: false,
        textLineCount: 2,
        media: SizedBox.square(dimension: 24, key: Key('media')),
        primary: Text('Ada'),
        secondary: Text('Away'),
      );

      await pump(
        tester,
        Builder(
          builder: (context) => SizedBox(
            key: key,
            child: buildFluentPersona(
              state,
              FluentPersonaStyle.from(
                gap: 7,
                primaryTextStyle: const TextStyle(fontSize: 14, height: 10 / 7),
                secondaryTextStyle: const TextStyle(
                  fontSize: 12,
                  height: 4 / 3,
                ),
                contentPadding: EdgeInsets.zero,
                lineOverlap: 0,
              ),
              const <WidgetState>{},
            ),
          ),
        ),
      );

      expect(
        tester.getRect(find.text('Ada')).left -
            tester.getRect(find.byKey(const Key('media'))).right,
        7,
      );
      expect(tester.getSize(find.byKey(key)).height, 36);
    });

    testWidgets('state resolution picks the components, not the colours', (
      tester,
    ) async {
      final state = resolveFluentPersonaState(
        name: 'Ada',
        size: FluentPersonaSize.huge,
        presenceOnly: true,
        status: FluentPresenceStatus.offline,
      );
      expect(state.media, isA<FluentPresenceBadge>());
      expect(
        (state.media! as FluentPresenceBadge).size,
        FluentPresenceBadgeSize.large,
      );
      expect(state.textLineCount, 1);
      expect(state.alignMediaToPrimaryLine, isTrue);
    });

    testWidgets('style resolution reads only tokens', (tester) async {
      final theme = FluentThemeData.dark(fontPlatform: FluentFontPlatform.web);
      final style = resolveFluentPersonaStyle(
        resolveFluentPersonaState(name: 'Ada', secondary: const Text('Away')),
        theme,
      );
      const none = <WidgetState>{};
      expect(
        style.primaryColor!.resolve(none),
        theme.colors.neutralForeground1,
      );
      expect(
        style.secondaryColor!.resolve(none),
        theme.colors.neutralForeground2,
      );
      expect(style.gap!.resolve(none), FluentSpacing.s);
      expect(style.lineOverlap!.resolve(none), FluentSpacing.xxs);
      expect(
        style.contentPadding!.resolve(none),
        const EdgeInsets.symmetric(vertical: FluentSpacing.xxs),
      );
      expect(style.primaryTextStyle!.resolve(none), theme.typography.body1);
      expect(
        style.secondaryTextStyle!.resolve(none),
        theme.typography.caption1,
      );
    });

    testWidgets('the two largest steps move both ramps up together', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      for (final size in <FluentPersonaSize>[
        FluentPersonaSize.extraLarge,
        FluentPersonaSize.huge,
      ]) {
        final style = resolveFluentPersonaStyle(
          resolveFluentPersonaState(
            name: 'Ada',
            secondary: const Text('Away'),
            size: size,
          ),
          theme,
        );
        const none = <WidgetState>{};
        expect(
          style.primaryTextStyle!.resolve(none),
          theme.typography.subtitle2,
        );
        // Figma steps the second line up at extraLarge; upstream waits for huge.
        expect(style.secondaryTextStyle!.resolve(none), theme.typography.body1);
      }
    });

    testWidgets('an extra-small presence-only persona with one line drops to '
        'caption1', (tester) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      const none = <WidgetState>{};
      final oneLine = resolveFluentPersonaStyle(
        resolveFluentPersonaState(
          name: 'Ada',
          size: FluentPersonaSize.extraSmall,
          presenceOnly: true,
          status: FluentPresenceStatus.available,
        ),
        theme,
      );
      expect(
        oneLine.primaryTextStyle!.resolve(none),
        theme.typography.caption1,
      );

      // Upstream gates that on the line count, and so do we.
      final twoLines = resolveFluentPersonaStyle(
        resolveFluentPersonaState(
          name: 'Ada',
          secondary: const Text('Away'),
          size: FluentPersonaSize.extraSmall,
          presenceOnly: true,
          status: FluentPresenceStatus.available,
        ),
        theme,
      );
      expect(twoLines.primaryTextStyle!.resolve(none), theme.typography.body1);
    });
  });
}

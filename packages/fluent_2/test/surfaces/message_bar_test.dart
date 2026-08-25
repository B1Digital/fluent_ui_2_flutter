import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/spec_fixture.dart';

/// `FluentMessageBar` is, with `FluentProgressBar`, the main consumer of the
/// ported STATUS token layer, so these tests are as much a check on
/// `theme.colors.status*` as on the widget: every intent asserts the exact
/// alias getter its Figma variable resolves to rather than a hex value.
///
/// Two things about the fixture are worth knowing before reading it.
///
/// The Figma set has a **`Layout` axis only**. The intent axis is the four
/// modes of the component-scoped `MessageBar status` variable collection, which
/// the extractor records in the fixture's `aliases` block rather than as
/// variants — `SpecFixture` does not expose that block, so the intent triples
/// are transcribed into `intentTokens` below and asserted against the theme.
///
/// And the body is **one** Figma TEXT node carrying three styled runs — a
/// semibold title, a regular message and an underlined link — so `fills` and
/// `fontName` both come back `figma.mixed`. The traversal that produced this
/// fixture splits such a node into one part per run, which is why the parts are
/// named `Text string [0 Semibold]` and so on. Every run shares the node's box,
/// so a run part's `size` is the whole node's; only its ramp and fill are its
/// own.
void main() {
  const key = Key('bar');

  const layoutNames = <FluentMessageBarLayout, String>{
    FluentMessageBarLayout.singleLine: 'Single line',
    FluentMessageBarLayout.multiLine: 'Multi line',
  };

  /// The `MessageBar status` collection, mode by mode, as the fixture's
  /// `aliases` block records it: `(background, stroke, glyph)`. The glyph token
  /// is the one the fixture cannot carry — three of the four icon layers are
  /// hidden, and the traversal skips invisible subtrees — so it was read
  /// read-only off the `Status icon container > Icon > Shape` vectors
  /// (`I9121:5947;81157:30` and its three siblings).
  const intentTokens = <FluentMessageBarIntent, (String, String, String)>{
    FluentMessageBarIntent.info: (
      'Neutral/Background/3/Rest',
      'Neutral/Stroke/1/Rest',
      'Neutral/Foreground/3/Rest',
    ),
    FluentMessageBarIntent.success: (
      'Status/Success/Background/1/Rest',
      'Status/Success/Stroke/1/Rest',
      'Status/Success/Foreground/1/Rest',
    ),
    FluentMessageBarIntent.warning: (
      'Status/Warning/Background/1/Rest',
      'Status/Warning/Stroke/1/Rest',
      'Status/Warning/Foreground/1/Rest',
    ),
    // The finding StatusIndicator taught us, confirmed a second time: the axis
    // value is Error and the token family is DANGER.
    FluentMessageBarIntent.error: (
      'Status/Danger/Background/1/Rest',
      'Status/Danger/Stroke/1/Rest',
      'Status/Danger/Foreground/1/Rest',
    ),
  };

  /// The Dart getter each Figma token name resolves to, for [theme].
  Color tokenOf(FluentThemeData theme, String figma) => switch (figma) {
    'Neutral/Background/3/Rest' => theme.colors.neutralBackground3,
    'Neutral/Stroke/1/Rest' => theme.colors.neutralStroke1,
    'Neutral/Foreground/3/Rest' => theme.colors.neutralForeground3,
    'Status/Success/Background/1/Rest' => theme.colors.statusSuccessBackground1,
    'Status/Success/Stroke/1/Rest' => theme.colors.statusSuccessBorder1,
    'Status/Success/Foreground/1/Rest' => theme.colors.statusSuccessForeground1,
    'Status/Warning/Background/1/Rest' => theme.colors.statusWarningBackground1,
    'Status/Warning/Stroke/1/Rest' => theme.colors.statusWarningBorder1,
    'Status/Warning/Foreground/1/Rest' => theme.colors.statusWarningForeground1,
    'Status/Danger/Background/1/Rest' => theme.colors.statusDangerBackground1,
    'Status/Danger/Stroke/1/Rest' => theme.colors.statusDangerBorder1,
    'Status/Danger/Foreground/1/Rest' => theme.colors.statusDangerForeground1,
    _ => throw StateError('no Dart getter mapped for $figma'),
  };

  Future<void> pump(
    WidgetTester tester,
    Widget bar, {
    FluentThemeData? theme,
    double width = 800,
  }) => tester.pumpWidget(
    FluentApp(
      theme:
          theme ?? FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
      home: Center(
        child: SizedBox(width: width, child: bar),
      ),
    ),
  );

  /// A bar carrying everything the Figma variant frame draws: a glyph, a title
  /// and body, two actions and a dismiss button. Both fixture variants are
  /// measured with all four slots filled, so a test that leaves one out no
  /// longer matches the frame.
  Widget bar({
    FluentMessageBarIntent intent = FluentMessageBarIntent.info,
    FluentMessageBarLayout layout = FluentMessageBarLayout.singleLine,
    FluentMessageBarShape shape = FluentMessageBarShape.rounded,
    FluentMessageBarStyle? style,
    bool showIcon = true,
    bool actions = true,
    bool dismissible = true,
    Widget? icon,
    Widget? title = const Text('Descriptive title'),
    VoidCallback? onDismiss,
  }) => FluentMessageBar(
    key: key,
    intent: intent,
    layout: layout,
    shape: shape,
    style: style,
    showIcon: showIcon,
    icon: icon,
    title: title,
    onDismiss: dismissible ? (onDismiss ?? () {}) : null,
    actions: actions
        ? <Widget>[
            FluentButton(
              size: FluentButtonSize.small,
              onPressed: () {},
              child: const Text('Action'),
            ),
            FluentButton(
              size: FluentButtonSize.small,
              onPressed: () {},
              child: const Text('Second'),
            ),
          ]
        : const <Widget>[],
    child: const Text('Message providing information to the user.'),
  );

  /// The bar's own surface decoration — the outermost, which is the one the
  /// fixture describes.
  BoxDecoration decorationOf(WidgetTester tester) =>
      tester
              .widgetList<DecoratedBox>(
                find.descendant(
                  of: find.byKey(key),
                  matching: find.byType(DecoratedBox),
                ),
              )
              .first
              .decoration
          as BoxDecoration;

  /// The tint and size the bar pushed down to its status glyph.
  IconThemeData iconThemeOf(WidgetTester tester) => tester
      .widgetList<IconTheme>(
        find.descendant(of: find.byKey(key), matching: find.byType(IconTheme)),
      )
      .first
      .data;

  /// The style the BODY actually painted with.
  ///
  /// Not `resolvedTextStyleOf(of: find.byKey(key))`: `Icon` renders through a
  /// `RichText` of its own, carrying the icon font at the icon's size, and it
  /// comes first in the subtree.
  TextStyle bodyTextStyleOf(WidgetTester tester) => resolvedTextStyleOf(
    tester,
    of: find.text('Message providing information to the user.'),
  );

  List<Row> rowsOf(WidgetTester tester) => tester
      .widgetList<Row>(
        find.descendant(of: find.byKey(key), matching: find.byType(Row)),
      )
      .toList();

  group('pixel fidelity against Figma', () {
    final spec = loadSpec('message_bar');

    test('the fixture covers the whole component set', () {
      expect(spec.variants.length, 2);
      expect(spec.properties['Layout'], layoutNames.values.toList());
      expect(spec.properties.keys, <String>['Layout']);
    });

    for (final layout in FluentMessageBarLayout.values) {
      testWidgets('${layoutNames[layout]} matches the variant frame', (
        tester,
      ) async {
        // Measured WITHOUT the status glyph, and that is a harness limitation
        // rather than a claim about the component: `Icon` renders through its
        // own `RichText`, so `expectSpec`'s "first RichText" would read the
        // glyph's 20px icon font instead of the 12px label. Dropping the glyph
        // changes nothing expectSpec asserts — the frame is 800 wide, its
        // height is set by the 24-high dismiss button, and padding, radius and
        // fill are the frame's own. The glyph's own box is asserted below.
        final variant = spec.variant({'Layout': layoutNames[layout]!});
        await pump(tester, bar(layout: layout, showIcon: false));
        expectSpec(tester, find.byKey(key), variant);
      });
    }

    testWidgets('the single-line row carries the frame gap', (tester) async {
      final variant = spec.variant({'Layout': 'Single line'});
      await pump(tester, bar());
      // One row, one gap: Figma binds Spacing/Horizontal/S to the variant
      // frame's itemSpacing AND to the Actions container's, so the glyph, the
      // body, each action and the dismiss button are all 8 apart.
      expect(rowsOf(tester).first.spacing, variant.gap);
      expect(variant.gap, FluentSpacing.s);
      expect(variant.part('Actions container').gap, variant.gap);
    });

    testWidgets('the multi-line stack carries the frame gap', (tester) async {
      final variant = spec.variant({'Layout': 'Multi line'});
      await pump(tester, bar(layout: FluentMessageBarLayout.multiLine));

      final column = tester.widget<Column>(
        find.descendant(of: find.byKey(key), matching: find.byType(Column)),
      );
      expect(column.spacing, variant.gap, reason: 'content row to actions row');
      expect(variant.gap, FluentSpacing.mNudge);

      // The Column's own children, not every Row in the subtree: each slotted
      // FluentButton contains a Row of its own.
      final contentRow = column.children.first as Row;
      final actionsRow = column.children.last as Row;
      expect(
        contentRow.spacing,
        variant.part('Content container').gap,
        reason: 'glyph to body to dismiss',
      );
      expect(
        actionsRow.spacing,
        variant.part('Actions container').gap,
        reason: 'action to action',
      );
      expect(
        actionsRow.mainAxisAlignment,
        MainAxisAlignment.end,
        reason: 'Figma sets the Actions container to primaryAxisAlign MAX',
      );
    });

    testWidgets('the glyph is a 20 box, inset only when multi-line', (
      tester,
    ) async {
      final single = spec.variant({'Layout': 'Single line'});
      final multi = spec.variant({'Layout': 'Multi line'});
      expect(single.part('Info').size, const Size(20, 20));
      expect(multi.part('Info').size, const Size(20, 20));

      await pump(tester, bar());
      expect(iconThemeOf(tester).size, FluentSize.size200);
      expect(
        tester
            .widgetList<Padding>(
              find.descendant(
                of: find.byKey(key),
                matching: find.byType(Padding),
              ),
            )
            .elementAt(1)
            .padding,
        EdgeInsets.zero,
        reason: 'a single-line row centres instead of insetting',
      );

      // Multi-line offsets the glyph by 2 and the body by 4, which is what
      // centres both against the 24-high dismiss button while keeping the glyph
      // beside the FIRST line of a wrapped body.
      expect(
        multi.part('Status icon container').padding!.top,
        FluentSpacing.xxs,
      );
      expect(multi.part('Text container').padding!.top, FluentSpacing.xs);

      await pump(tester, bar(layout: FluentMessageBarLayout.multiLine));
      final paddings = tester
          .widgetList<Padding>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(Padding),
            ),
          )
          .toList();
      expect(
        paddings[1].padding,
        const EdgeInsets.only(top: FluentSpacing.xxs),
      );
      expect(paddings[2].padding, const EdgeInsets.only(top: FluentSpacing.xs));
    });

    testWidgets('the type ramp is caption1Strong over caption1', (
      tester,
    ) async {
      // The divergence most likely to be "corrected" from React, which uses
      // body1Strong over body1 (14/20). Figma's single text node is 12/16 in
      // both runs; only the weight changes.
      final variant = spec.variant({'Layout': 'Single line'});
      final title = variant.part('Text string [0 Semibold]').text!;
      final body = variant.part('Text string [1 Regular]').text!;
      expect((title.fontSize, title.lineHeight), (12.0, 16.0));
      expect((body.fontSize, body.lineHeight), (12.0, 16.0));
      expect(title.fontStyle, 'Semibold');
      expect(body.fontStyle, 'Regular');

      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final style = resolveFluentMessageBarStyle(
        resolveFluentMessageBarState(body: const Text('m')),
        theme,
      );
      const empty = <WidgetState>{};
      expect(
        style.titleTextStyle!.resolve(empty),
        theme.typography.caption1Strong,
      );
      expect(style.textStyle!.resolve(empty), theme.typography.caption1);
      expect(theme.typography.caption1Strong.fontSize, title.fontSize);
      expect(theme.typography.caption1.fontSize, body.fontSize);
      expect(
        theme.typography.caption1Strong.fontWeight!.value >
            theme.typography.caption1.fontWeight!.value,
        isTrue,
        reason: 'the title run is Semibold and the body run Regular',
      );

      await pump(tester, bar());
      final painted = bodyTextStyleOf(tester);
      expect(painted.fontSize, body.fontSize);
      expect(
        painted.height! * body.fontSize,
        body.lineHeight,
        reason: 'line height must be explicit, not left to the font metric',
      );
    });

    testWidgets('the dismiss button is a 24 square around a 20 glyph', (
      tester,
    ) async {
      final variant = spec.variant({'Layout': 'Single line'});
      final button = variant.part('Button');
      expect(button.size, const Size(24, 24));
      expect(button.padding, const EdgeInsets.all(FluentSpacing.xxs));
      expect(button.radius, FluentRadius.allMedium);
      // Neutral/Background/Transparent/Rest. Figma stores a fully transparent
      // token as transparent WHITE and core as transparent black, so only the
      // alpha is comparable — see doc/token-divergences.md.
      expect(button.fill!.a, 0);

      await pump(tester, bar());
      expect(
        tester.getSize(find.bySemanticsLabel('Dismiss')),
        const Size(24, 24),
      );
    });

    test('every action slot is the same box in both layouts', () {
      // Not rendered by this component — actions are caller-supplied widgets —
      // but pinned so a future FluentButton change that moves the small ramp is
      // noticed here rather than in a screenshot.
      for (final variant in spec.variants) {
        final action = variant.part('Action');
        expect(action.size, const Size(66, 24), reason: variant.name);
        expect(
          action.padding,
          const EdgeInsets.symmetric(
            horizontal: FluentSpacing.m,
            vertical: FluentSpacing.xxs,
          ),
          reason: variant.name,
        );
      }
    });
  });

  group('intent to token mapping', () {
    testWidgets('each intent selects the three tokens Figma bound to it', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      for (final entry in intentTokens.entries) {
        final (background, border, glyph) = entry.value;
        await pump(tester, bar(intent: entry.key), theme: theme);

        final decoration = decorationOf(tester);
        expect(
          decoration.color,
          tokenOf(theme, background),
          reason: '${entry.key.name}: background must be $background',
        );
        expect(
          (decoration.border! as Border).top.color,
          tokenOf(theme, border),
          reason: '${entry.key.name}: border must be $border',
        );
        expect(
          iconThemeOf(tester).color,
          tokenOf(theme, glyph),
          reason: '${entry.key.name}: glyph must be $glyph',
        );
        expect(
          bodyTextStyleOf(tester).color,
          theme.colors.neutralForeground1,
          reason: '${entry.key.name}: Fluent tints the glyph, never the prose',
        );
      }
    });

    test('error binds the Danger family, not an Error one', () {
      // The trap this component shares with StatusIndicator. There is no
      // `statusErrorBackground1`; reaching for one does not compile, and
      // reaching for Severe compiles and is wrong.
      expect(
        intentTokens[FluentMessageBarIntent.error]!.$1,
        contains('Danger'),
      );
      expect(
        intentTokens[FluentMessageBarIntent.info]!.$1,
        contains('Neutral'),
      );
    });

    testWidgets('the default glyph follows the intent', (tester) async {
      const expected = <FluentMessageBarIntent, IconData>{
        FluentMessageBarIntent.info: FluentIcons.info_20_regular,
        FluentMessageBarIntent.success: FluentIcons.checkmark_circle_20_filled,
        FluentMessageBarIntent.warning: FluentIcons.warning_20_filled,
        FluentMessageBarIntent.error: FluentIcons.error_circle_20_filled,
      };
      for (final entry in expected.entries) {
        expect(entry.key.glyph, entry.value);
        await pump(tester, bar(intent: entry.key));
        expect(
          tester
              .widgetList<Icon>(
                find.descendant(
                  of: find.byKey(key),
                  matching: find.byType(Icon),
                ),
              )
              .first
              .icon,
          entry.value,
          reason: entry.key.name,
        );
      }
    });

    testWidgets('an explicit icon overrides the intent default', (
      tester,
    ) async {
      await pump(tester, bar(icon: const Icon(FluentIcons.person_20_regular)));
      expect(
        tester
            .widgetList<Icon>(
              find.descendant(of: find.byKey(key), matching: find.byType(Icon)),
            )
            .first
            .icon,
        FluentIcons.person_20_regular,
      );
    });

    testWidgets('showIcon: false removes the glyph and its gap', (
      tester,
    ) async {
      await pump(
        tester,
        bar(showIcon: false, actions: false, dismissible: false),
      );
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(IconTheme)),
        findsNothing,
      );
      // With the glyph the row has one; the slots are excluded above so this
      // counts only the bar's own.
      await pump(tester, bar(actions: false, dismissible: false));
      expect(
        find.descendant(of: find.byKey(key), matching: find.byType(IconTheme)),
        findsOneWidget,
      );
    });
  });

  group('shape', () {
    testWidgets('rounded is medium and square is zero', (tester) async {
      final variant = loadSpec(
        'message_bar',
      ).variant({'Layout': 'Single line'});
      await pump(tester, bar());
      expect(decorationOf(tester).borderRadius, variant.radius);
      expect(variant.radius, FluentRadius.allMedium);

      await pump(tester, bar(shape: FluentMessageBarShape.square));
      expect(decorationOf(tester).borderRadius, BorderRadius.zero);
    });

    test('there is no circular shape to select', () {
      // Figma binds `Message bar/Container` to the shared Shape collection,
      // whose third mode is Circular — but neither the component set nor
      // React's `shape` prop offers it, so neither does this enum.
      expect(FluentMessageBarShape.values, <FluentMessageBarShape>[
        FluentMessageBarShape.rounded,
        FluentMessageBarShape.square,
      ]);
    });
  });

  group('motion', () {
    testWidgets('an intent change is instant — Fluent specs no transition', (
      tester,
    ) async {
      // useMessageBarStyles.styles.ts declares no transition, no animation and
      // no motionTokens reference, and neither do the Title, Body or Actions
      // styles files. This is the Checkbox/Tooltip category in
      // FluentMotionSpec: absence, not oversight.
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(tester, bar(intent: FluentMessageBarIntent.success));
      await tester.pumpAndSettle();
      expect(decorationOf(tester).color, theme.colors.statusSuccessBackground1);

      await pump(tester, bar(intent: FluentMessageBarIntent.error));
      await tester.pump();
      expect(
        decorationOf(tester).color,
        theme.colors.statusDangerBackground1,
        reason: 'must be instant, not mid-tween',
      );
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('nothing animates under reduced motion either', (tester) async {
      // Trivially true because there is nothing to shorten, which is exactly
      // the claim worth pinning: no raw AnimationController may appear here.
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          builder: (context, child) => MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: child!,
          ),
          home: Center(
            child: SizedBox(
              width: 800,
              // No slots: a FluentButton animates its OWN surface, and that is
              // the button's spec rather than the bar's.
              child: bar(actions: false, dismissible: false),
            ),
          ),
        ),
      );
      expect(tester.hasRunningAnimations, isFalse);
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FluentAnimatedStyle<Color>),
        ),
        findsNothing,
      );
    });
  });

  group('style resolution order', () {
    testWidgets('the widget style beats the subtree theme beats the defaults', (
      tester,
    ) async {
      const themed = Color(0xFF111111);
      const explicit = Color(0xFF222222);
      await pump(
        tester,
        FluentMessageBarTheme(
          style: FluentMessageBarStyle.from(backgroundColor: themed),
          child: bar(
            style: FluentMessageBarStyle.from(backgroundColor: explicit),
          ),
        ),
      );
      expect(decorationOf(tester).color, explicit);
    });

    testWidgets('the subtree theme beats the defaults', (tester) async {
      const themed = Color(0xFF111111);
      await pump(
        tester,
        FluentMessageBarTheme(
          style: FluentMessageBarStyle.from(backgroundColor: themed),
          child: bar(),
        ),
      );
      expect(decorationOf(tester).color, themed);
    });

    testWidgets('a partial override keeps every other resolved value', (
      tester,
    ) async {
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        bar(
          intent: FluentMessageBarIntent.warning,
          style: FluentMessageBarStyle.from(gap: 17),
        ),
      );
      expect(rowsOf(tester).first.spacing, 17);
      expect(
        decorationOf(tester).color,
        theme.colors.statusWarningBackground1,
        reason: 'overriding the gap must not drop the status fill',
      );
    });

    test('merge folds the nested dismiss style per property', () {
      const base = FluentMessageBarStyle(
        dismissButtonStyle: FluentButtonStyle(
          iconSize: WidgetStatePropertyAll<double?>(20),
          minimumSize: WidgetStatePropertyAll<Size?>(Size(24, 24)),
        ),
      );
      final merged = base.merge(
        const FluentMessageBarStyle(
          dismissButtonStyle: FluentButtonStyle(
            iconSize: WidgetStatePropertyAll<double?>(12),
          ),
        ),
      );
      const empty = <WidgetState>{};
      expect(merged.dismissButtonStyle!.iconSize!.resolve(empty), 12);
      expect(
        merged.dismissButtonStyle!.minimumSize!.resolve(empty),
        const Size(24, 24),
        reason: 'overriding the glyph size must not drop the 24 square',
      );
    });
  });

  group('recomposition contract', () {
    testWidgets('build accepts BASE state, so styling can be substituted', (
      tester,
    ) async {
      const base = FluentMessageBarBaseState(
        body: Text('Message'),
        multiline: false,
        icon: Icon(FluentIcons.info_20_regular),
      );
      const mine = Color(0xFF00FF00);

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentMessageBar(
            base,
            FluentMessageBarStyle.from(
              backgroundColor: mine,
              iconColor: mine,
              iconSize: 24,
            ),
            const <WidgetState>{},
          ),
        ),
      );
      expect(decorationOf(tester).color, mine);
      expect(iconThemeOf(tester).color, mine);
      expect(iconThemeOf(tester).size, 24);
    });

    testWidgets('the style function can be reused and then adjusted', (
      tester,
    ) async {
      final state = resolveFluentMessageBarState(
        body: const Text('Message'),
        intent: FluentMessageBarIntent.error,
      );
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      final adjusted = resolveFluentMessageBarStyle(
        state,
        theme,
      ).merge(FluentMessageBarStyle.from(gap: 2));

      await pump(
        tester,
        KeyedSubtree(
          key: key,
          child: buildFluentMessageBar(state, adjusted, const <WidgetState>{}),
        ),
      );
      expect(decorationOf(tester).color, theme.colors.statusDangerBackground1);
      expect(rowsOf(tester).first.spacing, 2);
    });
  });

  group('theming', () {
    testWidgets('a single-token override reaches the bar', (tester) async {
      const magenta = Color(0xFF780510);
      await tester.pumpWidget(
        FluentApp(
          theme: FluentThemeData.light(fontPlatform: FluentFontPlatform.web),
          home: FluentThemeOverride(
            colors: const {FluentColorToken.statusDangerBackground1: magenta},
            child: Center(
              child: SizedBox(
                width: 800,
                child: bar(intent: FluentMessageBarIntent.error),
              ),
            ),
          ),
        ),
      );
      expect(decorationOf(tester).color, magenta);
    });

    testWidgets('high contrast leaves no intent without a visible border', (
      tester,
    ) async {
      // The mode nobody looks at, and the one where a bar whose only mark is a
      // tinted fill becomes an unlabelled rectangle: high contrast collapses
      // every status colour, so the border is what keeps the bar a shape.
      final theme = FluentThemeData.highContrast(
        fontPlatform: FluentFontPlatform.web,
      );
      for (final intent in FluentMessageBarIntent.values) {
        await pump(tester, bar(intent: intent), theme: theme);
        final decoration = decorationOf(tester);
        final border = (decoration.border! as Border).top;

        expect(
          border.width,
          FluentStroke.thin,
          reason: '${intent.name}: width',
        );
        expect(
          border.color.a,
          1.0,
          reason: '${intent.name}: a transparent border vanishes here',
        );
        expect(
          decoration.color!.a,
          1.0,
          reason: '${intent.name}: the surface must be opaque',
        );
        expect(
          border.color,
          isNot(decoration.color),
          reason: '${intent.name}: border and fill must not be the same colour',
        );
        expect(
          iconThemeOf(tester).color!.a,
          1.0,
          reason: '${intent.name}: the glyph must be opaque',
        );
      }
    });
  });

  group('behaviour', () {
    final spec = loadSpec('message_bar');

    test('there is no disabled state to render', () {
      // Not a gap in the port. The Figma set has a Layout axis and nothing
      // else, and useMessageBarStyles declares no hover, pressed, selected or
      // disabled rule — so disabled is not a treatment this component may
      // invent. The affordances INSIDE it disable normally; see below.
      expect(spec.properties.keys, <String>['Layout']);
    });

    testWidgets('the bar itself takes no hover, press or focus', (
      tester,
    ) async {
      await pump(tester, bar(actions: false, dismissible: false));
      expect(
        find.descendant(
          of: find.byKey(key),
          matching: find.byType(FluentInteractive),
        ),
        findsNothing,
      );
    });

    testWidgets('a disabled action is a real disabled state', (tester) async {
      // Disabled lives on the slotted affordances, and it is a state rather
      // than a treatment there: the theme's disabled ramp is selected wholesale
      // and the control announces itself as disabled.
      final theme = FluentThemeData.light(fontPlatform: FluentFontPlatform.web);
      await pump(
        tester,
        const FluentMessageBar(
          key: key,
          actions: <Widget>[
            FluentButton(size: FluentButtonSize.small, child: Text('Retry')),
          ],
          child: Text('Message'),
        ),
      );

      expect(
        tester.getSemantics(find.text('Retry')),
        isSemantics(isEnabled: false, isButton: true),
      );
      expect(
        resolvedTextStyleOf(tester, of: find.text('Retry')).color,
        theme.colors.neutralForegroundDisabled,
      );
    });

    testWidgets('the dismiss button activates from the keyboard', (
      tester,
    ) async {
      var dismissed = 0;
      await pump(tester, bar(actions: false, onDismiss: () => dismissed++));

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(dismissed, 1, reason: 'Enter must activate the dismiss button');

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(dismissed, 2, reason: 'Space must activate it too');
    });

    testWidgets('no dismiss button is rendered without onDismiss', (
      tester,
    ) async {
      await pump(tester, bar(dismissible: false, actions: false));
      expect(find.bySemanticsLabel('Dismiss'), findsNothing);
    });

    testWidgets('the bar announces itself as a live region', (tester) async {
      await pump(
        tester,
        const FluentMessageBar(
          key: key,
          intent: FluentMessageBarIntent.error,
          semanticLabel: 'Sync failed',
          child: Text('Message'),
        ),
      );
      final node = tester.getSemantics(find.byKey(key));
      expect(node, isSemantics(isLiveRegion: true));
      // The body has no node of its own, so it merges into the container's
      // label behind the explicit one.
      expect(node.label, startsWith('Sync failed'));
    });

    testWidgets('liveRegion: false silences the announcement', (tester) async {
      await pump(
        tester,
        const FluentMessageBar(
          key: key,
          liveRegion: false,
          semanticLabel: 'Quiet',
          child: Text('Message'),
        ),
      );
      expect(
        tester.getSemantics(find.byKey(key)),
        isSemantics(isLiveRegion: false),
      );
    });

    testWidgets('a single-line body never wraps', (tester) async {
      // Upstream's root is `white-space: nowrap`, flipped by rootMultiline.
      // Without it the 36-high frame would grow a second line.
      await pump(
        tester,
        bar(actions: false, dismissible: false, title: null),
        width: 120,
      );
      expect(tester.getSize(find.byKey(key)).height, 36);

      await pump(
        tester,
        bar(
          layout: FluentMessageBarLayout.multiLine,
          actions: false,
          dismissible: false,
          title: null,
        ),
        width: 120,
      );
      expect(
        tester.getSize(find.byKey(key)).height,
        greaterThan(36),
        reason: 'multi-line must wrap',
      );
    });
  });
}

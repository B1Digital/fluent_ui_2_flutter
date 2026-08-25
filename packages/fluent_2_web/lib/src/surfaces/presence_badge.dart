import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import '../internal/interaction.dart';
import '../l10n/l10n.dart';
import 'presence_badge_style.dart';

/// A person's availability. Figma's `Status` axis.
enum FluentPresenceStatus {
  /// Green. The person is reachable.
  available,

  /// Marigold when in office, berry when out of office — see
  /// [resolveFluentPresenceBadgeStyle].
  away,

  /// Red, filled.
  busy,

  /// Red, with a bar through it.
  doNotDisturb,

  /// Red, with a line through it. Never has a filled glyph.
  blocked,

  /// Neutral, hollow.
  offline,

  /// Berry. Distinct from the [outOfOffice] *flag*, which modifies any status.
  outOfOffice,

  /// Presence could not be determined.
  unknown,
}

/// Badge diameter. Figma's `Size` axis.
enum FluentPresenceBadgeSize {
  /// 6. A bare dot with no glyph at all.
  tiny,

  /// 10.
  extraSmall,

  /// 12.
  small,

  /// 16. The default.
  medium,

  /// 20.
  large,

  /// 28. Figma calls this `Extra-large huge`.
  extraLarge,
}

/// Everything needed to render a presence badge, independent of size.
///
/// The counterpart of `FluentBadgeBaseState`. [glyph] is already chosen here
/// rather than in the style, because which icon a status uses is content, not
/// styling — and because the choice is not a mechanical one: see
/// [resolveFluentPresenceBadgeState].
@immutable
class FluentPresenceBadgeBaseState {
  /// Creates a base state.
  const FluentPresenceBadgeBaseState({required this.semanticLabel, this.glyph});

  /// The status glyph, or null for a bare dot.
  final IconData? glyph;

  /// Announced by assistive technology. A presence badge is pure colour and
  /// shape, so it is never left unlabelled.
  final String semanticLabel;
}

/// A presence badge's fully resolved state, including the design axes.
@immutable
class FluentPresenceBadgeState extends FluentPresenceBadgeBaseState {
  /// Creates a resolved state.
  const FluentPresenceBadgeState({
    required super.semanticLabel,
    required this.status,
    required this.outOfOffice,
    required this.size,
    super.glyph,
  });

  /// The availability being shown.
  final FluentPresenceStatus status;

  /// Whether the person is out of office. Figma stores this inverted, as
  /// `In office`.
  final bool outOfOffice;

  /// Badge diameter.
  final FluentPresenceBadgeSize size;
}

/// Builds the state a presence badge will be styled and rendered from.
///
/// The first of the three-function recomposition contract, and the only one
/// with a real decision in it: [outOfOffice] does not simply hollow out the
/// glyph, it can *substitute* a different one. Away out of office becomes the
/// out-of-office glyph, and busy out of office becomes the **unknown** glyph
/// while keeping the danger colour. Figma and upstream React agree on both.
///
/// [semanticLabel] defaults to the status's name in [l10n]; pass your own for a
/// personalised announcement ("Ada is available"). This is a plain function
/// with no [BuildContext], so the wording arrives as a parameter:
/// [FluentPresenceBadge] passes `fluentL10n(context)`, and null takes
/// [fluentLocalizationsFallback], which is US English.
FluentPresenceBadgeState resolveFluentPresenceBadgeState({
  required FluentPresenceStatus status,
  bool outOfOffice = false,
  FluentPresenceBadgeSize size = FluentPresenceBadgeSize.medium,
  String? semanticLabel,
  FluentLocalizations? l10n,
}) => FluentPresenceBadgeState(
  status: status,
  outOfOffice: outOfOffice,
  size: size,
  glyph: _glyph(status, outOfOffice: outOfOffice, size: size),
  semanticLabel:
      semanticLabel ??
      fluentPresenceStatusLabel(
        status,
        outOfOffice: outOfOffice,
        l10n: l10n ?? fluentLocalizationsFallback,
      ),
);

/// Resolves the default style for [state] against [theme].
///
/// The second of the three-function recomposition contract, and the only one
/// that reads the design axes.
///
/// The colour mapping is worth reading rather than skimming, because three of
/// the eight statuses do not use the token their name suggests:
///
/// * **Away** takes `Status/Away/Background/3/Rest` in office but
///   `Status/Oof/Foreground/3/Rest` — berry, not marigold — out of office.
/// * **Blocked**, **busy**, **do not disturb** and **unknown** all take
///   `Status/Danger/Background/3/Rest`. Unknown being red is Figma's reading;
///   React uses a neutral there.
/// * **Offline** is the only neutral one.
FluentPresenceBadgeStyle resolveFluentPresenceBadgeStyle(
  FluentPresenceBadgeState state,
  FluentThemeData theme,
) {
  final c = theme.colors;

  final glyphColor = switch (state.status) {
    FluentPresenceStatus.available => c.statusAvailableForeground3,
    FluentPresenceStatus.away =>
      state.outOfOffice ? c.statusOofForeground3 : c.statusAwayBackground3,
    FluentPresenceStatus.busy ||
    FluentPresenceStatus.doNotDisturb ||
    FluentPresenceStatus.blocked ||
    FluentPresenceStatus.unknown => c.statusDangerBackground3,
    FluentPresenceStatus.offline => c.neutralForeground3,
    FluentPresenceStatus.outOfOffice => c.statusOofForeground3,
  };

  final diameter = switch (state.size) {
    FluentPresenceBadgeSize.tiny => 6.0,
    FluentPresenceBadgeSize.extraSmall => FluentSize.size100,
    FluentPresenceBadgeSize.small => FluentSize.size120,
    FluentPresenceBadgeSize.medium => FluentSize.size160,
    FluentPresenceBadgeSize.large => FluentSize.size200,
    FluentPresenceBadgeSize.extraLarge => FluentSize.size280,
  };

  return FluentPresenceBadgeStyle(
    backgroundColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    foregroundColor: FluentStateColor.tokens(rest: glyphColor),
    borderColor: FluentStateColor.tokens(rest: c.neutralBackground1),
    borderWidth: WidgetStatePropertyAll<double?>(
      state.size == FluentPresenceBadgeSize.tiny
          ? FluentStroke.thin
          : FluentStroke.thick,
    ),
    diameter: WidgetStatePropertyAll<double?>(diameter),
  );
}

/// Renders a presence badge from a resolved [state] and [style].
///
/// The third of the three-function recomposition contract. Takes
/// [FluentPresenceBadgeBaseState] rather than [FluentPresenceBadgeState] on
/// purpose: it never reads status, size or the out-of-office flag.
///
/// The disc and ring are a [CustomPaint] rather than a `DecoratedBox`, for the
/// same reason `FluentFocusRing` is: the ring is stroke-aligned OUTSIDE in
/// Figma, so it has to paint beyond the widget's own bounds without changing
/// what the badge costs in layout. A decoration cannot do that.
///
/// There is **no transition** here — upstream declares none — so a status
/// change lands on the frame. [states] is accepted for symmetry with the
/// interactive components; a standalone [FluentPresenceBadge] passes an empty
/// set.
Widget buildFluentPresenceBadge(
  FluentPresenceBadgeBaseState state,
  FluentPresenceBadgeStyle style,
  Set<WidgetState> states,
) {
  final diameter = style.diameter?.resolve(states) ?? FluentSize.size160;
  final background = style.backgroundColor?.resolve(states);
  final foreground = style.foregroundColor?.resolve(states);
  final ring = style.borderColor?.resolve(states);
  final ringWidth = style.borderWidth?.resolve(states) ?? FluentStroke.none;
  final glyph = state.glyph;

  return SizedBox.square(
    dimension: diameter,
    child: CustomPaint(
      painter: FluentPresenceBadgePainter(
        disc: background,
        ring: ring,
        ringWidth: ringWidth,
        // Tiny has no glyph in Figma, so the status colour has to be the disc
        // itself. Painting it here keeps the widget tree identical across
        // sizes.
        dot: glyph == null ? foreground : null,
      ),
      child: glyph == null
          ? null
          : Icon(glyph, size: diameter, color: foreground),
    ),
  );
}

/// Paints a presence badge's disc and cut-out ring.
///
/// Every input is a public field so tests can assert the resolved tokens
/// directly instead of diffing pixels.
class FluentPresenceBadgePainter extends CustomPainter {
  /// Creates a painter for the given tones and widths.
  const FluentPresenceBadgePainter({
    required this.disc,
    required this.ring,
    required this.ringWidth,
    this.dot,
  });

  /// The disc under the glyph. Fluent's `Neutral/Background/1/Rest`, which is
  /// what the hollow out-of-office glyphs read against.
  final Color? disc;

  /// The ring painted outside the badge's box. Same token as [disc], different
  /// job.
  final Color? ring;

  /// Ring width: 1 at [FluentPresenceBadgeSize.tiny], 2 everywhere else.
  final double ringWidth;

  /// The status colour, painted as a solid disc when there is no glyph.
  final Color? dot;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final centre = Offset(size.width / 2, size.height / 2);

    if (disc != null) {
      canvas.drawCircle(centre, radius, Paint()..color = disc!);
    }
    // A stroke is centred on its path, so Figma's strokeAlign OUTSIDE for a
    // width-w stroke is the same circle grown by w/2.
    if (ring != null && ringWidth > 0) {
      canvas.drawCircle(
        centre,
        radius + ringWidth / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringWidth
          ..color = ring!,
      );
    }
    if (dot != null) {
      canvas.drawCircle(centre, radius, Paint()..color = dot!);
    }
  }

  @override
  bool shouldRepaint(FluentPresenceBadgePainter oldDelegate) =>
      oldDelegate.disc != disc ||
      oldDelegate.ring != ring ||
      oldDelegate.ringWidth != ringWidth ||
      oldDelegate.dot != dot;
}

/// Overrides the presence badge style for a subtree.
class FluentPresenceBadgeTheme extends InheritedTheme {
  /// Applies [style] to every `FluentPresenceBadge` in [child].
  const FluentPresenceBadgeTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the status and size defaults.
  final FluentPresenceBadgeStyle style;

  /// The nearest presence badge style, or null.
  static FluentPresenceBadgeStyle? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<FluentPresenceBadgeTheme>()
      ?.style;

  @override
  bool updateShouldNotify(FluentPresenceBadgeTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentPresenceBadgeTheme(style: style, child: child);
}

/// A Fluent 2 presence badge: the availability dot that sits on an avatar.
///
/// ```dart
/// FluentPresenceBadge(
///   status: FluentPresenceStatus.away,
///   outOfOffice: true,
///   size: FluentPresenceBadgeSize.large,
/// )
/// ```
///
/// Non-interactive, like `FluentBadge`. The white cut-out ring paints *outside*
/// the widget's bounds, so an ancestor clipping tightly to it will shave the
/// ring; give it room, or let it overhang as Fluent intends.
///
/// Customisation follows the usual three rungs: [style] wins,
/// [FluentPresenceBadgeTheme] restyles a subtree, and
/// [resolveFluentPresenceBadgeState], [resolveFluentPresenceBadgeStyle] and
/// [buildFluentPresenceBadge] are public for anything further.
class FluentPresenceBadge extends StatelessWidget {
  /// Creates a presence badge for [status].
  const FluentPresenceBadge({
    super.key,
    required this.status,
    this.outOfOffice = false,
    this.size = FluentPresenceBadgeSize.medium,
    this.style,
    this.semanticLabel,
  });

  /// The availability being shown.
  final FluentPresenceStatus status;

  /// Whether the person is out of office. Changes the glyph, and for
  /// [FluentPresenceStatus.away] the colour too.
  final bool outOfOffice;

  /// Badge diameter.
  final FluentPresenceBadgeSize size;

  /// Overrides layered over the theme defaults. Merged last, so it wins.
  final FluentPresenceBadgeStyle? style;

  /// Announced by assistive technology. Defaults to an English name for
  /// [status]; pass your own to localise or personalise it.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final state = resolveFluentPresenceBadgeState(
      status: status,
      outOfOffice: outOfOffice,
      size: size,
      semanticLabel: semanticLabel,
      l10n: fluentL10n(context),
    );

    // Lowest to highest: defaults, subtree theme, then the caller's own style.
    final resolved = resolveFluentPresenceBadgeStyle(
      state,
      FluentTheme.of(context),
    ).merge(FluentPresenceBadgeTheme.maybeOf(context)).merge(style);

    return Semantics(
      label: state.semanticLabel,
      container: true,
      child: buildFluentPresenceBadge(state, resolved, const <WidgetState>{}),
    );
  }
}

/// The nominal icon size Fluent ships a presence glyph at, or null at
/// [FluentPresenceBadgeSize.tiny], which has no glyph.
///
/// `extraLarge` is 28 in Figma but the icon set stops at 24, so the 24 glyph is
/// drawn at 28 — the same shape Figma scaled up when it flattened that variant
/// to a raw vector.
int? _nominal(FluentPresenceBadgeSize size) => switch (size) {
  FluentPresenceBadgeSize.tiny => null,
  FluentPresenceBadgeSize.extraSmall => 10,
  FluentPresenceBadgeSize.small => 12,
  FluentPresenceBadgeSize.medium => 16,
  FluentPresenceBadgeSize.large => 20,
  FluentPresenceBadgeSize.extraLarge => 24,
};

IconData? _glyph(
  FluentPresenceStatus status, {
  required bool outOfOffice,
  required FluentPresenceBadgeSize size,
}) {
  final nominal = _nominal(size);
  if (nominal == null) return null;
  final family = switch ((status, outOfOffice)) {
    (FluentPresenceStatus.available, false) => _availableFilled,
    (FluentPresenceStatus.available, true) => _availableRegular,
    (FluentPresenceStatus.away, false) => _awayFilled,
    // Away out of office is not a hollow marigold glyph: it is the
    // out-of-office glyph outright, berry and all.
    (FluentPresenceStatus.away, true) => _oofRegular,
    (FluentPresenceStatus.busy, false) => _busyFilled,
    // Busy has no regular glyph upstream, so out of office borrows Unknown's.
    (FluentPresenceStatus.busy, true) => _unknownRegular,
    (FluentPresenceStatus.doNotDisturb, false) => _dndFilled,
    (FluentPresenceStatus.doNotDisturb, true) => _dndRegular,
    (FluentPresenceStatus.blocked, _) => _blockedRegular,
    (FluentPresenceStatus.offline, _) => _offlineRegular,
    (FluentPresenceStatus.outOfOffice, _) => _oofRegular,
    (FluentPresenceStatus.unknown, _) => _unknownRegular,
  };
  return family[nominal]!;
}

/// What a presence badge announces for [status].
///
/// The out-of-office *flag* is orthogonal to the status, so it wraps whatever
/// the status is called — "Busy out of office" — except on
/// [FluentPresenceStatus.outOfOffice] itself, which would otherwise say it
/// twice.
String fluentPresenceStatusLabel(
  FluentPresenceStatus status, {
  required bool outOfOffice,
  required FluentLocalizations l10n,
}) {
  final name = switch (status) {
    FluentPresenceStatus.available => l10n.presenceAvailable,
    FluentPresenceStatus.away => l10n.presenceAway,
    FluentPresenceStatus.busy => l10n.presenceBusy,
    FluentPresenceStatus.doNotDisturb => l10n.presenceDoNotDisturb,
    FluentPresenceStatus.blocked => l10n.presenceBlocked,
    FluentPresenceStatus.offline => l10n.presenceOffline,
    FluentPresenceStatus.outOfOffice => l10n.presenceOutOfOffice,
    FluentPresenceStatus.unknown => l10n.presenceUnknown,
  };
  return outOfOffice && status != FluentPresenceStatus.outOfOffice
      ? l10n.presenceOutOfOfficeStatus(name)
      : name;
}

const Map<int, IconData> _availableFilled = {
  10: FluentIcons.presence_available_10_filled,
  12: FluentIcons.presence_available_12_filled,
  16: FluentIcons.presence_available_16_filled,
  20: FluentIcons.presence_available_20_filled,
  24: FluentIcons.presence_available_24_filled,
};
const Map<int, IconData> _availableRegular = {
  10: FluentIcons.presence_available_10_regular,
  12: FluentIcons.presence_available_12_regular,
  16: FluentIcons.presence_available_16_regular,
  20: FluentIcons.presence_available_20_regular,
  24: FluentIcons.presence_available_24_regular,
};
const Map<int, IconData> _awayFilled = {
  10: FluentIcons.presence_away_10_filled,
  12: FluentIcons.presence_away_12_filled,
  16: FluentIcons.presence_away_16_filled,
  20: FluentIcons.presence_away_20_filled,
  24: FluentIcons.presence_away_24_filled,
};
const Map<int, IconData> _busyFilled = {
  10: FluentIcons.presence_busy_10_filled,
  12: FluentIcons.presence_busy_12_filled,
  16: FluentIcons.presence_busy_16_filled,
  20: FluentIcons.presence_busy_20_filled,
  24: FluentIcons.presence_busy_24_filled,
};
const Map<int, IconData> _dndFilled = {
  10: FluentIcons.presence_dnd_10_filled,
  12: FluentIcons.presence_dnd_12_filled,
  16: FluentIcons.presence_dnd_16_filled,
  20: FluentIcons.presence_dnd_20_filled,
  24: FluentIcons.presence_dnd_24_filled,
};
const Map<int, IconData> _dndRegular = {
  10: FluentIcons.presence_dnd_10_regular,
  12: FluentIcons.presence_dnd_12_regular,
  16: FluentIcons.presence_dnd_16_regular,
  20: FluentIcons.presence_dnd_20_regular,
  24: FluentIcons.presence_dnd_24_regular,
};
const Map<int, IconData> _blockedRegular = {
  10: FluentIcons.presence_blocked_10_regular,
  12: FluentIcons.presence_blocked_12_regular,
  16: FluentIcons.presence_blocked_16_regular,
  20: FluentIcons.presence_blocked_20_regular,
  24: FluentIcons.presence_blocked_24_regular,
};
const Map<int, IconData> _offlineRegular = {
  10: FluentIcons.presence_offline_10_regular,
  12: FluentIcons.presence_offline_12_regular,
  16: FluentIcons.presence_offline_16_regular,
  20: FluentIcons.presence_offline_20_regular,
  24: FluentIcons.presence_offline_24_regular,
};
const Map<int, IconData> _oofRegular = {
  10: FluentIcons.presence_oof_10_regular,
  12: FluentIcons.presence_oof_12_regular,
  16: FluentIcons.presence_oof_16_regular,
  20: FluentIcons.presence_oof_20_regular,
  24: FluentIcons.presence_oof_24_regular,
};
const Map<int, IconData> _unknownRegular = {
  10: FluentIcons.presence_unknown_10_regular,
  12: FluentIcons.presence_unknown_12_regular,
  16: FluentIcons.presence_unknown_16_regular,
  20: FluentIcons.presence_unknown_20_regular,
  24: FluentIcons.presence_unknown_24_regular,
};

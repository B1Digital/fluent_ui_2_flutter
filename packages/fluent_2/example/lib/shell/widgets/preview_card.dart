import 'dart:async';

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../catalog.dart';
import '../docs_metrics.dart';
import '../rtl_scope.dart';
import '../showroom_scope.dart';
import '../theme_variants.dart';
import 'code_panel.dart';
import 'preview_band.dart';
import 'story_outlines.dart';

/// One story section's preview: the bordered card, its zoom controls, its action
/// row, and the code panel that slides out underneath.
class PreviewCard extends StatefulWidget {
  /// Renders [section], reading its source from [assetPath] when "Show code" is
  /// pressed.
  const PreviewCard({
    super.key,
    required this.section,
    required this.assetPath,
  });

  /// The section to render.
  final DocsSection section;

  /// The owning page's source, as a `rootBundle` key.
  final String assetPath;

  @override
  State<PreviewCard> createState() => _PreviewCardState();
}

class _PreviewCardState extends State<PreviewCard> {
  static const List<double> _zoomSteps = <double>[0.5, 0.75, 1, 1.5, 2, 3];

  bool _showCode = false;
  double _zoom = 1;

  void _stepZoom(int direction) {
    final int current = _zoomSteps.indexOf(_zoom);
    final int next = (current < 0 ? 2 : current) + direction;
    if (next < 0 || next >= _zoomSteps.length) {
      return;
    }
    setState(() => _zoom = _zoomSteps[next]);
  }

  Future<void> _openInNewTab() async {
    final Uri base = Uri.base;
    // The canvas route lives in the fragment, so the origin, the Pages
    // base-href and any existing query all survive untouched.
    final Uri target = base.replace(fragment: '/story/${widget.section.id}');
    await launchUrl(target, webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    final ShowroomScope scope = ShowroomScope.of(context);

    return Padding(
      padding: DocsMetrics.cardMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // The border is a *foreground* decoration, and the box clips to the
          // same radius. A background border is painted behind the children, so
          // the opaque action row at the bottom edge paints straight over it and
          // the outline reads as cut. Foreground draws the border last, over
          // everything, so the card keeps an unbroken rounded outline.
          Container(
            decoration: BoxDecoration(
              color: DocsMetrics.canvas,
              borderRadius: BorderRadius.circular(DocsMetrics.cardRadius),
            ),
            foregroundDecoration: BoxDecoration(
              border: Border.all(color: DocsMetrics.border),
              borderRadius: BorderRadius.circular(DocsMetrics.cardRadius),
            ),
            clipBehavior: Clip.antiAlias,
            // Controls, not prose. Without this the article's selection region
            // drags a highlight straight across every button label and every
            // live demo — which is what a browser avoids by putting
            // `user-select: none` on its controls.
            child: SelectionContainer.disabled(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _ZoomBar(
                    onZoomIn: () => _stepZoom(1),
                    onZoomOut: () => _stepZoom(-1),
                    onReset: () => setState(() => _zoom = 1),
                  ),
                  // Upstream's `.docs-story`: the grid and the background
                  // show only in the 38px band around the opaque story
                  // wrapper, and the action bar sits over the bottom band,
                  // flush with it, its right edge ~31px in (`geo.tree`).
                  // ponytail: not snapped to device pixels; at DPR 1 with an
                  // odd pane width or a dragged sidebar the 1px grid lines
                  // smear lighter (pitch intact). Snap the band's global x in a
                  // RenderProxyBox if that shows.
                  PreviewBand(
                    grid: scope.grid,
                    background: scope.background,
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: <Widget>[
                        _StoryStage(
                          variant: scope.variant,
                          zoom: _zoom,
                          // A Builder, so the section builds under the stage's
                          // FluentTheme. Called with this context, a builder
                          // that reads the theme itself got the light chrome's.
                          child: Builder(builder: widget.section.builder),
                        ),
                        Positioned(
                          right: 31,
                          bottom: 0,
                          child: _ActionRow(
                            showCode: _showCode,
                            onToggleCode: () =>
                                setState(() => _showCode = !_showCode),
                            onOpenInNewTab: _openInNewTab,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_showCode)
            CodePanel(
              assetPath: widget.assetPath,
              docregion: widget.section.id,
            ),
        ],
      ),
    );
  }
}

/// The band between `.docs-story` and the story, upstream: the zoom wrapper's
/// 30px padding plus the story child's 8px transparent border
/// (`addons/docs/src/blocks/components/Preview.tsx:50-58,260`), measured 38px
/// on all four sides of the live card.
///
/// ponytail: the band stays outside the zoom transform, so it keeps 38px when
/// a card zooms; upstream's scales with the zoom (59.4px at x1.5625). Move the
/// inset inside the `Transform.scale` if that ever matters.
const EdgeInsets _stageInset = EdgeInsets.all(38);

/// The story itself, re-themed and scaled.
class _StoryStage extends StatelessWidget {
  const _StoryStage({
    required this.variant,
    required this.zoom,
    required this.child,
  });

  final ThemeVariant variant;
  final double zoom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ShowroomScope scope = ShowroomScope.of(context);
    final FluentThemeData data = variant.data;

    // `FluentApp` installed a DefaultTextStyle and an IconTheme from the *chrome*
    // theme, several ancestors up. Supplying only FluentTheme here would leave
    // every bare `Text` and `Icon` in a preview painted on the chrome ramp — so
    // all three are re-established, plus the surface colour behind them.
    final Widget themed = FluentTheme(
      data: data,
      child: RtlScope(
        textDirection: scope.textDirection,
        child: DefaultTextStyle(
          style: data.typography.body1,
          child: IconTheme(
            data: IconThemeData(
              color: data.colors.neutralForeground1,
              size: 20,
            ),
            // The outliner sits above the wrapper, so the wrapper is its first
            // descendant and gets the blue box upstream's
            // `[data-story-block] div` rule gives it.
            child: StoryOutlines(
              enabled: scope.outlines,
              // Upstream's story decorator, `FluentExampleContainer`
              // (`withFluentProvider.tsx:56-61`): an opaque
              // `colorNeutralBackground2` box with `padding: 48px 24px`,
              // always painted. It covers the FluentProvider's nb1 behind it
              // exactly, so that box is not drawn here. Read from the theme,
              // it tracks the Theme menu: #fafafa light, #1f1f1f Web Dark,
              // #242424 Teams Dark, #000 High Contrast.
              child: ColoredBox(
                color: data.colors.neutralBackground2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 48,
                  ),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    // Strict mode flips the key, so every story remounts on
                    // each toggle — what wrapping and unwrapping
                    // `<React.StrictMode>` does upstream.
                    child: KeyedSubtree(
                      key: ValueKey<bool>(scope.strictMode),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // `Transform.scale` alone does not change layout, so the card would keep the
    // unscaled height and the preview would spill out of it. `Align`'s
    // heightFactor reports `child.height * zoom`, and handing the child
    // `maxWidth / zoom` makes it lay out at logical width and scale to fill.
    // Hit-testing is transformed too, so controls inside a zoomed preview still
    // work.
    //
    // The same tree at every zoom, 1 included — an identity scale and no clip
    // paint exactly what a bare child does. A separate zoom-1 branch remounted
    // the story on every step to or from 1, where upstream keeps its value.
    return Padding(
      padding: _stageInset,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return ClipRect(
            clipBehavior: zoom == 1 ? Clip.none : Clip.hardEdge,
            child: Align(
              alignment: Alignment.topLeft,
              heightFactor: zoom,
              child: Transform.scale(
                scale: zoom,
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: constraints.maxWidth / zoom,
                  child: themed,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ZoomBar extends StatelessWidget {
  const _ZoomBar({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: DocsMetrics.cardTopPadding,
      child: Row(
        children: <Widget>[
          const SizedBox(width: 12),
          _IconAction(
            icon: FluentIcons.zoom_in_20_regular,
            label: 'Zoom in',
            onPressed: onZoomIn,
          ),
          _IconAction(
            icon: FluentIcons.zoom_out_20_regular,
            label: 'Zoom out',
            onPressed: onZoomOut,
          ),
          _IconAction(
            icon: FluentIcons.arrow_reset_20_regular,
            label: 'Reset zoom',
            onPressed: onReset,
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FluentTooltip(
      content: Text(label),
      child: FluentButton.icon(
        icon: Icon(icon, size: 16),
        semanticLabel: label,
        appearance: FluentButtonAppearance.transparent,
        size: FluentButtonSize.small,
        onPressed: onPressed,
      ),
    );
  }
}

/// The buttons flush against the card's bottom edge.
///
/// Upstream shows three. "Open in Stackblitz" is not one of ours: Stackblitz
/// runs neither Dart nor Flutter, so there is no target to point it at and a
/// button that cannot work is worse than an absent one.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.showCode,
    required this.onToggleCode,
    required this.onOpenInNewTab,
  });

  final bool showCode;
  final VoidCallback onToggleCode;
  final Future<void> Function() onOpenInNewTab;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _ActionButton(
          label: 'Open in new tab',
          icon: FluentIcons.open_20_regular,
          onPressed: () => unawaited(onOpenInNewTab()),
        ),
        const SizedBox(width: 4),
        _ActionButton(
          label: showCode ? 'Hide code' : 'Show code',
          onPressed: onToggleCode,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          height: DocsMetrics.cardActionHeight,
          padding: DocsMetrics.cardActionPadding,
          decoration: const BoxDecoration(
            color: DocsMetrics.actionBackground,
            borderRadius: DocsMetrics.cardActionRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 14, color: DocsMetrics.actionText),
                const SizedBox(width: 6),
              ],
              Text(label, style: DocsMetrics.action),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../pages.dart';
import '../catalog.dart';
import '../docs_metrics.dart';
import '../rtl_scope.dart';
import '../showroom_scope.dart';
import '../vision_filter.dart';
import 'shell_toolbar.dart';
import 'story_outlines.dart';
import 'toolbar_parts.dart';

/// One story, on its own canvas: what a preview card's "Open in new tab"
/// opens, Storybook's `#/story/<id>`.
///
/// Its bar is Storybook 9.1.17's story-mode toolbar (live `tools.t15`), left
/// to right: Remount, Zoom in, Zoom out, Reset zoom and a separator
/// (`tools/remount.tsx`, `tools/zoom.tsx:39-99`), then Outline, Viewport,
/// Vision simulator, Theme, Direction and Strict mode, and Copy canvas link
/// against the right edge (`Toolbar.tsx:32-72`). No Grid and no Background:
/// the live canvas bar has neither, on every story probed.
///
/// Outline, Theme, Direction and Strict mode are the docs bar's own widgets
/// on the same [ShowroomScope], so both bars drive one set of globals. Zoom
/// and the vision filter are transient manager state upstream
/// (`zoom.tsx:15-35`, `VisionSimulator.tsx:126`) and live here.
///
/// Not drawn, by scope: Measure, Full screen and "Open canvas in new tab".
class StoryCanvas extends StatefulWidget {
  /// Renders the section with id [storyId].
  const StoryCanvas({super.key, required this.storyId});

  /// The section to render.
  final String storyId;

  @override
  State<StoryCanvas> createState() => _StoryCanvasState();
}

/// Storybook's `MINIMAL_VIEWPORTS` (`viewport/defaults.ts:236-269`), the set
/// upstream offers because Fluent sets no `parameters.viewport`, with the
/// `iconsMap` glyphs (`viewport/utils.tsx:40-45`).
enum _Viewport {
  mobile1('Small mobile', Size(320, 568), FluentIcons.phone_20_regular),
  mobile2('Large mobile', Size(414, 896), FluentIcons.phone_20_regular),
  tablet('Tablet', Size(834, 1112), FluentIcons.tablet_20_regular),
  desktop('Desktop', Size(1280, 1024), FluentIcons.desktop_20_regular);

  const _Viewport(this.label, this.size, this.icon);

  final String label;

  /// Portrait: width by height.
  final Size size;

  final IconData icon;
}

class _StoryCanvasState extends State<StoryCanvas> {
  /// Unclamped, as upstream's (`zoom.tsx:68-88`, measured 9.313 after ten
  /// zoom-ins).
  double _zoom = 1;

  /// Bumped by Remount: keys the story, and is the glyph's turn count.
  int _mount = 0;

  // ponytail: viewport is a story-only *global* upstream (`viewport.value`,
  // `viewport.isRotated`), kept here with the transient state because nothing
  // else reads it and globals are not in the URL. Lift it into ShowroomScope
  // when `?globals=` lands.
  _Viewport? _viewport;
  bool _rotated = false;
  VisionFilter? _vision;

  @override
  Widget build(BuildContext context) {
    final ({DocsPage page, DocsSection section})? found = sectionById(
      widget.storyId,
    );
    if (found == null) {
      return ColoredBox(
        color: DocsMetrics.canvas,
        child: Center(
          child: Text('No story "${widget.storyId}".', style: DocsMetrics.body),
        ),
      );
    }

    final ShowroomScope scope = ShowroomScope.of(context);
    final FluentThemeData data = scope.variant.data;
    final _Viewport? preset = _viewport;
    final Size? size = preset == null
        ? null
        : _rotated
        ? preset.size.flipped
        : preset.size;

    // The iframe document, upstream: `body.sb-main-padded` (`padding: 1rem`,
    // `iframe.html:78-82`), then the FluentProvider at full width, then the
    // story decorator, `FluentExampleContainer` (`withFluentProvider.tsx:
    // 56-61`) — an opaque colorNeutralBackground2 box with `padding: 48px
    // 24px` (live `canvasGeo`). The theme and RtlScope wrap all of it, so the
    // directional alignment resolves in the story's direction and RTL puts
    // the story against the right edge, as upstream's `dir` does.
    final Widget page = FluentTheme(
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
            child: Padding(
              padding: const EdgeInsets.all(16),
              // Around the wrapper, so it is the outliner's first box —
              // upstream's `.sb-show-main div` outlines #storybook-root, the
              // FluentProvider and the wrapper, all this one rect.
              child: StoryOutlines(
                enabled: scope.outlines,
                child: ColoredBox(
                  color: data.colors.neutralBackground2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 48,
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      // Remount and Strict mode both replace the story:
                      // FORCE_REMOUNT upstream, and wrapping or unwrapping
                      // `<React.StrictMode>`.
                      child: KeyedSubtree(
                        key: ValueKey<(int, bool)>((_mount, scope.strictMode)),
                        child: Builder(builder: found.section.builder),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return ColoredBox(
      color: DocsMetrics.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ToolbarFrame(
            start: <Widget>[
              // `tools/remount.tsx`: SyncIcon, spun once by `rotate360
              // 1000ms ease-out`. Not a ToolbarButton, whose glyph is a bare
              // `Icon(icon)`: the turn has to sit between FluentButton's icon
              // slot, which paints the state colour, and the glyph.
              FluentTooltip(
                content: const Text('Remount component'),
                child: FluentButton.icon(
                  icon: AnimatedRotation(
                    turns: _mount.toDouble(),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOut,
                    child: const Icon(FluentIcons.arrow_sync_20_regular),
                  ),
                  semanticLabel: 'Remount component',
                  appearance: FluentButtonAppearance.transparent,
                  size: FluentButtonSize.small,
                  style: toolbarButtonStyle(active: false),
                  onPressed: () => setState(() => _mount++),
                ),
              ),
              // Upstream's handlers set `0.8 * value` and `1.25 * value` on
              // a body scaled by `1 / value` (`ZoomIFrame.tsx:38-58`), so on
              // screen Zoom in is x1.25 and Zoom out x0.8.
              ToolbarButton(
                icon: FluentIcons.zoom_in_20_regular,
                tooltip: 'Zoom in',
                onPressed: () => setState(() => _zoom *= 1.25),
              ),
              ToolbarButton(
                icon: FluentIcons.zoom_out_20_regular,
                tooltip: 'Zoom out',
                onPressed: () => setState(() => _zoom *= 0.8),
              ),
              ToolbarButton(
                icon: FluentIcons.arrow_reset_20_regular,
                tooltip: 'Reset zoom',
                onPressed: () => setState(() => _zoom = 1),
              ),
              const ToolbarSeparator(),
              const OutlineTool(),
              // `viewport/components/Tool.tsx:113-196`. Upstream's
              // double-click reset is not wired: a double-tap recogniser
              // would hold every single click until the double-tap timeout.
              ToolbarMenuButton(
                icon: FluentIcons.resize_20_regular,
                tooltip: 'Change the size of the preview',
                active: preset != null,
                // `IconButtonLabel` (`viewport/utils.tsx:35-38`): 13px,
                // `margin-left: 10px` past the button's 6px gap.
                label: preset == null
                    ? null
                    : Padding(
                        padding: const EdgeInsetsDirectional.only(start: 10),
                        child: Text(
                          '${preset.label} (${_rotated ? 'L' : 'P'})',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                items: <FluentMenuItem>[
                  if (preset != null)
                    FluentMenuItem(
                      icon: const Icon(FluentIcons.arrow_clockwise_20_regular),
                      label: const Text('Reset viewport'),
                      onPressed: () => setState(() {
                        _viewport = null;
                        _rotated = false;
                      }),
                    ),
                  for (final _Viewport option in _Viewport.values)
                    FluentMenuItem(
                      icon: Icon(option.icon),
                      label: toolbarItemLabel(
                        option.label,
                        chosen: option == preset,
                      ),
                      onPressed: () => setState(() {
                        _viewport = option;
                        _rotated = false;
                      }),
                    ),
                ],
              ),
              // `ActiveViewportSize`: one inline-flex group, so no bar gap
              // inside it (live `vp.small`: 320 at 676, rotate at 718, 568
              // at 746).
              if (size != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _sizeLabel('Viewport width', size.width),
                    ToolbarButton(
                      icon: FluentIcons.arrow_swap_20_regular,
                      tooltip: 'Rotate viewport',
                      onPressed: () => setState(() => _rotated = !_rotated),
                    ),
                    _sizeLabel('Viewport height', size.height),
                  ],
                ),
              // `addons/a11y` `VisionSimulator.tsx:92-158`. Double-click
              // reset skipped, as for the viewport.
              ToolbarMenuButton(
                icon: FluentIcons.accessibility_20_regular,
                tooltip: 'Vision simulator',
                active: _vision != null,
                items: <FluentMenuItem>[
                  if (_vision != null)
                    FluentMenuItem(
                      label: const Text('Reset color filter'),
                      onPressed: () => setState(() => _vision = null),
                    ),
                  for (final VisionFilter filter in VisionFilter.values)
                    FluentMenuItem(
                      label: toolbarItemLabel(
                        filter.label,
                        chosen: filter == _vision,
                      ),
                      secondary: filter.share == null
                          ? null
                          : Text('${filter.share} of users'),
                      onPressed: () => setState(() => _vision = filter),
                    ),
                ],
              ),
              const ThemeTool(),
              const DirectionTool(),
              const StrictModeTool(),
            ],
            end: <Widget>[
              // `tools/copy.tsx` copies the chrome-free `iframe.html?id=…`;
              // the showroom's canvas route is this page itself.
              ToolbarButton(
                icon: FluentIcons.link_20_regular,
                tooltip: 'Copy canvas link',
                onPressed: () => unawaited(
                  Clipboard.setData(ClipboardData(text: Uri.base.toString())),
                ),
              ),
            ],
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints stage) {
                final Size frame = size ?? stage.biggest;
                // One tree whatever the settings, so a viewport, a filter or
                // a zoom never remounts the story — upstream only restyles
                // the iframe.
                //
                // The frame is `Iframe.tsx:8-19` in `IframeWrapper`
                // (`utils/components.ts:49-63`): a grid cell with `margin:
                // auto`, so centred on each axis it fits and flush to the
                // start where it overflows (live: 320x568 at y=86, 1280x1024
                // at y=40), under a `0 0 100px 100vw rgba(0,0,0,.5)` backdrop.
                //
                // ponytail: an overflowing frame is clipped where upstream's
                // wrapper (`overflow: auto`) scrolls it; wrap the OverflowBox
                // in a two-axis scroll view if Desktop in a short window
                // matters. And there is no MediaQuery override inside the
                // frame: fluent_2's popups measure their room from
                // MediaQuery against global rects (`anchor_metrics.dart`),
                // so a phone-sized MediaQuery would open menus outside the
                // frame. The upgrade is a local Overlay in the frame plus
                // overlay-relative anchor metrics in the library.
                return ClipRect(
                  child: OverflowBox(
                    minWidth: 0,
                    maxWidth: double.infinity,
                    minHeight: 0,
                    maxHeight: double.infinity,
                    alignment: Alignment(
                      frame.width <= stage.maxWidth ? 0 : -1,
                      frame.height <= stage.maxHeight ? 0 : -1,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: DocsMetrics.canvas,
                        boxShadow: size == null
                            ? null
                            : <BoxShadow>[
                                BoxShadow(
                                  color: const Color(0x80000000),
                                  blurRadius: 100,
                                  spreadRadius: stage.maxWidth,
                                ),
                              ],
                      ),
                      child: SizedBox.fromSize(
                        size: frame,
                        // Upstream filters the iframe element. A disabled
                        // ImageFiltered paints its child as-is, with no layer.
                        child: ImageFiltered(
                          enabled: _vision != null,
                          imageFilter:
                              _vision?.imageFilter ?? ImageFilter.blur(),
                          child: SingleChildScrollView(
                            // `ZoomIFrame`: the body laid out at
                            // `width: 100/zoom %`, then `scale(zoom)` from the
                            // top left, so the story reflows. FittedBox
                            // hands its child unbounded constraints and
                            // scales it to the frame's width, so it also
                            // reports the scaled height to the scroll view.
                            child: FittedBox(
                              fit: BoxFit.fitWidth,
                              alignment: Alignment.topLeft,
                              child: SizedBox(
                                width: frame.width / _zoom,
                                child: page,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// `ActiveViewportLabel` (`viewport/utils.tsx:16-28`): the bar's grey at
/// 13px/700, `padding: 10px`, under its `title`.
Widget _sizeLabel(String tooltip, double value) => FluentTooltip(
  content: Text(tooltip),
  child: Padding(
    padding: const EdgeInsets.all(10),
    child: Text(
      value.round().toString(),
      style: const TextStyle(
        fontFamily: DocsMetrics.fontFamily,
        fontFamilyFallback: DocsMetrics.fontFamilyFallback,
        fontSize: 13,
        fontWeight: FontWeight.w700,
        height: 1,
        color: ToolbarColors.rest,
      ),
    ),
  ),
);

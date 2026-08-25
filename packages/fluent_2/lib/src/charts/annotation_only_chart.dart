import 'dart:math' as math;

import 'package:fluent_2_core/fluent_2_core.dart';
import 'package:flutter/widgets.dart';

import 'annotation_only_chart_style.dart';
import 'chrome/annotation_layer.dart';
import 'model/chart_annotation.dart';
import 'model/chart_common.dart';

/// Applies a [FluentAnnotationOnlyChartStyle] to every
/// [FluentAnnotationOnlyChart] below it.
class FluentAnnotationOnlyChartTheme extends InheritedTheme {
  /// Applies [style] to every [FluentAnnotationOnlyChart] in `child`.
  const FluentAnnotationOnlyChartTheme({
    super.key,
    required this.style,
    required super.child,
  });

  /// The style layered over the derived defaults.
  final FluentAnnotationOnlyChartStyle style;

  /// The nearest annotation-only-chart style, or null.
  static FluentAnnotationOnlyChartStyle? maybeOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<FluentAnnotationOnlyChartTheme>()
          ?.style;

  @override
  bool updateShouldNotify(FluentAnnotationOnlyChartTheme oldWidget) =>
      style != oldWidget.style;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FluentAnnotationOnlyChartTheme(style: style, child: child);
}

/// A chart made of annotations alone: no axes, no legend, no marks.
///
/// The package exports it and the annotations layer requires it, even though
/// the storybook sidebar omits it. It exists because the Plotly adapter
/// produces figures whose only content is annotations
/// (`AnnotationOnlyChart.types.ts:14`, `:22`, `:30`).
///
/// Every annotation whose coordinates resolve in data space is **dropped**:
/// the context supplies no scales (`AnnotationOnlyChart.tsx:139-143`), so
/// `resolveDataCoordinate` returns nothing and the layer skips the annotation
/// silently. Only relative and pixel coordinates render here.
///
/// Upstream's two-pass measure — an unmeasured annotation is laid out at
/// 180 x 60 on the first frame and snaps once a hidden measurement div reports
/// (`ChartAnnotationLayer.tsx:446-467`, `:535-536`, `:607-633`) — has no
/// analogue here, because [FluentChartAnnotationLayer] measures its children
/// synchronously during layout. The 180 x 60 fallback and the JSON
/// measurement-signature cache are therefore both absent.
// ponytail: synchronous layout removes the measure/settle pass and its cache.
class FluentAnnotationOnlyChart extends StatelessWidget {
  /// Creates an annotation-only chart.
  const FluentAnnotationOnlyChart({
    super.key,
    required this.annotations,
    this.chartTitle,
    this.description,
    this.width,
    this.height,
    this.paperBackgroundColor,
    this.plotBackgroundColor,
    this.fontColor,
    this.fontFamily,
    this.margin,
    this.style,
  });

  /// The annotations to place.
  final List<FluentChartAnnotation> annotations;

  /// Optional heading above the content box. Rendered but hidden from
  /// assistive technology (`AnnotationOnlyChart.tsx:190`).
  final String? chartTitle;

  /// Preferred accessible name, taking precedence over [chartTitle]
  /// (`AnnotationOnlyChart.tsx:169`).
  final String? description;

  /// Hard width. Null honours the incoming constraints.
  final double? width;

  /// Hard height. Null resolves to the style's 650
  /// (`AnnotationOnlyChart.tsx:92`).
  final double? height;

  /// Overrides the outer background (`AnnotationOnlyChart.tsx:152`).
  final Color? paperBackgroundColor;

  /// Overrides the content-box background (`AnnotationOnlyChart.tsx:162`).
  final Color? plotBackgroundColor;

  /// Overrides the text colour (`AnnotationOnlyChart.tsx:153`).
  final Color? fontColor;

  /// Overrides the font family (`AnnotationOnlyChart.tsx:154`).
  final String? fontFamily;

  /// Converted to padding on the outer box (`AnnotationOnlyChart.tsx:14-29`).
  final FluentChartMargins? margin;

  /// Style layered over the derived defaults and the nearest
  /// [FluentAnnotationOnlyChartTheme].
  final FluentAnnotationOnlyChartStyle? style;

  /// Ports `buildPadding` (`AnnotationOnlyChart.tsx:14-29`): each component
  /// defaults to zero, and an all-zero margin yields no padding declaration at
  /// all.
  EdgeInsets get _padding {
    final m = margin;
    if (m == null) {
      return EdgeInsets.zero;
    }
    final top = m.top ?? 0;
    final right = m.right ?? 0;
    final bottom = m.bottom ?? 0;
    final left = m.left ?? 0;
    if (top == 0 && right == 0 && bottom == 0 && left == 0) {
      return EdgeInsets.zero;
    }
    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    final resolved = resolveFluentAnnotationOnlyChartStyle(
      theme,
    ).merge(FluentAnnotationOnlyChartTheme.maybeOf(context)).merge(style);
    const states = <WidgetState>{};

    final hasAnnotations = annotations.isNotEmpty;
    // AnnotationOnlyChart.tsx:169.
    final label = hasAnnotations ? (description ?? chartTitle) : null;
    // AnnotationOnlyChart.tsx:92 — Math.max(height ?? 650, 1).
    final resolvedHeight = math.max(
      height ?? resolved.defaultHeight!.resolve(states)!,
      1.0,
    );

    return Semantics(
      image: label != null,
      label: label ?? '',
      child: LayoutBuilder(
        builder: (context, constraints) {
          // AnnotationOnlyChart.tsx:91 — Math.max(measured || 400, 1). A
          // LayoutBuilder always has a width unless the constraints are
          // unbounded, where the fallback stands in for the unmeasured case.
          final resolvedWidth = math.max(
            width ??
                (constraints.hasBoundedWidth
                    ? constraints.maxWidth
                    : resolved.fallbackWidth!.resolve(states)!),
            1.0,
          );
          return SizedBox(
            width: resolvedWidth,
            height: resolvedHeight,
            child: ColoredBox(
              color:
                  paperBackgroundColor ??
                  resolved.paperBackgroundColor!.resolve(states)!,
              child: Padding(
                padding: _padding,
                child: DefaultTextStyle(
                  style: resolved.titleTextStyle!
                      .resolve(states)!
                      .copyWith(
                        color:
                            fontColor ??
                            resolved.foregroundColor!.resolve(states),
                        fontFamily: fontFamily,
                      ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (chartTitle != null) ...<Widget>[
                        // AnnotationOnlyChart.tsx:190 — aria-hidden="true". The
                        // empty label makes this a node of its own rather than
                        // a hole that reads the chart's name a second time.
                        Semantics(
                          container: true,
                          excludeSemantics: true,
                          label: '',
                          child: Text(chartTitle!, textAlign: TextAlign.center),
                        ),
                        // useAnnotationOnlyChartStyles.styles.ts:11 — rowGap.
                        SizedBox(height: resolved.rowGap!.resolve(states)),
                      ],
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color:
                                plotBackgroundColor ??
                                resolved.plotBackgroundColor!.resolve(states),
                            borderRadius: BorderRadius.circular(
                              resolved.contentRadius!.resolve(states)!,
                            ),
                          ),
                          child: hasAnnotations
                              ? FluentChartAnnotationLayer(
                                  annotations: annotations,
                                  context: FluentChartAnnotationContext(
                                    // AnnotationOnlyChart.tsx:140-141 — the
                                    // plot rect is the WHOLE resolved box, not
                                    // the content box, and no scales are
                                    // supplied.
                                    plotRect: Rect.fromLTWH(
                                      0,
                                      0,
                                      resolvedWidth,
                                      resolvedHeight,
                                    ),
                                    chartSize: Size(
                                      resolvedWidth,
                                      resolvedHeight,
                                    ),
                                    isRtl:
                                        Directionality.of(context) ==
                                        TextDirection.rtl,
                                  ),
                                )
                              : const SizedBox.expand(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:fluent_2/fluent_2.dart';
import 'package:flutter/widgets.dart';

import '../support/golden.dart';

/// Four columns. The cell order is the legend, because the placeholder test
/// font would draw a caption as a row of boxes:
///
/// * **Row 1** — a whole picker (rounded); the same picker square; the colour
///   area at pure red; the same picker disabled, which is deliberately
///   identical because upstream ships no disabled tokens for any of this.
/// * **Row 2** — the colour area at a mid teal; at a near-white pale green;
///   then two stacks of four horizontal rails. The first stack is rounded hue,
///   saturation, value and alpha; the second is square hue, square alpha,
///   alpha in transparency mode, and hue at 0 — where the thumb sits on the
///   rail's own edge and hangs 11 past it.
/// * **Row 3** — vertical hue and vertical alpha, both anchored at the bottom.
///
/// Three things here are exactly what a golden is for, because each fails as a
/// picture that still looks like a colour picker: the saturation ramp's
/// premultiplication (a grey haze down the middle of the square), the
/// checkerboard's parity, and the thumb's deliberate overhang past the ends of
/// a rail.
void main() {
  const red = HSVColor.fromAHSV(1, 0, 1, 1);
  const teal = HSVColor.fromAHSV(1, 200, 0.5, 0.5);
  const pale = HSVColor.fromAHSV(1, 90, 0.08, 0.96);
  const faded = HSVColor.fromAHSV(0.3, 300, 1, 1);

  Widget slot(Widget child, {double width = 300, double? height}) =>
      SizedBox(width: width, height: height, child: child);

  Widget picker({
    FluentColorPickerShape shape = FluentColorPickerShape.rounded,
    bool enabled = true,
  }) => slot(
    FluentColorPicker(
      color: teal,
      shape: shape,
      onColorChanged: enabled ? (_) {} : null,
      children: const <Widget>[
        FluentColorArea(
          saturationLabel: 'Saturation',
          brightnessLabel: 'Brightness',
        ),
        FluentColorSlider(semanticLabel: 'Hue'),
        FluentAlphaSlider(semanticLabel: 'Alpha'),
      ],
    ),
  );

  Widget area(HSVColor color) => slot(
    FluentColorArea(
      color: color,
      onChanged: (_) {},
      saturationLabel: 'Saturation',
      brightnessLabel: 'Brightness',
    ),
  );

  Widget rail(
    FluentColorChannel channel, {
    HSVColor color = teal,
    FluentColorPickerShape shape = FluentColorPickerShape.rounded,
  }) => slot(
    FluentColorSlider(
      color: color,
      channel: channel,
      shape: shape,
      onChanged: (_) {},
      semanticLabel: 'Channel',
    ),
  );

  Widget alpha({
    bool transparency = false,
    FluentColorPickerShape shape = FluentColorPickerShape.rounded,
  }) => slot(
    FluentAlphaSlider(
      color: faded,
      transparency: transparency,
      shape: shape,
      onChanged: (_) {},
      semanticLabel: 'Alpha',
    ),
  );

  goldenGridTest(
    'color_picker',
    () => goldenGrid(<Widget>[
      picker(),
      picker(shape: FluentColorPickerShape.square),
      area(red),
      picker(enabled: false),

      area(teal),
      area(pale),
      // Column 3 and 4 of this row hold the four horizontal rails, stacked so
      // the row stays four cells wide.
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: <Widget>[
          rail(FluentColorChannel.hue),
          rail(FluentColorChannel.saturation),
          rail(FluentColorChannel.value),
          alpha(),
        ],
      ),
      Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: <Widget>[
          rail(FluentColorChannel.hue, shape: FluentColorPickerShape.square),
          alpha(shape: FluentColorPickerShape.square),
          alpha(transparency: true),
          // At hue 0 the thumb sits on the rail's own edge and hangs 11 past
          // it — the overhang upstream's collapsed grid tracks produce.
          rail(FluentColorChannel.hue, color: red),
        ],
      ),
      slot(
        FluentColorSlider(
          color: teal,
          vertical: true,
          onChanged: (_) {},
          semanticLabel: 'Hue',
        ),
        width: 20,
        height: 280,
      ),
      slot(
        FluentAlphaSlider(
          color: faded,
          vertical: true,
          onChanged: (_) {},
          semanticLabel: 'Alpha',
        ),
        width: 20,
        height: 280,
      ),
    ], columns: 4),
    // A picker is ~300 x 380 and the grid is four of them across.
    surfaceSize: const Size(1400, 1600),
  );
}

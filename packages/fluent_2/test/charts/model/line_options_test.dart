import 'dart:ui';

import 'package:fluent_2/src/charts/model/line_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluentLineCurve', () {
    test('carries the five named curves', () {
      expect(
        FluentLineCurve.values.length,
        5,
        reason:
            "types/DataPoint.ts:448 — 'linear' | 'natural' | 'step' | "
            "'stepAfter' | 'stepBefore', plus a user-supplied factory arm that "
            'is not a member of this enum.',
      );
    });
  });

  group('FluentLineMode.parse', () {
    test('reads markers and text as substrings, per upstream', () {
      final mode = FluentLineMode.parse('lines+markers');
      expect(mode.markers, isTrue, reason: "includes('markers').");
      expect(mode.text, isFalse, reason: "does not include 'text'.");
      expect(mode.lines, isTrue, reason: "includes('lines').");
    });
    test("treats 'markers+text' as both, in either order", () {
      final a = FluentLineMode.parse('text+markers');
      final b = FluentLineMode.parse('markers+text');
      expect(
        a.markers,
        isTrue,
        reason: 'Order is irrelevant to a substring test.',
      );
      expect(
        a.text,
        isTrue,
        reason: 'Order is irrelevant to a substring test.',
      );
      expect(
        b.markers,
        isTrue,
        reason: 'Order is irrelevant to a substring test.',
      );
      expect(
        b.text,
        isTrue,
        reason: 'Order is irrelevant to a substring test.',
      );
    });
    test("'none' turns everything off", () {
      final mode = FluentLineMode.parse('none');
      expect(mode.lines, isFalse, reason: "'none' contains no 'lines'.");
      expect(mode.markers, isFalse, reason: "'none' contains no 'markers'.");
      expect(mode.text, isFalse, reason: "'none' contains no 'text'.");
    });
    test('an unrecognised gauge mode reports no line parts', () {
      final mode = FluentLineMode.parse('gauge+number+delta');
      expect(
        mode.lines,
        isFalse,
        reason:
            'The gauge modes at types/DataPoint.ts:462-468 are consumed by '
            'GaugeChart, not by the line renderer.',
      );
      expect(mode.markers, isFalse, reason: 'No markers substring.');
      expect(mode.text, isFalse, reason: 'No text substring.');
    });
    test('preserves the raw string for the gauge consumers', () {
      expect(
        FluentLineMode.parse('gauge+number').upstreamName,
        'gauge+number',
        reason:
            'GaugeChart switches on the whole literal, so parsing must not be '
            'lossy.',
      );
    });
  });

  group('FluentLineOptions', () {
    test('leaves every one of the nine fields null by default', () {
      const options = FluentLineOptions();
      expect(
        options.strokeWidth,
        isNull,
        reason:
            'No default at the type: 4 in LineChart, 3 in PolarChart and GVBC.',
      );
      expect(options.strokeDasharray, isNull, reason: 'Optional.');
      expect(options.strokeDashoffset, isNull, reason: 'Optional.');
      expect(options.strokeLinecap, isNull, reason: "'inherit' maps to null.");
      expect(options.lineBorderWidth, isNull, reason: 'Optional.');
      expect(options.lineBorderColor, isNull, reason: 'Optional.');
      expect(options.curve, isNull, reason: 'Optional.');
      expect(options.mode, isNull, reason: 'Optional.');
      expect(options.fill, isNull, reason: 'Optional.');
    });

    test('keeps fill, which is a real feature and not a pass-through', () {
      const options = FluentLineOptions(fill: 'toself');
      expect(
        options.fill,
        'toself',
        reason:
            'LineChart.tsx:1316 reads it and :1318-1343 closes the path with Z '
            'and paints it, so closing the type to eight fields would delete '
            'scatterpolar area fill (spec 5.6).',
      );
    });

    test('accepts a StrokeCap for strokeLinecap', () {
      const options = FluentLineOptions(strokeLinecap: StrokeCap.square);
      expect(
        options.strokeLinecap,
        StrokeCap.square,
        reason:
            "types/DataPoint.ts:432 'butt' | 'round' | 'square' | 'inherit'.",
      );
    });
  });
}

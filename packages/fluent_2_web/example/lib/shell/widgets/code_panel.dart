import 'dart:async';

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../dart_highlighter.dart';
import '../source_loader.dart';
import 'selectable.dart';

/// The dark panel under a preview card, showing the Dart that built it.
///
/// The source is read from the page's own file at runtime and sliced on the
/// section's `#docregion`, so what is printed here is the code that ran — see
/// `source_loader.dart` for why that indirection is worth it.
class CodePanel extends StatefulWidget {
  /// Shows the [docregion] found in [assetPath].
  const CodePanel({
    super.key,
    required this.assetPath,
    required this.docregion,
  });

  /// The page's own source, as a `rootBundle` key.
  final String assetPath;

  /// The `#docregion` marking this section.
  final String docregion;

  @override
  State<CodePanel> createState() => _CodePanelState();
}

class _CodePanelState extends State<CodePanel> {
  late Future<TextSpan> _span;

  /// The unhighlighted slice, kept so the copy button hands over source rather
  /// than a flattened span tree.
  String? _plain;

  static const TextStyle _codeStyle = TextStyle(
    fontFamily: FluentFontFamily.monospace,
    fontFamilyFallback: FluentFontFamily.monospaceFallback,
    fontSize: 14,
    height: 19 / 14,
    leadingDistribution: TextLeadingDistribution.even,
  );

  @override
  void initState() {
    super.initState();
    _span = _load();
  }

  @override
  void didUpdateWidget(CodePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath ||
        oldWidget.docregion != widget.docregion) {
      _span = _load();
    }
  }

  Future<TextSpan> _load() async {
    final String source = await loadPageSource(widget.assetPath);
    final String slice = sliceDocregion(source, widget.docregion);
    _plain = slice;
    return highlightDart(slice, style: _codeStyle);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: DartSyntaxColors.background,
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: FutureBuilder<TextSpan>(
          future: _span,
          builder: (BuildContext context, AsyncSnapshot<TextSpan> snapshot) {
            if (snapshot.hasError) {
              // A missing region is a wiring bug, and hiding it behind an empty
              // panel is how it would survive to production. Say so.
              return Text(
                '// ${snapshot.error}',
                style: _codeStyle.copyWith(color: DartSyntaxColors.comment),
              );
            }
            if (!snapshot.hasData) {
              return const SizedBox(height: 19);
            }
            return Stack(
              children: <Widget>[
                Selectable(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text.rich(snapshot.data!, style: _codeStyle),
                  ),
                ),
                // `SelectableText` lives in Material, which this app no longer
                // depends on. A copy button is the thing a reader wanted the
                // selection for anyway.
                Positioned(
                  top: 0,
                  right: 0,
                  child: _CopyCodeButton(source: _plain ?? ''),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Puts the section's source on the clipboard.
class _CopyCodeButton extends StatefulWidget {
  const _CopyCodeButton({required this.source});

  final String source;

  @override
  State<_CopyCodeButton> createState() => _CopyCodeButtonState();
}

class _CopyCodeButtonState extends State<_CopyCodeButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.source));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) {
      return;
    }
    setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => unawaited(_copy()),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(
            _copied
                ? FluentIcons.checkmark_20_regular
                : FluentIcons.copy_20_regular,
            size: 16,
            color: DartSyntaxColors.base,
          ),
        ),
      ),
    );
  }
}

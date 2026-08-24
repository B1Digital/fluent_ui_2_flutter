import 'dart:async';

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../catalog.dart';
import '../docs_metrics.dart';
import '../showroom_scope.dart';
import '../theme_variants.dart';

/// The row under the page title: theme picker, direction switch, Copy Page.
class DocsToolbar extends StatelessWidget {
  /// Controls for [page].
  const DocsToolbar({super.key, required this.page});

  /// The page the Copy Page button serialises.
  final DocsPage page;

  @override
  Widget build(BuildContext context) {
    final ShowroomScope scope = ShowroomScope.of(context);
    final bool rtl = scope.textDirection == TextDirection.rtl;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 208,
            child: FluentDropdown<ThemeVariant>(
              value: scope.variant,
              onChanged: scope.onVariantChanged,
              options: <FluentDropdownOption<ThemeVariant>>[
                for (final ThemeVariant variant in ThemeVariant.values)
                  FluentDropdownOption<ThemeVariant>(
                    value: variant,
                    label: Text(variant.label),
                    text: variant.label,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Text('LTR', style: DocsMetrics.body),
          const SizedBox(width: 8),
          FluentSwitch(
            checked: rtl,
            semanticLabel: 'Right to left',
            onChanged: (bool value) => scope.onTextDirectionChanged(
              value ? TextDirection.rtl : TextDirection.ltr,
            ),
          ),
          const SizedBox(width: 8),
          Text('RTL', style: DocsMetrics.body),
          const Spacer(),
          _CopyPageButton(page: page),
        ],
      ),
    );
  }
}

class _CopyPageButton extends StatefulWidget {
  const _CopyPageButton({required this.page});

  final DocsPage page;

  @override
  State<_CopyPageButton> createState() => _CopyPageButtonState();
}

class _CopyPageButtonState extends State<_CopyPageButton> {
  bool _copied = false;

  /// The page as markdown: title, description, then every section heading and
  /// its sentence. Mirrors what upstream's Copy Page puts on the clipboard.
  String get _markdown {
    final StringBuffer buffer = StringBuffer()
      ..writeln('# ${widget.page.title}')
      ..writeln()
      ..writeln(widget.page.description)
      ..writeln();
    for (final DocsSection section in widget.page.sections) {
      buffer
        ..writeln('## ${section.title}')
        ..writeln();
      if (section.description != null) {
        buffer
          ..writeln(section.description)
          ..writeln();
      }
    }
    return buffer.toString();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _markdown));
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
    return SizedBox(
      height: DocsMetrics.toolbarButtonHeight,
      child: FluentButton(
        icon: Icon(
          _copied
              ? FluentIcons.checkmark_20_regular
              : FluentIcons.copy_20_regular,
          size: 16,
        ),
        appearance: FluentButtonAppearance.outline,
        onPressed: () => unawaited(_copy()),
        child: Text(_copied ? 'Copied' : 'Copy Page'),
      ),
    );
  }
}

import 'dart:async';

import 'package:fluent_2_web/fluent_2_web.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import '../catalog.dart';
import '../docs_metrics.dart';
import '../page_markdown.dart';
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
      // Controls, not prose — see PreviewCard for why.
      child: SelectionContainer.disabled(
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
      ),
    );
  }
}

/// The split button under the page title.
///
/// The primary half copies the page as markdown and reports nothing back — the
/// upstream button has no "Copied" state. The chevron opens a one-item menu,
/// "View as Markdown", which opens the raw markdown in a NEW TAB rather than a
/// dialog: upstream navigates to a plain `llms/<page>.txt`, and a popup would be
/// a different thing wearing the same label.
class _CopyPageButton extends StatelessWidget {
  const _CopyPageButton({required this.page});

  final DocsPage page;

  Future<void> _openMarkdown() async {
    final Uri target = Uri.base.replace(fragment: '/markdown/${page.id}');
    await launchUrl(target, webOnlyWindowName: '_blank');
  }

  @override
  Widget build(BuildContext context) {
    return FluentMenu(
      items: <FluentMenuItem>[
        FluentMenuItem(
          label: const Text('View as Markdown'),
          icon: const Icon(FluentIcons.markdown_20_regular, size: 16),
          onPressed: () => unawaited(_openMarkdown()),
        ),
      ],
      builder: (BuildContext context, VoidCallback toggle) => SizedBox(
        height: DocsMetrics.toolbarButtonHeight,
        child: FluentSplitButton(
          appearance: FluentButtonAppearance.outline,
          menuSemanticLabel: 'More copy options',
          icon: const Icon(FluentIcons.markdown_20_regular, size: 16),
          onPressed: () => unawaited(
            Clipboard.setData(ClipboardData(text: pageAsMarkdown(page))),
          ),
          onMenuPressed: toggle,
          child: const Text('Copy Page'),
        ),
      ),
    );
  }
}

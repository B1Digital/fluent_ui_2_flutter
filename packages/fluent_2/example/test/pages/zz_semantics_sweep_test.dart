/// Every section in the showroom, mounted with the semantics tree switched on.
///
/// `SemanticsRole` is validated by `_DebugSemanticsRoleChecks`, which runs from
/// an assert inside `SemanticsNode._addToUpdate` — reached only when a real
/// `SemanticsUpdate` is actually built. Nothing else triggers it:
/// `tester.getSemantics` walks `RenderObject.debugSemantics` and never gets
/// there, so a `matchesSemantics` assertion can pass over a role tree the
/// framework would reject. `tester.ensureSemantics()` does build the update,
/// which is what makes this file the only thing standing between a malformed
/// role tree and a red screen in every debug build with a screen reader on.
///
/// It matters because the roles are structural rather than local: `table` wants
/// `row` children, `row` wants `cell` children, a `radioGroup` rejects two
/// checked descendants, and two unnamed `navigation` landmarks on one page
/// throw. None of that is visible from the widget that declares the role — it
/// only shows up once a whole page is composed, which is exactly what this
/// sweep composes.
///
/// Deliberately assertion-free. Mounting *is* the assertion: an invalid role
/// tree throws during the update, and `expectClean` inside `pumpSection` fails
/// the test.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fluent_2_example/pages.dart';
import 'package:fluent_2_example/shell/catalog.dart';

import 'harness.dart';

void main() {
  for (final DocsGroup group in catalog) {
    group_(group);
  }
}

void group_(DocsGroup docsGroup) {
  group('semantics — ${docsGroup.title}', () {
    for (final DocsPage page in docsGroup.pages) {
      for (final DocsSection section in page.sections) {
        testWidgets('${page.id} / ${section.id} builds a valid role tree', (
          WidgetTester tester,
        ) async {
          // Disposed inside the body, not from `addTearDown`: the binding
          // verifies that no `SemanticsHandle` is still active the moment the
          // body returns, which is *before* tear-downs run.
          final SemanticsHandle handle = tester.ensureSemantics();
          try {
            await pumpSection(tester, section);
          } finally {
            handle.dispose();
          }
        });
      }
    }
  });
}

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Saves `bytes` the way upstream's DeclarativeChart story does: a transient
/// `<a download>` appended to the body, clicked and removed
/// (`charts-declarativechart--declarative-chart-basic-example.tsx:329-341`).
///
/// Upstream's href is a data URL. Here it is a Blob URL over the same bytes,
/// which has no length ceiling: Chromium refuses URLs past 2 MB, and a dense
/// chart exported at scale 5 can base64-encode past that. The URL is revoked
/// straight after the click, because the anchor resolves it when clicked.
void saveFile(Uint8List bytes, String fileName) {
  final String url = web.URL.createObjectURL(
    web.Blob(<JSAny>[bytes.toJS].toJS),
  );
  final web.HTMLAnchorElement link = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body!.appendChild(link);
  link.click();
  link.remove();
  web.URL.revokeObjectURL(url);
}

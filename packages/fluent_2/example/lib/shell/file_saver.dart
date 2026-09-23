import 'dart:typed_data';

import 'file_saver_vm.dart'
    if (dart.library.js_interop) 'file_saver_web.dart'
    as platform;

/// Hands `bytes` to the browser as a download named `fileName`.
///
/// A variable rather than a function because the example's tests run on the
/// Dart VM, where there is no browser to save to: they swap in a recorder and
/// assert on what would have been saved.
void Function(Uint8List bytes, String fileName) saveFile = platform.saveFile;

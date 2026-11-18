import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

class CsvExportPlatform {
  static void download({
    required String fileName,
    required List<List<Object?>> rows,
  }) {
    final csvContent = rows
        .map((row) => row.map(_escapeCsvValue).join(','))
        .join('\r\n');
    final bytes = utf8.encode('\uFEFF$csvContent');
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
    );

    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;

    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();

    Future<void>.delayed(const Duration(seconds: 1), () {
      web.URL.revokeObjectURL(url);
    });
  }

  static String _escapeCsvValue(Object? value) {
    final rawValue = value?.toString() ?? '';
    final safeValue =
        value is String && RegExp(r'^\s*[=+\-@]').hasMatch(rawValue)
        ? "'$rawValue"
        : rawValue;
    final escapedValue = safeValue.replaceAll('"', '""');
    return '"$escapedValue"';
  }
}

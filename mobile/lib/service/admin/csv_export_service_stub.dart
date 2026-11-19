/// VM/non-web fallback for the conditional CSV import.
/// Report widgets compile here, while actual browser export uses csv_export_service_web.dart.
class CsvExportPlatform {
  static void download({
    required String fileName,
    required List<List<Object?>> rows,
  }) {
    throw UnsupportedError('CSV export is only available on web.');
  }
}

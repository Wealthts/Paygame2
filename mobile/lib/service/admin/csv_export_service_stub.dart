class CsvExportPlatform {
  static void download({
    required String fileName,
    required List<List<Object?>> rows,
  }) {
    throw UnsupportedError('CSV export is only available on web.');
  }
}

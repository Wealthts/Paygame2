import 'csv_export_service_stub.dart'
    if (dart.library.js_interop) 'csv_export_service_web.dart'
    as platform;

class CsvExportService {
  static void download({
    required String fileName,
    required List<List<Object?>> rows,
  }) => platform.CsvExportPlatform.download(fileName: fileName, rows: rows);
}

import 'package:material_ui/material_ui.dart';

import 'package:mobile/model/admin/admin_report_model.dart';
import 'package:mobile/service/admin/report_service.dart';

/// Presentation state for ReportView.
/// The controller owns loading/error/report state and notifies the UI after refreshes.
class ReportController extends ChangeNotifier {
  final ReportService reportService;

  ReportController(this.reportService);
  AdminReportModel? report;
  bool isLoading = false;
  String? errorMessage;

  /// Calls ReportService and records success or failure for AnimatedBuilder UI states.
  Future<void> loadReport() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      report = await reportService.getAdminReport();
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

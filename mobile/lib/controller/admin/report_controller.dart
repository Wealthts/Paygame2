import 'package:material_ui/material_ui.dart';

import 'package:mobile/model/admin/admin_report_model.dart';
import 'package:mobile/service/admin/report_service.dart';

class ReportController extends ChangeNotifier {
  final ReportService reportService;

  ReportController(this.reportService);
  AdminReportModel? report;
  bool isLoading = false;
  String? errorMessage;

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

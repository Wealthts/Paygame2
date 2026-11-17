import 'package:material_ui/material_ui.dart';

import 'package:mobile/model/point_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/point_service.dart';

class PointController extends ChangeNotifier {
  final PointService _pointService;

  PointController(this._pointService);

  List<PointModel> _transactions = [];

  bool _isLoading = false;
  bool _isSaving = false;

  String? _errorMessage;

  List<PointModel> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  int get totalEarned {
    return _transactions
        .where((item) => item.pointsDelta > 0)
        .fold(0, (sum, item) => sum + item.pointsDelta);
  }

  int get totalSpent {
    return _transactions
        .where((item) => item.pointsDelta < 0)
        .fold(0, (sum, item) => sum + item.pointsDelta.abs());
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _transactions = await _pointService.getAllTransactions();
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPoints({required int userId, required int points}) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final eventKey =
          'ADMIN_${userId}_${DateTime.now().microsecondsSinceEpoch}';

      await _pointService.addPoints(
        userId: userId,
        points: points,
        eventKey: eventKey,
      );

      _transactions = await _pointService.getAllTransactions();

      return true;
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  String _getErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is FormatException) {
      return error.message;
    }

    return 'เกิดข้อผิดพลาด กรุณาลองอีกครั้ง';
  }
}

import 'package:material_ui/material_ui.dart';

import 'package:mobile/model/payment_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/payment_service.dart';

class PaymentController extends ChangeNotifier {
  final PaymentService _paymentService;

  PaymentController(this._paymentService);

  List<PaymentModel> _payments = [];

  bool _isLoading = false;
  int? _busyPaymentId;
  String? _errorMessage;

  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  int? get busyPaymentId => _busyPaymentId;
  String? get errorMessage => _errorMessage;

  Future<void> loadPayments() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _payments = await _paymentService.getAllPayments();
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsPaid(int paymentId) async {
    await _performAction(
      paymentId,
      () => _paymentService.markAsPaid(paymentId),
    );
  }

  Future<void> cancelPayment(int paymentId) async {
    await _performAction(
      paymentId,
      () => _paymentService.cancelPayment(paymentId),
    );
  }

  Future<void> _performAction(
    int paymentId,
    Future<void> Function() action,
  ) async {
    if (_busyPaymentId != null) return;

    _busyPaymentId = paymentId;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      _payments = await _paymentService.getAllPayments();
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
    } finally {
      _busyPaymentId = null;
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

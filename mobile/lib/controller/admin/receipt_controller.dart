import 'package:material_ui/material_ui.dart';

import 'package:mobile/model/receipt_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/receipt_service.dart';

class ReceiptController extends ChangeNotifier {
  final ReceiptService _receiptService;

  ReceiptController(this._receiptService);

  List<ReceiptModel> _receipts = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<ReceiptModel> get receipts => _receipts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadReceipts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _receipts = await _receiptService.getAllReceipts();
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ReceiptModel?> getReceiptById(int receiptId) async {
    try {
      return await _receiptService.getReceiptById(receiptId);
    } catch (error) {
      _errorMessage = _getErrorMessage(error);
      notifyListeners();
      return null;
    }
  }

  String _getErrorMessage(Object error) {
    if (error is ApiException) {
      return error.message;
    }

    if (error is FormatException) {
      return error.message;
    }

    return 'Something went wrong. Please try again.';
  }
}

import 'package:mobile/model/receipt_model.dart';
import 'package:mobile/service/api_service.dart';

class ReceiptService {
  final ApiService _apiService;

  ReceiptService(this._apiService);

  static const String _endpoint = '/api/receipts';

  Future<List<ReceiptModel>> getAllReceipts() async {
    final response = await _apiService.get('$_endpoint/all');

    if (response is! Map) {
      throw const FormatException('Invalid receipt data format');
    }

    final data = Map<String, dynamic>.from(response);
    final receiptsJson = data['receipts'];

    if (receiptsJson is! List) {
      throw const FormatException('Receipts not found');
    }

    return receiptsJson.map((item) {
      return ReceiptModel.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  Future<ReceiptModel> getReceiptById(int receiptId) async {
    final response = await _apiService.get('$_endpoint/$receiptId');

    if (response is! Map) {
      throw const FormatException('Invalid receipt details format');
    }

    final data = Map<String, dynamic>.from(response);

    final receiptJson = data['receipt'] ?? data;

    if (receiptJson is! Map) {
      throw const FormatException('Receipt details not found');
    }

    return ReceiptModel.fromJson(Map<String, dynamic>.from(receiptJson));
  }

  // ========================================
  // Get My Receipts (Customer)
  // ========================================
  Future<List<ReceiptModel>> getMyReceipts() async {
    final response = await _apiService.get('$_endpoint/my-receipts');

    if (response is! Map) {
      throw const FormatException('Invalid receipt data format');
    }

    final data = Map<String, dynamic>.from(response);
    final receiptsJson = data['receipts'];

    if (receiptsJson is! List) {
      throw const FormatException('Receipts not found');
    }

    return receiptsJson.map((item) {
      if (item is! Map) {
        throw const FormatException('Invalid receipt data');
      }

      return ReceiptModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }
}

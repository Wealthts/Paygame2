import 'package:mobile/model/receipt_model.dart';
import 'package:mobile/service/api_service.dart';

class ReceiptService {
  final ApiService _apiService;

  ReceiptService(this._apiService);

  static const String _endpoint = '/api/receipts';

  Future<List<ReceiptModel>> getAllReceipts() async {
    final response = await _apiService.get('$_endpoint/all');

    if (response is! Map) {
      throw const FormatException('รูปแบบข้อมูลใบเสร็จไม่ถูกต้อง');
    }

    final data = Map<String, dynamic>.from(response);
    final receiptsJson = data['receipts'];

    if (receiptsJson is! List) {
      throw const FormatException('ไม่พบรายการใบเสร็จ');
    }

    return receiptsJson.map((item) {
      return ReceiptModel.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  Future<ReceiptModel> getReceiptById(int receiptId) async {
    final response = await _apiService.get('$_endpoint/$receiptId');

    if (response is! Map) {
      throw const FormatException('รูปแบบรายละเอียดใบเสร็จไม่ถูกต้อง');
    }

    final data = Map<String, dynamic>.from(response);

    final receiptJson = data['receipt'] ?? data;

    if (receiptJson is! Map) {
      throw const FormatException('ไม่พบรายละเอียดใบเสร็จ');
    }

    return ReceiptModel.fromJson(Map<String, dynamic>.from(receiptJson));
  }

  // ========================================
  // Get My Receipts (Customer)
  // ========================================
  Future<List<ReceiptModel>> getMyReceipts() async {
    final response = await _apiService.get('$_endpoint/my-receipts');

    if (response is! Map) {
      throw const FormatException('รูปแบบข้อมูลใบเสร็จไม่ถูกต้อง');
    }

    final data = Map<String, dynamic>.from(response);
    final receiptsJson = data['receipts'];

    if (receiptsJson is! List) {
      throw const FormatException('ไม่พบรายการใบเสร็จ');
    }

    return receiptsJson.map((item) {
      if (item is! Map) {
        throw const FormatException('ข้อมูลใบเสร็จไม่ถูกต้อง');
      }

      return ReceiptModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }
}

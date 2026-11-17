import 'package:mobile/model/payment_model.dart';
import 'package:mobile/service/api_service.dart';

class PaymentService {
  final ApiService _apiService;

  PaymentService(this._apiService);

  static const String _endpoint = '/api/payments';

  // ดึงรายการชำระเงินทั้งหมดสำหรับ Admin
  Future<List<PaymentModel>> getAllPayments() async {
    final response = await _apiService.get('$_endpoint/all');

    if (response is! Map) {
      throw const FormatException('รูปแบบข้อมูลการชำระเงินไม่ถูกต้อง');
    }

    final data = Map<String, dynamic>.from(response);
    final paymentsJson = data['payments'];

    if (paymentsJson is! List) {
      throw const FormatException('ไม่พบรายการชำระเงิน');
    }

    return paymentsJson.map((item) {
      return PaymentModel.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  // เปลี่ยนสถานะเป็น Paid
  Future<void> markAsPaid(int paymentId) async {
    await _apiService.patch('$_endpoint/$paymentId', body: {'status': 'Paid'});
  }

  // ========================================
  // Get My Payments (Customer)
  // ========================================
  Future<List<PaymentModel>> getMyPayments() async {
    final response = await _apiService.get('$_endpoint/my-payments');

    if (response is! Map || response['payments'] is! List) {
      throw const FormatException('รูปแบบประวัติการชำระเงินไม่ถูกต้อง');
    }

    final paymentsJson = response['payments'] as List;

    return paymentsJson.map((item) {
      if (item is! Map) {
        throw const FormatException('ข้อมูลการชำระเงินไม่ถูกต้อง');
      }

      return PaymentModel.fromJson(Map<String, dynamic>.from(item));
    }).toList();
  }

  // ========================================
  // Create Payment (Customer)
  // ========================================
  Future<Map<String, dynamic>> createPayment({
    required int orderId,
    required String transactionRef,
    required String method,
  }) async {
    if (orderId <= 0) {
      throw ArgumentError('Invalid order ID');
    }

    final response = await _apiService.post(
      _endpoint,
      body: {
        'order_id': orderId,
        'transaction_ref': transactionRef.trim(),
        'method': method.trim(),
      },
    );

    if (response is! Map) {
      throw const FormatException('รูปแบบข้อมูลการชำระเงินไม่ถูกต้อง');
    }

    return Map<String, dynamic>.from(response);
  }

  // ยกเลิก Payment
  Future<void> cancelPayment(int paymentId) async {
    await _apiService.delete('$_endpoint/$paymentId');
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/controller/receipt_controller.dart';
import 'package:mobile/model/receipt_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/receipt_service.dart';

/// Mock ApiService: returns a canned response per GET path, no network.
/// A response that is an Exception is thrown instead of returned.
class _MockApiService extends ApiService {
  _MockApiService(this.responses);

  final Map<String, Object?> responses;
  final requests = <String>[];

  @override
  Future<dynamic> get(String path, {bool requiresAuth = true}) async {
    requests.add('GET $path');
    final response = responses[path];
    if (response is Exception) throw response;
    return response;
  }
}

const _receiptJson = {
  'receipt_id': 1,
  'order_id': 101,
  'receipt_number': 'RCP_101',
  'issued_at': '2026-01-02T12:05:00Z',
  'game_name_snapshot': 'Arena Test',
  'package_name_snapshot': '500 Diamonds',
  'total_amount': '159.00',
};

void main() {
  group('ReceiptModel', () {
    test('parses receipt metadata and total amount', () {
      final receipt = ReceiptModel.fromJson({
        'receipt_id': '13',
        'order_id': 44,
        'receipt_number': 'PG-2026-00013',
        'issued_at': '2026-07-14T09:30:00Z',
        'game_name_snapshot': 'Game D',
        'package_name_snapshot': 'Weekly Pass',
        'total_amount': '299.00',
      });

      expect(receipt.receiptId, 13);
      expect(receipt.orderId, 44);
      expect(receipt.receiptNumber, 'PG-2026-00013');
      expect(receipt.totalAmount, 299);
      expect(receipt.issuedAt, isNotNull);
    });

    test('missing or bad fields fall back to safe defaults', () {
      final receipt = ReceiptModel.fromJson({
        'receipt_id': 'abc',
        'issued_at': 'not-a-date',
      });

      expect(receipt.receiptId, 0);
      expect(receipt.orderId, 0);
      expect(receipt.receiptNumber, '');
      expect(receipt.issuedAt, isNull);
      expect(receipt.gameName, isNull);
      expect(receipt.totalAmount, isNull);
    });
  });

  group('ReceiptService (mock API)', () {
    test('getMyReceipts calls my-receipts and parses the list', () async {
      final api = _MockApiService({
        '/api/receipts/my-receipts': {
          'receipts': [_receiptJson],
        },
      });

      final receipts = await ReceiptService(api).getMyReceipts();

      expect(api.requests, ['GET /api/receipts/my-receipts']);
      expect(receipts, hasLength(1));
      expect(receipts.first.receiptNumber, 'RCP_101');
      expect(receipts.first.totalAmount, 159);
    });

    test('getAllReceipts calls the admin endpoint', () async {
      final api = _MockApiService({
        '/api/receipts/all': {
          'receipts': [_receiptJson, _receiptJson],
        },
      });

      final receipts = await ReceiptService(api).getAllReceipts();

      expect(api.requests, ['GET /api/receipts/all']);
      expect(receipts, hasLength(2));
    });

    test('getReceiptById reads a wrapped or plain receipt', () async {
      final api = _MockApiService({
        '/api/receipts/1': {'receipt': _receiptJson},
        '/api/receipts/2': _receiptJson,
      });
      final service = ReceiptService(api);

      expect((await service.getReceiptById(1)).orderId, 101);
      expect((await service.getReceiptById(2)).orderId, 101);
    });

    test('bad response shape throws FormatException', () async {
      final api = _MockApiService({
        '/api/receipts/my-receipts': {'receipts': 'oops'},
        '/api/receipts/all': 'not json',
      });
      final service = ReceiptService(api);

      expect(service.getMyReceipts(), throwsFormatException);
      expect(service.getAllReceipts(), throwsFormatException);
    });

    test('API error is passed through', () async {
      final api = _MockApiService({
        '/api/receipts/my-receipts': const ApiException(
          statusCode: 401,
          message: 'Unauthorized',
        ),
      });

      expect(
        ReceiptService(api).getMyReceipts(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'code', 401)),
      );
    });
  });

  group('ReceiptController (mock API)', () {
    test('loadReceipts stores receipts and toggles loading', () async {
      final api = _MockApiService({
        '/api/receipts/all': {
          'receipts': [_receiptJson],
        },
      });
      final controller = ReceiptController(ReceiptService(api));
      final loading = <bool>[];
      controller.addListener(() => loading.add(controller.isLoading));

      await controller.loadReceipts();

      expect(loading, [true, false]);
      expect(controller.receipts, hasLength(1));
      expect(controller.errorMessage, isNull);
    });

    test('loadReceipts keeps the API message on error', () async {
      final api = _MockApiService({
        '/api/receipts/all': const ApiException(
          statusCode: 500,
          message: 'Server down',
        ),
      });
      final controller = ReceiptController(ReceiptService(api));

      await controller.loadReceipts();

      expect(controller.errorMessage, 'Server down');
      expect(controller.receipts, isEmpty);
      expect(controller.isLoading, isFalse);
    });

    test('getReceiptById returns null and sets error on failure', () async {
      final api = _MockApiService({
        '/api/receipts/9': const ApiException(
          statusCode: 404,
          message: 'Receipt not found',
        ),
      });
      final controller = ReceiptController(ReceiptService(api));

      expect(await controller.getReceiptById(9), isNull);
      expect(controller.errorMessage, 'Receipt not found');
    });
  });
}

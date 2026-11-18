import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/controller/point_controller.dart';
import 'package:mobile/model/point_model.dart';
import 'package:mobile/service/api_service.dart';
import 'package:mobile/service/point_service.dart';

/// Mock ApiService: returns a canned response per path, no network.
/// A response that is an Exception is thrown instead of returned.
class _MockApiService extends ApiService {
  _MockApiService(this.responses);

  final Map<String, Object?> responses;
  final requests = <String>[];
  Object? lastBody;

  Future<dynamic> _reply(String request, String path) async {
    requests.add(request);
    final response = responses[path];
    if (response is Exception) throw response;
    return response;
  }

  @override
  Future<dynamic> get(String path, {bool requiresAuth = true}) =>
      _reply('GET $path', path);

  @override
  Future<dynamic> post(String path, {Object? body, bool requiresAuth = true}) {
    lastBody = body;
    return _reply('POST $path', 'POST $path');
  }
}

Map<String, Object?> _pointJson(int id, int delta) => {
  'point_transaction_id': id,
  'user_id': 10,
  'order_id': null,
  'event_key': 'ADMIN_$id',
  'type': delta > 0 ? 'Earn' : 'Spend',
  'points_delta': delta,
  'created_at': '2026-01-02T12:05:00Z',
};

void main() {
  group('PointModel', () {
    test('parses positive and nullable transaction fields', () {
      final point = PointModel.fromJson({
        'point_transaction_id': '91',
        'user_id': 8,
        'order_id': null,
        'event_key': 'signup_event',
        'type': 'Earn',
        'points_delta': '50',
        'created_at': '2026-08-01T00:00:00Z',
      });

      expect(point.pointTransactionId, 91);
      expect(point.userId, 8);
      expect(point.orderId, isNull);
      expect(point.pointsDelta, 50);
      expect(point.type, 'Earn');
      expect(point.createdAt, isNotNull);
    });

    test('parses negative delta, order id and user names', () {
      final point = PointModel.fromJson({
        'point_transaction_id': 5,
        'user_id': '3',
        'order_id': '17',
        'event_key': 'ORDER_17_SPEND',
        'type': 'Spend',
        'points_delta': '-15',
        'username': 'test_player',
        'display_name': 'Test Player',
      });

      expect(point.orderId, 17);
      expect(point.pointsDelta, -15);
      expect(point.username, 'test_player');
      expect(point.displayName, 'Test Player');
      expect(point.createdAt, isNull);
    });
  });

  group('PointService (mock API)', () {
    test('getMyPoints reads total_points as int', () async {
      final api = _MockApiService({
        '/api/points/my-points': {'total_points': '1250'},
      });

      expect(await PointService(api).getMyPoints(), 1250);
      expect(api.requests, ['GET /api/points/my-points']);
    });

    test('getMyPoints rejects missing or non-number total', () async {
      final missing = _MockApiService({'/api/points/my-points': {}});
      final bad = _MockApiService({
        '/api/points/my-points': {'total_points': 'abc'},
      });

      expect(PointService(missing).getMyPoints(), throwsFormatException);
      expect(PointService(bad).getMyPoints(), throwsFormatException);
    });

    test('getMyPointHistory parses the history list', () async {
      final api = _MockApiService({
        '/api/points/history': {
          'history': [_pointJson(1, 25), _pointJson(2, -10)],
        },
      });

      final history = await PointService(api).getMyPointHistory();

      expect(history.map((p) => p.pointsDelta), [25, -10]);
      expect(api.requests, ['GET /api/points/history']);
    });

    test('getAllTransactions throws on bad shape', () async {
      final api = _MockApiService({
        '/api/points/all': {'transactions': null},
      });

      expect(PointService(api).getAllTransactions(), throwsFormatException);
    });

    test('addPoints posts an Earn transaction body', () async {
      final api = _MockApiService({'POST /api/points': {}});

      await PointService(
        api,
      ).addPoints(userId: 3, points: 100, eventKey: 'ADMIN_3_1');

      expect(api.requests, ['POST /api/points']);
      expect(api.lastBody, {
        'user_id': 3,
        'event_key': 'ADMIN_3_1',
        'type': 'Earn',
        'points_delta': 100,
      });
    });
  });

  group('PointController (mock API)', () {
    test('loadTransactions sums earned and spent', () async {
      final api = _MockApiService({
        '/api/points/all': {
          'transactions': [
            _pointJson(1, 25),
            _pointJson(2, -10),
            _pointJson(3, 5),
          ],
        },
      });
      final controller = PointController(PointService(api));

      await controller.loadTransactions();

      expect(controller.transactions, hasLength(3));
      expect(controller.totalEarned, 30);
      expect(controller.totalSpent, 10);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('loadTransactions keeps the API message on error', () async {
      final api = _MockApiService({
        '/api/points/all': const ApiException(
          statusCode: 500,
          message: 'Server down',
        ),
      });
      final controller = PointController(PointService(api));

      await controller.loadTransactions();

      expect(controller.errorMessage, 'Server down');
      expect(controller.transactions, isEmpty);
    });

    test('addPoints posts with ADMIN_ key then reloads', () async {
      final api = _MockApiService({
        'POST /api/points': {},
        '/api/points/all': {
          'transactions': [_pointJson(1, 100)],
        },
      });
      final controller = PointController(PointService(api));

      final ok = await controller.addPoints(userId: 3, points: 100);

      expect(ok, isTrue);
      expect(api.requests, ['POST /api/points', 'GET /api/points/all']);
      expect((api.lastBody as Map)['event_key'], startsWith('ADMIN_3_'));
      expect(controller.transactions, hasLength(1));
      expect(controller.isSaving, isFalse);
    });

    test('addPoints returns false and skips reload on error', () async {
      final api = _MockApiService({
        'POST /api/points': const ApiException(
          statusCode: 404,
          message: 'User not found',
        ),
      });
      final controller = PointController(PointService(api));

      final ok = await controller.addPoints(userId: 999, points: 5);

      expect(ok, isFalse);
      expect(api.requests, ['POST /api/points']);
      expect(controller.errorMessage, 'User not found');
      expect(controller.isSaving, isFalse);
    });
  });
}

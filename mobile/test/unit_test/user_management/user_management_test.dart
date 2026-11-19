import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/model/admin/user_admin_model.dart';
import 'package:mobile/model/admin/user_details_model.dart';

void main() {
  group('AdminUserModel', () {
    test('parses active member JSON including string numbers', () {
      final user = AdminUserModel.fromJson({
        'user_id': '15',
        'username': 'player_one',
        'email': 'player1@example.com',
        'display_name': 'Player One',
        'role': 'user',
        'is_active': '1',
        'created_at': '2026-10-15T08:30:00.000Z',
      });

      expect(user.userId, 15);
      expect(user.username, 'player_one');
      expect(user.email, 'player1@example.com');
      expect(user.displayName, 'Player One');
      expect(user.role, 'user');
      expect(user.isActive, isTrue);
      expect(user.createdAt, '2026-10-15T08:30:00.000Z');
    });

    test('parses inactive user and applies default values for missing fields', () {
      final user = AdminUserModel.fromJson({
        'user_id': 20,
        'is_active': 0,
      });

      expect(user.userId, 20);
      expect(user.username, '');
      expect(user.email, '');
      expect(user.displayName, '');
      expect(user.role, 'user');
      expect(user.isActive, isFalse);
      expect(user.createdAt, '');
    });
  });

  group('UserDetailsModel', () {
    test('parses user profile, summary metrics, and history lists', () {
      final details = UserDetailsModel.fromJson({
        'user': {
          'user_id': 15,
          'username': 'player_one',
          'email': 'player1@example.com',
          'display_name': 'Player One',
          'role': 'user',
          'is_active': 1,
          'created_at': '2026-10-15T08:30:00.000Z',
        },
        'summary': {
          'order_count': '4',
          'payment_count': 3,
          'paid_amount': '450.50',
          'point_balance': '120',
          'receipt_count': 3,
          'coupon_count': 2,
        },
        'orders': [
          {'order_id': 101, 'total_amount': 150},
        ],
        'payments': [
          {'payment_id': 201, 'status': 'Paid'},
        ],
        'point_transactions': [
          {'point_transaction_id': 301, 'points_delta': 20},
        ],
        'receipts': [
          {'receipt_id': 401, 'receipt_number': 'PG-0401'},
        ],
        'user_coupons': [
          {'user_coupon_id': 501, 'code': 'WELCOME50'},
        ],
      });

      expect(details.user.userId, 15);
      expect(details.orderCount, 4);
      expect(details.paymentCount, 3);
      expect(details.paidAmount, 450.50);
      expect(details.pointBalance, 120);
      expect(details.receiptCount, 3);
      expect(details.couponCount, 2);
      expect(details.orders, hasLength(1));
      expect(details.payments, hasLength(1));
      expect(details.pointTransactions, hasLength(1));
      expect(details.receipts, hasLength(1));
      expect(details.userCoupons, hasLength(1));
    });

    test('handles missing or non-list history arrays gracefully', () {
      final details = UserDetailsModel.fromJson({
        'user': {'user_id': 1, 'username': 'admin', 'role': 'admin'},
        'summary': {},
        'orders': null,
        'payments': 'invalid',
      });

      expect(details.orderCount, 0);
      expect(details.paidAmount, 0.0);
      expect(details.orders, isEmpty);
      expect(details.payments, isEmpty);
      expect(details.pointTransactions, isEmpty);
      expect(details.receipts, isEmpty);
      expect(details.userCoupons, isEmpty);
    });
  });
}
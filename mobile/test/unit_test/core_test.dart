import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/api_constant.dart';
import 'package:mobile/core/app_colors.dart';
import 'package:mobile/core/formatter.dart';
import 'package:mobile/core/validator.dart';

void main() {
  group('PayGame core utilities', () {
    test('API configuration defaults to local Chrome development server', () {
      expect(ApiConstant.baseUrl, startsWith('http'));
      expect(ApiConstant.baseUrl, contains('localhost:3000'));
      expect(ApiConstant.authLogin, '/api/auth/login');
    });

    test('brand palette exposes the approved red gold and white colors', () {
      expect(AppColors.red.toARGB32(), 0xFFB0151F);
      expect(AppColors.gold.toARGB32(), 0xFFD4A72C);
      expect(AppColors.white.toARGB32(), 0xFFFFFFFF);
      expect(AppColors.cream.toARGB32(), 0xFFFFF8EC);
    });

    test('formats currency, grouped numbers and dates', () {
      expect(AppFormatter.formatNumber(1250000), '1,250,000');
      expect(AppFormatter.formatCurrency(1250), '฿1,250.00');
      expect(AppFormatter.formatCurrency(10, decimalDigits: 0), '฿10');
      expect(AppFormatter.formatDate(DateTime(2026, 4, 5)), '05/04/2026');
      expect(AppFormatter.formatTime(DateTime(2026, 4, 5, 9, 7)), '09:07');
    });

    test('maps known order/payment status values to Thai labels', () {
      expect(AppFormatter.formatStatus('Pending'), 'รอดำเนินการ');
      expect(AppFormatter.formatStatus('Completed'), 'สำเร็จ');
      expect(AppFormatter.formatStatus('unknown-status'), 'unknown-status');
      expect(AppFormatter.formatStatus(null), 'ไม่ระบุสถานะ');
    });

    test('validates player UID and optional server code', () {
      const uidPattern = r'^\d{8}$';
      expect(AppValidator.playerUid('12345678', pattern: uidPattern), isNull);
      expect(AppValidator.playerUid('', pattern: uidPattern), isNotNull); 
      expect(
        AppValidator.playerUid('123ABC78', pattern: uidPattern),
        isNull,
      );
      expect(AppValidator.serverCode('', isRequired: false), isNull);
      expect(AppValidator.serverCode('', isRequired: true), isNotNull);
      expect(AppValidator.serverCode('TH-01', isRequired: true), isNull);
    });
  });
}

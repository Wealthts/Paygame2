/// Formatting helpers used by customer and administrator screens.
/// No intl dependency is required.
abstract final class AppFormatter {
  static String formatNumber(num value) {
    final text = value.toString();
    final parts = text.split('.');
    final integer = parts.first;
    final grouped = integer.replaceAllMapped(
      RegExp(r'(?<=\d)(?=(\d{3})+$)'),
      (_) => ',',
    );
    return parts.length == 1 ? grouped : '$grouped.${parts[1]}';
  }

  static String formatCurrency(
    num value, {
    String symbol = '฿',
    int decimalDigits = 2,
  }) {
    final fixed = value.toStringAsFixed(decimalDigits);
    final parts = fixed.split('.');
    final integer = parts[0].replaceAllMapped(
      RegExp(r'(?<=\d)(?=(\d{3})+$)'),
      (_) => ',',
    );
    final decimal = decimalDigits == 0 ? '' : '.${parts[1]}';
    return '$symbol$integer$decimal';
  }

  static String formatPoints(int value) => formatNumber(value);

  static String formatDate(DateTime? value, {String emptyValue = '-'}) {
    if (value == null) return emptyValue;
    final date = value.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  static String formatTime(DateTime? value, {String emptyValue = '-'}) {
    if (value == null) return emptyValue;
    final date = value.toLocal();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String formatDateTime(DateTime? value, {String emptyValue = '-'}) {
    if (value == null) return emptyValue;
    return '${formatDate(value)} ${formatTime(value)}';
  }

  static String formatStatus(String? value) {
    final status = value?.trim() ?? '';
    if (status.isEmpty) return 'ไม่ระบุสถานะ';

    switch (status.toLowerCase()) {
      case 'pending':
        return 'รอดำเนินการ';
      case 'processing':
        return 'กำลังดำเนินการ';
      case 'completed':
        return 'สำเร็จ';
      case 'cancelled':
      case 'canceled':
        return 'ยกเลิก';
      case 'failed':
        return 'ไม่สำเร็จ';
      case 'paid':
        return 'ชำระแล้ว';
      case 'unpaid':
        return 'ยังไม่ชำระ';
      default:
        return status;
    }
  }
}

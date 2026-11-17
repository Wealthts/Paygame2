/// Pure validators shared by form fields and unit tests.
abstract final class AppValidator {
  static String? requiredText(
    String? value, {
    String fieldName = 'ข้อมูล',
    int? maxLength,
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'กรุณากรอก$fieldName';
    if (maxLength != null && text.length > maxLength) {
      return '$fieldNameต้องไม่เกิน $maxLength ตัวอักษร';
    }
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'กรุณากรอก Email';
    if (text.length > 100) return 'Email ต้องไม่เกิน 100 ตัวอักษร';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(text)) {
      return 'รูปแบบ Email ไม่ถูกต้อง';
    }
    return null;
  }

  static String? username(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'กรุณากรอก Username';
    if (text.length < 3 || text.length > 100) {
      return 'Username ต้องมีความยาว 3–100 ตัวอักษร';
    }
    if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(text)) {
      return 'Username ใช้ได้เฉพาะภาษาอังกฤษ ตัวเลข . _ และ -';
    }
    return null;
  }

  static String? password(String? value) {
    final text = value ?? '';
    if (text.isEmpty) return 'กรุณากรอกรหัสผ่าน';
    if (text.length < 8) return 'รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร';
    if (text.length > 128) return 'รหัสผ่านต้องไม่เกิน 128 ตัวอักษร';
    return null;
  }

  static String? confirmPassword(
    String? value, {
    required String passwordValue,
  }) {
    if (value == null || value.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
    if (value != passwordValue) return 'รหัสผ่านไม่ตรงกัน';
    return null;
  }

  static String? displayName(String? value) {
    return requiredText(value, fieldName: 'ชื่อที่ใช้แสดง', maxLength: 100);
  }

  static String? playerUid(String? value, {required String pattern}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'กรุณากรอก Player UID';
    if (text.length < 3 || text.length > 80) {
      return 'Player UID ต้องมีความยาว 3–80 ตัวอักษร';
    }
    if (RegExp(r'[<>]').hasMatch(text)) {
      return 'Player UID มีอักขระที่ไม่อนุญาต';
    }
    return null;
  }

  static String? serverCode(String? value, {required bool isRequired}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty && !isRequired) return null;
    if (text.isEmpty) return 'กรุณากรอก Server ID';
    if (text.length > 40) return 'Server ID ต้องไม่เกิน 40 ตัวอักษร';
    if (RegExp(r'[<>]').hasMatch(text)) return 'Server ID มีอักขระที่ไม่อนุญาต';
    return null;
  }

  static String? phone(String? value, {bool isRequired = false}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return isRequired ? 'กรุณากรอกเบอร์โทรศัพท์' : null;
    final digits = text.replaceAll(RegExp(r'[\s-]'), '');
    if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(digits)) {
      return 'รูปแบบเบอร์โทรศัพท์ไม่ถูกต้อง';
    }
    return null;
  }
}

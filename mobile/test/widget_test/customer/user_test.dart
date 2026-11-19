import 'package:flutter_test/flutter_test.dart'; // นำเข้าเครื่องมือสำหรับเขียนและรันทดสอบ Flutter
import 'package:material_ui/material_ui.dart'; // นำเข้า widget พื้นฐานที่ใช้สร้างหน้าแอป
import 'package:mobile/model/user_model.dart'; // นำเข้าโมเดลข้อมูลผู้ใช้สำหรับ service จำลอง
import 'package:mobile/service/customer/customer_profile_service.dart'; // นำเข้า service โปรไฟล์ที่หน้าจอต้องใช้
import 'package:mobile/view/customer/user_view.dart'; // นำเข้าหน้าโปรไฟล์ลูกค้าที่ต้องการทดสอบ
import 'package:provider/provider.dart'; // นำเข้า Provider สำหรับส่ง service ให้หน้าจอ

import '../../support/fake_services.dart'; // นำเข้า service จำลองและข้อมูลผู้ใช้ทดสอบ

void main() { // กำหนดชุดการทดสอบทั้งหมดของไฟล์นี้
  testWidgets('profile page displays the signed-in user profile', (tester) async { // ทดสอบว่าหน้าแสดงข้อมูลบัญชีที่ลงชื่อเข้าใช้
    await tester.pumpWidget(_buildProfilePage(FakeCustomerProfileService())); // เปิดหน้าด้วย service จำลองที่ส่งข้อมูลผู้ใช้สำเร็จ
    await tester.pumpAndSettle(); // รอให้การสร้างและอัปเดต widget เสร็จสิ้น

    expect(find.text('ข้อมูลส่วนตัว'), findsOneWidget); // ตรวจว่ามีชื่อหน้าข้อมูลส่วนตัว
    expect(find.text('Test Player'), findsNWidgets(2)); // ตรวจว่าชื่อแสดงทั้งส่วนหัวและรายละเอียดบัญชี
    expect(find.text('@test_player'), findsOneWidget); // ตรวจว่ามีชื่อบัญชีพร้อมเครื่องหมาย @
    expect(find.text('CUSTOMER'), findsOneWidget); // ตรวจว่าบัญชีแสดงสถานะลูกค้า
    expect(find.text('10'), findsOneWidget); // ตรวจว่ามีรหัสผู้ใช้ตามข้อมูลจำลอง
    expect(find.text('test@example.com'), findsOneWidget); // ตรวจว่าอีเมลของผู้ใช้ถูกแสดง
    expect(find.text('รายละเอียดบัญชี'), findsOneWidget); // ตรวจว่ามีหัวข้อรายละเอียดบัญชี
  }); // จบการทดสอบกรณีโหลดโปรไฟล์สำเร็จ

  testWidgets('profile page shows a loading state while fetching data', (tester) async { // ทดสอบสถานะระหว่างรอข้อมูลโปรไฟล์
    final service = _DelayedCustomerProfileService(); // สร้าง service ที่หน่วงการตอบกลับเพื่อให้เห็นสถานะโหลด
    await tester.pumpWidget(_buildProfilePage(service)); // เปิดหน้าโปรไฟล์ด้วย service ที่ตอบกลับช้า

    expect(find.text('กำลังโหลดข้อมูลโปรไฟล์...'), findsOneWidget); // ตรวจว่าหน้าแสดงข้อความระหว่างโหลด
    expect(find.byType(CircularProgressIndicator), findsOneWidget); // ตรวจว่ามีวงแสดงความคืบหน้าระหว่างโหลด

    await tester.pump(const Duration(seconds: 1)); // เลื่อนเวลาใน widget test ให้ครบช่วงหน่วงของ service
    await tester.pumpAndSettle(); // รอให้การแสดงข้อมูลหลังโหลดเสร็จสิ้น
    expect(find.text('@test_player'), findsOneWidget); // ตรวจว่าหน้าแสดงชื่อบัญชีเมื่อโหลดสำเร็จ
  }); // จบการทดสอบสถานะกำลังโหลด

  testWidgets('profile page shows an error when loading fails', (tester) async { // ทดสอบว่าหน้าแจ้งข้อผิดพลาดเมื่อโหลดโปรไฟล์ไม่สำเร็จ
    await tester.pumpWidget(_buildProfilePage(_FailingCustomerProfileService())); // เปิดหน้าด้วย service ที่จำลองข้อผิดพลาด
    await tester.pumpAndSettle(); // รอให้ FutureBuilder รับรู้ผลลัพธ์ที่ผิดพลาด

    expect(find.text('ไม่สามารถโหลดข้อมูลโปรไฟล์ได้'), findsOneWidget); // ตรวจว่ามีข้อความแจ้งว่าโหลดโปรไฟล์ไม่ได้
    expect(find.text('ลองอีกครั้ง'), findsOneWidget); // ตรวจว่ามีปุ่มสำหรับลองโหลดข้อมูลใหม่
  }); // จบการทดสอบสถานะข้อผิดพลาด
} // จบชุดการทดสอบ

Widget _buildProfilePage(CustomerProfileService service) { // สร้าง widget สำหรับเปิดหน้าด้วย service ที่กำหนด
  return Provider<CustomerProfileService>( // สร้าง Provider สำหรับส่ง service เข้าไปใน widget tree
    create: (_) => service, // ส่ง service ที่ได้รับเข้าถึงหน้าโปรไฟล์
    child: const MaterialApp(home: CustomerProfileView()), // กำหนดหน้าโปรไฟล์เป็นหน้าแรกของแอปทดสอบ
  ); // คืนค่า Provider ที่ห่อหน้าจอทดสอบ
} // จบฟังก์ชันสร้างหน้าโปรไฟล์สำหรับทดสอบ

class _DelayedCustomerProfileService extends FakeCustomerProfileService { // สร้าง service จำลองที่ตอบกลับหลังหน่วงเวลา
  @override // ระบุว่าเมธอดนี้เขียนทับเมธอดของ service จำลองเดิม
  Future<UserModel> getMyProfile() async { // กำหนดการโหลดโปรไฟล์แบบไม่พร้อมใช้งานทันที
    await Future<void>.delayed(const Duration(seconds: 1)); // หน่วงการตอบกลับหนึ่งวินาทีเพื่อทดสอบสถานะโหลด
    return super.getMyProfile(); // คืนข้อมูลโปรไฟล์จำลองหลังครบเวลาหน่วง
  } // จบเมธอดโหลดโปรไฟล์แบบหน่วงเวลา
} // จบคลาส service จำลองแบบหน่วงเวลา

class _FailingCustomerProfileService extends FakeCustomerProfileService { // สร้าง service จำลองที่โหลดโปรไฟล์ไม่สำเร็จ
  @override // ระบุว่าเมธอดนี้เขียนทับเมธอดของ service จำลองเดิม
  Future<UserModel> getMyProfile() async { // กำหนดเมธอดโหลดโปรไฟล์ให้เกิดข้อผิดพลาด
    throw StateError('จำลองการโหลดโปรไฟล์ไม่สำเร็จ'); // ส่งข้อผิดพลาดเพื่อทดสอบหน้าจอสถานะผิดพลาด
  } // จบเมธอดที่จำลองการโหลดล้มเหลว
} // จบคลาส service จำลองที่ล้มเหลว